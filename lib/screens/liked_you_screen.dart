import 'dart:ui'; // ImageFilter.blur için
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectify_app/screens/profile/user_profile_screen.dart'; // AppBar'daki ikon için
import 'package:connectify_app/screens/home_screen.dart'; // Anasayfa yönlendirmesi için (şimdilik)

class LikedYouScreen extends StatefulWidget {
  const LikedYouScreen({super.key});

  @override
  State<LikedYouScreen> createState() => _LikedYouScreenState();
}

class _LikedYouScreenState extends State<LikedYouScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  List<Map<String, dynamic>> _likerProfiles =
      []; // Sizi beğenenlerin profil verileri
  bool _isPremiumUser = false; // Mevcut kullanıcının premium durumu

  @override
  void initState() {
    super.initState();
    _fetchLikedYouData();
  }

  // Sizi beğenenleri ve onların profillerini çeken fonksiyon
  Future<void> _fetchLikedYouData() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('LikedYouScreen: Kullanıcı giriş yapmamış. Veri çekilmedi.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Mevcut kullanıcının premium durumunu kontrol et
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (userDoc.exists) {
        _isPremiumUser =
            (userDoc.data() as Map<String, dynamic>)['isPremium'] ?? false;
      }

      // 2. Sizi beğenenlerin UID'lerini bul (likes koleksiyonundan)
      QuerySnapshot likedYouSnapshot = await _firestore
          .collection('likes')
          .where(
            'likedId',
            isEqualTo: currentUser.uid,
          ) // likedId'si mevcut kullanıcının UID'si olanları getir
          .get();

      List<String> likerUids = likedYouSnapshot.docs
          .map((doc) => doc['likerId'] as String)
          .toList();

      if (likerUids.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('LikedYouScreen: Sizi beğenen kimse bulunamadı.');
        return;
      }

      // 3. Beğenenlerin profil verilerini çek
      List<Map<String, dynamic>> tempLikerProfiles = [];
      for (String likerUid in likerUids) {
        DocumentSnapshot likerProfileDoc = await _firestore
            .collection('users')
            .doc(likerUid)
            .get();
        if (likerProfileDoc.exists) {
          tempLikerProfiles.add(likerProfileDoc.data() as Map<String, dynamic>);
        }
      }

      setState(() {
        _likerProfiles = tempLikerProfiles;
      });
    } catch (e) {
      debugPrint("LikedYouScreen: Veri çekilirken hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sizi beğenenleri yüklerken hata oluştu: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Premium'a yükseltme butonu tıklandığında
  void _upgradeToPremium() {
    debugPrint('LikedYouScreen: Premium\'a yükselt tıklandı.');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Premium yükseltme ekranı buraya gelecek.')),
    );
    // Buraya Premium satın alma ekranına yönlendirme gelecek
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seni Beğenenler'),
        // Profil ikonu, DiscoverScreen'deki gibi
        leading: IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () {
            debugPrint('LikedYouScreen: AppBar Profil İkonu tıklandı.');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const UserProfileScreen(),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), // Yenile ikonu
            onPressed: _fetchLikedYouData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _likerProfiles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Seni beğenen kimse bulunamadı.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _fetchLikedYouData,
                    child: const Text('Yenile'),
                  ),
                  if (!_isPremiumUser) ...[
                    // Premium değilse göster
                    const SizedBox(height: 40),
                    const Text(
                      'Kimlerin seni beğendiğini görmek ister misin?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _upgradeToPremium,
                      icon: const Icon(Icons.star),
                      label: const Text('Premium Ol'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            )
          : Column(
              children: [
                // Premium değilse üstte uyarı ve yükseltme butonu
                if (!_isPremiumUser)
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.yellow.withOpacity(0.2),
                    child: Column(
                      children: [
                        const Text(
                          'Kimlerin seni beğendiğini görmek için Premium ol!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _upgradeToPremium,
                          icon: const Icon(Icons.star, color: Colors.black),
                          label: const Text('Premium Ol'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Sizi beğenen profillerin listesi
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Yan yana 2 profil
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8, // Kart boyutu ayarlaması
                        ),
                    itemCount: _likerProfiles.length,
                    itemBuilder: (context, index) {
                      final profile = _likerProfiles[index];
                      final String profileImageUrl =
                          profile['profileImageUrl'] ??
                          'https://via.placeholder.com/150';
                      final String name = profile['name'] ?? 'Bilinmiyor';
                      final int age = profile['age'] ?? '?';

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Profil Resmi
                              Image.network(
                                profileImageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
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
                              // Blur efekti (Premium değilse)
                              if (!_isPremiumUser)
                                BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10.0,
                                    sigmaY: 10.0,
                                  ), // Blur gücü
                                  child: Container(
                                    color: Colors.black.withOpacity(
                                      0.2,
                                    ), // Hafif karartma
                                  ),
                                ),
                              // Bilgiler (Premium değilse isim ve yaş blurlu)
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isPremiumUser
                                            ? '$name, $age'
                                            : '?', // Premium değilse ? göster
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 5,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (_isPremiumUser) // Premium ise biyografi veya ilgi alanı özeti
                                        Text(
                                          profile['bio'] ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 5,
                                                color: Colors.black,
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
