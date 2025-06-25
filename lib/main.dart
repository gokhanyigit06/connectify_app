import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectify_app/firebase_options.dart';
import 'package:connectify_app/screens/auth/welcome_screen.dart';
import 'package:connectify_app/screens/home_screen.dart';
import 'package:connectify_app/screens/profile/profile_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Connectify',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.yellow[700],
          textTheme: ButtonTextTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow[700],
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.yellow,
        ).copyWith(secondary: Colors.yellowAccent),
      ),
      home:
          const AuthWrapper(), // Kullanıcının durumuna göre yönlendirecek widget
    );
  }
}

// Kullanıcının giriş ve profil durumunu kontrol eden sarmalayıcı (EN SON VE KESİN VERSİYON)
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Yönlendirme işlemi tamamlanana kadar gösterilecek ekran
  Widget _initialWidget = const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  void initState() {
    super.initState();
    // Uygulama ilk açıldığında auth ve profil durumunu kontrol et
    // Bu sadece uygulamanın en başında bir kez çalışır.
    // Auth ekranlarından sonraki yönlendirmeler artık o ekranlar tarafından yönetiliyor.
    _checkAuthStateAndProfileOnAppStart();
  }

  Future<void> _checkAuthStateAndProfileOnAppStart() async {
    debugPrint(
      'AuthWrapper: _checkAuthStateAndProfileOnAppStart başlatıldı. (YENİ VERSİYON)',
    ); // KESİN TEKİL LOG
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint(
        'AuthWrapper: Uygulama başlangıcı - Kullanıcı giriş yapmamış, WelcomeScreen ayarlanıyor. (YENİ VERSİYON)',
      );
      setState(() {
        _initialWidget = const WelcomeScreen();
      });
    } else {
      debugPrint(
        'AuthWrapper: Uygulama başlangıcı - Kullanıcı giriş yapmış (${user.uid}), profil kontrol ediliyor. (YENİ VERSİYON)',
      );
      try {
        // Firestore'dan her zaman sunucudan en güncel veriyi çek.
        DocumentSnapshot profileDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(
              const GetOptions(source: Source.server),
            ); // KESİN SUNUCU KONTROLÜ

        if (profileDoc.exists) {
          final userData = profileDoc.data() as Map<String, dynamic>?;
          if (userData != null && userData['isProfileCompleted'] == true) {
            debugPrint(
              'AuthWrapper: Uygulama başlangıcı - Profil tamamlandı, HomeScreen ayarlanıyor. (YENİ VERSİYON)',
            );
            setState(() {
              _initialWidget = const HomeScreen();
            });
          } else {
            debugPrint(
              'AuthWrapper: Uygulama başlangıcı - Profil mevcut ama tamamlanmamış, ProfileSetupScreen ayarlanıyor. (YENİ VERSİYON)',
            );
            setState(() {
              _initialWidget = const ProfileSetupScreen();
            });
          }
        } else {
          debugPrint(
            'AuthWrapper: Uygulama başlangıcı - Profil yok, ProfileSetupScreen ayarlanıyor. (YENİ VERSİYON)',
          );
          setState(() {
            _initialWidget = const ProfileSetupScreen();
          });
        }
      } catch (e) {
        debugPrint(
          'AuthWrapper: Uygulama başlangıcı - Profil kontrol edilirken hata oluştu: $e. ProfileSetupScreen ayarlanıyor. (YENİ VERSİYON)',
        );
        setState(() {
          _initialWidget = const ProfileSetupScreen();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'AuthWrapper: build metodu çalıştı. Gösterilen initialWidget. (YENİ VERSİYON)',
    ); // KESİN TEKİL LOG
    return _initialWidget;
  }
}
