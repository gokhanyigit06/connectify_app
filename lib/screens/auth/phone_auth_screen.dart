import 'package:flutter/material.dart';
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectify_app/screens/auth/phone_otp_screen.dart'; // OTP ekranına yönlendirme için

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  String? _verificationId; // Firebase'den gelen doğrulama kimliği

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhoneNumber() async {
    final phoneNumber = _phoneNumberController.text.trim();
    if (phoneNumber.isEmpty) {
      SnackBarService.showSnackBar(
        context,
        message: 'Lütfen telefon numaranızı girin.',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber:
            '+90$phoneNumber', // Ülke kodunu otomatik ekle (Türkiye için +90)
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android'de otomatik doğrulama tamamlandığında burası tetiklenir
          debugPrint(
              'Telefon numarası otomatik doğrulandı: ${credential.smsCode}');
          await _auth.signInWithCredential(credential);
          SnackBarService.showSnackBar(
            context,
            message: 'Telefon numarası başarıyla doğrulandı!',
            type: SnackBarType.success,
          );
          // Doğrulama tamamlandıktan sonra ana ekrana yönlendir
          Navigator.of(context).pop(); // PhoneAuthScreen'i kapat
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Telefon doğrulama başarısız: ${e.code} - ${e.message}');
          String errorMessage = 'Telefon doğrulaması başarısız oldu.';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Geçersiz telefon numarası formatı.';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Çok fazla istek. Lütfen daha sonra tekrar deneyin.';
          }
          SnackBarService.showSnackBar(
            context,
            message: errorMessage,
            type: SnackBarType.error,
          );
          setState(() {
            _isLoading = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          // Doğrulama kodu gönderildiğinde burası tetiklenir
          setState(() {
            _verificationId =
                verificationId; // Gelen doğrulama kimliğini kaydet
            _isLoading = false;
          });
          debugPrint(
              'Doğrulama kodu gönderildi. Verification ID: $_verificationId');
          SnackBarService.showSnackBar(
            context,
            message: 'Doğrulama kodu telefonunuza gönderildi!',
            type: SnackBarType.success,
          );
          // OTP giriş ekranına yönlendir
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PhoneOtpScreen(
                verificationId: verificationId,
                phoneNumber: phoneNumber,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Kod otomatik alınamazsa burası tetiklenir
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
          debugPrint('Doğrulama kodu zaman aşımına uğradı.');
        },
        timeout: const Duration(
            seconds: 60), // Kodu almak için maksimum bekleme süresi
      );
    } catch (e) {
      debugPrint('Telefon doğrulama sırasında genel hata: $e');
      SnackBarService.showSnackBar(
        context,
        message:
            'Telefon doğrulaması sırasında bir hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telefon ile Giriş'),
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
                'Telefon Numaranızı Girin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefon Numarası (Örn: 5XXXXXXXXX)',
                  prefixIcon: Icon(Icons.phone, color: AppColors.primaryYellow),
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
                      onPressed: _verifyPhoneNumber,
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
                      child: const Text('Doğrulama Kodu Gönder'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
