import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectify_app/screens/home_screen.dart';
import 'package:connectify_app/screens/profile/profile_setup_screen.dart';
import 'package:connectify_app/screens/profile/intro_screen1.dart'; // IntroScreen1'e yönlendirme için
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:connectify_app/utils/app_colors.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLogin = true; // Giriş mi, kayıt mı?
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // Giriş yap
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        SnackBarService.showSnackBar(
          context,
          message: 'Başarıyla giriş yapıldı!',
          type: SnackBarType.success,
        );
        // Giriş başarılı olduğunda AuthWrapper yönetecek (HomeScreen'e gidecek)
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        // Kayıt ol
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        SnackBarService.showSnackBar(
          context,
          message: 'Hesabınız başarıyla oluşturuldu! Profilinizi tamamlayın.',
          type: SnackBarType.success,
        );
        // KAYIT BAŞARILI OLDUĞUNDA DİREKT PROFİL OLUŞTURMA AKIŞINA YÖNLENDİR
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) =>
                    const IntroScreen1()), // Doğrudan IntroScreen1'e yönlendir
            (Route<dynamic> route) => false, // Tüm önceki rotaları temizle
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Kimlik Doğrulama Hatası: ${e.code} - ${e.message}');
      String errorMessage = 'Bir hata oluştu.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage = 'Yanlış e-posta veya şifre.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Bu e-posta zaten kullanılıyor.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Şifre çok zayıf.';
      }
      SnackBarService.showSnackBar(
        context,
        message: errorMessage,
        type: SnackBarType.error,
      );
    } catch (e) {
      debugPrint('Genel Kimlik Doğrulama Hatası: $e');
      SnackBarService.showSnackBar(
        context,
        message: 'Kimlik doğrulanırken bir hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
      );
    } finally {
      if (mounted && _isLogin) {
        // Sadece giriş modunda hata sonrası geri dön
        setState(() {
          _isLoading = false;
        });
        // Navigator.of(context).pop(); // Giriş modunda pop yap (WelcomeScreen'e dön)
      } else if (mounted) {
        // Kayıt modunda ise işlem bitince isLoading'i kapat sadece
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLogin
                    ? 'Hesabınıza Giriş Yapın'
                    : 'Yeni Bir Hesap Oluşturun',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.email, color: AppColors.primaryYellow),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: TextStyle(color: AppColors.primaryText),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: Icon(Icons.lock, color: AppColors.primaryYellow),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: TextStyle(color: AppColors.primaryText),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _authenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        foregroundColor: AppColors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
                    ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _emailController.clear();
                    _passwordController.clear();
                  });
                },
                child: Text(
                  _isLogin
                      ? 'Hesabın yok mu? Kayıt Ol'
                      : 'Zaten hesabın var mı? Giriş Yap',
                  style: TextStyle(color: AppColors.accentPink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
