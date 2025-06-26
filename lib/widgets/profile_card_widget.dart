import 'package:flutter/material.dart';
import 'package:connectify_app/utils/app_colors.dart'; // Renk paletimiz için

class ProfileCardWidget extends StatelessWidget {
  // StatelessWidget olarak kalacak
  final Map<String, dynamic> userData; // Gösterilecek kullanıcının tüm verileri
  final VoidCallback? onLike; // Beğenme butonu için callback
  final VoidCallback? onPass; // Geçme butonu için callback

  const ProfileCardWidget({
    super.key,
    required this.userData,
    this.onLike,
    this.onPass,
  });

  @override
  Widget build(BuildContext context) {
    // Güvenli veri erişimi
    final String name = userData['name'] ?? 'Bilinmiyor';
    final int age = userData['age'] ?? 0;
    final String gender = userData['gender'] ?? ''; // Cinsiyet alanı eklendi
    final String bio = userData['bio'] ?? 'Merhaba!';
    final List<String> interests = List<String>.from(
      userData['interests'] ?? [],
    );
    final String profileImageUrl =
        userData['profileImageUrl'] ??
        'https://placehold.co/400x600/CCCCCC/000000?text=Profil'; // Placeholder güncellendi

    return Card(
      elevation: 8, // Kartın gölgesi
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Köşeleri daha yuvarlak yap
      ),
      clipBehavior:
          Clip.antiAlias, // Resmin kartın köşelerini takip etmesini sağlar
      child: Stack(
        // Burası refactor edildi
        fit: StackFit.expand, // Stack'in Card'ı kaplamasını sağla
        children: [
          // 1. Profil Resmi (doğrudan Image.network olarak)
          Image.network(
            profileImageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryYellow,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.grey.withOpacity(0.3),
              child: Icon(
                Icons.broken_image, // Daha uygun bir ikon
                color: AppColors.red,
                size: 48,
              ),
            ),
          ),
          // 2. Karartma ve Gradyan Katmanı
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
          ),
          // 3. İçerik (İsim, Yaş, Biyografi, İlgi Alanları ve Butonlar)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end, // İçeriği alta hizala
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İsim, Yaş
                Text(
                  '$name, $age',
                  style: const TextStyle(
                    color: AppColors.white, // Renk paletinden
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 5.0,
                        color: AppColors.black, // Renk paletinden
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Cinsiyet (Eğer varsa)
                if (gender.isNotEmpty)
                  Text(
                    gender,
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.8),
                      fontSize: 18,
                    ),
                  ),
                const SizedBox(height: 8),

                // Biyografi
                Text(
                  bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.7), // Renk paletinden
                    fontSize: 16,
                    shadows: const [
                      Shadow(
                        blurRadius: 5.0,
                        color: AppColors.black, // Renk paletinden
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // İlgi Alanları (Sadece ilk 3'ü gösterelim)
                if (interests.isNotEmpty)
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: interests.take(3).map((interest) {
                      return Chip(
                        label: Text(interest),
                        backgroundColor: AppColors.primaryYellow.withOpacity(
                          0.7,
                        ), // Renk paletinden
                        labelStyle: const TextStyle(
                          color: AppColors.black, // Renk paletinden
                          fontSize: 13,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 0,
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),

                // Beğen/Geç Butonları (onPressed callback'leri doğrudan çağıracak)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Geçme butonu
                    FloatingActionButton(
                      heroTag:
                          'passBtn_${userData['uid']}', // Unique tag for hero
                      mini: false, // Daha büyük butonlar için mini: false
                      backgroundColor: AppColors.white, // Renk paletinden
                      onPressed: onPass, // Doğrudan onPass callback'i
                      child: const Icon(
                        Icons.close,
                        color: AppColors.red,
                      ), // Renk paletinden
                    ),
                    // Beğenme butonu
                    FloatingActionButton(
                      heroTag:
                          'likeBtn_${userData['uid']}', // Unique tag for hero
                      mini: false, // Daha büyük butonlar için mini: false
                      backgroundColor:
                          AppColors.accentPink, // Renk paletinden (Vurgu rengi)
                      onPressed: onLike, // Doğrudan onLike callback'i
                      child: const Icon(
                        Icons.favorite,
                        color: AppColors.white,
                      ), // Renk paletinden (beyaz ikon)
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
