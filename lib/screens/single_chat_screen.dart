// lib/screens/single_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:connectify_app/utils/app_colors.dart';

class SingleChatScreen extends StatefulWidget {
  // <<<--- DÜZELTİLDİ: Yeni parametreler tanımlandı
  final String chatId;
  final String otherUserUid;
  final String otherUserName;
  // matchedUser parametresi kaldırıldı, bilgileri diğer parametrelerden alacağız

  const SingleChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserUid,
    required this.otherUserName,
  });

  @override
  State<SingleChatScreen> createState() => _SingleChatScreenState();
}

class _SingleChatScreenState extends State<SingleChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();

  String? _currentUserId;
  // _matchedUserId artık widget.otherUserUid'den alınacak
  Map<String, dynamic>?
      _otherUserProfileData; // Diğer kullanıcının tam profil verisi

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
    // _matchedUserId'yi doğrudan widget'tan al
    // _matchedUserId = widget.otherUserUid; // Aslında bu değişkene ihtiyacımız yok, doğrudan widget.otherUserUid kullanabiliriz
    _fetchOtherUserProfileData(); // Diğer kullanıcının tam profil verisini çek
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // Sohbet edilen diğer kişinin profil verilerini çeker
  Future<void> _fetchOtherUserProfileData() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(widget.otherUserUid).get();
      if (userDoc.exists) {
        setState(() {
          _otherUserProfileData = userDoc.data() as Map<String, dynamic>;
        });
      } else {
        debugPrint(
            'SingleChatScreen: Sohbet edilen kişinin profil verisi bulunamadı.');
      }
    } catch (e) {
      debugPrint(
          'SingleChatScreen: Sohbet edilen kişinin profil verileri çekilirken hata: $e');
    }
  }

  // Mesaj gönderme fonksiyonu
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty ||
        widget.chatId == null || // Widget'tan gelen chatId'yi kullan
        _currentUserId == null) {
      return; // Boş mesaj gönderme veya chat/kullanıcı ID yoksa
    }

    try {
      // 1. Sohbet belgesini (chats/{chatId}) oluştur veya güncelle
      await _firestore.collection('chats').doc(widget.chatId).set(
        {
          'user1Id': _currentUserId,
          'user2Id':
              widget.otherUserUid, // Widget'tan gelen diğer UID'yi kullan
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageContent': _messageController.text.trim(),
        },
        SetOptions(merge: true),
      );
      debugPrint('SingleChatScreen: Sohbet belgesi oluşturuldu/güncellendi.');

      // 2. Mesajı sohbetin alt koleksiyonuna kaydet
      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'senderId': _currentUserId,
        'receiverId': widget.otherUserUid,
        'content': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
      debugPrint('SingleChatScreen: Mesaj gönderildi.');

      // ChatsScreen'de son mesajı güncellemek için matches koleksiyonunu da güncelle
      String user1IdForMatch =
          _currentUserId!.compareTo(widget.otherUserUid) < 0
              ? _currentUserId!
              : widget.otherUserUid;
      String user2IdForMatch =
          _currentUserId!.compareTo(widget.otherUserUid) < 0
              ? widget.otherUserUid
              : _currentUserId!;

      QuerySnapshot matchQuery = await _firestore
          .collection('matches')
          .where('user1Id', isEqualTo: user1IdForMatch)
          .where('user2Id', isEqualTo: user2IdForMatch)
          .get();

      if (matchQuery.docs.isNotEmpty) {
        await _firestore
            .collection('matches')
            .doc(matchQuery.docs.first.id)
            .update({
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageContent': _messageController.text.trim(),
        });
        debugPrint('SingleChatScreen: Matches belgesi güncellendi.');
      }
    } catch (e) {
      debugPrint('SingleChatScreen: Mesaj gönderilirken hata: $e');
      SnackBarService.showSnackBar(
        context,
        message: 'Mesaj gönderilemedi: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  // Mesaj baloncuğu widget'ı
  Widget _buildMessageBubble(DocumentSnapshot messageDoc) {
    final Map<String, dynamic> messageData =
        messageDoc.data() as Map<String, dynamic>;
    final bool isMe = messageData['senderId'] == _currentUserId;

    // Compliment mesajları için özel görünüm
    if (messageData['type'] == 'compliment') {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.accentTeal.withOpacity(0.8)
                : AppColors.primaryYellow.withOpacity(0.8),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMe
                    ? 'Senin Özel Yorumun:'
                    : '${widget.otherUserName}\'dan Özel Yorum:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isMe ? AppColors.white : AppColors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                messageData['content'],
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: isMe ? AppColors.white : AppColors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Normal mesajlar için görünüm
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primaryYellow.withOpacity(0.8)
              : AppColors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft:
                isMe ? const Radius.circular(15) : const Radius.circular(0),
            bottomRight:
                isMe ? const Radius.circular(0) : const Radius.circular(15),
          ),
        ),
        child: Text(
          messageData['content'],
          style: TextStyle(
            color: isMe ? AppColors.black : AppColors.primaryText,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Profil resmini _otherUserProfileData'dan çek
    final String profileImageUrl = _otherUserProfileData?['profileImageUrl'] ??
        'https://placehold.co/150x150/CCCCCC/000000?text=Profil';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(profileImageUrl),
              backgroundColor: AppColors.grey.withOpacity(0.2),
            ),
            const SizedBox(width: 8),
            Text(widget.otherUserName), // Widget'tan gelen ismi kullan
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              debugPrint('Sesli arama tıklandı');
              SnackBarService.showSnackBar(
                context,
                message: 'Sesli arama özelliği yakında eklenecek!',
                type: SnackBarType.info,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: () {
              debugPrint('Görüntülü arama tıklandı');
              SnackBarService.showSnackBar(
                context,
                message: 'Görüntülü arama özelliği yakında eklenecek!',
                type: SnackBarType.info,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.chatId == null ||
                    _otherUserProfileData ==
                        null // Hem chatId hem de profil verisi bekleniyor
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('chats')
                        .doc(widget.chatId)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Mesajlar yüklenirken hata: ${snapshot.error}',
                            style: TextStyle(color: AppColors.red),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Henüz mesaj yok. İlk mesajı sen gönder!',
                          ),
                        );
                      }

                      return ListView.builder(
                        reverse: true,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(
                            snapshot.data!.docs[index],
                          );
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Mesaj yaz...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  backgroundColor: AppColors.primaryYellow,
                  child: const Icon(
                    Icons.send,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
