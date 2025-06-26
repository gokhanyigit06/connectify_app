import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth olarak düzeltildi
import 'package:connectify_app/screens/single_chat_screen.dart';
import 'package:connectify_app/widgets/empty_state_widget.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:connectify_app/providers/tab_navigation_provider.dart';
import 'package:connectify_app/services/snackbar_service.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Hata düzeltmesi: FirebaseAueth -> FirebaseAuth

  bool _isLoading = false;
  List<Map<String, dynamic>> _matchedUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

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
      matchedUids = matchedUids.toSet().toList();

      if (matchedUids.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('ChatsScreen: Hiç eşleşme bulunamadı.');
        return;
      }

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
      SnackBarService.showSnackBar(
        context,
        message: 'Eşleşmeleri yüklerken hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
            icon: const Icon(Icons.search),
            onPressed: () {
              debugPrint('ChatsScreen: Sohbet Ara tıklandı');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matchedUsers.isEmpty
          ? EmptyStateWidget(
              icon: Icons.chat_bubble_outline,
              title: 'Henüz Kimseyle Eşleşmedin',
              description:
                  'Sohbet etmek için yeni eşleşmeler bulman gerekiyor! Keşfet ekranına giderek yeni kişilerle tanışmaya ne dersin?',
              buttonText: 'Keşfetmeye Başla',
              onButtonPressed: () {
                Provider.of<TabNavigationProvider>(
                  context,
                  listen: false,
                ).setIndex(1);
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _matchedUsers.length,
              itemBuilder: (context, index) {
                final matchedUser = _matchedUsers[index];
                final String name = matchedUser['name'] ?? 'Bilinmiyor';
                final String profileImageUrl =
                    matchedUser['profileImageUrl'] ??
                    'https://placehold.co/150x150/CCCCCC/000000?text=Profil';
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
                      'Son mesaj buraya gelecek...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                    trailing: Text(
                      'Şimdi',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    onTap: () => _onChatTapped(matchedUser),
                  ),
                );
              },
            ),
    );
  }
}
