import 'package:flutter/material.dart';
import 'package:connectify_app/utils/app_colors.dart'; // Renk paletimiz için
import 'package:connectify_app/services/snackbar_service.dart'; // SnackBarService için
import 'package:connectify_app/screens/single_chat_screen.dart'; // Sohbet ekranına yönlendirme için
import 'package:provider/provider.dart'; // Provider için
import 'package:connectify_app/providers/tab_navigation_provider.dart'; // Sekme değiştirmek için

class MatchFoundScreen extends StatelessWidget {
  final Map<String, dynamic> currentUserProfile; // Mevcut kullanıcının profili
  final Map<String, dynamic>
  matchedUserProfile; // Eşleşilen kullanıcının profili

  const MatchFoundScreen({
    super.key,
    required this.currentUserProfile,
    required this.matchedUserProfile,
  });

  @override
  Widget build(BuildContext context) {
    final String currentUserName = currentUserProfile['name'] ?? 'Sen';
    final String currentUserProfileImageUrl =
        currentUserProfile['profileImageUrl'] ??
        'https://placehold.co/150x150/CCCCCC/000000?text=Sen';
    final String matchedUserName = matchedUserProfile['name'] ?? 'Bilinmeyen';
    final String matchedUserProfileImageUrl =
        matchedUserProfile['profileImageUrl'] ??
        'https://placehold.co/150x150/CCCCCC/000000?text=Eşleşen';

    return Scaffold(
      backgroundColor: AppColors.background, // Arka plan rengi
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

              // Profil Resimleri ve Çapraz Efekt
              SizedBox(
                height: 200, // Yükseklik ver
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Eşleşilen Kullanıcının Profili (Sol üstten sağ alta doğru)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Transform.rotate(
                        // Hafif rotasyon
                        angle: -0.2, // Yaklaşık -11 derece
                        child: _buildProfileCard(
                          context,
                          imageUrl: matchedUserProfileImageUrl,
                          name: matchedUserName,
                          color: AppColors.accentPink.withOpacity(
                            0.8,
                          ), // Pembe ton
                        ),
                      ),
                    ),
                    // Mevcut Kullanıcının Profili (Sağ alttan sol üste doğru)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Transform.rotate(
                        // Hafif rotasyon
                        angle: 0.2, // Yaklaşık 11 derece
                        child: _buildProfileCard(
                          context,
                          imageUrl: currentUserProfileImageUrl,
                          name: currentUserName,
                          color: AppColors.primaryYellow.withOpacity(
                            0.8,
                          ), // Sarı ton
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

              // Mesaj Gönder Butonu
              ElevatedButton.icon(
                onPressed: () {
                  // Sohbet ekranına yönlendir
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) =>
                          SingleChatScreen(matchedUser: matchedUserProfile),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.message_outlined,
                  color: AppColors.white,
                ),
                label: Text(
                  '${matchedUserName} ile Sohbeti Başlat',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPink, // Vurgu rengi
                  foregroundColor: AppColors.white, // Beyaz metin
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Keşfetmeye Devam Et Butonu
              TextButton(
                onPressed: () {
                  // BottomNavigationBar'da Keşfet sekmesine git (index 1)
                  // Eğer bu ekran Navigator.pushReplacement ile açılırsa, önceki ekranı kaldıracağı için
                  // doğrudan tab değişimini tetiklememiz gerekir.
                  Provider.of<TabNavigationProvider>(
                    context,
                    listen: false,
                  ).setIndex(1);
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

  // Profil resmi ve ismini içeren kart (Avatar benzeri)
  Widget _buildProfileCard(
    BuildContext context, {
    required String imageUrl,
    required String name,
    required Color color,
  }) {
    return Container(
      width: 150, // Sabit genişlik
      height: 150, // Sabit yükseklik
      decoration: BoxDecoration(
        color: color, // Arka plan rengi
        borderRadius: BorderRadius.circular(15), // Yuvarlak köşeler
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
                name.split(' ')[0], // Sadece ilk ismi göster
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
