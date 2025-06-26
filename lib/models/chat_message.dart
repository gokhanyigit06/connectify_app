import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String senderId;
  final String content; // Metin mesajı veya sesli mesajsa "Sesli Mesaj" yazısı
  final Timestamp timestamp;
  final bool isAI; // AI'den mi geldi
  final bool isImage; // Görsel mesaj mı
  final String? imageUrl; // Görsel URL'si
  // isAudio ve audioUrl alanları sesli mesaj özelliği kaldırıldığı için çıkarıldı.

  ChatMessage({
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.isAI = false,
    this.isImage = false,
    this.imageUrl,
  });

  // Firestore'dan veri okurken kullanmak için factory metodu
  factory ChatMessage.fromFirestore(Map<String, dynamic> data) {
    return ChatMessage(
      senderId: data['senderId'] as String,
      content: data['content'] as String,
      timestamp: data['timestamp'] as Timestamp,
      isAI: data['isAI'] as bool? ?? false,
      isImage: data['isImage'] as bool? ?? false,
      imageUrl: data['imageUrl'] as String?,
      // isAudio ve audioUrl buradan da kaldırıldı.
    );
  }

  // Firestore'a veri yazarken kullanmak için toJson metodu
  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp,
      'isAI': isAI,
      'isImage': isImage,
      'imageUrl': imageUrl,
      // isAudio ve audioUrl buradan da kaldırıldı.
    };
  }
}
