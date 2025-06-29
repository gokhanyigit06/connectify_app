import 'dart:ui'; // ImageFilter.blur için
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectify_app/screens/profile/user_profile_screen.dart';
// import 'package:connectify_app/screens/home_screen.dart'; // Kullanılmıyor, kaldırabiliriz
import 'package:connectify_app/widgets/empty_state_widget.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:connectify_app/providers/tab_navigation_provider.dart';
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:connectify_app/screens/filter_screen.dart'; // FilterScreen için import
import 'package:connectify_app/screens/premium/premium_screen.dart'; // PremiumScreen için import

class LikedYouScreen extends StatefulWidget {
  const LikedYouScreen({super.key});

  @override
  State<LikedYouScreen> createState() => _LikedYouScreenState();
}

class _LikedYouScreenState extends State<LikedYouScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  List<Map<String, dynamic>> _allLikerProfiles = []; // Tüm beğenen profiller
  bool _isPremiumUser = false;

  FilterCriteria _currentFilters = FilterCriteria(); // <<<--- Filtre kriterleri

  @override
  void initState() {
    super.initState();
    _fetchLikedYouData();
  }

  // Kullanıcının premium durumunu kontrol eder ve bizi beğenenleri çeker
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
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        _isPremiumUser =
            (userDoc.data() as Map<String, dynamic>)['isPremium'] ?? false;
      }

      QuerySnapshot likedYouSnapshot = await _firestore
          .collection('likes')
          .where('likedId', isEqualTo: currentUser.uid)
          .get();

      // **ÖNEMLİ DÜZELTME:** likerUids listesini benzersiz hale getiriyoruz
      List<String> likerUids = likedYouSnapshot.docs
          .map((doc) => doc['likerId'] as String)
          .toSet() // Burası eklendi: UID'leri benzersiz yapar
          .toList(); // Tekrar listeye çevir

      if (likerUids.isEmpty) {
        setState(() {
          _isLoading = false;
          _allLikerProfiles.clear(); // Liste boşaltıldı
        });
        debugPrint('LikedYouScreen: Sizi beğenen kimse bulunamadı.');
        return;
      }

      List<Map<String, dynamic>> tempLikerProfiles = [];
      for (String likerUid in likerUids) {
        DocumentSnapshot likerProfileDoc =
            await _firestore.collection('users').doc(likerUid).get();
        if (likerProfileDoc.exists) {
          tempLikerProfiles.add(likerProfileDoc.data() as Map<String, dynamic>);
        }
      }

      setState(() {
        _allLikerProfiles = tempLikerProfiles; // Tüm profiller çekildi
      });
    } catch (e) {
      debugPrint("LikedYouScreen: Veri çekilirken hata oluştu: $e");
      SnackBarService.showSnackBar(
        context,
        message: 'Seni beğenenleri yüklerken hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filtreleme ekranını açar ve sonuçları alır
  void _openFilterScreen() async {
    final FilterCriteria? newFilters = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FilterScreen(initialFilters: _currentFilters),
      ),
    );

    if (newFilters != null) {
      setState(() {
        _currentFilters = newFilters;
      });
      // Filtreler değiştiğinde UI'ı yeniden çizmek yeterli, yeniden veri çekmeye gerek yok
      // Çünkü filtreleme client-side yapılacak
    }
  }

  void _upgradeToPremium() {
    debugPrint('LikedYouScreen: Premium\'a yükselt tıklandı.');
    // PremiumScreen'e yönlendirme
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PremiumScreen(
                  message: 'Kimlerin seni beğendiğini görmek için Premium ol!',
                )));
  }

  @override
  Widget build(BuildContext context) {
    // Filtrelenmiş profiller listesini oluştur
    final List<Map<String, dynamic>> filteredProfiles =
        _allLikerProfiles.where((profile) {
      // Yaş filtresi
      final int age = profile['age'] ?? 0;
      if (_currentFilters.minAge != null && age < _currentFilters.minAge!)
        return false;
      if (_currentFilters.maxAge != null && age > _currentFilters.maxAge!)
        return false;

      // Cinsiyet filtresi
      final String gender = profile['gender'] ?? '';
      if (_currentFilters.gender != null &&
          _currentFilters.gender != 'Fark Etmez' &&
          gender != _currentFilters.gender) return false;

      // Konum filtresi
      final String location = profile['location'] ?? '';
      if (_currentFilters.location != null &&
          _currentFilters.location!.isNotEmpty &&
          location.toLowerCase() != _currentFilters.location!.toLowerCase())
        return false;

      // Onaylı kullanıcı filtresi kaldırıldı, çünkü geçici olarak hepsi onaylı
      // if (_currentFilters.onlyVerified == true && !(profile['isVerified'] ?? false)) return false;

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seni Beğenenler'),
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
            icon: const Icon(Icons.refresh), // Yenile butonu
            onPressed: _fetchLikedYouData,
            tooltip: 'Yenile',
          ),
          IconButton(
            // Filtreleme butonu
            icon: const Icon(Icons.tune),
            onPressed: _openFilterScreen,
            tooltip: 'Filtrele',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredProfiles.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.favorite_border,
                  title: 'Henüz Kimse Seni Beğenmedi',
                  description: _isPremiumUser
                      ? 'Panikleme! Yeni kişileri keşfetmeye devam et, elbet seni beğenenler olacaktır.'
                      : 'Kimlerin seni beğendiğini görmek ister misin? Premium olarak gizemleri çöz!',
                  buttonText:
                      _isPremiumUser ? 'Keşfetmeye Başla' : 'Premium Ol',
                  onButtonPressed: () {
                    if (_isPremiumUser) {
                      // TODO: Keşfet sekmesine git (index 1)
                      Provider.of<TabNavigationProvider>(
                        context,
                        listen: false,
                      ).setIndex(1);
                      Navigator.of(context).popUntil(
                          (route) => route.isFirst); // Tüm route'ları kapat
                    } else {
                      _upgradeToPremium();
                    }
                  },
                )
              : Column(
                  children: [
                    if (!_isPremiumUser)
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: AppColors.primaryYellow.withOpacity(0.2),
                        child: Column(
                          children: [
                            Text(
                              'Kimlerin seni beğendiğini görmek için Premium ol!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _upgradeToPremium,
                              icon: const Icon(Icons.star,
                                  color: AppColors.black),
                              label: const Text('Premium Ol'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryYellow,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: filteredProfiles.length,
                        itemBuilder: (context, index) {
                          final profile = filteredProfiles[index];
                          final String profileImageUrl = profile[
                                  'profileImageUrl'] ??
                              'https://placehold.co/150x150/CCCCCC/000000?text=Profil';
                          final String name = profile['name'] ?? 'Bilinmiyor';
                          final int age = profile['age'] ?? 0;

                          return GestureDetector(
                            // <<< Tıklanabilir olması için GestureDetector ekledik
                            onTap: () {
                              // TODO: Profil detay ekranına yönlendirme
                              SnackBarService.showSnackBar(context,
                                  message:
                                      'Profil detayına yönlendiriliyorsunuz!',
                                  type: SnackBarType.info);
                            },
                            child: Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      profileImageUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.primaryYellow,
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        color: AppColors.grey.withOpacity(0.3),
                                        child: Icon(
                                          Icons.error_outline,
                                          color: AppColors.red,
                                        ),
                                      ),
                                    ),
                                    if (!_isPremiumUser)
                                      BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 15.0, // <<< BLUR ARTIRILDI
                                          sigmaY: 15.0, // <<< BLUR ARTIRILDI
                                        ),
                                        child: Container(
                                          color:
                                              AppColors.black.withOpacity(0.2),
                                        ),
                                      ),
                                    Positioned.fill(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _isPremiumUser
                                                  ? '$name, $age'
                                                  : '?',
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                shadows: [
                                                  Shadow(
                                                    blurRadius: 5,
                                                    color: AppColors.black,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (_isPremiumUser)
                                              Text(
                                                profile['bio'] ?? '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: AppColors.white
                                                      .withOpacity(
                                                    0.7,
                                                  ),
                                                  fontSize: 14,
                                                  shadows: [
                                                    Shadow(
                                                      blurRadius: 5,
                                                      color: AppColors.black,
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
