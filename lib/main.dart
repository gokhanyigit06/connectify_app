import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectify_app/firebase_options.dart';
import 'package:connectify_app/screens/auth/welcome_screen.dart'; // YENİ: WelcomeScreen'i import ettik

void main() async {
  // Uygulamanın başlatılması için Flutter motorunun hazır olduğundan emin ol
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat
  // Bu kod, tüm platformlar için Firebase'i doğru seçeneklerle başlatır.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Debug bandını kaldırır
      title: 'Connectify', // Uygulama adı
      theme: ThemeData(
        primarySwatch: Colors.yellow, // Uygulamanın ana rengi (sarı tonları)
        scaffoldBackgroundColor: Colors.white, // Genel arka plan rengi
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // AppBar arka planı
          foregroundColor: Colors.black, // AppBar metin/ikon rengi
          elevation: 0, // AppBar altında gölge olmaması
          centerTitle: true, // Başlığı ortala
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
          // Diğer metin stillerini buraya ekleyebilirsiniz
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.yellow[700], // Buton rengi
          textTheme: ButtonTextTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Buton kenar yuvarlaklığı
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow[700], // Yükseltilmiş buton rengi
            foregroundColor:
                Colors.black, // Yükseltilmiş buton metin/ikon rengi
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
        // Diğer tema ayarları eklenebilir (input dekorasyonları, kart temaları vb.)
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.yellow,
        ).copyWith(secondary: Colors.yellowAccent),
      ),
      // YENİ: Uygulama başladığında WelcomeScreen'i göster
      home: const WelcomeScreen(),
    );
  }
}

// NOT: Daha önceki MyHomePage widget'ına artık ihtiyacımız kalmadı,
// onu tamamen silebilir veya yorum satırı yapabilirsiniz.
/*
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connectify'),
      ),
      body: const Center(
        child: Text(
          'Connectify Uygulamasına Hoş Geldiniz!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
*/
