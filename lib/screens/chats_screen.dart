import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectify_app/screens/single_chat_screen.dart';
import 'package:connectify_app/widgets/empty_state_widget.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:connectify_app/providers/tab_navigation_provider.dart';
import 'package:connectify_app/services/snackbar_service.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  List<Map<String, dynamic>> _unMessagedMatches =
      []; // Mesajlaşmanın başlamadığı eşleşmeler
  List<Map<String, dynamic>> _messagedMatches =
      []; // Mesajlaşmanın başladığı eşleşmeler
  int _likesCount = 0;
  String? _profileImageUrlForLikedYouQueue;

  @override
  void initState() {
    super.initState();
    _fetchMatchesAndLikesCount();
  }

  // Eşleşmeleri ve beğeni sayısını Firestore'dan çeken fonksiyon
  Future<void> _fetchMatchesAndLikesCount() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('ChatsScreen: Kullanıcı giriş yapmamış. Veri çekilemedi.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Mevcut kullanıcının tüm eşleşmelerini çek
      QuerySnapshot matchesSnapshot1 = await _firestore
          .collection('matches')
          .where('user1Id', isEqualTo: currentUser.uid)
          .get();

      QuerySnapshot matchesSnapshot2 = await _firestore
          .collection('matches')
          .where('user2Id', isEqualTo: currentUser.uid)
          .get();

      List<DocumentSnapshot> allMatchesDocs = [];
      allMatchesDocs.addAll(matchesSnapshot1.docs);
      allMatchesDocs.addAll(matchesSnapshot2.docs);

      List<String> matchedUids = [];
      for (var doc in allMatchesDocs) {
        String user1Id = doc['user1Id'];
        String user2Id = doc['user2Id'];
        if (user1Id == currentUser.uid) {
          matchedUids.add(user2Id);
        } else {
          matchedUids.add(user1Id);
        }
      }
      matchedUids = matchedUids.toSet().toList(); // Benzersiz eşleşen UID'ler
      debugPrint(
        'ChatsScreen: Toplam benzersiz eşleşen UID sayısı: ${matchedUids.length}',
      );

      List<Map<String, dynamic>> tempUnMessagedMatches = [];
      List<Map<String, dynamic>> tempMessagedMatches = [];

      for (String matchedUid in matchedUids) {
        DocumentSnapshot matchedUserProfile = await _firestore
            .collection('users')
            .doc(matchedUid)
            .get();

        if (matchedUserProfile.exists) {
          Map<String, dynamic> userData =
              matchedUserProfile.data() as Map<String, dynamic>;
          userData['uid'] =
              matchedUserProfile.id; // UID'yi userData'ya ekleyelim

          // **ÖNEMLİ DÜZELTME:** Sohbet belgesinin varlığını kontrol et
          String currentChatId = _getChatId(currentUser.uid, matchedUid);
          DocumentSnapshot chatDoc = await _firestore
              .collection('chats')
              .doc(currentChatId)
              .get();

          if (chatDoc.exists) {
            // Sohbet belgesi varsa, mesajları kontrol et
            QuerySnapshot chatMessages = await _firestore
                .collection('chats')
                .doc(currentChatId)
                .collection('messages')
                .limit(1)
                .get();

            if (chatMessages.docs.isNotEmpty) {
              debugPrint(
                'ChatsScreen: ${userData['name']} (${userData['uid']}) ile mesajlaşma başlamış.',
              );
              tempMessagedMatches.add(userData);
            } else {
              debugPrint(
                'ChatsScreen: ${userData['name']} (${userData['uid']}) ile mesajlaşma başlamış ancak mesaj yok.',
              );
              tempUnMessagedMatches.add(
                userData,
              ); // Varsa ama mesaj yoksa da unmessaged kabul edilebilir
            }
          } else {
            // Sohbet belgesi yoksa (hiç mesaj gönderilmemiş demektir)
            debugPrint(
              'ChatsScreen: ${userData['name']} (${userData['uid']}) ile sohbet belgesi yok, mesajlaşma başlamamış.',
            );
            tempUnMessagedMatches.add(userData);
          }
        } else {
          debugPrint(
            'ChatsScreen: Eşleşen kullanıcı profili bulunamadı: $matchedUid',
          );
        }
      }
      debugPrint(
        'ChatsScreen: Mesajlaşmamış eşleşme sayısı: ${tempUnMessagedMatches.length}',
      );
      debugPrint(
        'ChatsScreen: Mesajlaşmış eşleşme sayısı: ${tempMessagedMatches.length}',
      );

      // Sizi beğenenlerin sayısını ve ilk beğenenin profil resmini çekme
      QuerySnapshot likedYouSnapshot = await _firestore
          .collection('likes')
          .where('likedId', isEqualTo: currentUser.uid)
          .get();

      List<String> likerUids = likedYouSnapshot.docs
          .map((doc) => doc['likerId'] as String)
          .toSet()
          .toList();
      debugPrint('ChatsScreen: Toplam beğenen UID sayısı: ${likerUids.length}');

      // Halihazırda eşleşme başlamış veya başlamamış eşleşmelerdeki kişileri beğenenler listesinden çıkar
      List<String> allMatchedUids =
          tempUnMessagedMatches.map((e) => e['uid'] as String).toList()..addAll(
            tempMessagedMatches.map((e) => e['uid'] as String).toList(),
          );
      likerUids.removeWhere((uid) => allMatchedUids.contains(uid));

      _likesCount = likerUids.length;
      debugPrint(
        'ChatsScreen: Eşleşmelerden sonra kalan beğeni sayısı: $_likesCount',
      );

      if (likerUids.isNotEmpty) {
        DocumentSnapshot firstLikerProfile = await _firestore
            .collection('users')
            .doc(likerUids.first)
            .get();
        if (firstLikerProfile.exists) {
          _profileImageUrlForLikedYouQueue =
              (firstLikerProfile.data()
                  as Map<String, dynamic>)['profileImageUrl'];
          debugPrint('ChatsScreen: İlk beğenenin profil resmi çekildi.');
        } else {
          _profileImageUrlForLikedYouQueue = null;
        }
      } else {
        _profileImageUrlForLikedYouQueue = null;
      }

      setState(() {
        _unMessagedMatches = tempUnMessagedMatches;
        _messagedMatches = tempMessagedMatches;
      });
    } catch (e) {
      debugPrint("ChatsScreen: Veri çekilirken HATA oluştu: $e");
      SnackBarService.showSnackBar(
        context,
        message:
            'Sohbetleri ve beğenileri yüklerken hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      debugPrint(
        'ChatsScreen: _fetchMatchesAndLikesCount tamamlandı. isLoading: $_isLoading',
      );
    }
  }

  // Sohbet odası ID'sini oluşturan yardımcı fonksiyon
  String _getChatId(String user1Id, String user2Id) {
    // UID'leri alfabetik sıraya göre birleştirerek tutarlı bir sohbet ID'si oluşturur
    if (user1Id.compareTo(user2Id) < 0) {
      return '${user1Id}_$user2Id';
    } else {
      return '${user2Id}_$user1Id';
    }
  }

  void _onChatTapped(Map<String, dynamic> matchedUser) {
    debugPrint('ChatsScreen: Sohbet başlatılıyor: ${matchedUser['name']}');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SingleChatScreen(matchedUser: matchedUser),
      ),
    );
  }

  // "Seni Beğenenler" ekranına yönlendirme
  void _navigateToLikedYouScreen() {
    Provider.of<TabNavigationProvider>(
      context,
      listen: false,
    ).setIndex(3); // "Beğenenler" sekmesi index 3
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohbetler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              debugPrint('ChatsScreen: Sohbet Ara tıklandı');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _unMessagedMatches.isEmpty &&
                _messagedMatches.isEmpty &&
                _likesCount == 0
          ? EmptyStateWidget(
              icon: Icons.chat_bubble_outline,
              title: 'Henüz Hiç Eşleşmen Yok',
              description:
                  'Sohbet etmek için yeni eşleşmeler bulman gerekiyor! Keşfet ekranına giderek yeni kişilerle tanışmaya ne dersin?',
              buttonText: 'Keşfetmeye Başla',
              onButtonPressed: () {
                Provider.of<TabNavigationProvider>(
                  context,
                  listen: false,
                ).setIndex(1); // Keşfet sekmesi index 1
              },
            )
          : Column(
              children: [
                // Beğeni Sayısı ve Mesajlaşılmamış Eşleşmeler Listesi (Yukarıdaki Kısım)
                // Sadece varsa göster
                if (_likesCount > 0 || _unMessagedMatches.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            _unMessagedMatches.length +
                            (_likesCount > 0 ? 1 : 0),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemBuilder: (context, index) {
                          // İlk eleman "Beğeniler" kutusunu temsil etsin
                          if (index == 0 && _likesCount > 0) {
                            return GestureDetector(
                              onTap: _navigateToLikedYouScreen,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Column(
                                  children: [
                                    Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundImage:
                                              _profileImageUrlForLikedYouQueue !=
                                                  null
                                              ? NetworkImage(
                                                  _profileImageUrlForLikedYouQueue!,
                                                )
                                              : null,
                                          backgroundColor: AppColors.grey
                                              .withOpacity(0.2),
                                          child:
                                              _profileImageUrlForLikedYouQueue ==
                                                  null
                                              ? Icon(
                                                  Icons.person_outline,
                                                  size: 30,
                                                  color: AppColors.primaryText,
                                                )
                                              : null,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentPink,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: AppColors.white,
                                                width: 2,
                                              ),
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 20,
                                              minHeight: 20,
                                            ),
                                            child: Text(
                                              _likesCount > 99
                                                  ? '99+'
                                                  : _likesCount.toString(),
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Beğeniler',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primaryText,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            // Mesajlaşılmamış Eşleşmelerin Yuvarlak Avatarları
                            final unMessagedUser =
                                _unMessagedMatches[index -
                                    (_likesCount > 0 ? 1 : 0)];
                            final String name =
                                unMessagedUser['name'] ?? 'Bilinmiyor';
                            final String profileImageUrl =
                                unMessagedUser['profileImageUrl'] ??
                                'https://placehold.co/150x150/CCCCCC/000000?text=Profil';
                            return GestureDetector(
                              onTap: () => _onChatTapped(unMessagedUser),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.primaryYellow,
                                          width: 2.0,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 30,
                                        backgroundImage: NetworkImage(
                                          profileImageUrl,
                                        ),
                                        backgroundColor: AppColors.grey
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      name.split(' ')[0],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primaryText,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                // Sadece hem mesajlaşılmamış eşleşme/beğeni hem de mesajlaşılmış eşleşme varsa ayırıcı çizgi
                if ((_unMessagedMatches.isNotEmpty || _likesCount > 0) &&
                    _messagedMatches.isNotEmpty)
                  const Divider(height: 1, thickness: 1, color: AppColors.grey),
                const SizedBox(height: 8),

                // Mesajlaşılmış Eşleşmeler Başlığı (varsa)
                if (_messagedMatches.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sohbetler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                  ),

                // Mevcut Sohbet Listesi (Mesajlaşılmış Eşleşmeler)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _messagedMatches.length,
                    itemBuilder: (context, index) {
                      final messagedUser = _messagedMatches[index];
                      final String name = messagedUser['name'] ?? 'Bilinmiyor';
                      final String profileImageUrl =
                          messagedUser['profileImageUrl'] ??
                          'https://placehold.co/150x150/CCCCCC/000000?text=Profil';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(profileImageUrl),
                            backgroundColor: AppColors.grey.withOpacity(0.2),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'Son mesaj buraya gelecek...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.secondaryText),
                          ),
                          trailing: Text(
                            'Şimdi',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          onTap: () => _onChatTapped(messagedUser),
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
