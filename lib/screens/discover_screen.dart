import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectify_app/widgets/profile_card_widget.dart';
import 'package:connectify_app/screens/profile/user_profile_screen.dart';
import 'package:connectify_app/widgets/empty_state_widget.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:connectify_app/providers/tab_navigation_provider.dart';
import 'package:connectify_app/services/snackbar_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<DocumentSnapshot> _userProfiles = [];
  bool _isLoading = false;

  DocumentSnapshot? _lastDocument;
  final List<String> _seenUserIds = [];

  bool _noMoreProfilesToFetch =
      false; // Firebase'den çekilecek başka profil kalmadığını belirtir

  @override
  void initState() {
    super.initState();
    _fetchUserProfiles(isInitialLoad: true);
  }

  Future<void> _fetchUserProfiles({
    bool isInitialLoad = false,
    bool isRefresh = false,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('DiscoverScreen: Kullanıcı giriş yapmamış. Profil çekilmedi.');
      return;
    }

    if (isRefresh) {
      _userProfiles.clear();
      _seenUserIds.clear();
      _lastDocument = null;
      _noMoreProfilesToFetch = false; // Yenilemede sıfırla
      debugPrint(
        'DiscoverScreen: Yenileme işlemi başlatıldı. Her şey sıfırlandı.',
      );
    }

    if (_isLoading && !isRefresh) {
      // Eğer zaten yükleniyorsa ve bu bir yenileme isteği değilse, tekrar çekim yapma
      debugPrint(
        'DiscoverScreen: Zaten profiller yükleniyor veya listeye yeni eklendi. Tekrar çekim yapılmadı.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    debugPrint(
      'DiscoverScreen: _fetchUserProfiles başlatıldı. isLoading: $_isLoading, noMoreProfilesToFetch: $_noMoreProfilesToFetch',
    );

    try {
      Query query = _firestore
          .collection('users')
          .where('uid', isNotEqualTo: currentUser.uid)
          .orderBy('uid', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(10); // Her seferde 10 profil çek

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
        debugPrint(
          'DiscoverScreen: Pagination ile _lastDocument sonrası çekiliyor: ${_lastDocument!.id}',
        );
      } else {
        debugPrint(
          'DiscoverScreen: İlk çekim veya sıfırlanmış çekim yapılıyor.',
        );
      }

      QuerySnapshot querySnapshot = await query.get();
      debugPrint(
        'DiscoverScreen: Firestore sorgu sonucu - ${querySnapshot.docs.length} yeni belge çekildi.',
      );

      if (querySnapshot.docs.isEmpty) {
        _noMoreProfilesToFetch = true;
        debugPrint(
          'DiscoverScreen: Firestore\'dan çekilecek yeni profil bulunamadı.',
        );
        if (_userProfiles.isEmpty) {
          // Sadece UI'daki listemiz boşsa SnackBar göster
          SnackBarService.showSnackBar(
            context,
            message: 'Keşfedilecek yeni profil kalmadı.',
            type: SnackBarType.info,
          );
        }
      } else {
        _noMoreProfilesToFetch = false;
      }

      setState(() {
        // Yeni çekilen profilleri mevcut listeye ekle
        // Aynı profillerin tekrar gelmemesi için pagination zaten çalışıyor olmalı.
        _userProfiles.addAll(querySnapshot.docs);
        if (querySnapshot.docs.isNotEmpty) {
          _lastDocument = querySnapshot.docs.last;
          debugPrint(
            'DiscoverScreen: _lastDocument güncellendi: ${_lastDocument!.id}',
          );
        }
        debugPrint(
          'DiscoverScreen: Güncel profil sayısı: ${_userProfiles.length}',
        );
      });
    } catch (e) {
      debugPrint(
        "DiscoverScreen: Kullanıcı profilleri çekilirken HATA oluştu: $e",
      );
      _noMoreProfilesToFetch = true;
      SnackBarService.showSnackBar(
        context,
        message: 'Profiller yüklenirken hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      debugPrint(
        'DiscoverScreen: _fetchUserProfiles tamamlandı. Final isLoading: $_isLoading, Final noMoreProfilesToFetch: $_noMoreProfilesToFetch',
      );
    }
  }

  void _handleLike(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    debugPrint('DiscoverScreen: Beğenildi: $targetUserId');
    _seenUserIds.add(targetUserId); // Görülenler listesine ekle

    try {
      await _firestore.collection('likes').add({
        'likerId': currentUser.uid,
        'likedId': targetUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('DiscoverScreen: Beğeni Firestore\'a kaydedildi.');

      QuerySnapshot reciprocalLike = await _firestore
          .collection('likes')
          .where('likerId', isEqualTo: targetUserId)
          .where('likedId', isEqualTo: currentUser.uid)
          .get();

      if (reciprocalLike.docs.isNotEmpty) {
        debugPrint(
          'DiscoverScreen: Eşleşme oluştu: ${currentUser.uid} ve $targetUserId',
        );

        String user1Id = currentUser.uid.compareTo(targetUserId) < 0
            ? currentUser.uid
            : targetUserId;
        String user2Id = currentUser.uid.compareTo(targetUserId) < 0
            ? targetUserId
            : currentUser.uid;

        QuerySnapshot existingMatch = await _firestore
            .collection('matches')
            .where('user1Id', isEqualTo: user1Id)
            .where('user2Id', isEqualTo: user2Id)
            .get();

        if (existingMatch.docs.isEmpty) {
          await _firestore.collection('matches').add({
            'user1Id': user1Id,
            'user2Id': user2Id,
            'createdAt': FieldValue.serverTimestamp(),
          });
          debugPrint('DiscoverScreen: Eşleşme Firestore\'a kaydedildi.');
          SnackBarService.showSnackBar(
            context,
            message: 'Yeni bir eşleşmen var!',
            type: SnackBarType.success,
          );
        } else {
          debugPrint('DiscoverScreen: Eşleşme zaten mevcut.');
        }
      }
    } catch (e) {
      debugPrint(
        'DiscoverScreen: Beğeni/Eşleşme kaydedilirken hata oluştu: $e',
      );
      SnackBarService.showSnackBar(
        context,
        message: 'Beğeni veya eşleşme kaydedilemedi: ${e.toString()}',
        type: SnackBarType.error,
      );
    }

    _showNextProfile();
  }

  void _handlePass(String targetUserId) {
    debugPrint('DiscoverScreen: Geçildi: $targetUserId');
    _seenUserIds.add(targetUserId); // Görülenler listesine ekle
    _showNextProfile();
  }

  void _showNextProfile() {
    setState(() {
      debugPrint(
        'DiscoverScreen: _showNextProfile çağrıldı. Mevcut profil sayısı: ${_userProfiles.length}, isLoading: $_isLoading, noMoreProfilesToFetch: $_noMoreProfilesToFetch',
      );
      if (_userProfiles.isNotEmpty) {
        _userProfiles.removeAt(0); // Kartı kaldır
        debugPrint(
          'DiscoverScreen: Bir profil kaldırıldı. Yeni profil sayısı: ${_userProfiles.length}',
        );
      }

      // **BASİTLEŞTİRİLMİŞ PRE-FETCHING/EMPTY STATE MANTIĞI:**
      // Eğer liste tamamen boşaldıysa ve şu an bir yükleme işlemi yoksa,
      // Firebase'den daha fazla profil olup olmadığını kontrol et (bir kez daha çekmeyi dene).
      // Eğer çekilen profil yoksa, _noMoreProfilesToFetch true olacak ve EmptyStateWidget gösterilecek.
      if (_userProfiles.isEmpty && !_isLoading) {
        debugPrint(
          'DiscoverScreen: Liste tamamen boşaldı. Yeni profil çekme denemesi yapılıyor veya Empty State gösterilecek...',
        );
        if (!_noMoreProfilesToFetch) {
          // Eğer henüz Firebase'de çekilecek profil kalmadığı kesinleşmediyse
          _fetchUserProfiles(); // Yeni bir grup profil çekmeyi dene
        } else {
          // Liste boş ve Firebase'de gerçekten başka profil kalmadıysa, EmptyStateWidget görünecek.
          debugPrint(
            'DiscoverScreen: Liste boşaldı ve Firebase\'de daha fazla profil yok. Empty State UI görünmeli.',
          );
        }
      } else {
        // Liste hala boş değilse veya yükleme devam ediyorsa, hiçbir şey yapma.
        debugPrint(
          'DiscoverScreen: Profil çekme koşulu karşılanmadı. Mevcut _userProfiles.length: ${_userProfiles.length}, _isLoading: $_isLoading, _noMoreProfilesToFetch: $_noMoreProfilesToFetch',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'DiscoverScreen: Build metodu çalıştı. _userProfiles.length: ${_userProfiles.length}, _isLoading: $_isLoading, _noMoreProfilesToFetch: $_noMoreProfilesToFetch',
    );

    final double appBarHeight = AppBar().preferredSize.height;
    final double bottomNavBarHeight = kBottomNavigationBarHeight;
    final double availableHeight =
        MediaQuery.of(context).size.height -
        appBarHeight -
        bottomNavBarHeight -
        32;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keşfet'),
        leading: IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () {
            debugPrint('DiscoverScreen: AppBar Profil İkonu tıklandı.');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const UserProfileScreen(),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              debugPrint('DiscoverScreen: Filtre İkonu tıklandı');
            },
          ),
          if (!_noMoreProfilesToFetch) // Sadece çekilecek profil olabileceği düşünülüyorsa yenile butonu göster
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _fetchUserProfiles(isRefresh: true),
              tooltip: 'Profilleri Yenile',
            ),
        ],
      ),
      body: Builder(
        // Yeni Builder widget'ı eklendi
        builder: (BuildContext innerContext) {
          // innerContext kullanıldı
          if (_isLoading && _userProfiles.isEmpty) {
            // Eğer yükleme devam ediyorsa ve liste boşsa yükleme göster
            return const Center(child: CircularProgressIndicator());
          } else if (_userProfiles.isEmpty) {
            // Yükleme bitti ve hala boşsa EmptyStateWidget göster
            return EmptyStateWidget(
              icon: Icons.mood_bad_outlined,
              title: 'Keşfedilecek Kimse Yok',
              description:
                  'Görünüşe göre şu an gösterilecek yeni profil kalmadı. Daha hızlı bağlantılar kurmak için Canlı Sohbet\'i denemek ister misin?',
              buttonText: 'Canlı Sohbet\'e Git',
              onButtonPressed: () {
                Provider.of<TabNavigationProvider>(
                  innerContext,
                  listen: false,
                ).setIndex(5);
              },
            );
          } else {
            // Profiller varsa Stack'i göster
            return Stack(
              children: [
                // Arka plandaki kart (biraz daha küçük ve geride)
                if (_userProfiles.length > 1)
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(innerContext).size.width * 0.85,
                        height: availableHeight * 0.9,
                        child: ProfileCardWidget(
                          userData:
                              _userProfiles[1].data() as Map<String, dynamic>,
                        ),
                      ),
                    ),
                  ),

                // Ön plandaki kart (en büyük ve en önde)
                if (_userProfiles.isNotEmpty)
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(innerContext).size.width * 0.9,
                        height: availableHeight,
                        child: ProfileCardWidget(
                          userData:
                              _userProfiles[0].data() as Map<String, dynamic>,
                          onLike: () => _handleLike(_userProfiles[0].id),
                          onPass: () => _handlePass(_userProfiles[0].id),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }
        },
      ),
    );
  }
}
