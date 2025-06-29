// lib/src/features/discover/presentation/screens/discover_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:connectify_app/widgets/profile_card_widget.dart';
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:connectify_app/screens/profile_detail/profile_detail_screen.dart';
import 'package:connectify_app/providers/tab_navigation_provider.dart';
import 'package:connectify_app/screens/filter_screen.dart';
import 'package:connectify_app/screens/match_found_screen.dart';
import 'package:connectify_app/screens/profile/user_profile_screen.dart';
import 'package:connectify_app/widgets/empty_state_widget.dart';
import 'package:connectify_app/screens/premium/premium_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<DocumentSnapshot> _userProfiles = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final int _documentLimit = 10;
  final ScrollController _scrollController = ScrollController();

  Set<String> _seenUserIds = {};

  FilterCriteria _currentFilters = FilterCriteria();

  bool _isPremiumUser = false;
  int _likesRemainingToday = 0;
  int _superLikesAvailable = 0;
  int _complimentsAvailable = 0;

  final int _initialSuperLikeGrantAmount = 3;
  final int _premiumWeeklySuperLikeAmount = 5;
  final int _initialComplimentGrantAmount = 3;
  final int _premiumWeeklyComplimentAmount = 5;

  bool _initialSuperLikesGranted = false;
  bool _initialComplimentsGranted = false;
  Timestamp? _lastPremiumSuperLikeResetDate;
  Timestamp? _lastPremiumComplimentResetDate;

  final int _defaultFreeLikeLimitDaily = 24;

  String? _lastSwipedUserId;
  String? _lastSwipedAction;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _checkUserStatusAndLimits();
    await _loadSeenUserIds();
    _fetchUserProfiles(isInitialLoad: true);
  }

  Future<void> _checkUserStatusAndLimits() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _isPremiumUser = userData['isPremium'] ?? false;
          _likesRemainingToday =
              userData['likesRemainingToday'] ?? _defaultFreeLikeLimitDaily;
          _superLikesAvailable = userData['superLikesAvailable'] ?? 0;
          _complimentsAvailable = userData['complimentsAvailable'] ?? 0;
          _initialSuperLikesGranted =
              userData['initialSuperLikesGranted'] ?? false;
          _initialComplimentsGranted =
              userData['initialComplimentsGranted'] ?? false;
          _lastPremiumSuperLikeResetDate =
              userData['lastPremiumSuperLikeResetDate'];
          _lastPremiumComplimentResetDate =
              userData['lastPremiumComplimentResetDate'];
        });
        debugPrint(
            'DiscoverScreen: Kullanıcı durumu: Premium: $_isPremiumUser, Kalan Beğeni: $_likesRemainingToday, Kalan Süper Beğeni: $_superLikesAvailable, Kalan Compliment: $_complimentsAvailable');

        if (!_isPremiumUser && !_initialSuperLikesGranted) {
          debugPrint(
              'DiscoverScreen: Yeni kullanıcıya başlangıç Süper Beğenileri veriliyor (3 adet).');
          setState(() {
            _superLikesAvailable = _initialSuperLikeGrantAmount;
            _initialSuperLikesGranted = true;
          });
          await _firestore.collection('users').doc(currentUser.uid).set({
            'superLikesAvailable': _initialSuperLikeGrantAmount,
            'initialSuperLikesGranted': true,
          }, SetOptions(merge: true));
        }

        if (!_isPremiumUser && !_initialComplimentsGranted) {
          debugPrint(
              'DiscoverScreen: Yeni kullanıcıya başlangıç Complimentleri veriliyor (3 adet).');
          setState(() {
            _complimentsAvailable = _initialComplimentGrantAmount;
            _initialComplimentsGranted = true;
          });
          await _firestore.collection('users').doc(currentUser.uid).set({
            'complimentsAvailable': _initialComplimentGrantAmount,
            'initialComplimentsGranted': true,
          }, SetOptions(merge: true));
        }

        if (_isPremiumUser && _lastPremiumSuperLikeResetDate != null) {
          DateTime lastResetDateTime = _lastPremiumSuperLikeResetDate!.toDate();
          DateTime now = DateTime.now().toUtc().add(const Duration(hours: 3));

          if (now.difference(lastResetDateTime).inDays >= 7) {
            debugPrint(
                'DiscoverScreen: Premium kullanıcıya haftalık Süper Beğeni sıfırlaması yapılıyor.');
            setState(() {
              _superLikesAvailable = _premiumWeeklySuperLikeAmount;
              _lastPremiumSuperLikeResetDate = Timestamp.fromDate(now);
            });
            await _firestore.collection('users').doc(currentUser.uid).set({
              'superLikesAvailable': _premiumWeeklySuperLikeAmount,
              'lastPremiumSuperLikeResetDate': Timestamp.fromDate(now),
            }, SetOptions(merge: true));
          }
        } else if (_isPremiumUser && _lastPremiumSuperLikeResetDate == null) {
          debugPrint(
              'DiscoverScreen: Premium kullanıcıya ilk haftalık Süper Beğeni ataması yapılıyor.');
          setState(() {
            _superLikesAvailable = _premiumWeeklySuperLikeAmount;
            _lastPremiumSuperLikeResetDate = Timestamp.fromDate(
                DateTime.now().toUtc().add(const Duration(hours: 3)));
          });
          await _firestore.collection('users').doc(currentUser.uid).set({
            'superLikesAvailable': _premiumWeeklySuperLikeAmount,
            'lastPremiumSuperLikeResetDate': Timestamp.fromDate(
                DateTime.now().toUtc().add(const Duration(hours: 3))),
          }, SetOptions(merge: true));
        }

        if (_isPremiumUser && _lastPremiumComplimentResetDate != null) {
          DateTime lastResetDateTime =
              _lastPremiumComplimentResetDate!.toDate();
          DateTime now = DateTime.now().toUtc().add(const Duration(hours: 3));
          if (now.difference(lastResetDateTime).inDays >= 7) {
            debugPrint(
                'DiscoverScreen: Premium kullanıcıya haftalık Compliment sıfırlaması yapılıyor.');
            setState(() {
              _complimentsAvailable = _premiumWeeklyComplimentAmount;
              _lastPremiumComplimentResetDate = Timestamp.fromDate(now);
            });
            await _firestore.collection('users').doc(currentUser.uid).set({
              'complimentsAvailable': _premiumWeeklyComplimentAmount,
              'lastPremiumComplimentResetDate': Timestamp.fromDate(now),
            }, SetOptions(merge: true));
          }
        } else if (_isPremiumUser && _lastPremiumComplimentResetDate == null) {
          debugPrint(
              'DiscoverScreen: Premium kullanıcıya ilk haftalık Compliment ataması yapılıyor.');
          setState(() {
            _complimentsAvailable = _premiumWeeklyComplimentAmount;
            _lastPremiumComplimentResetDate = Timestamp.fromDate(
                DateTime.now().toUtc().add(const Duration(hours: 3)));
          });
          await _firestore.collection('users').doc(currentUser.uid).set({
            'complimentsAvailable': _premiumWeeklyComplimentAmount,
            'lastPremiumComplimentResetDate': Timestamp.fromDate(
                DateTime.now().toUtc().add(const Duration(hours: 3))),
          }, SetOptions(merge: true));
        }
      } else {
        debugPrint(
            'DiscoverScreen: Mevcut kullanıcı dokümanı bulunamadı. Limitler varsayılana ayarlandı.');
        setState(() {
          _isPremiumUser = false;
          _likesRemainingToday = _defaultFreeLikeLimitDaily;
          _superLikesAvailable = 0;
          _complimentsAvailable = 0;
          _initialSuperLikesGranted = false;
          _initialComplimentsGranted = false;
        });
      }
    } catch (e) {
      debugPrint(
          'DiscoverScreen: Kullanıcı durumu veya limitler çekilirken hata: $e');
      SnackBarService.showSnackBar(
        context,
        message:
            'Kullanıcı durumu veya limitler yüklenirken hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _loadSeenUserIds() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('[SeenUsers] Mevcut kullanıcı null. SeenUserIds yüklenmedi.');
      return;
    }
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        List<dynamic>? seenIds = userDoc.get('seenUserIds');
        if (seenIds != null) {
          setState(() {
            _seenUserIds = Set<String>.from(
                seenIds.where((id) => id != null && id.toString().isNotEmpty));
          });
          debugPrint('[SeenUsers] Yüklendi: Seen User IDs: $_seenUserIds');
        } else {
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .set({'seenUserIds': []}, SetOptions(merge: true));
          debugPrint(
              '[SeenUsers] Firestore\'da seenUserIds alanı oluşturuldu.');
        }
      } else {
        debugPrint('Kullanıcı dokümanı bulunamadı (yeni kullanıcı olabilir).');
      }
    } catch (e) {
      debugPrint('[SeenUsers] Seen User ID\'leri yüklenirken hata: $e');
    }
  }

  Future<void> _updateSeenUserIdsInFirestore(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    if (_seenUserIds.contains(userId)) {
      debugPrint(
          '[SeenUsers] $userId zaten görülenler listesinde. Firestore güncellenmedi.');
      return;
    }

    setState(() {
      _seenUserIds.add(userId);
    });

    try {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'seenUserIds': FieldValue.arrayUnion([userId]),
      });
      debugPrint(
          '[SeenUsers] Firestore güncellendi: $userId, Current Seen IDs: $_seenUserIds');
    } catch (e) {
      debugPrint(
          '[SeenUsers] Seen User ID\'leri Firestore\'a kaydedilirken hata: $e');
      SnackBarService.showSnackBar(context,
          message: 'Görülen profiller kaydedilemedi.',
          type: SnackBarType.error);
    }
  }

  Future<void> _fetchUserProfiles(
      {bool isInitialLoad = false, bool isRefresh = false}) async {
    debugPrint(
        '[FetchProfiles] Starting fetch. _hasMore: $_hasMore, _isLoading: $_isLoading, isInitialLoad: $isInitialLoad, isRefresh: $isRefresh');

    if (isRefresh) {
      _userProfiles.clear();
      _lastDocument = null;
      _hasMore = true;
      debugPrint('[FetchProfiles] Refresh initiated. User profiles cleared.');
    }

    if (_isLoading && !isRefresh) {
      debugPrint(
          '[FetchProfiles] Skipping fetch: already loading and not a refresh.');
      return;
    }
    if (!_hasMore && _userProfiles.isNotEmpty && !isRefresh) {
      debugPrint(
          '[FetchProfiles] Skipping fetch: No more profiles and not a refresh (and profiles exist).');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });
    debugPrint('[FetchProfiles] isLoading set to true.');

    try {
      Query query = _firestore.collection('users');

      final currentUserUid = _auth.currentUser?.uid;
      if (currentUserUid == null) {
        debugPrint(
            '[FetchProfiles] Current user UID is null, cannot fetch profiles.');
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
        SnackBarService.showSnackBar(context,
            message: 'Giriş yapılmış kullanıcı bulunamadı.',
            type: SnackBarType.error);
        return;
      }

      List<String> excludeUids = List.from(_seenUserIds);
      excludeUids.add(currentUserUid);

      excludeUids.removeWhere((id) => id.isEmpty);

      debugPrint(
          '[FetchProfiles] Exclude Uids (current user + seen) after filtering: $excludeUids');

      query = query.orderBy(FieldPath.documentId);

      if (excludeUids.isNotEmpty) {
        if (excludeUids.length > 10) {
          debugPrint(
              '[FetchProfiles] WARNING: excludeUids length (${excludeUids.length}) > 10. whereNotIn will be problematic.');
        } else {
          query = query.where(FieldPath.documentId, whereNotIn: excludeUids);
        }
      }

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

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
        debugPrint(
            '[FetchProfiles] Starting query after document: ${_lastDocument!.id}');
      } else {
        debugPrint('[FetchProfiles] Fetching initial documents.');
      }

      QuerySnapshot querySnapshot = await query.limit(_documentLimit).get();
      debugPrint(
          '[FetchProfiles] Firestore query completed. Docs fetched: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        debugPrint(
            '[FetchProfiles] No more docs from Firestore. _hasMore set to false, _isLoading set to false.');
        SnackBarService.showSnackBar(context,
            message: 'Gösterilecek başka kullanıcı yok.',
            type: SnackBarType.info);
        return;
      }

      setState(() {
        _userProfiles.addAll(querySnapshot.docs);
        _lastDocument = querySnapshot.docs.last;
        _isLoading = false;
        if (querySnapshot.docs.length < _documentLimit) {
          _hasMore = false;
        }
      });
      debugPrint(
          '[FetchProfiles] State updated. Total profiles: ${_userProfiles.length}. Has more: $_hasMore, isLoading: $_isLoading');
    } catch (e) {
      debugPrint('[FetchProfiles] ERROR fetching profiles: $e');
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
      SnackBarService.showSnackBar(context,
          message: 'Profiller yüklenirken bir hata oluştu: ${e.toString()}',
          type: SnackBarType.error);
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoading &&
        _hasMore) {
      debugPrint('[Scroll] Scroll end reached. Fetching more profiles.');
      _fetchUserProfiles();
    }
  }

  void _handleLike(String userId) async {
    debugPrint('[Interaction] Beğenildi: $userId');
    if (!_isPremiumUser && _likesRemainingToday <= 0) {
      SnackBarService.showSnackBar(
        context,
        message: 'Bugünlük beğeni limitini doldurdun!',
        type: SnackBarType.info,
        actionLabel: 'Premium Ol',
        onActionPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PremiumScreen(
                        message: 'Sınırsız beğeni için Premium olun!',
                      )));
        },
      );
      return;
    }
    _updateSeenUserIdsInFirestore(userId);
    await _createMatchOrLike(userId, 'like');
    if (!_isPremiumUser) {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'likesRemainingToday': FieldValue.increment(-1),
      });
      setState(() {
        _likesRemainingToday--;
      });
    }
    _removeTopProfile();
  }

  void _handlePass(String userId) async {
    debugPrint('[Interaction] Pas geçildi: $userId');
    if (!_isPremiumUser && _likesRemainingToday <= 0) {
      SnackBarService.showSnackBar(
        context,
        message: 'Bugünlük kaydırma limitini doldurdun!',
        type: SnackBarType.info,
        actionLabel: 'Premium Ol',
        onActionPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PremiumScreen(
                        message: 'Sınırsız kaydırma için Premium olun!',
                      )));
        },
      );
      return;
    }
    _updateSeenUserIdsInFirestore(userId);
    if (!_isPremiumUser) {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'likesRemainingToday': FieldValue.increment(-1),
      });
      setState(() {
        _likesRemainingToday--;
      });
    }
    _removeTopProfile();
    setState(() {
      _lastSwipedUserId = userId;
      _lastSwipedAction = 'pass';
    });
  }

  void _handleSuperLike(String userId) async {
    debugPrint('[Interaction] Süper Beğenildi: $userId');

    if (_superLikesAvailable <= 0) {
      SnackBarService.showSnackBar(
        context,
        message: 'Süper Beğeni hakların bitti!',
        type: SnackBarType.info,
        actionLabel: 'Satın Al / Premium Ol',
        onActionPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PremiumScreen(
                        message: 'Süper Beğeni paketleri burada olacak!',
                      )));
        },
      );
      return;
    }

    _updateSeenUserIdsInFirestore(userId);
    await _createMatchOrLike(userId, 'super_like');

    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      'superLikesAvailable': FieldValue.increment(-1),
    });
    setState(() {
      _superLikesAvailable--;
    });

    _removeTopProfile();
  }

  void _handleCompliment(String userId, String? comment) async {
    debugPrint('[Interaction] Compliment gönderildi: $userId, yorum: $comment');

    if (_complimentsAvailable <= 0) {
      SnackBarService.showSnackBar(
        context,
        message: 'Compliment hakların bitti!',
        type: SnackBarType.info,
        actionLabel: 'Satın Al / Premium Ol',
        onActionPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PremiumScreen(
                        message:
                            'Daha fazla Compliment için bu paketi satın alın veya Premium olun!',
                      )));
        },
      );
      return;
    }

    if (comment == null || comment.trim().isEmpty) {
      SnackBarService.showSnackBar(
        context,
        message: 'Compliment göndermek için bir yorum yazmalısın.',
        type: SnackBarType.info,
      );
      return;
    }

    _updateSeenUserIdsInFirestore(userId);

    try {
      await _firestore.collection('compliments').add({
        'senderId': _auth.currentUser!.uid,
        'receiverId': userId,
        'comment': comment.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
      debugPrint('[Firestore] Compliment Firestore\'a kaydedildi.');

      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'complimentsAvailable': FieldValue.increment(-1),
      });
      setState(() {
        _complimentsAvailable--;
      });

      SnackBarService.showSnackBar(context,
          message: 'Compliment gönderildi!', type: SnackBarType.success);
    } catch (e) {
      debugPrint('[Interaction] Compliment gönderilirken hata: $e');
      SnackBarService.showSnackBar(
        context,
        message: 'Compliment gönderilemedi: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
    _removeTopProfile();
  }

  void _removeTopProfile() {
    setState(() {
      if (_userProfiles.isNotEmpty) {
        _userProfiles.removeAt(0);
        debugPrint(
            '[ProfileDisplay] Bir profil kaldırıldı. Kalan: ${_userProfiles.length}');
      } else {
        debugPrint('[ProfileDisplay] Profil listesi zaten boş.');
      }
    });
    if (_userProfiles.length < _documentLimit / 2 && _hasMore && !_isLoading) {
      debugPrint(
          '[ProfileDisplay] Yeterince profil kalmadı, yeni çekim başlatılıyor.');
      _fetchUserProfiles();
    }
  }

  void _handleRewind() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null ||
        !_isPremiumUser ||
        _lastSwipedUserId == null ||
        _lastSwipedAction != 'pass') {
      SnackBarService.showSnackBar(
        context,
        message: 'Geri Al özelliği Premium üyelerine özeldir!',
        type: SnackBarType.info,
        actionLabel: 'Premium Ol',
        onActionPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PremiumScreen(
                        message:
                            'Geri Al özelliğini kullanmak için Premium olun!',
                      )));
        },
      );
      return;
    }

    debugPrint(
        '[Interaction] Geri Al işlemi başlatıldı. Son Kaydırılan UID: $_lastSwipedUserId, Eylem: $_lastSwipedAction');

    try {
      DocumentSnapshot lastSwipedUserDoc =
          await _firestore.collection('users').doc(_lastSwipedUserId!).get();
      if (lastSwipedUserDoc.exists) {
        setState(() {
          _userProfiles.insert(0, lastSwipedUserDoc);
          _seenUserIds.remove(_lastSwipedUserId);
          debugPrint(
              '[ProfileDisplay] $_lastSwipedUserId tekrar listeye eklendi.');
        });
      }

      if (!_isPremiumUser) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'likesRemainingToday': FieldValue.increment(1),
        });
        setState(() {
          _likesRemainingToday++;
        });
        debugPrint(
            '[Limits] Kalan kaydırma hakkı geri alındı: $_likesRemainingToday');
      }

      SnackBarService.showSnackBar(context,
          message: 'Geçilen profil geri alındı!', type: SnackBarType.success);
    } catch (e) {
      debugPrint('[Interaction] Geri Al işlemi sırasında hata: $e');
      SnackBarService.showSnackBar(context,
          message: 'Geri Al işlemi başarısız oldu: ${e.toString()}',
          type: SnackBarType.error);
    } finally {
      setState(() {
        _lastSwipedUserId = null;
        _lastSwipedAction = null;
      });
    }
  }

  Future<void> _createMatchOrLike(String targetUserId, String type) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final QuerySnapshot existingLike = await _firestore
          .collection('likes')
          .where('likerId', isEqualTo: targetUserId)
          .where('likedId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (existingLike.docs.isNotEmpty) {
        DocumentSnapshot matchedUserDoc =
            await _firestore.collection('users').doc(targetUserId).get();
        if (matchedUserDoc.exists) {
          final matchedUserProfileData =
              matchedUserDoc.data() as Map<String, dynamic>;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MatchFoundScreen(
                currentUserProfile: {}, // TODO: Kendi profil verinizi buraya ekleyin
                matchedUserProfile: matchedUserProfileData,
              ),
            ),
          );
        } else {
          SnackBarService.showSnackBar(context,
              message: 'Yeni bir eşleşmen var!', type: SnackBarType.success);
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
        await _firestore.collection('likes').add({
          'likerId': currentUser.uid,
          'likedId': targetUserId,
          'type': type,
          'timestamp': FieldValue.serverTimestamp(),
        });
        SnackBarService.showSnackBar(context,
            message: 'Beğeni kaydedildi!', type: SnackBarType.info);
      }
    } catch (e) {
      debugPrint('[Interaction] Beğenme/Eşleşme oluşturulurken hata: $e');
      SnackBarService.showSnackBar(context,
          message: 'İşlem sırasında bir hata oluştu.',
          type: SnackBarType.error);
    }
  }

  void _openFilterScreen() async {
    final newFilters = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FilterScreen(initialFilters: _currentFilters),
      ),
    );

    if (newFilters != null) {
      setState(() {
        _currentFilters = newFilters;
      });
      _fetchUserProfiles(isRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '[Build] DiscoverScreen build metodu çalıştı. _userProfiles.length: ${_userProfiles.length}, _isLoading: $_isLoading, _hasMore: $_hasMore');

    if (_isLoading && _userProfiles.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Keşfet')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfiles.isEmpty && !_isLoading && !_hasMore) {
      return Scaffold(
        appBar: AppBar(title: const Text('Keşfet')),
        body: EmptyStateWidget(
          icon: Icons.mood_bad_outlined,
          title: 'Keşfedilecek Kimse Yok',
          description:
              'Görünüşe göre şu an gösterilecek yeni profil kalmadı. Filtrelerini ayarlayabilir veya daha sonra tekrar kontrol edebilirsin.',
          buttonText: 'Filtreleri Ayarla',
          onButtonPressed: _openFilterScreen,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keşfet'),
        leading: IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () {
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
            onPressed: _openFilterScreen,
            tooltip: 'Filtrele',
          ),
          if (_isPremiumUser &&
              _lastSwipedUserId != null &&
              _lastSwipedAction == 'pass')
            IconButton(
              icon: Icon(Icons.undo, color: AppColors.primaryText),
              onPressed: _handleRewind,
              tooltip: 'Geri Al',
            ),
        ],
      ),
      body: Stack(
        children: _userProfiles.reversed.map((userDoc) {
          final userData = userDoc.data() as Map<String, dynamic>;

          userData['isVerified'] = true; // <<<--- GEÇİCİ ONAY TİKİ AYARI

          return Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                debugPrint('[Tap] User card tapped: ${userDoc.id}');
                final Map<String, dynamic> dataToSend = userData;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileDetailScreen(
                      userData: dataToSend,
                      onLike: _handleLike,
                      onPass: _handlePass,
                      onSuperLike: _handleSuperLike,
                      onCompliment: _handleCompliment,
                    ),
                  ),
                );
              },
              child: ProfileCardWidget(
                userData: userData,
                onLike: () => _handleLike(userDoc.id),
                onPass: () => _handlePass(userDoc.id),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
