import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectify_app/firebase_options.dart';
import 'package:connectify_app/screens/auth/welcome_screen.dart';
import 'package:connectify_app/screens/home_screen.dart';
import 'package:connectify_app/screens/profile/profile_setup_screen.dart';
import 'package:connectify_app/screens/profile/intro_screen1.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:connectify_app/providers/tab_navigation_provider.dart';
import 'package:connectify_app/providers/onboarding_data_provider.dart';
import 'package:connectify_app/services/snackbar_service.dart'; // SnackBarService import edildi

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TabNavigationProvider()),
        ChangeNotifierProvider(create: (context) => OnboardingDataProvider()),
      ],
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
      home:
          const AuthWrapper(), // Kullanıcının durumuna göre yönlendirecek widget
    );
  }
}

// Kullanıcının giriş ve profil durumunu kontrol eden sarmalayıcı
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        debugPrint(
            'AuthWrapper: authStateChanges - ConnectionState: ${snapshot.connectionState}, HasData: ${snapshot.hasData}, HasError: ${snapshot.hasError}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('AuthWrapper: Kimlik doğrulama durumu bekleniyor...');
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final User? user = snapshot.data;

        if (user == null) {
          debugPrint(
              'AuthWrapper: Kullanıcı giriş yapmamış, WelcomeScreen gösteriliyor.');
          return const WelcomeScreen();
        } else {
          debugPrint(
              'AuthWrapper: Kullanıcı giriş yapmış (${user.uid}), profil kontrol ediliyor.');
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, profileSnapshot) {
              debugPrint(
                  'AuthWrapper: Profil FutureBuilder - ConnectionState: ${profileSnapshot.connectionState}, HasData: ${profileSnapshot.hasData}, HasError: ${profileSnapshot.hasError}');

              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                debugPrint('AuthWrapper: Profil verisi bekleniyor...');
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }

              if (profileSnapshot.hasError) {
                debugPrint(
                    'AuthWrapper: Profil kontrol edilirken hata oluştu: ${profileSnapshot.error}. IntroScreen1\'e yönlendiriliyor.');
                if (mounted) {
                  // mounted kontrolü eklendi
                  SnackBarService.showSnackBar(
                    context,
                    message:
                        'Profil yüklenirken bir hata oluştu: ${profileSnapshot.error.toString()}',
                    type: SnackBarType.error,
                  );
                }
                return const IntroScreen1();
              }

              if (profileSnapshot.hasData && profileSnapshot.data!.exists) {
                final userData =
                    profileSnapshot.data!.data() as Map<String, dynamic>?;
                if (userData != null &&
                    userData['isProfileCompleted'] == true) {
                  debugPrint(
                      'AuthWrapper: Profil tamamlandı, HomeScreen gösteriliyor.');
                  return const HomeScreen();
                } else {
                  debugPrint(
                      'AuthWrapper: Profil mevcut ama tamamlanmamış, IntroScreen1 gösteriliyor.');
                  return const IntroScreen1();
                }
              } else {
                debugPrint(
                    'AuthWrapper: Profil belgesi yok, IntroScreen1 gösteriliyor.');
                return const IntroScreen1();
              }
            },
          );
        }
      },
    );
  }
}
