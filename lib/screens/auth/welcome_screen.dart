import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Bu satırı ekleyin

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arka Plan Görseli veya Gradient (İleride değiştirilebilir)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFEE140), // Bumble'a benzer sarı
                  Color(0xFFFA709A), // Hafif pembemsi ton
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // İçerik
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 48.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end, // İçeriği alta hizala
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Uygulama Logosu/Adı (Örnek metin)
                  const Text(
                    'Connectify',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black26,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Anlamlı Bağlantılar Kurun.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, color: Colors.white70),
                  ),
                  const SizedBox(height: 80), // Boşluk
                  // Giriş/Kayıt Butonları
                  _buildSocialLoginButton(
                    context,
                    text: 'Google ile Devam Et',
                    icon: Icons
                        .g_mobiledata, // Google'ın kendi ikonu daha uygun olurdu ama şimdilik bu
                    color: Colors.white,
                    textColor: Colors.black87,
                    onPressed: () {
                      // Google Girişi mantığı buraya gelecek
                      debugPrint('Google ile Devam Et tıklandı');
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSocialLoginButton(
                    context,
                    text: 'Apple ID ile Devam Et',
                    icon: Icons.apple,
                    color: Colors.black,
                    textColor: Colors.white,
                    onPressed: () {
                      // Apple ID Girişi mantığı buraya gelecek
                      debugPrint('Apple ID ile Devam Et tıklandı');
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildOutlineButton(
                    context,
                    text: 'E-posta ile Devam Et',
                    onPressed: () {
                      // E-posta ile kayıt/giriş ekranına yönlendir
                      debugPrint('E-posta ile Devam Et tıklandı');
                    },
                  ),
                  const SizedBox(height: 24),
                  // Kullanım Koşulları ve Gizlilik Politikası metni
                  Text.rich(
                    TextSpan(
                      text: 'Devam ederek ',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                      children: [
                        TextSpan(
                          text: 'Kullanım Koşullarımızı',
                          style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              debugPrint('Kullanım Koşulları tıklandı');
                              // URL Launcher ile link açma mantığı buraya gelecek
                            },
                        ),
                        TextSpan(
                          text: ' ve ',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        TextSpan(
                          text: 'Gizlilik Politikamızı',
                          style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              debugPrint('Gizlilik Politikası tıklandı');
                              // URL Launcher ile link açma mantığı buraya gelecek
                            },
                        ),
                        TextSpan(
                          text: ' kabul etmiş olursunuz.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sosyal medya giriş butonları için yardımcı widget
  Widget _buildSocialLoginButton(
    BuildContext context, {
    required String text,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // Daha yuvarlak kenarlar
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        elevation: 3,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      icon: Icon(icon, size: 24),
      label: Text(text),
    );
  }

  // Ana hatlı (Outline) buton için yardımcı widget
  Widget _buildOutlineButton(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white, // Metin rengi
        side: const BorderSide(color: Colors.white, width: 2), // Beyaz kenarlık
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      child: Text(text),
    );
  }
}
