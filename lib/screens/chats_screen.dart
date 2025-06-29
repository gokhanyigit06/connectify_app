// lib/src/screens/chat/chats_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:connectify_app/screens/single_chat_screen.dart'; // Tekil sohbet ekranı için doğru yol
import 'package:connectify_app/widgets/empty_state_widget.dart';
// import 'package:connectify_app/screens/match_found_screen.dart'; // Kullanılmadığı için kaldırıldı
import 'package:connectify_app/screens/liked_you_screen.dart'; // LikedYouScreen'e yönlendirme için
import 'package:connectify_app/providers/tab_navigation_provider.dart'; // Tab değişimi için (varsa)
import 'package:provider/provider.dart'; // Provider için

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({Key? key}) : super(key: key);

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot> _messagedMatches = [];
  List<DocumentSnapshot> _newMatches =
      []; // Yeni eşleşmeler (mesajlaşma başlamamış)
  List<DocumentSnapshot> _incomingCompliments =
      []; // Gelen Complimentler listesi
  int _likesCount = 0; // Bizi beğenen kişi sayısı
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMatchesAndLikesCount();
    _listenForIncomingCompliments();
  }

  // Eşleşmeleri ve beğenileri çeker
  Future<void> _fetchMatchesAndLikesCount() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Bizi beğenenlerin sayısını al (henüz eşleşmeyenler)
      QuerySnapshot likesSnapshot = await _firestore
          .collection('likes')
          .where('likedId', isEqualTo: currentUser.uid)
          .where('likerId', isNotEqualTo: currentUser.uid)
          .get();

      Set<String> matchedUids = {}; // Zaten eşleşmiş olan UID'leri tutar

      // Mevcut eşleşmeleri al (hem user1Id hem user2Id olarak)
      QuerySnapshot matchesAsUser1 = await _firestore
          .collection('matches')
          .where('user1Id', isEqualTo: currentUser.uid)
          .get();
      QuerySnapshot matchesAsUser2 = await _firestore
          .collection('matches')
          .where('user2Id', isEqualTo: currentUser.uid)
          .get();

      List<DocumentSnapshot> allMatches = [
        ...matchesAsUser1.docs,
        ...matchesAsUser2.docs
      ];

      for (var matchDoc in allMatches) {
        String otherUid = (matchDoc.get('user1Id') == currentUser.uid)
            ? matchDoc.get('user2Id')
            : matchDoc.get('user1Id');
        matchedUids.add(otherUid);
      }

      int currentLikesCount = 0;
      for (var likeDoc in likesSnapshot.docs) {
        String likerId = likeDoc.get('likerId');
        if (!matchedUids.contains(likerId)) {
          // Eğer beğenen kişiyle henüz eşleşme yoksa sayacı artır
          currentLikesCount++;
        }
      }

      // Yeni eşleşmeleri ve mesajlaşma başlayanları ayır
      List<DocumentSnapshot> messaged = [];
      List<DocumentSnapshot> newOnes = [];

      for (var matchDoc in allMatches) {
        final chatDocId =
            _getChatId(matchDoc.get('user1Id'), matchDoc.get('user2Id'));
        final messages = await _firestore
            .collection('chats')
            .doc(chatDocId)
            .collection('messages')
            .limit(1)
            .get();
        if (messages.docs.isNotEmpty) {
          messaged.add(matchDoc);
        } else {
          newOnes.add(matchDoc);
        }
      }

      setState(() {
        _likesCount = currentLikesCount;
        _newMatches = newOnes;
        _messagedMatches = messaged;
        _isLoading = false;
      });
      debugPrint(
          'ChatsScreen: _fetchMatchesAndLikesCount tamamlandı. isLoading: false');
      debugPrint(
          'ChatsScreen: Toplam benzersiz eşleşen UID sayısı: ${_newMatches.length + _messagedMatches.length}');
      debugPrint(
          'ChatsScreen: Mesajlaşmamış eşleşme sayısı: ${_newMatches.length}');
      debugPrint(
          'ChatsScreen: Mesajlaşmış eşleşme sayısı: ${_messagedMatches.length}');
      debugPrint('ChatsScreen: Toplam beğenen UID sayısı: $_likesCount');
    } catch (e) {
      debugPrint('ChatsScreen: Eşleşmeler ve beğeniler çekilirken hata: $e');
      SnackBarService.showSnackBar(context,
          message: 'Eşleşmeler yüklenirken hata oluştu: ${e.toString()}',
          type: SnackBarType.error);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _listenForIncomingCompliments() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _firestore
        .collection('compliments')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _incomingCompliments = snapshot.docs;
      });
      debugPrint(
          'ChatsScreen: Gelen Compliment sayısı: ${_incomingCompliments.length}');
    }, onError: (error) {
      debugPrint('ChatsScreen: Gelen Complimentler dinlenirken hata: $error');
      SnackBarService.showSnackBar(context,
          message: 'Complimentler yüklenirken hata oluştu.',
          type: SnackBarType.error);
    });
  }

  Future<void> _acceptCompliment(DocumentSnapshot complimentDoc) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final senderId = complimentDoc.get('senderId');
    final comment = complimentDoc.get('comment');
    final complimentId = complimentDoc.id;

    try {
      final batch = _firestore.batch();

      String user1Id =
          currentUser.uid.compareTo(senderId) < 0 ? currentUser.uid : senderId;
      String user2Id =
          currentUser.uid.compareTo(senderId) < 0 ? senderId : currentUser.uid;

      final chatDocRef =
          _firestore.collection('chats').doc(_getChatId(user1Id, user2Id));

      batch.set(
          _firestore.collection('matches').doc(_getChatId(user1Id, user2Id)),
          {
            'user1Id': user1Id,
            'user2Id': user2Id,
            'createdAt': FieldValue.serverTimestamp(),
            'participants': [user1Id, user2Id],
          },
          SetOptions(merge: true));

      batch.set(
          chatDocRef,
          {
            'participants': [user1Id, user2Id],
            'lastMessage': comment,
            'lastMessageTime': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      batch.set(chatDocRef.collection('messages').doc(), {
        'senderId': senderId,
        'receiverId': currentUser.uid,
        'text': comment,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'compliment',
      });

      batch.update(_firestore.collection('compliments').doc(complimentId), {
        'read': true,
        'accepted': true,
        'acceptedAt': FieldValue.serverTimestamp(),
        'chatId': _getChatId(user1Id, user2Id),
      });

      batch.update(_firestore.collection('users').doc(currentUser.uid), {
        'matches': FieldValue.arrayUnion([senderId]),
      });
      batch.update(_firestore.collection('users').doc(senderId), {
        'matches': FieldValue.arrayUnion([currentUser.uid]),
      });

      await batch.commit();
      SnackBarService.showSnackBar(context,
          message: 'Compliment kabul edildi ve sohbet başlatıldı!',
          type: SnackBarType.success);
      _fetchMatchesAndLikesCount();
    } catch (e) {
      debugPrint('Compliment kabul edilirken hata: $e');
      SnackBarService.showSnackBar(context,
          message: 'Compliment kabul edilemedi: ${e.toString()}',
          type: SnackBarType.error);
    }
  }

  Future<void> _declineCompliment(DocumentSnapshot complimentDoc) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final complimentId = complimentDoc.id;

    try {
      await _firestore.collection('compliments').doc(complimentId).update({
        'read': true,
        'declined': true,
        'declinedAt': FieldValue.serverTimestamp(),
      });
      SnackBarService.showSnackBar(context,
          message: 'Compliment reddedildi.', type: SnackBarType.info);
      _fetchMatchesAndLikesCount();
    } catch (e) {
      debugPrint('Compliment reddedilirken hata: $e');
      SnackBarService.showSnackBar(context,
          message: 'Compliment reddedilemedi: ${e.toString()}',
          type: SnackBarType.error);
    }
  }

  String _getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_newMatches.isEmpty &&
        _messagedMatches.isEmpty &&
        _incomingCompliments.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.chat_bubble_outline,
        title: 'Henüz Eşleşme veya Sohbet Yok',
        description:
            'Bağlantı kurmak için yeni kişileri keşfetmeye başla veya Compliment gönder.',
        buttonText: 'Profilleri Keşfet',
        onButtonPressed: () {
          Provider.of<TabNavigationProvider>(context, listen: false)
              .setIndex(1);
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohbetler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              SnackBarService.showSnackBar(context,
                  message: 'Sohbet arama yakında!', type: SnackBarType.info);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Eşleşmelerin (${_newMatches.length + _messagedMatches.length})',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LikedYouScreen()));
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accentPink,
                            AppColors.primaryYellow
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.white,
                        child: Text(
                          _likesCount.toString(),
                          style: TextStyle(
                              color: AppColors.accentPink,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Seni Beğenenler',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppColors.primaryText),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: AppColors.secondaryText),
                  ],
                ),
              ),
            ),
            if (_newMatches.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _newMatches.length,
                  itemBuilder: (context, index) {
                    final matchDoc = _newMatches[index];
                    final String user1Id = matchDoc.get('user1Id');
                    final String user2Id = matchDoc.get('user2Id');
                    final String otherUserUid =
                        (user1Id == _auth.currentUser!.uid) ? user2Id : user1Id;

                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore
                          .collection('users')
                          .doc(otherUserUid)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: CircleAvatar(
                                radius: 30,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            !snapshot.data!.exists) {
                          return const SizedBox.shrink();
                        }
                        final otherUserData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final otherUserName =
                            otherUserData['name'] ?? 'Bilinmiyor';
                        final otherUserProfileImageUrl =
                            otherUserData['profileImageUrl'] ??
                                'https://via.placeholder.com/150';

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.accentPink,
                                      AppColors.primaryYellow
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundImage:
                                      NetworkImage(otherUserProfileImageUrl),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                otherUserName.split(' ')[0],
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ), // <<<--- VİRGÜL BURAYA EKLENDİ (Önceki hatadan kaynaklı eksiklikti)
            else
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Yeni eşleşmen yok. Keşfetmeye devam et!',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.secondaryText),
              ),
            ),
            const Divider(),

            if (_incomingCompliments.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Gelen Özel Yorumlar (${_incomingCompliments.length})',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentPink),
                    ),
                  ),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _incomingCompliments.length,
                      itemBuilder: (context, index) {
                        final complimentDoc = _incomingCompliments[index];
                        final senderId = complimentDoc.get('senderId');
                        final comment = complimentDoc.get('comment');

                        return FutureBuilder<DocumentSnapshot>(
                          future: _firestore
                              .collection('users')
                              .doc(senderId)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2));
                            }
                            if (snapshot.hasError ||
                                !snapshot.hasData ||
                                !snapshot.data!.exists) {
                              return const SizedBox.shrink();
                            }
                            final senderData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            final senderName =
                                senderData['name'] ?? 'Bilinmiyor';
                            final senderImageUrl =
                                senderData['profileImageUrl'] ??
                                    'https://via.placeholder.com/150';

                            return GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: Text('$senderName\'den Özel Yorum'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 40,
                                          backgroundImage:
                                              NetworkImage(senderImageUrl),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(comment,
                                            textAlign: TextAlign.center),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          _declineCompliment(complimentDoc);
                                          Navigator.pop(dialogContext);
                                        },
                                        child: const Text('Reddet',
                                            style: TextStyle(
                                                color: AppColors.red)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          _acceptCompliment(complimentDoc);
                                          Navigator.pop(dialogContext);
                                        },
                                        child: const Text('Kabul Et',
                                            style: TextStyle(
                                                color: AppColors.accentTeal)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Card(
                                margin: const EdgeInsets.all(8),
                                child: Container(
                                  width: 100,
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundImage:
                                            NetworkImage(senderImageUrl),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        senderName.split(' ')[0],
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Yorum',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: AppColors.secondaryText),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            const Divider(),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Sohbetler (Yakın Zamanda)',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            _messagedMatches.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Henüz aktif sohbetin yok. Eşleşmelerinle konuşmaya başla!',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.secondaryText),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _messagedMatches.length,
                    itemBuilder: (context, index) {
                      final matchDoc = _messagedMatches[index];
                      final String user1Id = matchDoc.get('user1Id');
                      final String user2Id = matchDoc.get('user2Id');
                      final String otherUserUid =
                          (user1Id == _auth.currentUser!.uid)
                              ? user2Id
                              : user1Id;

                      return FutureBuilder<DocumentSnapshot>(
                        future: _firestore
                            .collection('users')
                            .doc(otherUserUid)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const ListTile(
                              leading: CircularProgressIndicator(),
                              title: Text('Yükleniyor...'),
                            );
                          }
                          if (snapshot.hasError ||
                              !snapshot.hasData ||
                              !snapshot.data!.exists) {
                            return const SizedBox.shrink();
                          }
                          final otherUserData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final otherUserName =
                              otherUserData['name'] ?? 'Bilinmiyor';
                          final otherUserProfileImageUrl =
                              otherUserData['profileImageUrl'] ??
                                  'https://via.placeholder.com/150';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  NetworkImage(otherUserProfileImageUrl),
                            ),
                            title: Text(otherUserName),
                            subtitle: FutureBuilder<QuerySnapshot>(
                              future: _firestore
                                  .collection('chats')
                                  .doc(_getChatId(user1Id, user2Id))
                                  .collection('messages')
                                  .orderBy('timestamp', descending: true)
                                  .limit(1)
                                  .get(),
                              builder: (context, msgSnapshot) {
                                if (msgSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text('Mesaj yükleniyor...',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors.secondaryText));
                                }
                                if (msgSnapshot.hasError ||
                                    !msgSnapshot.hasData ||
                                    msgSnapshot.data!.docs.isEmpty) {
                                  return Text('Henüz mesaj yok.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors.secondaryText));
                                }
                                final lastMessageContent =
                                    msgSnapshot.data!.docs.first.get('content');
                                final Timestamp timestamp = msgSnapshot
                                    .data!.docs.first
                                    .get('timestamp');
                                final DateTime dateTime = timestamp.toDate();
                                final String formattedTime =
                                    '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                                return Text(
                                  '$lastMessageContent · $formattedTime',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: AppColors.secondaryText),
                                );
                              },
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SingleChatScreen(
                                    chatId: _getChatId(user1Id, user2Id),
                                    otherUserUid: otherUserUid,
                                    otherUserName: otherUserName,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
