import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectify_app/services/snackbar_service.dart'; // SnackBarService import edildi
import 'package:connectify_app/utils/app_colors.dart'; // Renk paletimiz için

class SingleChatScreen extends StatefulWidget {
  final Map<String, dynamic> matchedUser; // Sohbet edilen kişinin bilgileri

  const SingleChatScreen({super.key, required this.matchedUser});

  @override
  State<SingleChatScreen> createState() => _SingleChatScreenState();
}

class _SingleChatScreenState extends State<SingleChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();

  String?
  _chatId; // Yeni: Sohbet ID'si (matches ID yerine chats koleksiyonu ID'si)
  String? _currentUserId;
  String? _matchedUserId; // Eşleşilen kullanıcının UID'si

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
    _matchedUserId =
        widget.matchedUser['uid']; // Eşleşilen kullanıcının UID'sini al
    _setChatId(); // Sohbet ID'sini ayarla
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // Current user ile matchedUser arasındaki sohbet ID'sini ayarlar
  void _setChatId() {
    if (_currentUserId == null || _matchedUserId == null) return;

    // UID'leri alfabetik sıraya göre birleştirerek tutarlı bir sohbet ID'si oluşturur
    // Bu, _getChatId fonksiyonuna benzer mantıkta
    if (_currentUserId!.compareTo(_matchedUserId!) < 0) {
      _chatId = '${_currentUserId!}_${_matchedUserId!}';
    } else {
      _chatId = '${_matchedUserId!}_${_currentUserId!}';
    }
    debugPrint('SingleChatScreen: Chat ID belirlendi: $_chatId');
  }

  // Mesaj gönderme fonksiyonu
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty ||
        _chatId == null || // Match ID yerine Chat ID kontrolü
        _currentUserId == null) {
      return; // Boş mesaj gönderme veya chat/kullanıcı ID yoksa
    }

    try {
      // 1. Sohbet belgesini (chats/{chatId}) oluştur veya güncelle
      // Eğer belge yoksa oluşturur, varsa birleştirir.
      await _firestore.collection('chats').doc(_chatId).set(
        {
          'user1Id': _currentUserId,
          'user2Id': _matchedUserId,
          'createdAt': FieldValue.serverTimestamp(), // İlk oluşturma zamanı
          'lastMessageTime': FieldValue.serverTimestamp(), // Son mesaj zamanı
          'lastMessageContent': _messageController.text
              .trim(), // Son mesaj içeriği
        },
        SetOptions(merge: true), // Mevcut veriyi koru, yenisini ekle/güncelle
      );
      debugPrint('SingleChatScreen: Sohbet belgesi oluşturuldu/güncellendi.');

      // 2. Mesajı sohbetin alt koleksiyonuna kaydet
      await _firestore
          .collection('chats') // chats koleksiyonu
          .doc(_chatId) // sohbet ID'si
          .collection('messages') // messages alt koleksiyonu
          .add({
            'senderId': _currentUserId,
            'receiverId': _matchedUserId,
            'content': _messageController.text.trim(),
            'timestamp': FieldValue.serverTimestamp(),
          });
      _messageController.clear();
      debugPrint('SingleChatScreen: Mesaj gönderildi.');

      // ChatsScreen'de son mesajı güncellemek için matches koleksiyonunu da güncelle
      // Bu, ChatsScreen'deki son mesaj önizlemesini doğru gösterecek.
      // Eşleşme ID'sini bulup güncelleyelim.
      String user1IdForMatch = _currentUserId!.compareTo(_matchedUserId!) < 0
          ? _currentUserId!
          : _matchedUserId!;
      String user2IdForMatch = _currentUserId!.compareTo(_matchedUserId!) < 0
          ? _matchedUserId!
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

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primaryYellow.withOpacity(0.8)
              : AppColors.grey.withOpacity(0.3), // Renk paletinden
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isMe
                ? const Radius.circular(15)
                : const Radius.circular(0),
            bottomRight: isMe
                ? const Radius.circular(0)
                : const Radius.circular(15),
          ),
        ),
        child: Text(
          messageData['content'],
          style: TextStyle(
            color: isMe ? AppColors.black : AppColors.primaryText,
          ), // Renk paletinden
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.matchedUser['name'] ?? 'Sohbet Partneri';
    final String profileImageUrl =
        widget.matchedUser['profileImageUrl'] ??
        'https://placehold.co/150x150/CCCCCC/000000?text=Profil';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(profileImageUrl),
              backgroundColor: AppColors.grey.withOpacity(
                0.2,
              ), // Renk paletinden
            ),
            const SizedBox(width: 8),
            Text(name),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call), // Sesli arama
            onPressed: () {
              debugPrint('Sesli arama tıklandı');
              SnackBarService.showSnackBar(
                // SnackBarService eklendi
                context,
                message: 'Sesli arama özelliği yakında eklenecek!',
                type: SnackBarType.info,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.video_call), // Görüntülü arama
            onPressed: () {
              debugPrint('Görüntülü arama tıklandı');
              SnackBarService.showSnackBar(
                // SnackBarService eklendi
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
            child: _chatId == null
                ? const Center(
                    child: CircularProgressIndicator(),
                  ) // Chat ID bekleniyor
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('chats') // chats koleksiyonu
                        .doc(_chatId) // sohbet ID'si
                        .collection('messages') // messages alt koleksiyonu
                        .orderBy(
                          'timestamp',
                          descending: true,
                        ) // En yeni mesaj en üstte
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Mesajlar yüklenirken hata: ${snapshot.error}',
                            style: TextStyle(
                              color: AppColors.red,
                            ), // Renk paletinden
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
                        reverse:
                            true, // Listeyi tersine çevir, en yeni mesaj alta gelsin
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
                    onSubmitted: (value) =>
                        _sendMessage(), // Enter'a basınca gönder
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  backgroundColor: AppColors.primaryYellow, // Renk paletinden
                  child: const Icon(
                    Icons.send,
                    color: AppColors.black,
                  ), // Renk paletinden
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
