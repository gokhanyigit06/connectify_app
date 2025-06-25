import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // Match ID'sini bulmak için değişken
  String? _matchId;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
    _findMatchId(); // Match ID'sini bulmak için çağır
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // Current user ile matchedUser arasındaki match ID'yi bulur
  Future<void> _findMatchId() async {
    if (_currentUserId == null) return;

    // user1Id ve user2Id her zaman alfabetik sıraya göre kaydedildiği için aynı mantıkla arayalım
    String user1Id = _currentUserId!.compareTo(widget.matchedUser['uid']) < 0
        ? _currentUserId!
        : widget.matchedUser['uid'];
    String user2Id = _currentUserId!.compareTo(widget.matchedUser['uid']) < 0
        ? widget.matchedUser['uid']
        : _currentUserId!;

    try {
      QuerySnapshot matchQuery = await _firestore
          .collection('matches')
          .where('user1Id', isEqualTo: user1Id)
          .where('user2Id', isEqualTo: user2Id)
          .get();

      if (matchQuery.docs.isNotEmpty) {
        setState(() {
          _matchId = matchQuery.docs.first.id;
        });
        debugPrint('SingleChatScreen: Match ID bulundu: $_matchId');
      } else {
        debugPrint(
          'SingleChatScreen: Match ID bulunamadı. Sohbet başlatılamaz.',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eşleşme bulunamadı, mesaj gönderilemiyor.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('SingleChatScreen: Match ID bulunurken hata: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sohbet başlatılırken hata: $e')));
    }
  }

  // Mesaj gönderme fonksiyonu
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty ||
        _matchId == null ||
        _currentUserId == null) {
      return; // Boş mesaj gönderme veya match/kullanıcı ID yoksa
    }

    try {
      await _firestore
          .collection('matches')
          .doc(_matchId)
          .collection('messages')
          .add({
            'senderId': _currentUserId,
            'receiverId': widget.matchedUser['uid'],
            'content': _messageController.text.trim(),
            'timestamp': FieldValue.serverTimestamp(),
          });
      _messageController
          .clear(); // Mesaj gönderildikten sonra metin kutusunu temizle
      debugPrint('SingleChatScreen: Mesaj gönderildi.');
    } catch (e) {
      debugPrint('SingleChatScreen: Mesaj gönderilirken hata: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mesaj gönderilemedi: $e')));
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
          color: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
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
          style: TextStyle(color: isMe ? Colors.black : Colors.black87),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.matchedUser['name'] ?? 'Sohbet Partneri';
    final String profileImageUrl =
        widget.matchedUser['profileImageUrl'] ??
        'https://via.placeholder.com/150';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(profileImageUrl),
              backgroundColor: Colors.grey[200],
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
            },
          ),
          IconButton(
            icon: const Icon(Icons.video_call), // Görüntülü arama
            onPressed: () {
              debugPrint('Görüntülü arama tıklandı');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _matchId == null
                ? const Center(
                    child: CircularProgressIndicator(),
                  ) // Match ID bekleniyor
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('matches')
                        .doc(_matchId)
                        .collection('messages')
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
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.send, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
