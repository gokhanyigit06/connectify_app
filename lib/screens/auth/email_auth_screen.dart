import 'package:flutter/material.dart';
import 'package:connectify_app/services/auth_service.dart';
import 'package:connectify_app/screens/home_screen.dart';
import 'package:connectify_app/screens/profile/profile_setup_screen.dart'; // ProfileSetupScreen'i import et
import 'package:firebase_auth/firebase_auth.dart'; // User sınıfı için
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore için

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLogin = true; // true: Giriş Ekranı, false: Kayıt Ekranı
  bool _isLoading = false; // Yüklenme durumu için

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  // YÖNLENDİRME YARDIMCI FONKSİYONU (EN SON VE KESİN VERSİYON)
  Future<void> _checkProfileAndNavigate(User? user) async {
    if (user == null || !mounted) {
      debugPrint(
        'EmailAuthScreen: _checkProfileAndNavigate -- User null veya widget bağlı değil. Çıkılıyor. (KESİN VERSİYON)',
      );
      return;
    }

    debugPrint(
      'EmailAuthScreen: _checkProfileAndNavigate başlatıldı. UID: ${user.uid} (KESİN VERSİYON)',
    );
    try {
      debugPrint(
        'EmailAuthScreen: Firestore belge çekiliyor: users/${user.uid} (KESİN VERSİYON)',
      );
      DocumentSnapshot profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      debugPrint(
        'EmailAuthScreen: Firestore belge çekildi. exists: ${profileDoc.exists} (KESİN VERSİYON)',
      );

      if (profileDoc.exists) {
        final userData = profileDoc.data() as Map<String, dynamic>?;
        debugPrint(
          'EmailAuthScreen: Profil verisi mevcut. isProfileCompleted: ${userData?['isProfileCompleted']} (KESİN VERSİYON)',
        );

        if (userData != null && userData['isProfileCompleted'] == true) {
          debugPrint(
            'EmailAuthScreen: YÖNLENDİRİLİYOR --> HomeScreen (KESİN VERSİYON)',
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        } else {
          debugPrint(
            'EmailAuthScreen: YÖNLENDİRİLİYOR --> ProfileSetupScreen (mevcut ama tamamlanmamış) (KESİN VERSİYON)',
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const ProfileSetupScreen(initialData: null),
            ),
            (route) => false,
          );
        }
      } else {
        debugPrint(
          'EmailAuthScreen: YÖNLENDİRİLİYOR --> ProfileSetupScreen (profil yok) (KESİN VERSİYON)',
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint(
        'EmailAuthScreen: HATA oluştu - ${e.toString()}. YÖNLENDİRİLİYOR --> ProfileSetupScreen (hata durumu) (KESİN VERSİYON)',
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
        (route) => false,
      );
    }
  }

  // Giriş ve Kayıt formlarının validasyonu
  bool _validateForm() {
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
    bool isValid = true;

    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _emailError = 'Geçerli bir e-posta adresi girin.';
      isValid = false;
    }

    if (_passwordController.text.isEmpty ||
        _passwordController.text.length < 6) {
      _passwordError = 'Şifre en az 6 karakter olmalı.';
      isValid = false;
    }

    if (!_isLogin &&
        _passwordController.text != _confirmPasswordController.text) {
      _confirmPasswordError = 'Şifreler eşleşmiyor.';
      isValid = false;
    }

    setState(() {});
    return isValid;
  }

  // Giriş yapma fonksiyonu (EN SON VE KESİN VERSİYON)
  Future<void> _handleSignIn() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });
    final userCredential = await _authService.signInWithEmailAndPassword(
      _emailController.text,
      _passwordController.text,
    );
    setState(() {
      _isLoading = false;
    });

    if (userCredential != null) {
      debugPrint("Giriş Başarılı: ${userCredential.user?.email}");
      if (mounted) {
        // Yeni yönlendirme mantığını çağır
        await _checkProfileAndNavigate(userCredential.user);
      }
    } else {
      String errorMessage =
          'Giriş başarısız oldu. Lütfen bilgilerinizi kontrol edin.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  // Kayıt olma fonksiyonu (EN SON VE KESİN VERSİYON)
  Future<void> _handleSignUp() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });
    final userCredential = await _authService.signUpWithEmailAndPassword(
      _emailController.text,
      _passwordController.text,
    );
    setState(() {
      _isLoading = false;
    });

    if (userCredential != null) {
      debugPrint("Kayıt Başarılı: ${userCredential.user?.email}");
      if (mounted) {
        // Yeni yönlendirme mantığını çağır
        await _checkProfileAndNavigate(userCredential.user);
      }
    } else {
      String errorMessage = 'Kayıt başarısız oldu. Lütfen tekrar deneyin.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // E-posta Giriş Alanı
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  hintText: 'e-posta adresinizi girin',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  errorText: _emailError,
                ),
              ),
              const SizedBox(height: 16),

              // Şifre Giriş Alanı
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  hintText: 'şifrenizi girin',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  errorText: _passwordError,
                ),
              ),
              const SizedBox(height: 16),

              // Şifre Tekrar Giriş Alanı (Sadece Kayıt Ekranında)
              if (!_isLogin)
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Şifreyi Onayla',
                    hintText: 'şifrenizi tekrar girin',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    errorText: _confirmPasswordError,
                  ),
                ),
              if (!_isLogin) const SizedBox(height: 16),

              // Ana Buton (Giriş Yap / Kayıt Ol)
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _isLogin ? _handleSignIn : _handleSignUp,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
                      ),
                    ),
              const SizedBox(height: 24),

              // Geçiş Butonu (Hesabınız yok mu? Kayıt Ol / Hesabınız var mı? Giriş Yap)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _emailError = null;
                    _passwordError = null;
                    _confirmPasswordError = null;
                    _emailController.clear();
                    _passwordController.clear();
                    _confirmPasswordController.clear();
                  });
                },
                child: Text(
                  _isLogin
                      ? 'Hesabınız yok mu? Kayıt Ol'
                      : 'Zaten hesabınız var mı? Giriş Yap',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
