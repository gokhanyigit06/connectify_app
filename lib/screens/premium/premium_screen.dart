import 'package:flutter/material.dart';
import 'package:connectify_app/utils/app_colors.dart'; // AppColors için
import 'package:connectify_app/services/snackbar_service.dart'; // SnackBarService için

class PremiumScreen extends StatelessWidget {
  final String?
      message; // Kullanıcı buraya neden yönlendirildiğini açıklayan opsiyonel mesaj

  const PremiumScreen({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium & Paketler'),
        backgroundColor: AppColors.primaryYellow, // AppBar rengi
        foregroundColor: AppColors.black, // AppBar metin rengi
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.workspace_premium,
                  size: 100, color: AppColors.primaryYellow),
              const SizedBox(height: 20),
              Text(
                message ??
                    'Connectify Premium ile bağlantılarınızı güçlendirin!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: AppColors.primaryText),
              ),
              const SizedBox(height: 30),
              // Premium Ol butonu
              ElevatedButton(
                onPressed: () {
                  // TODO: Premium paketler listesini gösterme/satın alma akışı
                  SnackBarService.showSnackBar(context,
                      message: 'Premium paketler listesi burada olacak!',
                      type: SnackBarType.info);
                  // Navigator.pop(context); // Geçici olarak ekranı kapatabiliriz
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPink,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
                child: Text('Connectify Premium Ol',
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              // Süper Beğeni Paketi Satın Al butonu
              TextButton(
                onPressed: () {
                  // TODO: Süper Beğeni paketlerini gösterme/satın alma akışı
                  SnackBarService.showSnackBar(context,
                      message: 'Süper Beğeni paketleri burada olacak!',
                      type: SnackBarType.info);
                  // Navigator.pop(context); // Geçici olarak ekranı kapatabiliriz
                },
                child: Text(
                  'Süper Beğeni Paketi Satın Al',
                  style: TextStyle(
                      color: AppColors.secondaryText,
                      decoration: TextDecoration.underline,
                      fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              // Geri dönüş butonu (opsiyonel)
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Bu ekranı kapat
                },
                child: Text(
                  'Şimdilik Değil',
                  style: TextStyle(color: AppColors.grey, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
