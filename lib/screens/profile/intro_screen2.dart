import 'package:flutter/material.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:provider/provider.dart'; // Provider için
import 'package:connectify_app/providers/onboarding_data_provider.dart'; // OnboardingDataProvider için
import 'package:connectify_app/screens/profile/photo_upload_screen.dart'; // Yeni: PhotoUploadScreen'e yönlendirme için

class IntroScreen2 extends StatefulWidget {
  const IntroScreen2({super.key});

  @override
  State<IntroScreen2> createState() => _IntroScreen2State();
}

class _IntroScreen2State extends State<IntroScreen2> {
  String? _selectedGender; // Seçilen cinsiyet

  final List<String> _genderOptions = [
    'Erkek',
    'Kadın',
    'Belirtmek İstemiyorum'
  ];

  @override
  void initState() {
    super.initState();
    // Eğer önceden seçili bir cinsiyet varsa yükle
    _selectedGender =
        Provider.of<OnboardingDataProvider>(context, listen: false).gender;
  }

  void _onNextPressed() {
    if (_selectedGender == null) {
      SnackBarService.showSnackBar(context,
          message: 'Lütfen cinsiyetinizi seçin.', type: SnackBarType.error);
      return;
    }

    // Seçilen cinsiyeti OnboardingDataProvider'a kaydet
    Provider.of<OnboardingDataProvider>(context, listen: false)
        .setGender(_selectedGender!);
    debugPrint('IntroScreen2: Cinsiyet kaydedildi: $_selectedGender');

    SnackBarService.showSnackBar(context,
        message: 'Devam ediliyor...', type: SnackBarType.info);

    // Bir sonraki ekrana (PhotoUploadScreen) geçiş
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) =>
              const PhotoUploadScreen()), // PhotoUploadScreen'e yönlendir
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
              // İlerleme Çubuğu
              LinearProgressIndicator(
                value: 0.4, // Örn: %40 tamamlandı
                backgroundColor: AppColors.grey.withOpacity(0.3),
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
              ),
              const SizedBox(height: 40),
              Text(
                'Sizi en iyi hangi cinsiyet tanımlıyor?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 30),
              // Cinsiyet Seçenekleri
              Column(
                children: _genderOptions.map((gender) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ChoiceChip(
                      label: SizedBox(
                        width: double.infinity, // Tüm genişliği kapla
                        child: Text(
                          gender,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: _selectedGender == gender
                                ? AppColors.white
                                : AppColors.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      selected: _selectedGender == gender,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedGender =
                              selected ? gender : null; // Sadece tek seçim
                        });
                      },
                      selectedColor: AppColors.accentPink,
                      backgroundColor: AppColors.grey.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: _selectedGender == gender
                              ? AppColors.accentPink
                              : AppColors.grey.withOpacity(0.5),
                          width: _selectedGender == gender
                              ? 2.0
                              : 1.0, // Seçilince kenarlık kalınlaşsın
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      elevation: _selectedGender == gender ? 3 : 0,
                    ),
                  );
                }).toList(),
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
}
