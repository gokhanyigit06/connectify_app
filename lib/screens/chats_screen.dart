import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectify_app/screens/single_chat_screen.dart'; // Tekil sohbet ekranı

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  List<Map<String, dynamic>> _matchedUsers =
      []; // Eşleşilen kullanıcıların profilleri

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  // Eşleşmeleri ve eşleşilen kullanıcıların profillerini çeken fonksiyon
  Future<void> _fetchMatches() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('ChatsScreen: Kullanıcı giriş yapmamış. Eşleşme çekilmedi.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Mevcut kullanıcının user1Id veya user2Id olduğu eşleşmeleri çek
      QuerySnapshot matchesSnapshot = await _firestore
          .collection('matches')
          .where('user1Id', isEqualTo: currentUser.uid)
          .get();

      QuerySnapshot matchesSnapshot2 = await _firestore
          .collection('matches')
          .where('user2Id', isEqualTo: currentUser.uid)
          .get();

      List<DocumentSnapshot> allMatchesDocs = [];
      allMatchesDocs.addAll(matchesSnapshot.docs);
      allMatchesDocs.addAll(matchesSnapshot2.docs);

      // Tekrar eden eşleşmeleri önlemek için (aynı eşleşme iki sorguda da gelebilir)
      // Veya sadece user1Id ve user2Id çiftini unique hale getirmek için
      List<String> matchedUids = [];
      for (var doc in allMatchesDocs) {
        String user1Id = doc['user1Id'];
        String user2Id = doc['user2Id'];
        if (user1Id == currentUser.uid) {
          matchedUids.add(user2Id);
        } else {
          matchedUids.add(user1Id);
        }
      }
      // Benzersiz hale getir
      matchedUids = matchedUids.toSet().toList();

      if (matchedUids.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('ChatsScreen: Hiç eşleşme bulunamadı.');
        return;
      }

      // Eşleşilen kullanıcıların profil verilerini çek
      List<Map<String, dynamic>> tempMatchedProfiles = [];
      for (String matchedUid in matchedUids) {
        DocumentSnapshot matchedUserProfile = await _firestore
            .collection('users')
            .doc(matchedUid)
            .get();
        if (matchedUserProfile.exists) {
          tempMatchedProfiles.add(
            matchedUserProfile.data() as Map<String, dynamic>,
          );
        }
      }

      setState(() {
        _matchedUsers = tempMatchedProfiles;
      });
    } catch (e) {
      debugPrint("ChatsScreen: Eşleşmeler çekilirken hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eşleşmeleri yüklerken hata oluştu: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sohbet öğesine tıklandığında
  void _onChatTapped(Map<String, dynamic> matchedUser) {
    debugPrint('ChatsScreen: Sohbet başlatılıyor: ${matchedUser['name']}');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SingleChatScreen(matchedUser: matchedUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohbetler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search), // Sohbet arama
            onPressed: () {
              debugPrint('ChatsScreen: Sohbet Ara tıklandı');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matchedUsers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Henüz hiç eşleşmen yok.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _fetchMatches,
                    child: const Text('Eşleşmeleri Yenile'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _matchedUsers.length,
              itemBuilder: (context, index) {
                final matchedUser = _matchedUsers[index];
                final String name = matchedUser['name'] ?? 'Bilinmiyor';
                final String profileImageUrl =
                    matchedUser['profileImageUrl'] ??
                    'https://via.placeholder.com/150';
                // Son mesajı ve zaman damgasını ileride Firestore'dan çekip buraya ekleyeceğiz

                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(profileImageUrl),
                      backgroundColor: Colors.grey[200],
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'Son mesaj buraya gelecek...', // İleride gerçek son mesaj
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: Text(
                      'Şimdi', // İleride son mesajın zaman damgası
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    onTap: () => _onChatTapped(matchedUser),
                  ),
                );
              },
            ),
    );
  }
}
