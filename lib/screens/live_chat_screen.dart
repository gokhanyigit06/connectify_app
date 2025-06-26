import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectify_app/screens/single_chat_screen.dart'; // Sohbet başlatmak için
import 'package:connectify_app/screens/home_screen.dart'; // Premium'a yönlendirme için (şimdilik)
import 'package:connectify_app/services/snackbar_service.dart'; // SnackBarService import edildi
import 'package:connectify_app/utils/app_colors.dart'; // Renk paletimiz için

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
  TextEditingController _locationFilterController =
      TextEditingController(); // Yeni: Konum filtresi controller

  // Cinsiyet seçenekleri
  final List<String> _genders = ['Kadın', 'Erkek', 'Fark Etmez'];

  @override
  void initState() {
    super.initState();
    _checkUserPremiumStatus();
  }

  @override
  void dispose() {
    _locationFilterController.dispose(); // Controller'ı dispose et
    super.dispose();
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
      SnackBarService.showSnackBar(
        context,
        message: 'Rastgele sohbet Premium özelliğidir.',
        type: SnackBarType.info,
      );
      _upgradeToPremium();
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
      // 1. Yeni bir sohbet oturumu oluştur (bekleme modunda)
      DocumentReference newSessionRef = await _firestore
          .collection('random_chat_sessions')
          .add({
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
                  : null, // Yeni: Konum filtresi eklendi
            },
          });
      debugPrint(
        'LiveChatScreen: Yeni sohbet oturumu oluşturuldu: ${newSessionRef.id}',
      );

      // 2. Diğer kullanıcıları dinle veya bir eşleşme bulmaya çalış
      // Bu kısım normalde bir Cloud Function veya backend tarafından yönetilir.
      // Şimdilik basit bir simülasyon yapalım:
      // Sürekli olarak 'waiting' durumundaki oturumları dinle ve eşleşme olunca yönlendir.
      // Firestore dinleme için Cloud Function tarafında filtreleme daha verimli olacaktır.
      // Arama mantığı karmaşıklaşabilir, gerçek bir uygulama için Cloud Functions kullanılması önerilir.
      _firestore
          .collection('random_chat_sessions')
          .where('status', isEqualTo: 'waiting')
          .where('participant1Id', isNotEqualTo: currentUser.uid)
          .snapshots()
          .listen((snapshot) async {
            if (_isSearching && snapshot.docs.isNotEmpty) {
              for (var doc in snapshot.docs) {
                // Sadece eşleşmemiş ve mevcut filtrelerle uyumlu oturumları bul
                bool genderMatch =
                    _selectedGenderFilter == null ||
                    _selectedGenderFilter == 'Fark Etmez' ||
                    doc['filters']['gender'] == null ||
                    doc['filters']['gender'] == 'Fark Etmez' ||
                    doc['filters']['gender'] == _selectedGenderFilter;
                bool minAgeMatch =
                    _minAgeFilter == null ||
                    (doc['filters']['minAge'] == null ||
                        doc['filters']['minAge'] <=
                            _maxAgeFilter!); // Karşıdaki kişinin yaşı bizim aralığımızdaysa
                bool maxAgeMatch =
                    _maxAgeFilter == null ||
                    (doc['filters']['maxAge'] == null ||
                        doc['filters']['maxAge'] >=
                            _minAgeFilter!); // Karşıdaki kişinin yaşı bizim aralığımızdaysa
                bool locationMatch =
                    _locationFilterController.text.trim().isEmpty ||
                    doc['filters']['location'] == null ||
                    doc['filters']['location'] ==
                        _locationFilterController.text.trim();

                if (doc['participant2Id'] == null &&
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
                    SnackBarService.showSnackBar(
                      context,
                      message: 'Eşleşme bulundu ancak profil yüklenemedi.',
                      type: SnackBarType.error,
                    );
                  }
                  return;
                }
              }
            }
          });

      // Eğer eşleşme bulunamazsa veya timeout olursa: (Cloud Function yönetir)
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
    SnackBarService.showSnackBar(
      context,
      message: 'Premium yükseltme ekranı buraya gelecek.',
      type: SnackBarType.info,
    );
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
                Text(
                  'Bu özellik Connectify Premium üyelerine özeldir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.red,
                  ), // Renk paletinden
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _upgradeToPremium,
                  icon: const Icon(
                    Icons.star,
                    color: AppColors.black,
                  ), // Renk paletinden
                  label: const Text('Premium Ol'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow, // Renk paletinden
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // Filtre Seçenekleri (Premium ise aktif)
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
                      const SizedBox(
                        height: 16,
                      ), // Yeni: Konum alanı öncesi boşluk
                      TextFormField(
                        // Yeni Konum Filtresi Alanı
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
                            ? AppColors
                                  .primaryYellow // Renk paletinden
                            : AppColors
                                  .grey, // Premium değilse gri (Renk paletinden)
                        foregroundColor: _isPremiumUser
                            ? AppColors
                                  .black // Renk paletinden
                            : AppColors.white, // Renk paletinden
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
                    SnackBarService.showSnackBar(
                      context,
                      message: 'Sohbet araması iptal edildi.',
                      type: SnackBarType.info,
                    );
                    // Oluşturulan oturumu temizle veya durumunu değiştir (Cloud Function yönetir)
                  },
                  child: Text(
                    'Aramayı İptal Et',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                    ), // Renk paletinden
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
