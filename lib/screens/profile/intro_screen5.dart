import 'package:flutter/material.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:provider/provider.dart';
import 'package:connectify_app/providers/onboarding_data_provider.dart';
import 'package:connectify_app/screens/profile/intro_screen6.dart'; // IntroScreen6'ya yönlendirme

class IntroScreen5 extends StatefulWidget {
  const IntroScreen5({super.key});

  @override
  State<IntroScreen5> createState() => _IntroScreen5State();
}

class _IntroScreen5State extends State<IntroScreen5> {
  List<String> _selectedInterests = [];

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
    'Meditasyon',
    'Gönüllülük',
    'Hayvanlar',
    'Bilim Kurgu',
    'Tarih',
    'Eğitim',
    'Yazılım',
    'Açık Hava',
    'Konserler',
    'Podcastler'
  ];

  @override
  void initState() {
    super.initState();
    // OnboardingDataProvider'dan mevcut ilgi alanlarını yükle (geri gelindiğinde)
    _selectedInterests = List.from(
        Provider.of<OnboardingDataProvider>(context, listen: false).interests);
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

  void _onNextPressed() {
    if (_selectedInterests.isEmpty) {
      SnackBarService.showSnackBar(context,
          message: 'Lütfen en az bir ilgi alanı seçin.',
          type: SnackBarType.error);
      return;
    }

    Provider.of<OnboardingDataProvider>(context, listen: false)
        .setInterests(_selectedInterests);
    debugPrint('IntroScreen5: İlgi alanları kaydedildi: $_selectedInterests');

    SnackBarService.showSnackBar(context,
        message: 'Devam ediliyor...', type: SnackBarType.info);

    // Bir sonraki ekrana (IntroScreen6) geçiş
    debugPrint(
        'IntroScreen5: IntroScreen6\'ya yönlendirme başlatılıyor...'); // Yönlendirme logu
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) =>
              const IntroScreen6()), // IntroScreen6'ya yönlendir
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
                    0.95, // Örn: %95 tamamlandı (toplam adım sayısına göre ayarlanacak)
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
              Expanded(
                child: SingleChildScrollView(
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
