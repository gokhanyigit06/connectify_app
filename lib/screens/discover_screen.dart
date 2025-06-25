import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectify_app/widgets/profile_card_widget.dart'; // ProfileCardWidget'ı import et
import 'package:connectify_app/screens/profile/user_profile_screen.dart'; // AppBar'daki profil ikonu için

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<DocumentSnapshot> _userProfiles = []; // Çekilen kullanıcı profilleri
  bool _isLoading = false; // Yüklenme durumu için

  @override
  void initState() {
    super.initState();
    _fetchUserProfiles();
  }

  // Kullanıcı profillerini Firestore'dan çeken fonksiyon
  Future<void> _fetchUserProfiles() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('DiscoverScreen: Kullanıcı giriş yapmamış. Profil çekilmedi.');
      return;
    }

    setState(() {
      _isLoading = true;
    }); // Yükleme başladı

    try {
      // Kendi profilimiz hariç ilk 10 profili çekelim
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where(
            'uid',
            isNotEqualTo: currentUser.uid,
          ) // Kendi profilimizi gösterme
          .limit(10) // İlk 10 profili çekelim şimdilik
          .get();

      setState(() {
        _userProfiles = querySnapshot
            .docs; // Listeyi yeni çekilen profillerle tamamen değiştir
      });

      if (_userProfiles.isEmpty) {
        debugPrint('DiscoverScreen: Keşfedilecek yeni profil bulunamadı.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keşfedilecek yeni profil bulunamadı.')),
        );
      }
    } catch (e) {
      debugPrint(
        "DiscoverScreen: Kullanıcı profilleri çekilirken hata oluştu: $e",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcılar yüklenirken hata oluştu: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      }); // Yükleme bitti
    }
  }

  // Beğenme (Like) işlemi
  void _handleLike(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    debugPrint('DiscoverScreen: Beğenildi: $targetUserId');

    try {
      // 1. Beğeni bilgisini Firestore'daki 'likes' koleksiyonuna kaydet
      await _firestore.collection('likes').add({
        'likerId': currentUser.uid, // Beğenen kişi
        'likedId': targetUserId, // Beğenilen kişi
        'timestamp': FieldValue.serverTimestamp(), // Beğenme zamanı
      });
      debugPrint('DiscoverScreen: Beğeni Firestore\'a kaydedildi.');

      // 2. Karşılıklı beğeni kontrolü (Eşleşme için)
      QuerySnapshot reciprocalLike = await _firestore
          .collection('likes')
          .where(
            'likerId',
            isEqualTo: targetUserId,
          ) // Beğenen kişi targetUserId
          .where(
            'likedId',
            isEqualTo: currentUser.uid,
          ) // Beğenilen kişi currentUser
          .get();

      if (reciprocalLike.docs.isNotEmpty) {
        // Karşılıklı beğeni var, eşleşme oluştu!
        debugPrint(
          'DiscoverScreen: Eşleşme oluştu: ${currentUser.uid} ve $targetUserId',
        );

        // Eşleşmeyi 'matches' koleksiyonuna kaydet
        // user1Id ve user2Id her zaman alfabetik sıraya göre kaydedilir
        String user1Id = currentUser.uid.compareTo(targetUserId) < 0
            ? currentUser.uid
            : targetUserId;
        String user2Id = currentUser.uid.compareTo(targetUserId) < 0
            ? targetUserId
            : currentUser.uid;

        // Aynı eşleşmenin zaten var olup olmadığını kontrol et (duplicate eşleşme olmaması için)
        QuerySnapshot existingMatch = await _firestore
            .collection('matches')
            .where('user1Id', isEqualTo: user1Id)
            .where('user2Id', isEqualTo: user2Id)
            .get();

        if (existingMatch.docs.isEmpty) {
          // Eğer daha önce böyle bir eşleşme kaydedilmediyse
          await _firestore.collection('matches').add({
            'user1Id': user1Id,
            'user2Id': user2Id,
            'createdAt': FieldValue.serverTimestamp(),
          });
          debugPrint('DiscoverScreen: Eşleşme Firestore\'a kaydedildi.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yeni bir eşleşmen var!')),
          );
        } else {
          debugPrint('DiscoverScreen: Eşleşme zaten mevcut.');
        }
      }
    } catch (e) {
      debugPrint(
        'DiscoverScreen: Beğeni/Eşleşme kaydedilirken hata oluştu: $e',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Beğeni veya eşleşme kaydedilemedi: $e')),
      );
    }

    _showNextProfile(); // Bir sonraki profili göster
  }

  // Geçme (Pass) işlemi
  void _handlePass(String targetUserId) {
    debugPrint('DiscoverScreen: Geçildi: $targetUserId');
    _showNextProfile(); // Bir sonraki profili göster
  }

  // Bir sonraki profili gösterme (Listeden çıkararak)
  void _showNextProfile() {
    setState(() {
      if (_userProfiles.isNotEmpty) {
        _userProfiles.removeAt(
          0,
        ); // Listenin ilk elemanını kaldır (yani gösterilen kartı)
      }

      if (_userProfiles.isEmpty) {
        // Tüm profiller bittiyse yeni profiller çek
        debugPrint(
          'DiscoverScreen: Tüm profiller bitti, yeni profiller çekiliyor...',
        );
        _fetchUserProfiles();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {
              debugPrint('DiscoverScreen: Filtre İkonu tıklandı');
              // Filtre ekranına yönlendirme gelecek
            },
          ),
        ],
      ),
      body: _userProfiles.isEmpty && _isLoading == false
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Keşfedilecek yeni profil bulunamadı.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _fetchUserProfiles,
                    child: const Text('Profilleri Yenile'),
                  ),
                ],
              ),
            )
          : _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              // Sadece tek bir kartı göster, o da listenin ilk elemanı
              children: [
                if (_userProfiles.isNotEmpty) // Liste boş değilse kartı göster
                  ProfileCardWidget(
                    userData: _userProfiles[0].data() as Map<String, dynamic>,
                    onLike: () =>
                        _handleLike(_userProfiles[0].id), // .id ile UID al
                    onPass: () => _handlePass(_userProfiles[0].id),
                  ),
              ],
            ),
    );
  }
}
