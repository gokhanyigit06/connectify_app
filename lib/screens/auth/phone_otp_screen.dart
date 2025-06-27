import 'package:flutter/material.dart';
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectify_app/screens/home_screen.dart'; // Başarılı doğrulama sonrası ana ekrana yönlendirme için

class PhoneOtpScreen extends StatefulWidget {
  final String verificationId; // Telefon doğrulamadan gelen kimlik
  final String phoneNumber; // Doğrulanan telefon numarası

  const PhoneOtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _signInWithOtp() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.isEmpty) {
      SnackBarService.showSnackBar(
        context,
        message: 'Lütfen doğrulama kodunu girin.',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: smsCode,
      );

      await _auth.signInWithCredential(credential);

      SnackBarService.showSnackBar(
        context,
        message: 'Telefon numarası başarıyla doğrulandı ve giriş yapıldı!',
        type: SnackBarType.success,
      );

      // Doğrulama ve giriş başarılı olduğunda ana ekrana yönlendir
      // AuthWrapper, profilin tamamlanıp tamamlanmadığını kontrol edecektir.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('OTP Doğrulama Hatası: ${e.code} - ${e.message}');
      String errorMessage = 'Doğrulama kodu yanlış veya süresi doldu.';
      if (e.code == 'invalid-verification-code') {
        errorMessage = 'Girdiğiniz doğrulama kodu geçersiz.';
      } else if (e.code == 'credential-already-in-use') {
        errorMessage = 'Bu telefon numarası zaten başka bir hesapla ilişkili.';
      }
      SnackBarService.showSnackBar(
        context,
        message: errorMessage,
        type: SnackBarType.error,
      );
    } catch (e) {
      debugPrint('Genel OTP Doğrulama Hatası: $e');
      SnackBarService.showSnackBar(
        context,
        message: 'OTP doğrulaması sırasında bir hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kodu Doğrula'),
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
                '${widget.phoneNumber} numarasına gönderilen 6 haneli kodu girin.',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6, // 6 haneli OTP kodu
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'Doğrulama Kodu',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(
                    fontSize: 24,
                    letterSpacing: 10,
                    color:
                        AppColors.primaryText), // Daha büyük ve aralıklı metin
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _signInWithOtp,
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
                      child: const Text('Doğrula ve Giriş Yap'),
                    ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // Kodu yeniden gönderme mantığı (Firebase verifyPhoneNumber'ı tekrar çağır)
                  // Ancak bu işlem için resendToken'ı kullanmak daha iyidir, şimdilik basitçe pop yapalım
                  Navigator.of(context)
                      .pop(); // Bir önceki ekrana (PhoneAuthScreen) dön
                  SnackBarService.showSnackBar(
                    context,
                    message: 'Doğrulama kodunu tekrar isteyin.',
                    type: SnackBarType.info,
                  );
                },
                child: Text(
                  'Kodu Tekrar Gönder',
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
