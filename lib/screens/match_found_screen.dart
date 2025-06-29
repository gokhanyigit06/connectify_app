import 'package:flutter/material.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:connectify_app/screens/single_chat_screen.dart'; // Sohbet ekranına yönlendirme için
import 'package:provider/provider.dart';
import 'package:connectify_app/providers/tab_navigation_provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Current user UID için

class MatchFoundScreen extends StatelessWidget {
  final Map<String, dynamic> currentUserProfile;
  final Map<String, dynamic> matchedUserProfile;

  const MatchFoundScreen({
    super.key,
    required this.currentUserProfile,
    required this.matchedUserProfile,
  });

  // Chat ID'sini oluşturmak için yardımcı metod (chats_screen'den kopyalandı)
  String _getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  @override
  Widget build(BuildContext context) {
    // Mevcut kullanıcının UID'si lazım olacak (sohbeti başlatırken)
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      // Eğer kullanıcı UID'si alınamazsa hata veya geri dön
      return Scaffold(
        body: Center(child: Text('Kullanıcı bilgisi alınamadı.')),
      );
    }

    final String currentUserName = currentUserProfile['name'] ?? 'Sen';
    final String currentUserProfileImageUrl =
        currentUserProfile['profileImageUrl'] ??
            'https://placehold.co/150x150/CCCCCC/000000?text=Sen';
    final String matchedUserName = matchedUserProfile['name'] ?? 'Bilinmeyen';
    final String matchedUserUid =
        matchedUserProfile['uid'] ?? ''; // Eşleşilen kullanıcının UID'si
    final String matchedUserProfileImageUrl =
        matchedUserProfile['profileImageUrl'] ??
            'https://placehold.co/150x150/CCCCCC/000000?text=Eşleşen';

    // Chat ID'sini oluştur
    final String chatId = _getChatId(currentUserId, matchedUserUid);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Eşleştiniz!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Transform.rotate(
                        angle: -0.2,
                        child: _buildProfileCard(
                          context,
                          imageUrl: matchedUserProfileImageUrl,
                          name: matchedUserName,
                          color: AppColors.accentPink.withOpacity(0.8),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Transform.rotate(
                        angle: 0.2,
                        child: _buildProfileCard(
                          context,
                          imageUrl: currentUserProfileImageUrl,
                          name: currentUserName,
                          color: AppColors.primaryYellow.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              Text(
                'Tebrikler! ${matchedUserName} ile eşleştiniz. İlk mesajı sen göndermek ister misin?',
                style: TextStyle(fontSize: 18, color: AppColors.secondaryText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Mesaj Gönder Butonu - Düzeltildi
              ElevatedButton.icon(
                onPressed: () {
                  // Sohbet ekranına yönlendir - Doğru parametrelerle
                  Navigator.of(context).pushReplacement(
                    // pushReplacement ile bu ekranı kapat
                    MaterialPageRoute(
                      builder: (context) => SingleChatScreen(
                        chatId: chatId, // Doğru parametre adı ve değeri
                        otherUserUid:
                            matchedUserUid, // Doğru parametre adı ve değeri
                        otherUserName:
                            matchedUserName, // Doğru parametre adı ve değeri
                      ),
                    ),
                  );
                },
                icon:
                    const Icon(Icons.message_outlined, color: AppColors.white),
                label: Text(
                  '${matchedUserName} ile Sohbeti Başlat',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPink,
                  foregroundColor: AppColors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 16),

              // Keşfetmeye Devam Et Butonu
              TextButton(
                onPressed: () {
                  Provider.of<TabNavigationProvider>(context, listen: false)
                      .setIndex(1);
                  Navigator.of(context).pop(); // Bu ekranı kapat
                },
                child: Text(
                  'Keşfetmeye Devam Et',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primaryText,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context, {
    required String imageUrl,
    required String name,
    required Color color,
  }) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            Expanded(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.grey.withOpacity(0.3),
                  child: Icon(
                    Icons.person_outline,
                    size: 50,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                name.split(' ')[0],
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
