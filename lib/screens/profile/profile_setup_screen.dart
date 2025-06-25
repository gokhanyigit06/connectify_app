import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:connectify_app/screens/home_screen.dart'; // Anasayfaya yönlendirme için

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

  File? _profileImage; // Yeni seçilen ana profil fotoğrafı
  String? _currentProfileImageUrl; // Mevcut profil fotoğrafının URL'si

  final List<File> _newOtherImages = []; // Yeni eklenen diğer fotoğraflar
  final List<String> _currentOtherImageUrls =
      []; // Mevcut diğer fotoğrafların URL'leri

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
    // Eğer initialData varsa, form alanlarını doldur
    if (widget.initialData != null) {
      _nameController.text = widget.initialData!['name'] ?? '';
      _bioController.text = widget.initialData!['bio'] ?? '';
      _selectedGender = widget.initialData!['gender'];
      _selectedAge = widget.initialData!['age'];
      _selectedInterests = List<String>.from(
        widget.initialData!['interests'] ?? [],
      );
      _currentProfileImageUrl = widget.initialData!['profileImageUrl'];
      _currentOtherImageUrls.addAll(
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
    int? otherImageIndex,
  }) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        if (isProfileImage) {
          _profileImage = File(pickedFile.path);
          _currentProfileImageUrl =
              null; // Yeni resim seçilince eski URL'yi temizle
        } else {
          if (otherImageIndex != null &&
              otherImageIndex < _currentOtherImageUrls.length) {
            // Mevcut bir diğer fotoğrafı değiştir
            _currentOtherImageUrls[otherImageIndex] =
                ''; // Eski URL'yi geçici olarak sil
            _newOtherImages.add(File(pickedFile.path)); // Yeni resmi ekle
          } else if (_newOtherImages.length + _currentOtherImageUrls.length <
              5) {
            // Yeni bir diğer fotoğraf ekle
            _newOtherImages.add(File(pickedFile.path));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('En fazla 5 ek fotoğraf yükleyebilirsiniz.'),
              ),
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
      return;
    }
    // Profil oluşturuluyorsa profil resmi zorunlu
    if (widget.initialData == null && _profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir profil fotoğrafı seçin.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı oturumu bulunamadı.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      String? finalProfileImageUrl = _currentProfileImageUrl;
      List<String> finalOtherImageUrls = List.from(
        _currentOtherImageUrls.where((url) => url.isNotEmpty),
      ); // Boş olanları (değiştirilenleri) atla

      // 1. Yeni Profil Fotoğrafını Yükle (varsa)
      if (_profileImage != null) {
        final profileImageRef = _storage.ref().child(
          'user_profiles/${currentUser.uid}/profile.jpg',
        );
        await profileImageRef.putFile(_profileImage!);
        finalProfileImageUrl = await profileImageRef.getDownloadURL();
      }

      // 2. Yeni Diğer Fotoğrafları Yükle (varsa)
      for (int i = 0; i < _newOtherImages.length; i++) {
        final otherImageRef = _storage.ref().child(
          'user_profiles/${currentUser.uid}/other_photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        ); // Benzersiz isim
        await otherImageRef.putFile(_newOtherImages[i]);
        finalOtherImageUrls.add(await otherImageRef.getDownloadURL());
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
        'otherImageUrls': finalOtherImageUrls,
        'location': 'Ankara, Türkiye', // Şimdilik sabit
        'isProfileCompleted': true,
        'isPremium':
            widget.initialData?['isPremium'] ??
            false, // Mevcut premium durumunu koru
        'likesRemainingToday': widget.initialData?['likesRemainingToday'] ?? 20,
        'messagesRemainingToday':
            widget.initialData?['messagesRemainingToday'] ?? 5,
        'createdAt':
            widget.initialData?['createdAt'] ??
            FieldValue.serverTimestamp(), // Oluşturma tarihini koru
        'updatedAt': FieldValue.serverTimestamp(), // Güncelleme tarihi ekle
      }, SetOptions(merge: true)); // Mevcut belgeyi birleştirerek güncelle

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil başarıyla kaydedildi!')),
      );

      // Profil kaydedildikten sonra Anasayfaya yönlendir (veya önceki ekrana dön)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint("Profil kaydetme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil kaydedilirken bir hata oluştu: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Diğer fotoğrafı silme fonksiyonu
  void _removeOtherImage(int index, {bool isNewImage = false}) {
    setState(() {
      if (isNewImage) {
        _newOtherImages.removeAt(index);
      } else {
        _currentOtherImageUrls.removeAt(index);
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
        automaticallyImplyLeading:
            widget.initialData != null, // Düzenleme modunda geri tuşu göster
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
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (_currentProfileImageUrl != null
                                    ? NetworkImage(_currentProfileImageUrl!)
                                    : null),
                          child:
                              _profileImage == null &&
                                  _currentProfileImageUrl == null
                              ? Icon(
                                  Icons.camera_alt,
                                  size: 50,
                                  color: Colors.grey[700],
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
                      itemCount: 5, // 5 adet kutucuk
                      itemBuilder: (context, index) {
                        bool isCurrent = index < _currentOtherImageUrls.length;
                        bool isNew =
                            index - _currentOtherImageUrls.length <
                            _newOtherImages.length;
                        File? newImage = isNew
                            ? _newOtherImages[index -
                                  _currentOtherImageUrls.length]
                            : null;
                        String? currentImageUrl = isCurrent
                            ? _currentOtherImageUrls[index]
                            : null;

                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: () => _showImageSourceDialog(
                                isProfileImage: false,
                                otherImageIndex: index,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                  image: newImage != null
                                      ? DecorationImage(
                                          image: FileImage(newImage),
                                          fit: BoxFit.cover,
                                        )
                                      : (currentImageUrl != null &&
                                                currentImageUrl.isNotEmpty
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                  currentImageUrl,
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : null),
                                ),
                                child:
                                    newImage == null &&
                                        (currentImageUrl == null ||
                                            currentImageUrl.isEmpty)
                                    ? Icon(
                                        Icons.add_a_photo,
                                        size: 30,
                                        color: Colors.grey[700],
                                      )
                                    : null,
                              ),
                            ),
                            // Silme butonu
                            if ((newImage != null ||
                                (currentImageUrl != null &&
                                    currentImageUrl.isNotEmpty)))
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _removeOtherImage(
                                    index,
                                    isNewImage: newImage != null,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
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
                            color: isSelected ? Colors.black : Colors.black87,
                          ),
                          backgroundColor: Colors.grey[200],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // --- Kaydet Butonu ---
                    ElevatedButton(
                      onPressed:
                          _saveProfile, // Fonksiyon adını _saveProfile olarak değiştirdim
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
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
    int? otherImageIndex,
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
                    otherImageIndex: otherImageIndex,
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
                    otherImageIndex: otherImageIndex,
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
