import 'package:flutter/material.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:provider/provider.dart';
import 'package:connectify_app/providers/onboarding_data_provider.dart';
import 'package:connectify_app/screens/profile/intro_screen4.dart'; // Yeni: IntroScreen4'e yönlendirme

class IntroScreen3 extends StatefulWidget {
  const IntroScreen3({super.key});

  @override
  State<IntroScreen3> createState() => _IntroScreen3State();
}

class _IntroScreen3State extends State<IntroScreen3> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final onboardingProvider =
        Provider.of<OnboardingDataProvider>(context, listen: false);
    _locationController.text = onboardingProvider.location;
    _bioController.text = onboardingProvider.bio;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    final String location = _locationController.text.trim();
    final String bio = _bioController.text.trim();

    if (location.isEmpty) {
      SnackBarService.showSnackBar(context,
          message: 'Lütfen konumunuzu girin.', type: SnackBarType.error);
      return;
    }
    if (bio.isEmpty) {
      SnackBarService.showSnackBar(context,
          message: 'Lütfen biyografinizi girin.', type: SnackBarType.error);
      return;
    }
    if (bio.length > 200) {
      SnackBarService.showSnackBar(context,
          message: 'Biyografi en fazla 200 karakter olabilir.',
          type: SnackBarType.error);
      return;
    }

    final onboardingProvider =
        Provider.of<OnboardingDataProvider>(context, listen: false);
    onboardingProvider.setLocation(location);
    onboardingProvider.setBio(bio);
    debugPrint(
        'IntroScreen3: Konum: ${onboardingProvider.location}, Biyografi: ${onboardingProvider.bio}');

    SnackBarService.showSnackBar(context,
        message: 'Devam ediliyor...', type: SnackBarType.info);

    // Bir sonraki ekrana (IntroScreen4) geçiş
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) =>
              const IntroScreen4()), // IntroScreen4'e yönlendir
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
                value: 0.8, // Örn: %80 tamamlandı
                backgroundColor: AppColors.grey.withOpacity(0.3),
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
              ),
              const SizedBox(height: 40),
              Text(
                'Neredesin? Kendini Tanıt!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 30),
              // Konumunuz
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Konumunuz (Şehir)',
                  hintText: 'Örn: Ankara',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon:
                      Icon(Icons.location_on, color: AppColors.primaryYellow),
                ),
                style: TextStyle(color: AppColors.primaryText),
              ),
              const SizedBox(height: 20),
              // Biyografiniz
              TextField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: 'Biyografi (Kendinizi tanıtın)',
                  hintText: 'En fazla 200 karakter...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon:
                      Icon(Icons.description, color: AppColors.primaryYellow),
                ),
                style: TextStyle(color: AppColors.primaryText),
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
