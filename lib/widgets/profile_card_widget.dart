import 'package:flutter/material.dart';

class ProfileCardWidget extends StatelessWidget {
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
    final int age =
        userData['age'] ?? 0; // Yaş 0 olarak varsayılsın, sonra düzeltiriz
    final String profileImageUrl =
        userData['profileImageUrl'] ?? 'https://via.placeholder.com/150';
    final String bio = userData['bio'] ?? 'Merhaba!';
    final List<String> interests = List<String>.from(
      userData['interests'] ?? [],
    );

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width:
              MediaQuery.of(context).size.width *
              0.9, // Ekran genişliğinin %90'ı
          height:
              MediaQuery.of(context).size.height *
              0.6, // Ekran yüksekliğinin %60'ı
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(profileImageUrl),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3),
                BlendMode.darken,
              ), // Görseli karart
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end, // İçeriği alta hizala
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İsim, Yaş
                Text(
                  '$name, $age',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 5.0,
                        color: Colors.black,
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Biyografi
                Text(
                  bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        blurRadius: 5.0,
                        color: Colors.black,
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
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor, // Ana sarı rengimiz
                        labelStyle: const TextStyle(
                          color: Colors.black,
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

                // Beğen/Geç Butonları
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Geçme butonu
                    FloatingActionButton(
                      heroTag:
                          'passBtn_${userData['uid']}', // Unique tag for hero
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: onPass,
                      child: const Icon(Icons.close, color: Colors.red),
                    ),
                    // Beğenme butonu
                    FloatingActionButton(
                      heroTag:
                          'likeBtn_${userData['uid']}', // Unique tag for hero
                      mini: true,
                      backgroundColor: Theme.of(context).primaryColor,
                      onPressed: onLike,
                      child: const Icon(Icons.favorite, color: Colors.black),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
