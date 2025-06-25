import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectify_app/screens/single_chat_screen.dart'; // Sohbet başlatmak için
import 'package:connectify_app/screens/home_screen.dart'; // Premium'a yönlendirme için (şimdilik)

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isPremiumUser = false; // Kullanıcının premium durumu
  bool _isSearching = false; // Eşleşme aranıyor mu
  String? _selectedGenderFilter; // Filtreler
  int? _minAgeFilter;
  int? _maxAgeFilter;

  // Cinsiyet seçenekleri
  final List<String> _genders = ['Kadın', 'Erkek', 'Fark Etmez'];

  @override
  void initState() {
    super.initState();
    _checkUserPremiumStatus();
  }

  // Kullanıcının premium durumunu Firestore'dan çek
  Future<void> _checkUserPremiumStatus() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
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

  // Rastgele sohbet başlatma fonksiyonu
  Future<void> _startRandomChat() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    if (!_isPremiumUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rastgele sohbet Premium özelliğidir.')),
      );
      _upgradeToPremium();
      return;
    }

    setState(() {
      _isSearching = true;
    });
    debugPrint('LiveChatScreen: Rastgele sohbet aranıyor...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sizin için bir eşleşme aranıyor...')),
    );

    try {
      // 1. Yeni bir sohbet oturumu oluştur (bekleme modunda)
      DocumentReference
      newSessionRef = await _firestore.collection('random_chat_sessions').add({
        'participant1Id': currentUser.uid,
        'participant2Id': null, // İkinci kullanıcı bulunduğunda doldurulacak
        'status': 'waiting', // waiting, active, ended
        'startTime': FieldValue.serverTimestamp(),
        'filters': {
          // Kullanıcının seçtiği filtreleri kaydet
          'gender': _selectedGenderFilter,
          'minAge': _minAgeFilter,
          'maxAge': _maxAgeFilter,
          // İleride konum filtresi de eklenecek
        },
      });
      debugPrint(
        'LiveChatScreen: Yeni sohbet oturumu oluşturuldu: ${newSessionRef.id}',
      );

      // 2. Diğer kullanıcıları dinle veya bir eşleşme bulmaya çalış
      // Bu kısım normalde bir Cloud Function veya backend tarafından yönetilir.
      // Şimdilik basit bir simülasyon yapalım:
      // Sürekli olarak 'waiting' durumundaki oturumları dinle ve eşleşme olunca yönlendir.
      _firestore
          .collection('random_chat_sessions')
          .where('status', isEqualTo: 'waiting')
          .where(
            'participant1Id',
            isNotEqualTo: currentUser.uid,
          ) // Kendi oturumumuzu atla
          // Filtreleri burada Cloud Function uygular
          .snapshots()
          .listen((snapshot) async {
            if (_isSearching && snapshot.docs.isNotEmpty) {
              // Uygun bir oturum bulundu, bu oturuma katıl
              for (var doc in snapshot.docs) {
                if (doc['participant2Id'] == null) {
                  // Henüz eşleşmemiş bir oturum bul
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
                  // Eşleşen kullanıcının profilini çekip sohbet ekranına yönlendir
                  DocumentSnapshot matchedUserProfile = await _firestore
                      .collection('users')
                      .doc(doc['participant1Id'])
                      .get();
                  if (matchedUserProfile.exists) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => SingleChatScreen(
                          matchedUser:
                              matchedUserProfile.data() as Map<String, dynamic>,
                        ),
                      ),
                    );
                  } else {
                    debugPrint(
                      'LiveChatScreen: Eşleşen kullanıcının profili bulunamadı.',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Eşleşme bulundu ancak profil yüklenemedi.',
                        ),
                      ),
                    );
                  }
                  return; // Sadece bir oturuma katıl
                }
              }
            }
          });

      // Eğer eşleşme bulunamazsa veya timeout olursa: (Cloud Function yönetir)
      // Şimdilik 10 saniye sonra zaman aşımına uğramış gibi yapalım
      Future.delayed(const Duration(seconds: 10), () {
        if (_isSearching) {
          setState(() {
            _isSearching = false;
          });
          debugPrint('LiveChatScreen: Eşleşme zaman aşımına uğradı.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Eşleşme bulunamadı. Lütfen tekrar deneyin.'),
            ),
          );
          // Oluşturulan oturumu sil veya durumunu 'timed_out' yap
          newSessionRef.update({'status': 'timed_out'});
        }
      });
    } catch (e) {
      debugPrint('LiveChatScreen: Rastgele sohbet başlatılırken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rastgele sohbet başlatılamadı: $e')),
      );
      setState(() {
        _isSearching = false;
      });
    }
  }

  // Premium'a yükseltme butonu tıklandığında
  void _upgradeToPremium() {
    debugPrint('LiveChatScreen: Premium\'a yükselt tıklandı.');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Premium yükseltme ekranı buraya gelecek.')),
    );
    // Buraya Premium satın alma ekranına yönlendirme gelecek
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

              // Premium Değilse Uyarı
              if (!_isPremiumUser) ...[
                const Text(
                  'Bu özellik Connectify Premium üyelerine özeldir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _upgradeToPremium,
                  icon: const Icon(Icons.star, color: Colors.black),
                  label: const Text('Premium Ol'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // Filtre Seçenekleri (Premium ise aktif)
              AbsorbPointer(
                // Premium değilse dokunmaları engelle
                absorbing: !_isPremiumUser,
                child: Opacity(
                  // Premium değilse soluk göster
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
                      // Yaş filtresi için basit TextFields (ileride RangeSlider olabilir)
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
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              // Sohbet Başlat Butonu
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
                            ? Theme.of(context).primaryColor
                            : Colors.grey, // Premium değilse gri
                      ),
                    ),
              const SizedBox(height: 20),
              // Sohbeti iptal et butonu (sadece aranırken)
              if (_isSearching)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                    });
                    debugPrint('LiveChatScreen: Sohbet araması iptal edildi.');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sohbet araması iptal edildi.'),
                      ),
                    );
                    // Oluşturulan oturumu temizle veya durumunu değiştir (Cloud Function yönetir)
                  },
                  child: const Text('Aramayı İptal Et'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
