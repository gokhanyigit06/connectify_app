import 'package:flutter/material.dart';
import 'package:connectify_app/utils/app_colors.dart'; // Renk paletimiz için

// SnackBar türlerini belirtmek için enum
enum SnackBarType { success, error, info }

class SnackBarService {
  static void showSnackBar(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info, // Varsayılan olarak bilgi tipi
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
  }) {
    Color backgroundColor;
    IconData icon;
    Color textColor = AppColors.white; // Metin rengi varsayılan olarak beyaz

    switch (type) {
      case SnackBarType.success:
        backgroundColor = Colors.green[700] ?? Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case SnackBarType.error:
        backgroundColor = AppColors.red; // Hata için ana kırmızı rengimiz
        icon = Icons.error_outline;
        break;
      case SnackBarType.info:
        backgroundColor =
            AppColors.primaryYellow; // Bilgi için ana sarı rengimiz
        textColor = AppColors.black; // Sarı üzerinde siyah metin
        icon = Icons.info_outline;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: textColor,
            ), // İkonun rengini metin rengiyle aynı yap
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: textColor)),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onActionPressed,
                textColor: textColor, // Aksiyon metninin rengini de ayarla
              )
            : null,
        behavior: SnackBarBehavior.floating, // Köşelerde yüzer SnackBar
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16), // Ekran kenarlarından biraz boşluk
      ),
    );
  }
}
