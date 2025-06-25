import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Web kontrolü için
import 'package:flutter/foundation.dart'; // Bu satırı ekleyin!

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Akım kullanıcıyı döndürür (Giriş yapılmışsa User nesnesi, değilse null)
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Google ile Giriş
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Web platformu için farklı bir akış gerekebilir (örneğin pop-up)
      // Şimdilik mobil için ana akışı kullanalım.
      // Web için GoogleSignInOptions'ı daha sonra yapılandırmamız gerekebilir.
      if (kIsWeb) {
        // Web için pop-up akışı
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobil için redirect/native akışı
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          // Kullanıcı girişi iptal etti
          return null;
        }
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint("Google ile giriş hatası: $e");
      return null;
    }
  }

  // E-posta ve Şifre ile Kayıt
  Future<UserCredential?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint("E-posta ile kayıt hatası: ${e.code}");
      return null;
    }
  }

  // E-posta ve Şifre ile Giriş
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint("E-posta ile giriş hatası: ${e.code}");
      return null;
    }
  }

  // Telefon Numarası ile Kimlik Doğrulama (OTP gönderme)
  // Bu akış biraz daha karmaşıktır ve Firebase konsolunda reCAPTCHA doğrulaması gerektirir.
  // Sadece ilk adımı, yani OTP göndermeyi ekleyelim.
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(PhoneAuthCredential) verificationCompleted,
    Function(FirebaseAuthException) verificationFailed,
    Function(String, int?) codeSent,
    Function(String) codeAutoRetrievalTimeout,
  ) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  // OTP kodu ile giriş yapma
  Future<UserCredential?> signInWithPhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    try {
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint("Telefon OTP ile giriş hatası: ${e.code}");
      return null;
    }
  }

  // Çıkış Yapma
  Future<void> signOut() async {
    await _googleSignIn.signOut(); // Google oturumunu da kapat
    await _auth.signOut();
  }
}
