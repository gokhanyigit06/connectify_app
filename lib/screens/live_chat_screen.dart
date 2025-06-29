// lib/screens/live_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectify_app/screens/single_chat_screen.dart';
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:connectify_app/screens/premium/premium_screen.dart';

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isPremiumUser = false;
  bool _isSearching = false;
  String? _selectedGenderFilter;
  int? _minAgeFilter;
  int? _maxAgeFilter;
  TextEditingController _locationFilterController = TextEditingController();

  final List<String> _genders = ['Kadın', 'Erkek', 'Fark Etmez'];

  @override
  void initState() {
    super.initState();
    _checkUserPremiumStatus();
  }

  @override
  void dispose() {
    _locationFilterController.dispose();
    super.dispose();
  }

  Future<void> _checkUserPremiumStatus() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        setState(() {
          _isPremiumUser =
              (userDoc.data() as Map<String, dynamic>)['isPremium'] ?? false;
        });
        debugPrint('LiveChatScreen: Kullanıcı premium durumu: $_isPremiumUser');
      }
    } catch (e) {
      debugPrint('LiveChatScreen: Premium durumu çekilirken hata: $e');
    }
  }

  String _getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  Future<void> _startRandomChat() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    if (!_isPremiumUser) {
      SnackBarService.showSnackBar(
        context,
        message: 'Rastgele sohbet Premium özelliğidir.',
        type: SnackBarType.info,
        actionLabel: 'Premium Ol',
        onActionPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PremiumScreen(
                        message: 'Rastgele sohbet için Premium olun!',
                      )));
        },
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });
    debugPrint('LiveChatScreen: Rastgele sohbet aranıyor...');
    SnackBarService.showSnackBar(
      context,
      message: 'Sizin için bir eşleşme aranıyor...',
      type: SnackBarType.info,
      duration: const Duration(seconds: 5),
    );

    try {
      DocumentReference newSessionRef =
          await _firestore.collection('random_chat_sessions').add({
        'participant1Id': currentUser.uid,
        'participant2Id': null,
        'status': 'waiting',
        'startTime': FieldValue.serverTimestamp(),
        'filters': {
          'gender': _selectedGenderFilter,
          'minAge': _minAgeFilter,
          'maxAge': _maxAgeFilter,
          'location': _locationFilterController.text.trim().isNotEmpty
              ? _locationFilterController.text.trim()
              : null,
        },
      });
      debugPrint(
          'LiveChatScreen: Yeni sohbet oturumu oluşturuldu: ${newSessionRef.id}');

      _firestore
          .collection('random_chat_sessions')
          .where('status', isEqualTo: 'waiting')
          .where('participant1Id', isNotEqualTo: currentUser.uid)
          .snapshots()
          .listen((snapshot) async {
        if (_isSearching && snapshot.docs.isNotEmpty) {
          for (var doc in snapshot.docs) {
            final sessionData = doc.data() as Map<String, dynamic>;
            final Map<String, dynamic> filters =
                sessionData['filters'] as Map<String, dynamic>;

            bool genderMatch = _selectedGenderFilter == null ||
                _selectedGenderFilter == 'Fark Etmez' ||
                filters['gender'] == null ||
                filters['gender'] == 'Fark Etmez' ||
                filters['gender'] == _selectedGenderFilter;
            bool minAgeMatch = _minAgeFilter == null ||
                (filters['minAge'] == null ||
                    filters['minAge'] <= (_maxAgeFilter ?? 999));
            bool maxAgeMatch = _maxAgeFilter == null ||
                (filters['maxAge'] == null ||
                    filters['maxAge'] >= (_minAgeFilter ?? 0));
            bool locationMatch = _locationFilterController.text
                    .trim()
                    .isEmpty ||
                filters['location'] == null ||
                filters['location'] == _locationFilterController.text.trim();

            if (sessionData['participant2Id'] == null &&
                genderMatch &&
                minAgeMatch &&
                maxAgeMatch &&
                locationMatch) {
              await _firestore
                  .collection('random_chat_sessions')
                  .doc(doc.id)
                  .update({
                'participant2Id': currentUser.uid,
                'status': 'active',
              });
              debugPrint('LiveChatScreen: Eşleşme bulundu: ${doc.id}');
              setState(() {
                _isSearching = false;
              });

              final String otherUserUid = sessionData['participant1Id'];
              DocumentSnapshot matchedUserProfileDoc =
                  await _firestore.collection('users').doc(otherUserUid).get();

              if (matchedUserProfileDoc.exists) {
                // HATA DÜZELTİLDİ: matchedUserProfileDoc.data()'yı Map'e cast et
                final Map<String, dynamic>? matchedUserData =
                    matchedUserProfileDoc.data() as Map<String, dynamic>?;
                final matchedUserName =
                    matchedUserData?['name'] ?? 'Bilinmiyor';

                final chatId = _getChatId(currentUser.uid, otherUserUid);

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => SingleChatScreen(
                      chatId: chatId,
                      otherUserUid: otherUserUid,
                      otherUserName: matchedUserName,
                    ),
                  ),
                );
              } else {
                debugPrint(
                    'LiveChatScreen: Eşleşen kullanıcının profili bulunamadı.');
                SnackBarService.showSnackBar(context,
                    message: 'Eşleşme bulundu ancak profil yüklenemedi.',
                    type: SnackBarType.error);
              }
              return;
            }
          }
        }
      });

      Future.delayed(const Duration(seconds: 10), () {
        if (_isSearching) {
          setState(() {
            _isSearching = false;
          });
          debugPrint('LiveChatScreen: Eşleşme zaman aşımına uğradı.');
          SnackBarService.showSnackBar(
            context,
            message: 'Eşleşme bulunamadı. Lütfen tekrar deneyin.',
            type: SnackBarType.info,
          );
          newSessionRef.update({'status': 'timed_out'});
        }
      });
    } catch (e) {
      debugPrint('LiveChatScreen: Rastgele sohbet başlatılırken hata: $e');
      SnackBarService.showSnackBar(
        context,
        message: 'Rastgele sohbet başlatılamadı: ${e.toString()}',
        type: SnackBarType.error,
      );
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _upgradeToPremium() {
    debugPrint('LiveChatScreen: Premium\'a yükselt tıklandı.');
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PremiumScreen(
                  message: 'Rastgele sohbet için Premium olun!',
                )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Canlı Sohbet')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Rastgele kişilerle anında sohbet et!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              if (!_isPremiumUser) ...[
                Text(
                  'Bu özellik Connectify Premium üyelerine özeldir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _upgradeToPremium,
                  icon: const Icon(
                    Icons.star,
                    color: AppColors.black,
                  ),
                  label: const Text('Premium Ol'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                  ),
                ),
                const SizedBox(height: 30),
              ],
              AbsorbPointer(
                absorbing: !_isPremiumUser,
                child: Opacity(
                  opacity: _isPremiumUser ? 1.0 : 0.4,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedGenderFilter,
                        decoration: InputDecoration(
                          labelText: 'Cinsiyet',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        hint: const Text('Aradığın cinsiyet'),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedGenderFilter = newValue;
                          });
                        },
                        items: _genders.map((String gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Min Yaş',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onChanged: (value) {
                                _minAgeFilter = int.tryParse(value);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Max Yaş',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onChanged: (value) {
                                _maxAgeFilter = int.tryParse(value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationFilterController,
                        decoration: InputDecoration(
                          labelText: 'Konum (Şehir)',
                          hintText: 'Örn: Ankara',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              _isSearching
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _startRandomChat,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Text(
                          _isPremiumUser
                              ? 'Rastgele Sohbet Başlat'
                              : 'Premium Ol',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPremiumUser
                            ? AppColors.primaryYellow
                            : AppColors.grey,
                        foregroundColor:
                            _isPremiumUser ? AppColors.black : AppColors.white,
                      ),
                    ),
              const SizedBox(height: 20),
              if (_isSearching)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                    });
                    debugPrint('LiveChatScreen: Sohbet araması iptal edildi.');
                    SnackBarService.showSnackBar(
                      context,
                      message: 'Sohbet araması iptal edildi.',
                      type: SnackBarType.info,
                    );
                  },
                  child: Text(
                    'Aramayı İptal Et',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
