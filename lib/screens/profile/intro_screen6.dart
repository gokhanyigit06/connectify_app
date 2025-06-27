import 'package:flutter/material.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:provider/provider.dart';
import 'package:connectify_app/providers/onboarding_data_provider.dart';
import 'package:connectify_app/screens/home_screen.dart'; // Yeni: Geçici olarak HomeScreen'e yönlendirme
// import 'package:connectify_app/screens/profile/profile_setup_screen.dart'; // Artık buraya geçici olarak yönlendirmiyoruz

class IntroScreen6 extends StatefulWidget {
  const IntroScreen6({super.key});

  @override
  State<IntroScreen6> createState() => _IntroScreen6State();
}

class _IntroScreen6State extends State<IntroScreen6> {
  String? _selectedRelationshipGoal; // Seçilen ilişki hedefi

  final List<String> _relationshipGoalsOptions = [
    'Uzun Süreli İlişki',
    'Hayat Arkadaşı',
    'Eğlenceli, Gündelik Buluşmalar',
    'Bağlılık Olmadan Samimiyet',
    'Evlilik'
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('IntroScreen6: initState çağrıldı.'); // Debug Log
    _selectedRelationshipGoal =
        Provider.of<OnboardingDataProvider>(context, listen: false)
            .relationshipGoal;
  }

  @override
  void dispose() {
    debugPrint('IntroScreen6: dispose çağrıldı.'); // Debug Log
    super.dispose();
  }

  void _onNextPressed() {
    debugPrint('IntroScreen6: _onNextPressed çağrıldı.'); // Debug Log
    if (_selectedRelationshipGoal == null) {
      SnackBarService.showSnackBar(context,
          message: 'Lütfen bir ilişki hedefi seçin.', type: SnackBarType.error);
      debugPrint('IntroScreen6: İlişki hedefi seçilmedi uyarısı.'); // Debug Log
      return;
    }

    // Seçilen ilişki hedefini OnboardingDataProvider'a kaydet
    Provider.of<OnboardingDataProvider>(context, listen: false)
        .setRelationshipGoal(_selectedRelationshipGoal!);
    debugPrint(
        'IntroScreen6: İlişki hedefi kaydedildi: $_selectedRelationshipGoal'); // Debug Log

    SnackBarService.showSnackBar(context,
        message: 'Devam ediliyor...', type: SnackBarType.info);

    // KRİTİK DÜZELTME: Geçici olarak HomeScreen'e yönlendirme
    // Eğer bu başarılı olursa, sorun ProfileSetupScreen'dedir.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (context) =>
              const HomeScreen()), // Geçici olarak HomeScreen'e yönlendir
      (Route<dynamic> route) => false, // Tüm önceki rotaları temizle
    );
    debugPrint('IntroScreen6: HomeScreen\'e yönlendirme yapıldı.'); // Debug Log
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('IntroScreen6: build metodu çağrıldı.'); // Debug Log
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.primaryText),
          onPressed: () {
            debugPrint('IntroScreen6: Geri butonu tıklandı.'); // Debug Log
            Navigator.of(context).pop();
          },
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
                    0.8, // Örn: %80 tamamlandı (toplam adım sayısına göre ayarlanacak)
                backgroundColor: AppColors.grey.withOpacity(0.3),
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
              ),
              const SizedBox(height: 40),
              Text(
                'Ne Arıyorsunuz?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 30),
              // İlişki Hedefi Seçenekleri
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _relationshipGoalsOptions.map((goal) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(
                              goal,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: _selectedRelationshipGoal == goal
                                    ? AppColors.white
                                    : AppColors.primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          selected: _selectedRelationshipGoal == goal,
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedRelationshipGoal =
                                  selected ? goal : null;
                              debugPrint(
                                  'IntroScreen6: İlişki hedefi seçildi: $goal - Selected: $selected');
                            });
                          },
                          selectedColor: AppColors.accentPink,
                          backgroundColor: AppColors.grey.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: _selectedRelationshipGoal == goal
                                  ? AppColors.accentPink
                                  : AppColors.grey.withOpacity(0.5),
                              width:
                                  _selectedRelationshipGoal == goal ? 2.0 : 1.0,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          elevation: _selectedRelationshipGoal == goal ? 3 : 0,
                        ),
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
