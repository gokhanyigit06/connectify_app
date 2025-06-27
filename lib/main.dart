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
    // Auth ekranlarından sonraki yönlendirmeler artık o ekranlar tarafından yönetiliyor.
    // _checkAuthStateAndProfileOnAppStart(); // Bu metodu StreamBuilder ile değiştiriyoruz
  }

  @override
  Widget build(BuildContext context) {
    // FirebaseAuth'ın authStateChanges stream'ini dinle
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Bağlantı beklenirken yükleme göster
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final User? user = snapshot.data;

        if (user == null) {
          // Kullanıcı giriş yapmamışsa karşılama ekranına yönlendir
          debugPrint(
              'AuthWrapper: Kullanıcı giriş yapmamış, WelcomeScreen gösteriliyor.');
          return const WelcomeScreen();
        } else {
          // Kullanıcı giriş yapmışsa profilini kontrol et
          debugPrint(
              'AuthWrapper: Kullanıcı giriş yapmış (${user.uid}), profil kontrol ediliyor.');
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                // Profil verisi beklenirken yükleme göster
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }

              if (profileSnapshot.hasError) {
                debugPrint(
                    'AuthWrapper: Profil kontrol edilirken hata oluştu: ${profileSnapshot.error}. ProfileSetupScreen\'e yönlendiriliyor.');
                // Hata durumunda profil kurulum ekranına yönlendir
                return const ProfileSetupScreen();
              }

              if (profileSnapshot.hasData && profileSnapshot.data!.exists) {
                final userData =
                    profileSnapshot.data!.data() as Map<String, dynamic>?;
                if (userData != null &&
                    userData['isProfileCompleted'] == true) {
                  debugPrint(
                      'AuthWrapper: Profil tamamlandı, HomeScreen gösteriliyor.');
                  return const HomeScreen(); // Profil tamamlandıysa ana ekrana
                } else {
                  debugPrint(
                      'AuthWrapper: Profil mevcut ama tamamlanmamış, ProfileSetupScreen gösteriliyor.');
                  return const ProfileSetupScreen(); // Profil tamamlanmadıysa profil kurulum ekranına
                }
              } else {
                // Profil belgesi yoksa profil kurulum ekranına yönlendir
                debugPrint(
                    'AuthWrapper: Profil belgesi yok, ProfileSetupScreen gösteriliyor.');
                return const ProfileSetupScreen();
              }
            },
          );
        }
      },
    );
  }
}
