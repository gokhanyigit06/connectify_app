import 'package:flutter/material.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için
import 'package:provider/provider.dart'; // Provider için
import 'package:connectify_app/providers/onboarding_data_provider.dart'; // OnboardingDataProvider için
import 'package:connectify_app/screens/profile/intro_screen2.dart'; // Yeni: IntroScreen2'ye yönlendirme için

class IntroScreen1 extends StatefulWidget {
  const IntroScreen1({super.key});

  @override
  State<IntroScreen1> createState() => _IntroScreen1State();
}

class _IntroScreen1State extends State<IntroScreen1> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  DateTime? _selectedDate; // Seçilen doğum tarihini tutacak

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // Doğum tarihi seçiciyi gösteren fonksiyon
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ??
          DateTime.now().subtract(const Duration(
              days: 365 * 18)), // Varsayılan olarak 18 yıl öncesi
      firstDate: DateTime(1900), // En eski tarih
      lastDate: DateTime.now().subtract(const Duration(
          days: 365 * 18)), // Bugün - 18 yıl (minimum yaş 18 varsayımıyla)
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
      // Yaşı hesapla
      final int age = DateTime.now().year - picked.year;
      // Doğum günü henüz geçmediyse yaşı bir eksiltme mantığı
      bool isAgeValid = true;
      if (DateTime.now().month < picked.month ||
          (DateTime.now().month == picked.month &&
              DateTime.now().day < picked.day)) {
        if (age - 1 < 18) {
          isAgeValid = false;
        }
      } else {
        if (age < 18) {
          isAgeValid = false;
        }
      }

      if (!isAgeValid) {
        SnackBarService.showSnackBar(
          context,
          message: 'Connectify\'ı kullanmak için en az 18 yaşında olmalısınız.',
          type: SnackBarType.error,
        );
        return;
      }

      setState(() {
        _selectedDate = picked;
        _dobController.text =
            DateFormat('dd/MM/yyyy').format(_selectedDate!); // Tarihi formatla
      });
    }
  }

  // İleri butonu tıklandığında
  void _onNextPressed() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      SnackBarService.showSnackBar(context,
          message: 'Lütfen adınızı girin.', type: SnackBarType.error);
      return;
    }
    if (_selectedDate == null) {
      SnackBarService.showSnackBar(context,
          message: 'Lütfen doğum tarihinizi seçin.', type: SnackBarType.error);
      return;
    }

    // Yaşı tekrar kontrol et (UI'da hata mesajı verildi ama burası son kontrol)
    final int age = DateTime.now().year - _selectedDate!.year;
    if (DateTime.now().month < _selectedDate!.month ||
        (DateTime.now().month == _selectedDate!.month &&
            DateTime.now().day < _selectedDate!.day)) {
      if (age - 1 < 18) {
        SnackBarService.showSnackBar(context,
            message:
                'Connectify\'ı kullanmak için en az 18 yaşında olmalısınız.',
            type: SnackBarType.error);
        return;
      }
    } else {
      if (age < 18) {
        SnackBarService.showSnackBar(context,
            message:
                'Connectify\'ı kullanmak için en az 18 yaşında olmalısınız.',
            type: SnackBarType.error);
        return;
      }
    }

    // Verileri OnboardingDataProvider'a kaydet
    final onboardingProvider =
        Provider.of<OnboardingDataProvider>(context, listen: false);
    onboardingProvider.setName(name);
    onboardingProvider.setDateOfBirth(_selectedDate!);
    debugPrint(
        'IntroScreen1: Ad ve Doğum Tarihi kaydedildi. Ad: ${onboardingProvider.name}, Doğum Tarihi: ${onboardingProvider.dateOfBirth}');

    // Bir sonraki ekrana (IntroScreen2) geçiş
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const IntroScreen2()),
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
                value: 0.2, // Örn: %20 tamamlandı
                backgroundColor: AppColors.grey.withOpacity(0.3),
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
              ),
              const SizedBox(height: 40),
              Text(
                'Merhaba! Tanışmaya Başlayalım.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 30),
              // Adınız
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Adınız',
                  hintText: 'Adınızı girin',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon:
                      Icon(Icons.person, color: AppColors.primaryYellow),
                ),
                style: TextStyle(color: AppColors.primaryText),
              ),
              const SizedBox(height: 20),
              // Doğum Tarihiniz
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  // TextField'ın kendisinin tıklanmasını engelle
                  child: TextField(
                    controller: _dobController,
                    decoration: InputDecoration(
                      labelText: 'Doğum Tarihiniz (GG/AA/YYYY)',
                      hintText: 'Tarihi seçmek için tıklayın',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.calendar_today,
                          color: AppColors.primaryYellow),
                    ),
                    style: TextStyle(color: AppColors.primaryText),
                  ),
                ),
              ),
              const Spacer(), // İçeriği yukarı it
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
