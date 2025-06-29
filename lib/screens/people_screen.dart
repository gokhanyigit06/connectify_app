// lib/src/screens/people_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth için
import 'package:connectify_app/screens/single_chat_screen.dart'; // SingleChatScreen için
import 'package:connectify_app/screens/profile/user_profile_screen.dart'; // Kendi profil ekranınız
import 'package:connectify_app/widgets/empty_state_widget.dart';
import 'package:connectify_app/services/snackbar_service.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<DocumentSnapshot> _userList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('PeopleScreen: Kullanıcı giriş yapmamış. Liste çekilmedi.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('uid', isNotEqualTo: currentUser.uid)
          .get();

      setState(() {
        _userList = querySnapshot.docs;
      });

      if (_userList.isEmpty) {
        debugPrint('PeopleScreen: Gösterilecek kullanıcı bulunamadı.');
      }
    } catch (e) {
      debugPrint("PeopleScreen: Kullanıcı listesi çekilirken hata oluştu: $e");
      SnackBarService.showSnackBar(
        context,
        message: 'Kullanıcılar yüklenirken hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
        actionLabel: 'Tekrar Dene',
        onActionPressed: _fetchUsers,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Yeni _getChatId metodu eklendi ---
  String _getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }
  // --- _getChatId metodu sonu ---

  void _viewUserProfileDetail(Map<String, dynamic> userData) {
    debugPrint(
      'PeopleScreen: Kullanıcı detayına gidiliyor: ${userData['name']}',
    );
    // Bu kısımda Profil Detay Ekranına yönlendirme yapılabilir.
    // Şimdilik sadece SnackBar mesajı veriliyor.
    SnackBarService.showSnackBar(
      context,
      message: '${userData['name']} profil detayına gideceksin.',
      type: SnackBarType.info,
    );
  }

  void _likeUser(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    debugPrint('PeopleScreen: Beğenildi: $targetUserId');
    try {
      await _firestore.collection('likes').add({
        'likerId': currentUser.uid,
        'likedId': targetUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('PeopleScreen: Beğeni Firestore\'a kaydedildi.');
      SnackBarService.showSnackBar(
        context,
        message: 'Kullanıcı beğenildi!',
        type: SnackBarType.success,
      );

      QuerySnapshot reciprocalLike = await _firestore
          .collection('likes')
          .where('likerId', isEqualTo: targetUserId)
          .where('likedId', isEqualTo: currentUser.uid)
          .get();

      if (reciprocalLike.docs.isNotEmpty) {
        debugPrint(
          'PeopleScreen: Eşleşme oluştu: ${currentUser.uid} ve $targetUserId',
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
          debugPrint('PeopleScreen: Eşleşme Firestore\'a kaydedildi.');
          SnackBarService.showSnackBar(
            context,
            message: 'Yeni bir eşleşmen var!',
            type: SnackBarType.success,
          );
        } else {
          debugPrint('PeopleScreen: Eşleşme zaten mevcut.');
        }
      }
    } catch (e) {
      debugPrint('PeopleScreen: Beğeni/Eşleşme kaydedilirken hata oluştu: $e');
      SnackBarService.showSnackBar(
        context,
        message: 'Beğeni veya eşleşme kaydedilemedi: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  // --- _messageUser metodu düzeltildi ---
  void _messageUser(Map<String, dynamic> userData) {
    debugPrint('PeopleScreen: Mesaj gönderiliyor: ${userData['name']}');
    final currentUserUid = _auth.currentUser?.uid;
    if (currentUserUid == null) {
      SnackBarService.showSnackBar(context,
          message: 'Mesaj göndermek için giriş yapmalısın.',
          type: SnackBarType.error);
      return;
    }

    final String otherUserUid = userData['uid'] ?? '';
    final String otherUserName = userData['name'] ?? 'Bilinmiyor';
    final String chatId =
        _getChatId(currentUserUid, otherUserUid); // _getChatId kullanıldı

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SingleChatScreen(
          chatId: chatId, // Doğru parametre adı ve değeri
          otherUserUid: otherUserUid, // Doğru parametre adı ve değeri
          otherUserName: otherUserName, // Doğru parametre adı ve değeri
        ),
      ),
    );
  }
  // --- _messageUser metodu sonu ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İnsanlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              debugPrint('PeopleScreen: Filtre İkonu tıklandı');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userList.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.person_search,
                  title: 'Kimse Bulunamadı',
                  description:
                      'Görünüşe göre kriterlerine uygun yeni bir kişi yok. Belki de filtrelerini güncellemeyi denemelisin?',
                  buttonText: 'Kullanıcıları Yenile',
                  onButtonPressed: _fetchUsers,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _userList.length,
                  itemBuilder: (context, index) {
                    final userData =
                        _userList[index].data() as Map<String, dynamic>;
                    final String name = userData['name'] ?? 'Bilinmiyor';
                    final int age = userData['age'] ?? 0;
                    final String profileImageUrl = userData[
                            'profileImageUrl'] ??
                        'https://placehold.co/100x100/CCCCCC/000000?text=Profil';
                    final String bio = userData['bio'] ?? '';
                    final List<String> interests = List<String>.from(
                      userData['interests'] ?? [],
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(profileImageUrl),
                              backgroundColor: Colors.grey[200],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$name, $age',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bio.isNotEmpty ? bio : 'Biyografi yok.',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (interests.isNotEmpty)
                                    Wrap(
                                      spacing: 6.0,
                                      runSpacing: 4.0,
                                      children:
                                          interests.take(3).map((interest) {
                                        return Chip(
                                          label: Text(interest),
                                          // AppColors'u import etmeliyiz eğer AppColors kullanacaksak
                                          // Şimdilik doğrudan Theme.of(context).primaryColor kullanıldı
                                          backgroundColor: Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.5),
                                          labelStyle: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        );
                                      }).toList(),
                                    ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.favorite_border,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _likeUser(userData['uid']),
                                        tooltip: 'Beğen',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.message_outlined,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () => _messageUser(userData),
                                        tooltip: 'Mesaj Gönder',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
