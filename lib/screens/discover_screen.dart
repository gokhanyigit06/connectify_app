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
import 'package:connectify_app/screens/filter_screen.dart';
import 'package:connectify_app/screens/match_found_screen.dart';

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
  final List<String> _seenUserIds = [];

  bool _noMoreProfilesToFetch = false;
  bool _isPremiumUser = false;
  int _swipeCount = 0;
  int _likesRemainingToday = 0;

  FilterCriteria _currentFilters = FilterCriteria();
  Map<String, dynamic>? _currentUserProfileData;

  // Geri Al/Geri Sar özelliği için yeni değişkenler
  String? _lastSwipedUserId; // En son kaydırılan kullanıcının UID'si
  String? _lastSwipedAction; // 'like' veya 'pass'

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserProfile();
    _checkUserPremiumStatus();
    _fetchUserProfiles(isInitialLoad: true);
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _fetchCurrentUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        setState(() {
          _currentUserProfileData = userDoc.data() as Map<String, dynamic>;
        });
        debugPrint(
            'DiscoverScreen: Mevcut kullanıcı profili çekildi: ${_currentUserProfileData?['name']}');
      }
    } catch (e) {
      debugPrint(
          'DiscoverScreen: Mevcut kullanıcı profili çekilirken hata: $e');
      SnackBarService.showSnackBar(
        context,
        message: 'Kendi profiliniz yüklenirken hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _checkUserPremiumStatus() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        setState(() {
          _isPremiumUser =
              (userDoc.data() as Map<String, dynamic>)['isPremium'] ?? false;
          _likesRemainingToday =
              (userDoc.data() as Map<String, dynamic>)['likesRemainingToday'] ??
                  0;
        });
        debugPrint(
            'DiscoverScreen: Kullanıcı premium durumu: $_isPremiumUser, Kalan Beğeni: $_likesRemainingToday');
      }
    } catch (e) {
      debugPrint(
          'DiscoverScreen: Premium durumu veya kalan beğeni çekilirken hata: $e');
      SnackBarService.showSnackBar(
        context,
        message:
            'Premium durumu veya kalan beğeni yüklenirken hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _fetchUserProfiles(
      {bool isInitialLoad = false, bool isRefresh = false}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('DiscoverScreen: Kullanıcı giriş yapmamış. Profil çekilmedi.');
      return;
    }

    if (isRefresh) {
      _userProfiles.clear();
      // _seenUserIds.clear(); // isRefresh'te seenUserIds'i temizlemiyoruz, çünkü geri sarma yapabiliriz.
      _lastDocument = null;
      _noMoreProfilesToFetch = false;
      debugPrint(
          'DiscoverScreen: Yenileme işlemi başlatıldı. Her şey sıfırlandı.');
    }

    if (_isLoading && !isRefresh) {
      debugPrint(
          'DiscoverScreen: Zaten profiller yükleniyor veya listeye yeni eklendi. Tekrar çekim yapılmadı.');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    debugPrint(
        'DiscoverScreen: _fetchUserProfiles başlatıldı. isLoading: $_isLoading, noMoreProfilesToFetch: $_noMoreProfilesToFetch');
    debugPrint(
        'DiscoverScreen: Mevcut Filtreler - MinAge: ${_currentFilters.minAge}, MaxAge: ${_currentFilters.maxAge}, Gender: ${_currentFilters.gender}, Location: ${_currentFilters.location}');

    try {
      Query query = _firestore
          .collection('users')
          .where('uid', isNotEqualTo: currentUser.uid)
          .orderBy('uid', descending: true)
          .orderBy('createdAt', descending: true);

      if (_currentFilters.minAge != null) {
        query =
            query.where('age', isGreaterThanOrEqualTo: _currentFilters.minAge);
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

      query = query.limit(10);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
        debugPrint(
            'DiscoverScreen: Pagination ile _lastDocument sonrası çekiliyor: ${_lastDocument!.id}');
      } else {
        debugPrint(
            'DiscoverScreen: İlk çekim veya sıfırlanmış çekim yapılıyor (lastDocument null).');
      }

      QuerySnapshot querySnapshot = await query.get();
      debugPrint(
          'DiscoverScreen: Firestore sorgu sonucu - ${querySnapshot.docs.length} yeni belge çekildi.');

      List<DocumentSnapshot> newProfiles = querySnapshot.docs
          .where((doc) => !_seenUserIds.contains(doc.id))
          .toList();
      debugPrint(
          'DiscoverScreen: Filtrelenen yeni profil sayısı (seenUserIds hariç): ${newProfiles.length}');

      if (newProfiles.isEmpty && querySnapshot.docs.isEmpty) {
        _noMoreProfilesToFetch = true;
        debugPrint(
            'DiscoverScreen: Firestore\'dan çekilecek yeni profil bulunamadı.');
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
              'DiscoverScreen: _lastDocument güncellendi: ${_lastDocument!.id}');
        }
        debugPrint(
            'DiscoverScreen: Güncel profil sayısı (setState sonrası): ${_userProfiles.length}');
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
          'DiscoverScreen: _fetchUserProfiles tamamlandı. Final isLoading: $_isLoading, Final noMoreProfilesToFetch: $_noMoreProfilesToFetch');
    }
  }

  void _handleLike(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    if (!_isPremiumUser && _likesRemainingToday <= 0) {
      SnackBarService.showSnackBar(
        context,
        message:
            'Bugünlük beğeni limitini doldurdun! Sınırsız beğeni için Premium ol.',
        type: SnackBarType.info,
        actionLabel: 'Premium Ol',
        onActionPressed: () {
          SnackBarService.showSnackBar(context,
              message: 'Premium ekranına yönlendiriliyorsunuz.',
              type: SnackBarType.info);
        },
      );
      return;
    }

    debugPrint('DiscoverScreen: Beğenildi: $targetUserId');
    _seenUserIds.add(targetUserId);

    try {
      if (!_isPremiumUser) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'likesRemainingToday': FieldValue.increment(-1),
        });
        setState(() {
          _likesRemainingToday--;
        });
        debugPrint(
            'DiscoverScreen: Kalan beğeni hakkı güncellendi: $_likesRemainingToday');
      }

      await _firestore.collection('likes').add({
        'likerId': currentUser.uid,
        'likedId': targetUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('DiscoverScreen: Beğeni Firestore\'a kaydedildi.');

      QuerySnapshot reciprocalLike = await _firestore
          .collection('likes')
          .where(
            'likerId',
            isEqualTo: targetUserId,
          )
          .where(
            'likedId',
            isEqualTo: currentUser.uid,
          )
          .get();

      if (reciprocalLike.docs.isNotEmpty) {
        debugPrint(
            'DiscoverScreen: Eşleşme oluştu: ${currentUser.uid} ve $targetUserId');

        DocumentSnapshot matchedUserDoc =
            await _firestore.collection('users').doc(targetUserId).get();
        if (matchedUserDoc.exists && _currentUserProfileData != null) {
          final matchedUserProfileData =
              matchedUserDoc.data() as Map<String, dynamic>;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MatchFoundScreen(
                currentUserProfile: _currentUserProfileData!,
                matchedUserProfile: matchedUserProfileData,
              ),
            ),
          );
        } else {
          SnackBarService.showSnackBar(
            context,
            message: 'Yeni bir eşleşmen var!',
            type: SnackBarType.success,
          );
        }

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
        } else {
          debugPrint('DiscoverScreen: Eşleşme zaten mevcut.');
        }
      } else {
        SnackBarService.showSnackBar(
          context,
          message: 'Kullanıcı beğenildi!',
          type: SnackBarType.info,
        );
      }
    } catch (e) {
      debugPrint(
          'DiscoverScreen: Beğeni/Eşleşme kaydedilirken hata oluştu: $e');
      SnackBarService.showSnackBar(
        context,
        message: 'Beğeni veya eşleşme kaydedilemedi: ${e.toString()}',
        type: SnackBarType.error,
      );
    }

    // Geri Al özelliği için son kaydırma bilgisini kaydet
    setState(() {
      _lastSwipedUserId = targetUserId;
      _lastSwipedAction = 'like';
    });

    _showNextProfile();
  }

  void _handlePass(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    if (!_isPremiumUser && _likesRemainingToday <= 0) {
      SnackBarService.showSnackBar(
        context,
        message:
            'Bugünlük kaydırma limitini doldurdun! Sınırsız kaydırma için Premium ol.',
        type: SnackBarType.info,
        actionLabel: 'Premium Ol',
        onActionPressed: () {
          SnackBarService.showSnackBar(context,
              message: 'Premium ekranına yönlendiriliyorsunuz.',
              type: SnackBarType.info);
        },
      );
      return;
    }

    debugPrint('DiscoverScreen: Geçildi: $targetUserId');
    _seenUserIds.add(targetUserId);

    try {
      if (!_isPremiumUser) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'likesRemainingToday': FieldValue.increment(-1),
        });
        setState(() {
          _likesRemainingToday--;
        });
        debugPrint(
            'DiscoverScreen: Kalan kaydırma hakkı güncellendi: $_likesRemainingToday');
      }
    } catch (e) {
      debugPrint(
          'DiscoverScreen: Kaydırma hakkı güncellenirken hata oluştu: $e');
      SnackBarService.showSnackBar(
        context,
        message: 'Kaydırma hakkı güncellenemedi: ${e.toString()}',
        type: SnackBarType.error,
      );
    }

    // Geri Al özelliği için son kaydırma bilgisini kaydet
    setState(() {
      _lastSwipedUserId = targetUserId;
      _lastSwipedAction = 'pass';
    });

    _showNextProfile();
  }

  // Yeni: Geri Al/Geri Sar (Rewind) işlemi
  void _handleRewind() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null ||
        !_isPremiumUser ||
        _lastSwipedUserId == null ||
        _lastSwipedAction == null) {
      SnackBarService.showSnackBar(
        context,
        message:
            'Geri Al özelliği Premium üyelerine özeldir veya geri alınacak bir işlem yok.',
        type: SnackBarType.info,
        actionLabel: 'Premium Ol',
        onActionPressed: () {
          SnackBarService.showSnackBar(context,
              message: 'Premium ekranına yönlendiriliyorsunuz.',
              type: SnackBarType.info);
        },
      );
      return;
    }

    debugPrint(
        'DiscoverScreen: Geri Al işlemi başlatıldı. Son Kaydırılan UID: $_lastSwipedUserId, Eylem: $_lastSwipedAction');

    try {
      // 1. Kullanıcıyı listeye geri ekle
      // _lastSwipedUserId'nin profilini Firestore'dan çek
      DocumentSnapshot lastSwipedUserDoc =
          await _firestore.collection('users').doc(_lastSwipedUserId!).get();
      if (lastSwipedUserDoc.exists) {
        setState(() {
          _userProfiles.insert(0, lastSwipedUserDoc); // Listeye en başa ekle
          _seenUserIds
              .remove(_lastSwipedUserId); // Görülenler listesinden çıkar
          debugPrint(
              'DiscoverScreen: $_lastSwipedUserId tekrar listeye eklendi.');
        });
      }

      // 2. Firestore'daki ilgili kaydı geri al
      if (_lastSwipedAction == 'like') {
        // Beğeni kaydını sil
        QuerySnapshot likeQuery = await _firestore
            .collection('likes')
            .where('likerId', isEqualTo: currentUser.uid)
            .where('likedId', isEqualTo: _lastSwipedUserId)
            .limit(1)
            .get();
        if (likeQuery.docs.isNotEmpty) {
          await _firestore
              .collection('likes')
              .doc(likeQuery.docs.first.id)
              .delete();
          debugPrint('DiscoverScreen: Beğeni kaydı Firestore\'dan silindi.');
        }

        // Karşılıklı beğeni ve eşleşme varsa onu da geri al (karmaşık, şimdilik sadece beğeni silindiğinde eşleşme durumuna bakmıyoruz)
        // Eğer eşleşme de silinecekse, matches koleksiyonunda da kontrol ve silme yapılmalı.
        // Bu daha ileri düzey bir güvenlik ve veri tutarlılığı gerektirir.
      } else if (_lastSwipedAction == 'pass') {
        // Geçiş kaydını sil (eğer tutuyorsak, şu an tutmuyoruz ama ileride tutarsak)
        // Örneğin, 'passes' adında bir koleksiyonunuz olsaydı:
        // QuerySnapshot passQuery = await _firestore.collection('passes').where('passerId', isEqualTo: currentUser.uid).where('passedId', isEqualTo: _lastSwipedUserId).limit(1).get();
        // if(passQuery.docs.isNotEmpty) await _firestore.collection('passes').doc(passQuery.docs.first.id).delete();
        debugPrint(
            'DiscoverScreen: Geçiş kaydı geri alındı (uygulama içi takip).');
      }

      // 3. Reklam sayacını ve kalan beğeni hakkını geri al (isteğe bağlı)
      if (!_isPremiumUser) {
        // Reklam sayacını bir azalt
        _swipeCount--;
        // Kalan beğeni hakkını bir artır (sadece ücretsiz kullanıcılar için)
        await _firestore.collection('users').doc(currentUser.uid).update({
          'likesRemainingToday': FieldValue.increment(1),
        });
        setState(() {
          _likesRemainingToday++;
        });
        debugPrint(
            'DiscoverScreen: Reklam sayacı ve kalan beğeni hakkı geri alındı.');
      }

      SnackBarService.showSnackBar(
        context,
        message: 'İşlem geri alındı!',
        type: SnackBarType.success,
      );
    } catch (e) {
      debugPrint('DiscoverScreen: Geri Al işlemi sırasında hata: $e');
      SnackBarService.showSnackBar(
        context,
        message: 'Geri Al işlemi başarısız oldu: ${e.toString()}',
        type: SnackBarType.error,
      );
    } finally {
      // Geri al işlemi tamamlandıktan sonra bilgileri sıfırla
      setState(() {
        _lastSwipedUserId = null;
        _lastSwipedAction = null;
      });
    }
  }

  void _showNextProfile() {
    setState(() {
      debugPrint(
          'DiscoverScreen: _showNextProfile çağrıldı. Mevcut profil sayısı: ${_userProfiles.length}, isLoading: $_isLoading, noMoreProfilesToFetch: $_noMoreProfilesToFetch');
      if (_userProfiles.isNotEmpty) {
        _userProfiles.removeAt(0);
        debugPrint(
            'DiscoverScreen: Bir profil kaldırıldı. Yeni profil sayısı: ${_userProfiles.length}');

        if (!_isPremiumUser) {
          _swipeCount++;
          debugPrint('DiscoverScreen: Kaydırma Sayısı: $_swipeCount');

          if (_swipeCount % 6 == 0 && _swipeCount != 0) {
            _showAdPlaceholder();
          }
        }
      }

      if (_userProfiles.isEmpty && !_isLoading) {
        debugPrint(
            'DiscoverScreen: Liste tamamen boşaldı. Yeni profil çekme denemesi yapılıyor veya Empty State gösterilecek...');
        if (!_noMoreProfilesToFetch) {
          _fetchUserProfiles();
        } else {
          debugPrint(
              'DiscoverScreen: Liste boşaldı ve Firebase\'de daha fazla profil yok. Empty State UI görünmeli.');
        }
      } else {
        debugPrint(
            'DiscoverScreen: Profil çekme koşulu karşılanmadı. Mevcut _userProfiles.length: ${_userProfiles.length}, _isLoading: $_isLoading, _noMoreProfilesToFetch: $_noMoreProfilesToFetch');
      }
    });
  }

  void _showAdPlaceholder() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Reklam Alanı",
            style: TextStyle(color: AppColors.primaryText),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                "https://placehold.co/300x250/FFC300/000000?text=AD",
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.image_not_supported, color: AppColors.red),
              ),
              const SizedBox(height: 10),
              Text(
                "Burada reklamınız gösterilecektir.",
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Kapat",
                style: TextStyle(color: AppColors.accentPink),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
        'DiscoverScreen: Build metodu çalıştı. _userProfiles.length: ${_userProfiles.length}, _isLoading: $_isLoading, _noMoreProfilesToFetch: $_noMoreProfilesToFetch');

    final double appBarHeight = AppBar().preferredSize.height;
    final double bottomNavBarHeight = kBottomNavigationBarHeight;
    final double availableHeight = MediaQuery.of(context).size.height -
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
          // Yeni: Geri Al (Rewind) butonu
          if (_isPremiumUser &&
              _lastSwipedUserId !=
                  null) // Sadece premium ve geri alınacak işlem varsa göster
            IconButton(
              icon: Icon(Icons.undo,
                  color: AppColors.primaryText), // Geri al ikonu
              onPressed: _handleRewind,
              tooltip: 'Geri Al',
            ),
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
              description: _isPremiumUser
                  ? 'Görünüşe göre şu an gösterilecek yeni profil kalmadı. Daha fazla kişiyle tanışmak için filtrelerini ayarlayabilirsin.'
                  : 'Görünüşe göre şu an gösterilecek yeni profil kalmadı. Daha hızlı bağlantılar kurmak için Canlı Sohbet\'i denemek ister misin?',
              buttonText:
                  _isPremiumUser ? 'Filtreleri Ayarla' : 'Canlı Sohbet\'e Git',
              onButtonPressed: () {
                if (_isPremiumUser) {
                  _openFilterScreen();
                } else {
                  Provider.of<TabNavigationProvider>(innerContext,
                          listen: false)
                      .setIndex(5);
                }
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
                          horizontal: 16.0, vertical: 8.0),
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
