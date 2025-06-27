import 'package:flutter/material.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // File objesi için
import 'package:provider/provider.dart';
import 'package:connectify_app/providers/onboarding_data_provider.dart';
import 'package:connectify_app/screens/profile/intro_screen3.dart'; // Yeni: IntroScreen3'e yönlendirme

class PhotoUploadScreen extends StatefulWidget {
  const PhotoUploadScreen({super.key});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  File? _profileImageFile; // Ana profil fotoğrafı File objesi
  List<File> _otherImageFiles = []; // Diğer fotoğraf File objeleri

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // OnboardingDataProvider'dan mevcut verileri yükle (düzenleme modunda veya geri dönüldüğünde)
    final onboardingProvider =
        Provider.of<OnboardingDataProvider>(context, listen: false);
    _profileImageFile = onboardingProvider.profileImageFile;
    _otherImageFiles =
        List.from(onboardingProvider.otherImageFiles); // Yeni liste oluştur
  }

  // Fotoğraf seçme fonksiyonu
  Future<void> _pickImage(ImageSource source,
      {bool isProfileImage = true, int? existingImageIndex}) async {
    final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70); // Kaliteyi düşürerek yüklemeyi hızlandır
    if (pickedFile != null) {
      setState(() {
        final File selectedFile = File(pickedFile.path);
        if (isProfileImage) {
          _profileImageFile = selectedFile;
          Provider.of<OnboardingDataProvider>(context, listen: false)
              .setProfileImageFile(selectedFile);
        } else {
          // Listeyi kopyalayıp değişiklikleri yapıp, sonra Provider'a yeni listeyi set ediyoruz.
          List<File> tempOtherImageFiles = List.from(_otherImageFiles);
          if (existingImageIndex != null &&
              existingImageIndex < tempOtherImageFiles.length) {
            tempOtherImageFiles[existingImageIndex] =
                selectedFile; // Mevcut fotoğrafı değiştir
          } else if (tempOtherImageFiles.length < 5) {
            // Max 5 fotoğraf sınırı
            tempOtherImageFiles.add(selectedFile);
          } else {
            SnackBarService.showSnackBar(
              context,
              message: 'En fazla 5 ek fotoğraf yükleyebilirsiniz.',
              type: SnackBarType.info,
            );
          }
          // OnboardingDataProvider'daki listeyi yeni listeyle güncelle
          Provider.of<OnboardingDataProvider>(context, listen: false)
              .setOtherImageFiles(tempOtherImageFiles);
          _otherImageFiles = tempOtherImageFiles; // Yerel state'i de güncelle
        }
      });
    }
  }

  // Diğer fotoğrafı silme fonksiyonu
  void _removeOtherImage(int index) {
    setState(() {
      if (index < _otherImageFiles.length) {
        // Listeyi kopyalayıp silme işlemini yapıp, sonra Provider'a yeni listeyi set ediyoruz.
        List<File> tempOtherImageFiles = List.from(_otherImageFiles);
        final removedFile = tempOtherImageFiles.removeAt(
            index); // removedFile'ı kullanmasak da silme işlemi tamamlanır
        Provider.of<OnboardingDataProvider>(context, listen: false)
            .removeOtherImageFile(removedFile); // Provider'dan da sil
        _otherImageFiles = tempOtherImageFiles; // Yerel state'i de güncelle
      }
    });
  }

  void _onNextPressed() {
    if (_profileImageFile == null) {
      SnackBarService.showSnackBar(context,
          message: 'Lütfen bir profil fotoğrafı seçin.',
          type: SnackBarType.error);
      return;
    }

    // Bir sonraki ekrana (IntroScreen3) geçiş
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const IntroScreen3()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
              // İlerleme Çubuğu (Toplam adımlara göre ayarlanacak)
              LinearProgressIndicator(
                value: 0.6, // Örn: %60 tamamlandı
                backgroundColor: AppColors.grey.withOpacity(0.3),
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
              ),
              const SizedBox(height: 40),
              Text(
                'Harika Görünüyorsun! Fotoğraflarını Yükle.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 30),
              // Ana Profil Fotoğrafı
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.grey.withOpacity(0.3),
                      backgroundImage: _profileImageFile != null
                          ? FileImage(_profileImageFile!)
                          : null,
                      child: _profileImageFile == null
                          ? Icon(Icons.person,
                              size: 60, color: AppColors.secondaryText)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () =>
                            _showImageSourceDialog(isProfileImage: true),
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
              // Ek Fotoğraflar
              Text('Ek Fotoğraflar (Max 5)',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText)),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5, // Her zaman 5 yuva göster
                  itemBuilder: (context, index) {
                    final bool hasImage = index < _otherImageFiles.length;
                    final File? currentImageFile =
                        hasImage ? _otherImageFiles[index] : null;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _showImageSourceDialog(
                                isProfileImage: false,
                                existingImageIndex: index),
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: AppColors.grey.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                                image: currentImageFile != null
                                    ? DecorationImage(
                                        image: FileImage(currentImageFile),
                                        fit: BoxFit.cover)
                                    : null,
                              ),
                              child: currentImageFile == null
                                  ? Icon(Icons.add_a_photo,
                                      size: 40, color: AppColors.secondaryText)
                                  : null,
                            ),
                          ),
                          if (hasImage) // Resim varsa sil butonu göster
                            Positioned(
                              top: -5,
                              right: -5,
                              child: GestureDetector(
                                onTap: () => _removeOtherImage(index),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppColors.red,
                                  child: Icon(Icons.close,
                                      size: 16, color: AppColors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: _onNextPressed,
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.black,
                  child: const Icon(Icons.arrow_forward_ios),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Resim kaynağı seçimi (Galeri / Kamera) için diyalog
  void _showImageSourceDialog(
      {required bool isProfileImage, int? existingImageIndex}) {
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
                  _pickImage(ImageSource.gallery,
                      isProfileImage: isProfileImage,
                      existingImageIndex: existingImageIndex);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera ile Çek'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera,
                      isProfileImage: isProfileImage,
                      existingImageIndex: existingImageIndex);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
