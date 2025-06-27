import 'package:flutter/cupertino.dart'; // CupertinoPicker için
import 'package:flutter/material.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:provider/provider.dart';
import 'package:connectify_app/providers/onboarding_data_provider.dart';
import 'package:connectify_app/screens/profile/profile_setup_screen.dart'; // Şimdilik son ekran olarak düşünülebilir veya IntroScreen5'e yönlendirme

class IntroScreen4 extends StatefulWidget {
  const IntroScreen4({super.key});

  @override
  State<IntroScreen4> createState() => _IntroScreen4State();
}

class _IntroScreen4State extends State<IntroScreen4> {
  int _selectedHeightCm = 170; // Varsayılan boy 170 cm

  @override
  void initState() {
    super.initState();
    // OnboardingDataProvider'dan mevcut boyu yükle (geri gelindiğinde veya düzenleme modunda)
    final onboardingProvider =
        Provider.of<OnboardingDataProvider>(context, listen: false);
    _selectedHeightCm =
        onboardingProvider.height ?? 170; // Eğer yoksa varsayılan 170
  }

  void _onNextPressed() {
    // Boy bilgisini OnboardingDataProvider'a kaydet
    Provider.of<OnboardingDataProvider>(context, listen: false)
        .setHeight(_selectedHeightCm);
    debugPrint('IntroScreen4: Boy kaydedildi: $_selectedHeightCm cm');

    SnackBarService.showSnackBar(context,
        message: 'Devam ediliyor...', type: SnackBarType.info);

    // İleride buraya IntroScreen5'e geçiş gelecek (İlgi Alanları)
    // Şimdilik akışı tamamlamak için ProfileSetupScreen'e yönlendirelim.
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) =>
              const ProfileSetupScreen()), // Geçici yönlendirme
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
                value:
                    0.9, // Örn: %90 tamamlandı (toplam adım sayısına göre ayarlanacak)
                backgroundColor: AppColors.grey.withOpacity(0.3),
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
              ),
              const SizedBox(height: 40),
              Text(
                'Boyunuz Kaç?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 30),
              // Boy Seçici
              Expanded(
                // Expanded ile kaydırıcının yerini doldur
                child: Center(
                  child: SizedBox(
                    height: 150, // Picker'ın yüksekliği
                    child: CupertinoPicker(
                      magnification: 1.22,
                      squeeze: 1.2,
                      useMagnifier: true,
                      itemExtent: 40.0, // Her bir öğenin yüksekliği
                      onSelectedItemChanged: (int selectedItem) {
                        setState(() {
                          _selectedHeightCm =
                              140 + selectedItem; // 140 cm'den başla
                        });
                      },
                      scrollController: FixedExtentScrollController(
                        initialItem:
                            _selectedHeightCm - 140, // Başlangıç öğesini ayarla
                      ),
                      children: List<Widget>.generate(
                        81, // 140 cm'den 220 cm'ye kadar (220-140+1)
                        (int index) {
                          final height = 140 + index;
                          return Center(
                            child: Text(
                              '$height cm',
                              style: TextStyle(
                                fontSize: 24,
                                color: AppColors.primaryText,
                                fontWeight: _selectedHeightCm == height
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
