// lib/src/screens/profile/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectify_app/screens/auth/welcome_screen.dart'; // Çıkış yapınca yönlendirmek için
import 'package:connectify_app/screens/profile/profile_setup_screen.dart'; // Profili düzenle ekranına yönlendirme
import 'package:connectify_app/services/snackbar_service.dart'; // SnackBarService
import 'package:connectify_app/utils/app_colors.dart'; // Renk paleti
import 'package:connectify_app/screens/premium/premium_screen.dart'; // <<<--- YENİ: PremiumScreen için import

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userProfileData; // Kullanıcı profil verisi
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Kullanıcı profil verilerini Firestore'dan çeken fonksiyon
  Future<void> _fetchUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('UserProfileScreen: Kullanıcı giriş yapmamış.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (userDoc.exists) {
        setState(() {
          _userProfileData = userDoc.data() as Map<String, dynamic>;
        });
        debugPrint('UserProfileScreen: Profil verileri çekildi.');
      } else {
        debugPrint('UserProfileScreen: Profil verisi bulunamadı.');
        SnackBarService.showSnackBar(
          context,
          message: 'Profiliniz bulunamadı. Lütfen profilinizi oluşturun.',
          type: SnackBarType.info,
        );
      }
    } catch (e) {
      debugPrint('UserProfileScreen: Profil verileri çekilirken hata: $e');
      SnackBarService.showSnackBar(
        context,
        message: 'Profiliniz yüklenirken hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Çıkış yapma fonksiyonu
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      SnackBarService.showSnackBar(
        context,
        message: 'Başarıyla çıkış yapıldı!',
        type: SnackBarType.success,
      );
      // Çıkış yapıldıktan sonra giriş ekranına yönlendir
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Çıkış yapma hatası: $e');
      SnackBarService.showSnackBar(
        context,
        message: 'Çıkış yapılırken bir hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userProfileData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Profiliniz bulunamadı.',
              style: TextStyle(color: AppColors.primaryText),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileSetupScreen(),
                  ),
                );
              },
              child: const Text('Profili Oluştur'),
            ),
          ],
        ),
      );
    }

    final String name = _userProfileData!['name'] ?? 'Bilinmiyor';
    final int age = _userProfileData!['age'] ?? 0;
    final String gender = _userProfileData!['gender'] ?? 'Belirtilmedi';
    final String bio = _userProfileData!['bio'] ?? 'Biyografi yok.';
    final String location = _userProfileData!['location'] ?? 'Belirtilmedi';
    final List<String> interests = List<String>.from(
      _userProfileData!['interests'] ?? [],
    );
    final String profileImageUrl = _userProfileData!['profileImageUrl'] ??
        'https://placehold.co/150x150/CCCCCC/000000?text=Profil';
    final List<String> otherImageUrls = List<String>.from(
      _userProfileData!['otherImageUrls'] ?? [],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileSetupScreen(),
                ),
              );
              _fetchUserProfile();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profil Resmi
            CircleAvatar(
              radius: 80,
              backgroundImage: NetworkImage(profileImageUrl),
              backgroundColor: AppColors.grey.withOpacity(0.2),
            ),
            const SizedBox(height: 20),
            Text(
              '$name, $age',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              gender,
              style: TextStyle(fontSize: 18, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 20,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.primaryText),
            ),
            const SizedBox(height: 20),
            if (interests.isNotEmpty)
              Column(
                children: [
                  Text(
                    'İlgi Alanları:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    alignment: WrapAlignment.center,
                    children: interests.map((interest) {
                      return Chip(
                        label: Text(interest),
                        backgroundColor: AppColors.primaryYellow.withOpacity(
                          0.5,
                        ),
                        labelStyle: const TextStyle(color: Colors.black87),
                      );
                    }).toList(),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            if (otherImageUrls.isNotEmpty)
              Column(
                children: [
                  Text(
                    'Diğer Fotoğraflar:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: otherImageUrls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              otherImageUrls[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 100,
                                height: 100,
                                color: AppColors.grey.withOpacity(0.3),
                                child: Icon(
                                  Icons.broken_image,
                                  color: AppColors.red,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            // <<<--- BURADAN SONRA YENİ BUTONU EKLEDİK
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PremiumScreen(
                        message: 'Bu buton bir test içindir.'),
                  ),
                );
              },
              child: const Text('Premium Ekranını Aç (TEST)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPink, // Rengi AppColors'tan al
                foregroundColor: AppColors.white, // Yazı rengi
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            // <<<--- YENİ BUTON BİTİŞ
          ],
        ),
      ),
    );
  }
}
