import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:connectify_app/screens/home_screen.dart'; // Anasayfaya yönlendirme için
import 'package:connectify_app/services/snackbar_service.dart'; // SnackBarService import edildi
import 'package:connectify_app/utils/app_colors.dart'; // Renk paletimiz için

class ProfileSetupScreen extends StatefulWidget {
  final Map<String, dynamic>?
  initialData; // Mevcut profil verileri için opsiyonel parametre

  const ProfileSetupScreen({super.key, this.initialData});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String? _selectedGender;
  int? _selectedAge;
  List<String> _selectedInterests = [];

  File? _profileImageFile; // Yeni seçilen ana profil fotoğrafı (File objesi)
  String?
  _profileImageUrl; // Ana profil fotoğrafının URL'si (mevcut veya yeni yüklenen)

  // Diğer fotoğraflar için tek bir liste kullanıyoruz.
  // İçinde hem File (yeni seçilenler) hem de String (mevcut URL'ler) tutabiliriz.
  // Bu, yönetimi basitleştirir.
  final List<dynamic> _otherImages = []; // File veya String URL tutacak

  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isLoading = false;

  final List<String> _genders = ['Kadın', 'Erkek', 'Belirtmek İstemiyorum'];
  final List<String> _availableInterests = [
    'Seyahat',
    'Kitaplar',
    'Film/Dizi',
    'Müzik',
    'Spor',
    'Yemek Yapma',
    'Yürüyüş',
    'Fotoğrafçılık',
    'Dans',
    'Gaming',
    'Sanat',
    'Moda',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _nameController.text = widget.initialData!['name'] ?? '';
      _bioController.text = widget.initialData!['bio'] ?? '';
      _selectedGender = widget.initialData!['gender'];
      _selectedAge = widget.initialData!['age'];
      _selectedInterests = List<String>.from(
        widget.initialData!['interests'] ?? [],
      );
      _profileImageUrl = widget.initialData!['profileImageUrl'];

      // Mevcut diğer fotoğraf URL'lerini _otherImages listesine ekle
      _otherImages.addAll(
        List<String>.from(widget.initialData!['otherImageUrls'] ?? []),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Fotoğraf seçme fonksiyonu
  Future<void> _pickImage(
    ImageSource source, {
    bool isProfileImage = true,
    int? existingImageIndex,
  }) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        if (isProfileImage) {
          _profileImageFile = File(pickedFile.path);
          _profileImageUrl = null; // Yeni resim seçilince eski URL'yi temizle
        } else {
          // Eğer mevcut bir yuvaya yeni fotoğraf ekleniyorsa veya değiştiriliyorsa
          if (existingImageIndex != null &&
              existingImageIndex < _otherImages.length) {
            _otherImages[existingImageIndex] = File(
              pickedFile.path,
            ); // Mevcut fotoğrafı değiştir
          } else if (_otherImages.length < 5) {
            // Max 5 fotoğraf sınırı
            _otherImages.add(File(pickedFile.path)); // Yeni fotoğraf ekle
          } else {
            SnackBarService.showSnackBar(
              context,
              message: 'En fazla 5 ek fotoğraf yükleyebilirsiniz.',
              type: SnackBarType.info,
            );
          }
        }
      });
    }
  }

  // İlgi alanı seçme/kaldırma
  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  // Profil Oluşturma/Kaydetme Fonksiyonu
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      SnackBarService.showSnackBar(
        context,
        message: 'Lütfen tüm zorunlu alanları doldurun.',
        type: SnackBarType.error,
      );
      return;
    }
    // Profil oluşturuluyorsa profil resmi zorunlu
    if (widget.initialData == null &&
        _profileImageFile == null &&
        _profileImageUrl == null) {
      SnackBarService.showSnackBar(
        context,
        message: 'Lütfen bir profil fotoğrafı seçin.',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      SnackBarService.showSnackBar(
        context,
        message: 'Kullanıcı oturumu bulunamadı.',
        type: SnackBarType.error,
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      String? finalProfileImageUrl = _profileImageUrl; // Mevcut URL'yi koru

      // 1. Yeni Profil Fotoğrafını Yükle (varsa)
      if (_profileImageFile != null) {
        final profileImageRef = _storage.ref().child(
          'user_profiles/${currentUser.uid}/profile.jpg',
        );
        await profileImageRef.putFile(_profileImageFile!);
        finalProfileImageUrl = await profileImageRef.getDownloadURL();
      }

      // 2. Diğer Fotoğrafları Yükle ve URL'leri Topla
      List<String> finalOtherImageUrls = [];
      for (int i = 0; i < _otherImages.length; i++) {
        final item = _otherImages[i];
        if (item is File) {
          // Yeni seçilen File ise yükle
          final otherImageRef = _storage.ref().child(
            'user_profiles/${currentUser.uid}/other_photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          );
          await otherImageRef.putFile(item);
          finalOtherImageUrls.add(await otherImageRef.getDownloadURL());
        } else if (item is String && item.isNotEmpty) {
          // Mevcut URL ise direkt ekle
          finalOtherImageUrls.add(item);
        }
      }

      // 3. Kullanıcı Bilgilerini Firestore'a Kaydet/Güncelle
      await _firestore.collection('users').doc(currentUser.uid).set({
        'uid': currentUser.uid,
        'email': currentUser.email,
        'phoneNumber': currentUser.phoneNumber,
        'name': _nameController.text.trim(),
        'age': _selectedAge,
        'gender': _selectedGender,
        'bio': _bioController.text.trim(),
        'interests': _selectedInterests,
        'profileImageUrl': finalProfileImageUrl,
        'otherImageUrls': finalOtherImageUrls, // Güncellenmiş liste
        'location': 'Ankara, Türkiye', // Şimdilik sabit
        'isProfileCompleted': true,
        'isPremium': widget.initialData?['isPremium'] ?? false,
        'likesRemainingToday': widget.initialData?['likesRemainingToday'] ?? 20,
        'messagesRemainingToday':
            widget.initialData?['messagesRemainingToday'] ?? 5,
        'createdAt':
            widget.initialData?['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      SnackBarService.showSnackBar(
        context,
        message: 'Profil başarıyla kaydedildi!',
        type: SnackBarType.success,
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint("Profil kaydetme hatası: $e");
      SnackBarService.showSnackBar(
        context,
        message: 'Profil kaydedilirken bir hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Diğer fotoğrafı silme fonksiyonu
  void _removeOtherImage(int index) {
    // isNewImage parametresi kaldırıldı
    setState(() {
      if (index < _otherImages.length) {
        _otherImages.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialData == null ? 'Profil Oluştur' : 'Profili Düzenle',
        ),
        automaticallyImplyLeading: widget.initialData != null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Profil Fotoğrafı ---
                    Center(
                      child: GestureDetector(
                        onTap: () =>
                            _showImageSourceDialog(isProfileImage: true),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor: AppColors.grey.withOpacity(
                            0.2,
                          ), // Renk paletinden
                          backgroundImage: _profileImageFile != null
                              ? FileImage(_profileImageFile!)
                              : (_profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                    : null),
                          child:
                              _profileImageFile == null &&
                                  _profileImageUrl == null
                              ? Icon(
                                  Icons.camera_alt,
                                  size: 50,
                                  color: AppColors
                                      .secondaryText, // Renk paletinden
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Profil Fotoğrafı (Zorunlu)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 32),

                    // --- Diğer Fotoğraflar ---
                    const Text(
                      'Diğer Fotoğraflar (Max 5)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: 5, // Her zaman 5 adet boş yuva göster
                      itemBuilder: (context, index) {
                        bool hasImage = index < _otherImages.length;
                        dynamic imageSource = hasImage
                            ? _otherImages[index]
                            : null;

                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                // Eğer yuvada fotoğraf yoksa yeni seç, varsa değiştir
                                if (!hasImage ||
                                    imageSource is String &&
                                        imageSource.isEmpty) {
                                  _showImageSourceDialog(isProfileImage: false);
                                } else {
                                  _showImageSourceDialog(
                                    isProfileImage: false,
                                    existingImageIndex: index,
                                  );
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.grey.withOpacity(
                                    0.2,
                                  ), // Renk paletinden
                                  borderRadius: BorderRadius.circular(10),
                                  image: imageSource != null
                                      ? (imageSource is File
                                            ? DecorationImage(
                                                image: FileImage(imageSource),
                                                fit: BoxFit.cover,
                                              )
                                            : (imageSource is String &&
                                                      imageSource.isNotEmpty
                                                  ? DecorationImage(
                                                      image: NetworkImage(
                                                        imageSource,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null))
                                      : null,
                                ),
                                child:
                                    !hasImage ||
                                        (imageSource is String &&
                                            imageSource.isEmpty)
                                    ? Icon(
                                        Icons.add_a_photo,
                                        size: 30,
                                        color: AppColors
                                            .secondaryText, // Renk paletinden
                                      )
                                    : null,
                              ),
                            ),
                            // Silme butonu
                            if (hasImage && imageSource is! String ||
                                (imageSource is String &&
                                    imageSource.isNotEmpty))
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _removeOtherImage(index),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.black.withOpacity(
                                        0.5,
                                      ), // Renk paletinden
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: AppColors.white, // Renk paletinden
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // --- İsim ---
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Adınız',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen adınızı girin.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- Yaş ---
                    DropdownButtonFormField<int>(
                      value: _selectedAge,
                      decoration: InputDecoration(
                        labelText: 'Yaşınız',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      hint: const Text('Yaşınızı seçin'),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedAge = newValue;
                        });
                      },
                      items: List.generate(
                        60, // 18'den 77'ye kadar
                        (index) => DropdownMenuItem(
                          value: 18 + index,
                          child: Text((18 + index).toString()),
                        ),
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'Lütfen yaşınızı seçin.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- Cinsiyet ---
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Cinsiyetiniz',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      hint: const Text('Cinsiyetinizi seçin'),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                      items: _genders.map((String gender) {
                        return DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null) {
                          return 'Lütfen cinsiyetinizi seçin.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- Biyografi ---
                    TextFormField(
                      controller: _bioController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Biyografi (Kendinizi tanıtın)',
                        hintText: 'En fazla 200 karakter...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      maxLength: 200,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen kendinizi tanıtan kısa bir biyografi girin.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- İlgi Alanları ---
                    const Text(
                      'İlgi Alanları (En Az 1 Seçin)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _availableInterests.map((interest) {
                        final isSelected = _selectedInterests.contains(
                          interest,
                        );
                        return ChoiceChip(
                          label: Text(interest),
                          selected: isSelected,
                          onSelected: (selected) {
                            _toggleInterest(interest);
                          },
                          selectedColor: Theme.of(context).primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.black
                                : AppColors.primaryText, // Renk paletinden
                          ),
                          backgroundColor: AppColors.grey.withOpacity(
                            0.2,
                          ), // Renk paletinden
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // --- Kaydet Butonu ---
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: AppColors.black,
                            ) // Renk paletinden
                          : Text(
                              widget.initialData == null
                                  ? 'Profili Oluştur'
                                  : 'Profili Güncelle',
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Resim kaynağı seçimi (Galeri / Kamera) için diyalog
  void _showImageSourceDialog({
    required bool isProfileImage,
    int? existingImageIndex, // diğer fotoğraflar için
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeriden Seç'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(
                    ImageSource.gallery,
                    isProfileImage: isProfileImage,
                    existingImageIndex: existingImageIndex,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera ile Çek'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(
                    ImageSource.camera,
                    isProfileImage: isProfileImage,
                    existingImageIndex: existingImageIndex,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
