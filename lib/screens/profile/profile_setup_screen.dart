import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectify_app/screens/home_screen.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için eklendi

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dobController =
      TextEditingController(); // Yeni: Doğum tarihi için controller

  String? _selectedGender;
  List<String> _selectedInterests = [];
  File? _profileImage;
  List<File> _otherImages = []; // Diğer resimler için
  List<String> _otherImageUrls = []; // Firestore'a kaydedilecek URL'ler

  DateTime? _selectedDate; // Seçilen doğum tarihini tutacak değişken

  final List<String> _genderOptions = [
    'Erkek',
    'Kadın',
    'Belirtmek İstemiyorum',
  ];
  final List<String> _interestOptions = [
    'Sinema',
    'Kitap Okumak',
    'Müzik',
    'Spor',
    'Seyahat',
    'Yemek Yapmak',
    'Oyun',
    'Doğa Yürüyüşü',
    'Sanat',
    'Teknoloji',
    'Dans',
    'Fotoğrafçılık',
    'Moda',
    'Meditasyon',
    'Gönüllülük',
    'Hayvanlar',
    'Bilim Kurgu',
    'Tarih',
    'Eğitim',
    'Yazılım',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _dobController.dispose(); // Dispose etmeyi unutma
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        _nameController.text = data['name'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _locationController.text = data['location'] ?? '';
        _selectedGender = data['gender'];
        _selectedInterests = List<String>.from(data['interests'] ?? []);
        _otherImageUrls = List<String>.from(
          data['otherImageUrls'] ?? [],
        ); // Mevcut URL'leri yükle

        // Doğum tarihini yükle ve controller'a set et
        if (data['dateOfBirth'] != null) {
          _selectedDate = (data['dateOfBirth'] as Timestamp).toDate();
          _dobController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
        }

        setState(() {});
      }
    }
  }

  Future<void> _pickImage(
    ImageSource source, {
    bool isProfileImage = true,
  }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        if (isProfileImage) {
          _profileImage = File(pickedFile.path);
        } else {
          if (_otherImages.length < 5) {
            // Maksimum 5 ek fotoğraf
            _otherImages.add(File(pickedFile.path));
          } else {
            SnackBarService.showSnackBar(
              context,
              message: 'En fazla 5 ek fotoğraf ekleyebilirsiniz.',
              type: SnackBarType.info,
            );
          }
        }
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final ref = _storage.ref().child(
        'user_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Resim yüklenirken hata: $e');
      SnackBarService.showSnackBar(
        context,
        message: 'Resim yüklenirken hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
      );
      return null;
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();
    final location = _locationController.text.trim();

    if (name.isEmpty ||
        bio.isEmpty ||
        location.isEmpty ||
        _selectedGender == null ||
        _selectedInterests.isEmpty ||
        _profileImage == null ||
        _selectedDate == null) {
      SnackBarService.showSnackBar(
        context,
        message: 'Lütfen tüm alanları doldurun ve bir profil fotoğrafı seçin.',
        type: SnackBarType.error,
      );
      return;
    }

    // Yaşı hesapla
    final int age = DateTime.now().year - _selectedDate!.year;
    if (DateTime.now().month < _selectedDate!.month ||
        (DateTime.now().month == _selectedDate!.month &&
            DateTime.now().day < _selectedDate!.day)) {
      // Eğer doğum günü henüz geçmediyse yaşı bir eksilt
      // Bu kontrol, 18 yaş altı kullanıcıların kaydolmasını engelleyebilir.
      // Eğer 18 yaş altı kısıtlaması varsa, burada ek kontrol yapılmalı.
      // Şimdilik sadece doğru yaş hesaplaması için yapıyoruz.
      // Uygulamanızın yaş kısıtlamalarına göre bu mantığı ayarlayabilirsiniz.
      // Örneğin, eğer hesaplanan yaş 18'den küçükse hata verebilirsiniz.
    }

    try {
      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await _uploadImage(_profileImage!);
      }

      // Diğer resimleri yükle
      List<String> newOtherImageUrls = [];
      for (File imageFile in _otherImages) {
        String? url = await _uploadImage(imageFile);
        if (url != null) {
          newOtherImageUrls.add(url);
        }
      }

      // Mevcut URL'leri koru ve yenilerini ekle
      List<String> finalOtherImageUrls = List.from(_otherImageUrls)
        ..addAll(newOtherImageUrls);
      // Eğer 5'ten fazla olursa ilk 5'i al
      if (finalOtherImageUrls.length > 5) {
        finalOtherImageUrls = finalOtherImageUrls.sublist(0, 5);
      }

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': name,
        'age': age, // Hesaplanan yaşı kaydet
        'dateOfBirth': _selectedDate, // Doğum tarihini de kaydet
        'gender': _selectedGender,
        'bio': bio,
        'location': location,
        'interests': _selectedInterests,
        'profileImageUrl': profileImageUrl,
        'otherImageUrls':
            finalOtherImageUrls, // Güncellenmiş diğer resim URL'leri
        'createdAt': FieldValue.serverTimestamp(),
        'isPremium': false, // Varsayılan olarak premium değil
        'likesRemainingToday': 24, // Günlük beğeni limiti
      }, SetOptions(merge: true));

      SnackBarService.showSnackBar(
        context,
        message: 'Profil başarıyla kaydedildi!',
        type: SnackBarType.success,
      );

      // Profil kurulumu tamamlandıktan sonra ana ekrana yönlendir
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Profil kaydedilirken hata: $e');
      SnackBarService.showSnackBar(
        context,
        message: 'Profil kaydedilirken hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  // Doğum tarihi seçiciyi gösteren fonksiyon
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ??
          DateTime.now().subtract(
            const Duration(days: 365 * 18),
          ), // Varsayılan olarak 18 yıl öncesi
      firstDate: DateTime(1900), // En eski tarih
      lastDate: DateTime.now().subtract(
        const Duration(days: 365 * 18),
      ), // Bugün - 18 yıl (minimum yaş 18 varsayımıyla)
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryYellow, // Header background color
              onPrimary: AppColors.black, // Header text color
              onSurface: AppColors.primaryText, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentPink, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat(
          'dd/MM/yyyy',
        ).format(_selectedDate!); // Tarihi formatla
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Kurulumu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.grey.withOpacity(0.3),
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.secondaryText,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () =>
                          _pickImage(ImageSource.gallery, isProfileImage: true),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryYellow,
                        child: Icon(Icons.camera_alt, color: AppColors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ek Fotoğraflar (Max 5)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5, // Maksimum 5 fotoğraf alanı
                itemBuilder: (context, index) {
                  File? currentImageFile = index < _otherImages.length
                      ? _otherImages[index]
                      : null;
                  String? currentImageUrl = index < _otherImageUrls.length
                      ? _otherImageUrls[index]
                      : null;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () => _pickImage(
                        ImageSource.gallery,
                        isProfileImage: false,
                      ),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                          image: currentImageFile != null
                              ? DecorationImage(
                                  image: FileImage(currentImageFile),
                                  fit: BoxFit.cover,
                                )
                              : (currentImageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(currentImageUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null),
                        ),
                        child:
                            currentImageFile == null && currentImageUrl == null
                            ? Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: AppColors.secondaryText,
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(_nameController, 'Adınız', Icons.person),
            _buildTextField(
              _bioController,
              'Biyografiniz',
              Icons.description,
              maxLines: 3,
            ),
            _buildTextField(_locationController, 'Şehriniz', Icons.location_on),

            // Yeni: Doğum tarihi alanı
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                // TextField'ın kendisinin tıklanmasını engelle
                child: _buildTextField(
                  _dobController,
                  'Doğum Tarihiniz (GG/AA/YYYY)',
                  Icons.calendar_today,
                ),
              ),
            ),

            _buildDropdownField('Cinsiyet', _selectedGender, _genderOptions, (
              String? newValue,
            ) {
              setState(() {
                _selectedGender = newValue;
              });
            }, Icons.wc),
            _buildInterestsSelection(),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Profili Kaydet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String labelText,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: AppColors.primaryYellow),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primaryYellow, width: 2),
          ),
        ),
        style: TextStyle(color: AppColors.primaryText),
      ),
    );
  }

  Widget _buildDropdownField(
    String labelText,
    String? selectedValue,
    List<String> options,
    ValueChanged<String?> onChanged,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: AppColors.primaryYellow),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primaryYellow, width: 2),
          ),
        ),
        dropdownColor: AppColors.background,
        style: TextStyle(color: AppColors.primaryText),
        items: options.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: TextStyle(color: AppColors.primaryText)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInterestsSelection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İlgi Alanlarınız',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _interestOptions.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return ChoiceChip(
                label: Text(interest),
                selected: isSelected,
                selectedColor: AppColors.accentPink,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.primaryText,
                ),
                backgroundColor: AppColors.grey.withOpacity(0.2),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedInterests.add(interest);
                    } else {
                      _selectedInterests.remove(interest);
                    }
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.accentPink
                        : AppColors.grey.withOpacity(0.5),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
