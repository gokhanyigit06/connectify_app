import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectify_app/screens/profile/user_profile_screen.dart'; // Profil detayına yönlendirme için

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<DocumentSnapshot> _userList = []; // Kullanıcı listesi
  bool _isLoading = false; // Yüklenme durumu için

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Kullanıcı listesini Firestore'dan çeken fonksiyon
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
      // Kendi profilimiz hariç tüm kullanıcıları çekelim (şimdilik filtre yok)
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where(
            'uid',
            isNotEqualTo: currentUser.uid,
          ) // Kendi profilimizi gösterme
          .get();

      setState(() {
        _userList = querySnapshot.docs;
      });

      if (_userList.isEmpty) {
        debugPrint('PeopleScreen: Gösterilecek kullanıcı bulunamadı.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gösterilecek kullanıcı bulunamadı.')),
        );
      }
    } catch (e) {
      debugPrint("PeopleScreen: Kullanıcı listesi çekilirken hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcılar yüklenirken hata oluştu: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Kullanıcı profili detayına gitme
  void _viewUserProfileDetail(Map<String, dynamic> userData) {
    debugPrint(
      'PeopleScreen: Kullanıcı detayına gidiliyor: ${userData['name']}',
    );
    // Burada daha sonra tek bir kullanıcının detaylı profilini gösterecek bir ekran olacak
    // Şimdilik sadece UserProfileScreen'i mevcut kullanıcı verisi ile açalım (kendisi değil, seçilen kişi)
    // Bunun için UserProfileScreen'in initialData alması gerekir veya yeni bir ProfileDetailScreen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${userData['name']} profil detayına gideceksin.'),
      ),
    );
  }

  // Kullanıcıyı beğenme işlemi
  void _likeUser(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    debugPrint('PeopleScreen: Beğenildi: $targetUserId');
    try {
      // 1. Beğeni bilgisini Firestore'daki 'likes' koleksiyonuna kaydet
      await _firestore.collection('likes').add({
        'likerId': currentUser.uid, // Beğenen kişi
        'likedId': targetUserId, // Beğenilen kişi
        'timestamp': FieldValue.serverTimestamp(), // Beğenme zamanı
      });
      debugPrint('PeopleScreen: Beğeni Firestore\'a kaydedildi.');
      ScaffoldMessenger.of(context).showSnackBar(
        // SnackBar'ı başarı durumunda göster
        SnackBar(content: Text('Kullanıcı beğenildi: $targetUserId')),
      );

      // 2. Karşılıklı beğeni kontrolü (Eşleşme için)
      QuerySnapshot reciprocalLike = await _firestore
          .collection('likes')
          .where(
            'likerId',
            isEqualTo: targetUserId,
          ) // Beğenen kişi targetUserId
          .where(
            'likedId',
            isEqualTo: currentUser.uid,
          ) // Beğenilen kişi currentUser
          .get();

      if (reciprocalLike.docs.isNotEmpty) {
        // Karşılıklı beğeni var, eşleşme oluştu!
        debugPrint(
          'PeopleScreen: Eşleşme oluştu: ${currentUser.uid} ve $targetUserId',
        );

        // Eşleşmeyi 'matches' koleksiyonuna kaydet
        String user1Id = currentUser.uid.compareTo(targetUserId) < 0
            ? currentUser.uid
            : targetUserId;
        String user2Id = currentUser.uid.compareTo(targetUserId) < 0
            ? targetUserId
            : currentUser.uid;

        // Aynı eşleşmenin zaten var olup olmadığını kontrol et (duplicate eşleşme olmaması için)
        QuerySnapshot existingMatch = await _firestore
            .collection('matches')
            .where('user1Id', isEqualTo: user1Id)
            .where('user2Id', isEqualTo: user2Id)
            .get();

        if (existingMatch.docs.isEmpty) {
          // Eğer daha önce böyle bir eşleşme kaydedilmediyse
          await _firestore.collection('matches').add({
            'user1Id': user1Id,
            'user2Id': user2Id,
            'createdAt': FieldValue.serverTimestamp(),
          });
          debugPrint('PeopleScreen: Eşleşme Firestore\'a kaydedildi.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yeni bir eşleşmen var!')),
          );
        } else {
          debugPrint('PeopleScreen: Eşleşme zaten mevcut.');
        }
      }
    } catch (e) {
      debugPrint('PeopleScreen: Beğeni/Eşleşme kaydedilirken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Beğeni veya eşleşme kaydedilemedi: $e')),
      );
    }
  }

  // Kullanıcıya mesaj gönderme işlemi
  void _messageUser(String targetUserId) {
    debugPrint('PeopleScreen: Mesaj gönderiliyor: $targetUserId');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kullanıcıya mesaj gönderiliyor: $targetUserId')),
    );
    // İleride mesajlaşma ekranına yönlendirme gelecek
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İnsanlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list), // Filtre ikonu
            onPressed: () {
              debugPrint('PeopleScreen: Filtre İkonu tıklandı');
              // Filtreleme ekranına yönlendirme gelecek
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Gösterilecek kullanıcı bulunamadı.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _fetchUsers,
                    child: const Text('Kullanıcıları Yenile'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _userList.length,
              itemBuilder: (context, index) {
                final userData =
                    _userList[index].data() as Map<String, dynamic>;
                final String name = userData['name'] ?? 'Bilinmiyor';
                final int age = userData['age'] ?? 0;
                final String profileImageUrl =
                    userData['profileImageUrl'] ??
                    'https://via.placeholder.com/150';
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
                        // Profil Resmi
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
                              // İsim ve Yaş
                              Text(
                                '$name, $age',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Biyografi
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
                              // İlgi Alanları
                              if (interests.isNotEmpty)
                                Wrap(
                                  spacing: 6.0,
                                  runSpacing: 4.0,
                                  children: interests.take(3).map((interest) {
                                    return Chip(
                                      label: Text(interest),
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
                              // Aksiyon Butonları
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.favorite_border,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _likeUser(userData['uid']),
                                    tooltip: 'Beğen',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.message_outlined,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () =>
                                        _messageUser(userData['uid']),
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
