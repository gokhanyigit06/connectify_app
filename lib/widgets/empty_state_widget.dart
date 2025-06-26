import 'package:flutter/material.dart';
import 'package:connectify_app/utils/app_colors.dart'; // Renk paletimizi kullanıyoruz

class EmptyStateWidget extends StatelessWidget {
  final IconData icon; // Gösterilecek ikon
  final String title; // Boş durum başlığı (örn: "Kişi Bulunamadı")
  final String
  description; // Açıklama metni (örn: "Filtreleri değiştirmeyi deneyebilirsin.")
  final String? buttonText; // Opsiyonel buton metni
  final VoidCallback? onButtonPressed; // Opsiyonel buton tıklama fonksiyonu

  const EmptyStateWidget({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    this.buttonText,
    this.onButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80, // Büyük ikon boyutu
            color: AppColors.primaryYellow, // Ana sarı rengimizle ikon
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
              fontFamily: Theme.of(
                context,
              ).textTheme.headlineMedium?.fontFamily, // Tema fontunu kullan
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText,
              fontFamily: Theme.of(
                context,
              ).textTheme.bodyMedium?.fontFamily, // Tema fontunu kullan
            ),
            textAlign: TextAlign.center,
          ),
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primaryYellow, // Ana sarı buton rengi
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: Theme.of(
                    context,
                  ).textTheme.labelLarge?.fontFamily, // Tema fontunu kullan
                ),
              ),
              child: Text(buttonText!),
            ),
          ],
        ],
      ),
    );
  }
}
