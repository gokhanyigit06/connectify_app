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
import 'package:connectify_app/screens/filter_screen.dart'; // FilterScreen import edildi

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with AutomaticKeepAliveClientMixin<DiscoverScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<DocumentSnapshot> _userProfiles = [];
  bool _isLoading = false;

  DocumentSnapshot? _lastDocument;
  // O anki oturumda görülen kullanıcıların ID'lerini tutacak liste (Firebase sorgusu için değil, UI'da tekrarları önlemek için)
  final List<String> _seenUserIds = [];

  // Firebase'den çekilecek başka profil kalmadığını belirtir (sorgu boş döndüğünde true olur)
  bool _noMoreProfilesToFetch = false;

  FilterCriteria _currentFilters = FilterCriteria(); // Varsayılan boş filtreler

  @override
  void initState() {
    super.initState();
    _fetchUserProfiles(isInitialLoad: true);
  }

  @override
  bool get wantKeepAlive => true;

  // Kullanıcı profillerini Firestore'dan çeken ana fonksiyon
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
      // _seenUserIds.clear(); // BU SATIR KALDIRILDI: isRefresh'te seenUserIds'i temizleme!
      _lastDocument = null;
      _noMoreProfilesToFetch = false;
      debugPrint(
        'DiscoverScreen: Yenileme işlemi başlatıldı. Her şey sıfırlandı.',
      );
    }

    if (_isLoading && !isRefresh) {
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
    debugPrint(
      'DiscoverScreen: Mevcut Filtreler - MinAge: ${_currentFilters.minAge}, MaxAge: ${_currentFilters.maxAge}, Gender: ${_currentFilters.gender}, Location: ${_currentFilters.location}',
    );

    try {
      Query query = _firestore
          .collection('users')
          .where('uid', isNotEqualTo: currentUser.uid)
          .orderBy('uid', descending: true)
          .orderBy('createdAt', descending: true);

      // --- Filtreleri sorguya uygulama ---
      if (_currentFilters.minAge != null) {
        query = query.where(
          'age',
          isGreaterThanOrEqualTo: _currentFilters.minAge,
        );
      }
      if (_currentFilters.maxAge != null) {
        query = query.where('age', isLessThanOrEqualTo: _currentFilters.maxAge);
      }
      if (_currentFilters.gender != null &&
          _currentFilters.gender != 'Belirtmek İstemiyorum') {
        query = query.where('gender', isEqualTo: _currentFilters.gender);
      }
      if (_currentFilters.location != null) {
        query = query.where('location', isEqualTo: _currentFilters.location);
      }
      // --- Filtreleme sonu ---

      query = query.limit(10);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
        debugPrint(
          'DiscoverScreen: Pagination ile _lastDocument sonrası çekiliyor: ${_lastDocument!.id}',
        );
      } else {
        debugPrint(
          'DiscoverScreen: İlk çekim veya sıfırlanmış çekim yapılıyor (lastDocument null).',
        );
      }

      QuerySnapshot querySnapshot = await query.get();
      debugPrint(
        'DiscoverScreen: Firestore sorgu sonucu - ${querySnapshot.docs.length} yeni belge çekildi.',
      );

      List<DocumentSnapshot> newProfiles = querySnapshot.docs
          .where((doc) => !_seenUserIds.contains(doc.id))
          .toList();
      debugPrint(
        'DiscoverScreen: Filtrelenen yeni profil sayısı (seenUserIds hariç): ${newProfiles.length}',
      );

      if (newProfiles.isEmpty && querySnapshot.docs.isEmpty) {
        _noMoreProfilesToFetch = true;
        debugPrint(
          'DiscoverScreen: Firestore\'dan çekilecek yeni profil bulunamadı.',
        );
        if (_userProfiles.isEmpty && !isRefresh) {
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
        _userProfiles.addAll(newProfiles);
        if (querySnapshot.docs.isNotEmpty) {
          _lastDocument = querySnapshot.docs.last;
          debugPrint(
            'DiscoverScreen: _lastDocument güncellendi: ${_lastDocument!.id}',
          );
        }
        debugPrint(
          'DiscoverScreen: Güncel profil sayısı (setState sonrası): ${_userProfiles.length}',
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
    _seenUserIds.add(targetUserId);

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
    _seenUserIds.add(targetUserId);
    _showNextProfile();
  }

  void _showNextProfile() {
    setState(() {
      debugPrint(
        'DiscoverScreen: _showNextProfile çağrıldı. Mevcut profil sayısı: ${_userProfiles.length}, isLoading: $_isLoading, noMoreProfilesToFetch: $_noMoreProfilesToFetch',
      );
      if (_userProfiles.isNotEmpty) {
        _userProfiles.removeAt(0);
        debugPrint(
          'DiscoverScreen: Bir profil kaldırıldı. Yeni profil sayısı: ${_userProfiles.length}',
        );
      }

      if (_userProfiles.isEmpty && !_isLoading) {
        debugPrint(
          'DiscoverScreen: Liste tamamen boşaldı. Yeni profil çekme denemesi yapılıyor veya Empty State gösterilecek...',
        );
        if (!_noMoreProfilesToFetch) {
          _fetchUserProfiles();
        } else {
          debugPrint(
            'DiscoverScreen: Liste boşaldı ve Firebase\'de daha fazla profil yok. Empty State UI görünmeli.',
          );
        }
      } else {
        debugPrint(
          'DiscoverScreen: Profil çekme koşulu karşılanmadı. Mevcut _userProfiles.length: ${_userProfiles.length}, _isLoading: $_isLoading, _noMoreProfilesToFetch: $_noMoreProfilesToFetch',
        );
      }
    });
  }

  void _openFilterScreen() async {
    final FilterCriteria? newFilters = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FilterScreen(initialFilters: _currentFilters),
      ),
    );

    if (newFilters != null &&
        (newFilters.minAge != _currentFilters.minAge ||
            newFilters.maxAge != _currentFilters.maxAge ||
            newFilters.gender != _currentFilters.gender ||
            newFilters.location != _currentFilters.location)) {
      setState(() {
        _currentFilters = newFilters;
        debugPrint('DiscoverScreen: Yeni filtreler uygulandı.');
      });
      _fetchUserProfiles(isRefresh: true);
    } else {
      debugPrint('DiscoverScreen: Filtreler değişmedi veya iptal edildi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
            icon: const Icon(Icons.tune), // Filtre ikonu
            onPressed: _openFilterScreen, // Filtre ekranını aç
            tooltip: 'Filtrele',
          ),
          // Yenile butonu kaldırıldı.
          // if (!_noMoreProfilesToFetch)
          //   IconButton(
          //     icon: const Icon(Icons.refresh),
          //     onPressed: () => _fetchUserProfiles(isRefresh: true),
          //     tooltip: 'Profilleri Yenile',
          //   ),
        ],
      ),
      body: Builder(
        builder: (BuildContext innerContext) {
          if (_isLoading && _userProfiles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          } else if (_userProfiles.isEmpty) {
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
            return Stack(
              children: [
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
