import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart'; // Sadece File objesi için kalacak, pickImage kaldırıldı
import 'dart:io';
import 'package:connectify_app/screens/home_screen.dart';
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:provider/provider.dart'; // Provider için
import 'package:connectify_app/providers/onboarding_data_provider.dart'; // OnboardingDataProvider için
import 'package:intl/intl.dart'; // Yaş hesaplaması için

class ProfileSetupScreen extends StatefulWidget {
  // initialData artık kullanılmıyor, OnboardingDataProvider'dan alacağız
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<String> _selectedInterests =
      []; // Bu ekranda sadece ilgi alanları seçilecek
  bool _isLoading = false;

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
    // OnboardingDataProvider'dan mevcut ilgi alanlarını yükle (geri gelindiğinde)
    _selectedInterests = List.from(
        Provider.of<OnboardingDataProvider>(context, listen: false).interests);
  }

  @override
  void dispose() {
    super.dispose();
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

  // Resim yükleme yardımcı fonksiyonu (OnboardingDataProvider'dan gelecek resim dosyaları için)
  Future<String?> _uploadImage(
      File imageFile, String userId, String path) async {
    try {
      final ref = _storage.ref().child(path);
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

  // Tüm profil verilerini Firebase'e kaydetme fonksiyonu
  Future<void> _saveFullProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      SnackBarService.showSnackBar(context,
          message: 'Kullanıcı oturumu bulunamadı.', type: SnackBarType.error);
      return;
    }

    final onboardingProvider =
        Provider.of<OnboardingDataProvider>(context, listen: false);

    // OnboardingDataProvider'dan tüm verileri al
    final String name = onboardingProvider.name;
    final DateTime? dateOfBirth = onboardingProvider.dateOfBirth;
    final String? gender = onboardingProvider.gender;
    final String location = onboardingProvider.location;
    final String bio = onboardingProvider.bio;
    final File? profileImageFile = onboardingProvider.profileImageFile;
    final List<File> otherImageFiles = onboardingProvider.otherImageFiles;

    // Temel doğrulamalar (zaten önceki ekranlarda yapıldı ama emin olmak için)
    if (name.isEmpty ||
        dateOfBirth == null ||
        gender == null ||
        location.isEmpty ||
        bio.isEmpty ||
        profileImageFile == null ||
        _selectedInterests.isEmpty) {
      SnackBarService.showSnackBar(context,
          message:
              'Lütfen tüm zorunlu alanları doldurun ve bir profil fotoğrafı seçin.',
          type: SnackBarType.error);
      return;
    }

    // Yaşı hesapla (tekrar)
    final int age = DateTime.now().year - dateOfBirth.year;
    // Eğer doğum günü henüz geçmediyse yaşı bir eksilt (bu kontrol zaten yapılıyor, ek güvenlik)
    if (DateTime.now().month < dateOfBirth.month ||
        (DateTime.now().month == dateOfBirth.month &&
            DateTime.now().day < dateOfBirth.day)) {
      // Eğer age 18'den küçükse (bu durum selectDate içinde engelleniyor olmalı)
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? profileImageUrl;
      List<String> finalOtherImageUrls = [];

      // 1. Ana Profil Fotoğrafını Yükle
      profileImageUrl = await _uploadImage(profileImageFile, currentUser.uid,
          'user_profiles/${currentUser.uid}/profile.jpg');
      if (profileImageUrl == null) {
        throw Exception('Profil fotoğrafı yüklenemedi.');
      }

      // 2. Diğer Fotoğrafları Yükle
      for (int i = 0; i < otherImageFiles.length; i++) {
        String? url = await _uploadImage(otherImageFiles[i], currentUser.uid,
            'user_profiles/${currentUser.uid}/other_photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        if (url != null) {
          finalOtherImageUrls.add(url);
        }
      }

      // 3. Kullanıcı Bilgilerini Firestore'a Kaydet
      await _firestore.collection('users').doc(currentUser.uid).set({
        'uid': currentUser.uid,
        'email': currentUser.email, // E-posta veya telefon numarası
        'phoneNumber': currentUser
            .phoneNumber, // Telefon numarası (eğer telefon ile giriş yaptıysa)
        'name': name,
        'age': age, // Hesaplanan yaş
        'dateOfBirth':
            dateOfBirth, // Doğum tarihi (Timestamp olarak kaydedilir)
        'gender': gender,
        'bio': bio,
        'location': location,
        'interests': _selectedInterests, // Bu ekranda seçilen ilgi alanları
        'profileImageUrl': profileImageUrl,
        'otherImageUrls': finalOtherImageUrls,
        'isProfileCompleted': true, // Profil tamamlandı olarak işaretle
        'isPremium': false, // Varsayılan olarak premium değil
        'likesRemainingToday': 24, // Günlük beğeni limiti
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      SnackBarService.showSnackBar(context,
          message: 'Profil başarıyla oluşturuldu!', type: SnackBarType.success);

      // Onboarding verilerini sıfırla
      onboardingProvider.reset();

      // Profil oluşturulduktan sonra Anasayfaya yönlendir (ve tüm önceki rotaları kapat)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint("Profil kaydetme hatası: $e");
      SnackBarService.showSnackBar(
        context,
        message: 'Profil oluşturulurken bir hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlgi Alanların'),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // İlerleme Çubuğu
              LinearProgressIndicator(
                value: 1.0, // %100 tamamlandı
                backgroundColor: AppColors.grey.withOpacity(0.3),
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
              ),
              const SizedBox(height: 40),
              Text(
                'Nelerden Hoşlanırsın?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 30),
              // İlgi Alanları Seçimi
              Text(
                'İlgi Alanları (En Az 1 Seçin)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                // Wrap'ı Expanded içine al
                child: SingleChildScrollView(
                  // Kaydırılabilir olması için
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _availableInterests.map((interest) {
                      final isSelected = _selectedInterests.contains(interest);
                      return ChoiceChip(
                        label: Text(interest),
                        selected: isSelected,
                        onSelected: (selected) {
                          _toggleInterest(interest);
                        },
                        selectedColor: AppColors.accentPink,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.primaryText,
                        ),
                        backgroundColor: AppColors.grey.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.accentPink
                                : AppColors.grey.withOpacity(0.5),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: _saveFullProfile,
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.black,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppColors.black)
                      : const Icon(Icons.check), // Yükleme göstergesi
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
