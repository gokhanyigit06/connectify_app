import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectify_app/firebase_options.dart';
import 'package:connectify_app/screens/auth/welcome_screen.dart';
import 'package:connectify_app/screens/home_screen.dart';
import 'package:connectify_app/screens/profile/profile_setup_screen.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:connectify_app/providers/tab_navigation_provider.dart';
import 'package:connectify_app/services/snackbar_service.dart'; // SnackBarService import edildi

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (context) => TabNavigationProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Connectify',
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.primaryText,
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.primaryText),
          bodyMedium: TextStyle(color: AppColors.primaryText),
          displayLarge: TextStyle(),
          displayMedium: TextStyle(),
          displaySmall: TextStyle(),
          headlineLarge: TextStyle(),
          headlineMedium: TextStyle(),
          headlineSmall: TextStyle(),
          titleLarge: TextStyle(),
          titleMedium: TextStyle(),
          titleSmall: TextStyle(),
          labelLarge: TextStyle(),
          labelMedium: TextStyle(),
          labelSmall: TextStyle(),
          bodySmall: TextStyle(),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: AppColors.primaryYellow,
          textTheme: ButtonTextTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryYellow,
            foregroundColor: AppColors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryYellow,
          primary: AppColors.primaryYellow,
          secondary: AppColors.accentPink,
          surface: AppColors.background,
          onPrimary: AppColors.black,
          onSecondary: AppColors.white,
          onSurface: AppColors.primaryText,
          background: AppColors.background,
          onBackground: AppColors.primaryText,
          error: AppColors.red,
          onError: AppColors.white,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Widget _initialWidget = const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  void initState() {
    super.initState();
    _checkAuthStateAndProfileOnAppStart();
  }

  Future<void> _checkAuthStateAndProfileOnAppStart() async {
    debugPrint(
      'AuthWrapper: _checkAuthStateAndProfileOnAppStart başlatıldı. (YENİ VERSİYON)',
    );
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
        DocumentSnapshot profileDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.server));

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
            SnackBarService.showSnackBar(
              // SnackBarService eklendi
              context,
              message: 'Profilinizi tamamlamanız gerekiyor!',
              type: SnackBarType.info,
            );
          }
        } else {
          debugPrint(
            'AuthWrapper: Uygulama başlangıcı - Profil yok, ProfileSetupScreen ayarlanıyor. (YENİ VERSİYON)',
          );
          setState(() {
            _initialWidget = const ProfileSetupScreen();
          });
          SnackBarService.showSnackBar(
            // SnackBarService eklendi
            context,
            message:
                'Hesabınızı kullanmaya başlamak için profilinizi oluşturun!',
            type: SnackBarType.info,
          );
        }
      } catch (e) {
        debugPrint(
          'AuthWrapper: Uygulama başlangıcı - Profil kontrol edilirken hata oluştu: $e. ProfileSetupScreen ayarlanıyor. (YENİ VERSİYON)',
        );
        setState(() {
          _initialWidget = const ProfileSetupScreen();
        });
        SnackBarService.showSnackBar(
          // SnackBarService eklendi
          context,
          message: 'Profil yüklenirken bir hata oluştu: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'AuthWrapper: build metodu çalıştı. Gösterilen initialWidget. (YENİ VERSİYON)',
    );
    return _initialWidget;
  }
}
