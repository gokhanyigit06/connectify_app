import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectify_app/services/auth_service.dart';
import 'package:connectify_app/screens/auth/welcome_screen.dart';
import 'package:connectify_app/screens/profile/profile_setup_screen.dart'; // YENİ: ProfileSetupScreen import edildi

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService(); // AuthService örneği

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (Route<dynamic> route) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        actions: [
          // Profili Düzenle butonu
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // Kullanıcının mevcut profil verilerini çek
              DocumentSnapshot userDoc = await _firestore
                  .collection('users')
                  .doc(currentUser.uid)
                  .get();
              if (userDoc.exists) {
                final userData = userDoc.data() as Map<String, dynamic>;
                // ProfileSetupScreen'e mevcut verileri gönder
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfileSetupScreen(initialData: userData),
                  ),
                );
                debugPrint('Profili Düzenle tıklandı');
              } else {
                debugPrint('Profil verisi bulunamadı.');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil verisi bulunamadı.')),
                );
              }
            },
          ),
          // Çıkış Yap butonu
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              debugPrint('Çıkış Yapıldı');
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Veri yüklenirken hata oluştu: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Profil verisi bulunamadı. Lütfen profilinizi oluşturun.',
              ),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          // Profildeki bilgileri göster
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profil Fotoğrafı
                CircleAvatar(
                  radius: 80,
                  backgroundImage: NetworkImage(
                    userData['profileImageUrl'] ??
                        'https://via.placeholder.com/150',
                  ),
                  backgroundColor: Colors.grey[200],
                  child: userData['profileImageUrl'] == null
                      ? Icon(Icons.person, size: 80, color: Colors.grey[700])
                      : null,
                ),
                const SizedBox(height: 16),

                // Ad ve Yaş
                Text(
                  '${userData['name'] ?? 'Bilinmiyor'}, ${userData['age'] ?? '?'}.',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Cinsiyet
                Text(
                  userData['gender'] ?? 'Cinsiyet belirtilmemiş',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),

                // Biyografi
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    userData['bio'] ?? 'Biyografi henüz eklenmedi.',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 16),

                // İlgi Alanları
                if (userData['interests'] != null &&
                    userData['interests'].isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'İlgi Alanlarım:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: (userData['interests'] as List<dynamic>).map((
                        interest,
                      ) {
                        return Chip(
                          label: Text(interest),
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.7),
                          labelStyle: const TextStyle(color: Colors.black),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Diğer Fotoğraflar
                if (userData['otherImageUrls'] != null &&
                    userData['otherImageUrls'].isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Diğer Fotoğraflarım:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount:
                        (userData['otherImageUrls'] as List<dynamic>).length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          userData['otherImageUrls'][index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: Theme.of(context).primaryColor,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                ),
                              ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
