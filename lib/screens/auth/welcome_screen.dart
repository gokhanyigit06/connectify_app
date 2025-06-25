import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:connectify_app/services/auth_service.dart';
import 'package:connectify_app/screens/home_screen.dart'; // HomeScreen'i import et
import 'package:connectify_app/screens/profile/profile_setup_screen.dart'; // ProfileSetupScreen'i import et
import 'package:firebase_auth/firebase_auth.dart'; // User sınıfı için
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore için
import 'package:connectify_app/screens/auth/email_auth_screen.dart'; // EmailAuthScreen'e yönlendirme için

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AuthService _authService = AuthService();

  // YÖNLENDİRME YARDIMCI FONKSİYONU (EN SON VE KESİN VERSİYON)
  Future<void> _checkProfileAndNavigate(User? user) async {
    if (user == null || !mounted) {
      debugPrint(
        'WelcomeScreen: _checkProfileAndNavigate -- User null veya widget bağlı değil. Çıkılıyor. (KESİN VERSİYON)',
      ); // KESİN TEKİL LOG
      return;
    }

    debugPrint(
      'WelcomeScreen: _checkProfileAndNavigate başlatıldı. UID: ${user.uid} (KESİN VERSİYON)',
    ); // KESİN TEKİL LOG
    try {
      debugPrint(
        'WelcomeScreen: Firestore belge çekiliyor: users/${user.uid} (KESİN VERSİYON)',
      ); // KESİN TEKİL LOG
      DocumentSnapshot profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      debugPrint(
        'WelcomeScreen: Firestore belge çekildi. exists: ${profileDoc.exists} (KESİN VERSİYON)',
      ); // KESİN TEKİL LOG

      if (profileDoc.exists) {
        final userData = profileDoc.data() as Map<String, dynamic>?;
        debugPrint(
          'WelcomeScreen: Profil verisi mevcut. isProfileCompleted: ${userData?['isProfileCompleted']} (KESİN VERSİYON)',
        ); // KESİN TEKİL LOG

        if (userData != null && userData['isProfileCompleted'] == true) {
          debugPrint(
            'WelcomeScreen: YÖNLENDİRİLİYOR --> HomeScreen (KESİN VERSİYON)',
          ); // KESİN TEKİL LOG
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        } else {
          debugPrint(
            'WelcomeScreen: YÖNLENDİRİLİYOR --> ProfileSetupScreen (mevcut ama tamamlanmamış) (KESİN VERSİYON)',
          ); // KESİN TEKİL LOG
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const ProfileSetupScreen(initialData: null),
            ),
            (route) => false,
          );
        }
      } else {
        debugPrint(
          'WelcomeScreen: YÖNLENDİRİLİYOR --> ProfileSetupScreen (profil yok) (KESİN VERSİYON)',
        ); // KESİN TEKİL LOG
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint(
        'WelcomeScreen: HATA oluştu - ${e.toString()}. YÖNLENDİRİLİYOR --> ProfileSetupScreen (hata durumu) (KESİN VERSİYON)',
      ); // KESİN TEKİL LOG
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
        (route) => false,
      );
    }
  }

  // Google ile giriş fonksiyonu (EN SON VE KESİN VERSİYON)
  Future<void> _handleGoogleSignIn() async {
    final userCredential = await _authService.signInWithGoogle();
    if (userCredential != null) {
      debugPrint("Google Girişi Başarılı: ${userCredential.user?.email}");
      if (mounted) {
        // Yeni yönlendirme mantığını çağır
        await _checkProfileAndNavigate(userCredential.user);
      }
    } else {
      debugPrint("Google Girişi İptal Edildi veya Başarısız Oldu.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Google ile giriş başarısız oldu. Lütfen tekrar deneyin.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arka Plan Görseli veya Gradient
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
                mainAxisAlignment: MainAxisAlignment.end,
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
                  const SizedBox(height: 80),

                  // Google Giriş Butonu
                  _buildSocialLoginButton(
                    context,
                    text: 'Google ile Devam Et',
                    icon: Icons.g_mobiledata,
                    color: Colors.white,
                    textColor: Colors.black87,
                    onPressed: _handleGoogleSignIn,
                  ),
                  const SizedBox(height: 16),
                  // Apple ID Giriş Butonu (Şimdilik işlevsiz, daha sonra entegre edilecek)
                  _buildSocialLoginButton(
                    context,
                    text: 'Apple ID ile Devam Et',
                    icon: Icons.apple,
                    color: Colors.black,
                    textColor: Colors.white,
                    onPressed: () {
                      debugPrint('Apple ID ile Devam Et tıklandı (Yakında!)');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Apple ID ile giriş yakında aktif olacak.',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // E-posta ile Giriş Butonu
                  _buildOutlineButton(
                    context,
                    text: 'E-posta ile Devam Et',
                    onPressed: () {
                      // YENİ: EmailAuthScreen'e git
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EmailAuthScreen(),
                        ),
                      );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      child: Text(text),
    );
  }
}
