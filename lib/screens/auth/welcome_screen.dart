import 'package:flutter/material.dart';
import 'package:connectify_app/screens/auth/email_auth_screen.dart'; // E-posta/Şifre ekranı
import 'package:connectify_app/screens/auth/phone_auth_screen.dart'; // Telefon numarası doğrulama ekranı
// import 'package:connectify_app/screens/profile/profile_setup_screen.dart'; // Artık doğrudan bu ekrana yönlendirmiyoruz
import 'package:connectify_app/screens/home_screen.dart'; // Anasayfa
import 'package:google_sign_in/google_sign_in.dart'; // Google Sign-In için
import 'package:firebase_auth/firebase_auth.dart'; // Firebase kimlik doğrulama için
import 'package:connectify_app/services/snackbar_service.dart'; // SnackBarService için
import 'package:connectify_app/utils/app_colors.dart'; // Renk paletimiz için

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // Google ile giriş yapma fonksiyonu
  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // Kullanıcı Google girişini iptal etti
        SnackBarService.showSnackBar(
          context,
          message: 'Google ile giriş iptal edildi.',
          type: SnackBarType.info,
        );
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        SnackBarService.showSnackBar(
          context,
          message: 'Google ile başarıyla giriş yapıldı!',
          type: SnackBarType.success,
        );
        // AuthWrapper, kimlik doğrulama durumundaki değişikliği algılayacak
        // ve kullanıcının profilinin tamamlanıp tamamlanmadığına göre
        // WelcomeScreen, ProfileSetupScreen veya HomeScreen'e yönlendirecektir.
        // Bu ekrandan doğrudan Anasayfa'ya dönerek AuthWrapper'ın devreye girmesini sağlıyoruz.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In Hatası: ${e.code} - ${e.message}');
      String errorMessage = 'Google ile giriş başarısız oldu.';
      if (e.code == 'account-exists-with-different-credential') {
        errorMessage = 'Bu e-posta adresi farklı bir yöntemle zaten kayıtlı.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'İnternet bağlantınızı kontrol edin.';
      }
      SnackBarService.showSnackBar(
        context,
        message: errorMessage,
        type: SnackBarType.error,
      );
    } catch (e) {
      debugPrint('Genel Google Sign-In Hatası: $e');
      SnackBarService.showSnackBar(
        context,
        message: 'Google ile giriş yapılırken bir hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arka plan gradyanı veya resmi
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryYellow, AppColors.accentPink],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Connectify',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Anlamlı Bağlantılar Kurun',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 80),
                  // Google ile devam et butonu
                  ElevatedButton.icon(
                    onPressed: () => _signInWithGoogle(context),
                    icon: Image.asset('assets/images/google_logo.png',
                        height: 24), // Google logosu
                    label: const Text('Google ile Devam Et'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Telefon Numarası ile devam et butonu
                  ElevatedButton.icon(
                    // Yeni buton
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const PhoneAuthScreen()),
                      );
                    },
                    icon: Icon(Icons.phone, color: AppColors.white),
                    label: const Text('Telefon Numarası ile Devam Et'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentTeal, // Renk paletinden
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // E-posta ile devam et butonu
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const EmailAuthScreen()),
                      );
                    },
                    icon: Icon(Icons.email, color: AppColors.white),
                    label: const Text('E-posta ile Devam Et'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentTeal,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextButton(
                    onPressed: () {
                      // Gizlilik politikası veya kullanım koşulları
                      SnackBarService.showSnackBar(
                        context,
                        message:
                            'Kullanım Koşulları ve Gizlilik Politikası yakında.',
                        type: SnackBarType.info,
                      );
                    },
                    child: Text(
                      'Kullanım Koşulları ve Gizlilik Politikası',
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.7),
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
