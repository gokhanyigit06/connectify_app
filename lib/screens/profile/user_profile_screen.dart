// lib/src/screens/profile/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectify_app/screens/auth/welcome_screen.dart';
import 'package:connectify_app/screens/profile/profile_setup_screen.dart'; // Profili düzenle için (kullanılabilir)
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:connectify_app/screens/premium/premium_screen.dart'; // PremiumScreen import edildi (örnek kullanım için)

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userProfileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Kullanıcı profil verilerini Firestore'dan çeken fonksiyon
  Future<void> _fetchUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('UserProfileScreen: Kullanıcı giriş yapmamış.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (userDoc.exists) {
        setState(() {
          _userProfileData = userDoc.data() as Map<String, dynamic>;
        });
        debugPrint('UserProfileScreen: Profil verileri çekildi.');
      } else {
        debugPrint('UserProfileScreen: Profil verisi bulunamadı.');
        SnackBarService.showSnackBar(
          context,
          message: 'Profiliniz bulunamadı. Lütfen profilinizi oluşturun.',
          type: SnackBarType.info,
        );
      }
    } catch (e) {
      debugPrint('UserProfileScreen: Profil verileri çekilirken hata: $e');
      SnackBarService.showSnackBar(
        context,
        message: 'Profiliniz yüklenirken hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Profil alanını düzenleme diyalogu
  Future<void> _editField(
      BuildContext context, String fieldName, String currentValue,
      {TextInputType keyboardType = TextInputType.text}) async {
    TextEditingController controller =
        TextEditingController(text: currentValue);
    String? newValue = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${fieldName} Düzenle'),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: 'Yeni ${fieldName} girin'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal')),
          ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Kaydet')),
        ],
      ),
    );

    if (newValue != null && newValue.isNotEmpty && newValue != currentValue) {
      try {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({
          fieldName.toLowerCase(): (keyboardType == TextInputType.number)
              ? int.tryParse(newValue)
              : newValue,
        });
        _fetchUserProfile(); // Verileri yeniden çek
        SnackBarService.showSnackBar(context,
            message: '${fieldName} güncellendi!', type: SnackBarType.success);
      } catch (e) {
        SnackBarService.showSnackBar(context,
            message: '${fieldName} güncellenemedi: $e',
            type: SnackBarType.error);
      }
    }
  }

  // Cinsiyet seçimi diyalogu
  Future<void> _editGender(BuildContext context, String currentGender) async {
    String? newGender = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cinsiyet Seçimi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Kadın'),
              value: 'Kadın',
              groupValue: currentGender,
              onChanged: (value) => Navigator.pop(dialogContext, value),
            ),
            RadioListTile<String>(
              title: const Text('Erkek'),
              value: 'Erkek',
              groupValue: currentGender,
              onChanged: (value) => Navigator.pop(dialogContext, value),
            ),
            RadioListTile<String>(
              title: const Text('Belirtmek İstemiyorum'),
              value: 'Belirtmek İstemiyorum',
              groupValue: currentGender,
              onChanged: (value) => Navigator.pop(dialogContext, value),
            ),
          ],
        ),
      ),
    );

    if (newGender != null && newGender != currentGender) {
      try {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({'gender': newGender});
        _fetchUserProfile();
        SnackBarService.showSnackBar(context,
            message: 'Cinsiyet güncellendi!', type: SnackBarType.success);
      } catch (e) {
        SnackBarService.showSnackBar(context,
            message: 'Cinsiyet güncellenemedi: $e', type: SnackBarType.error);
      }
    }
  }

  // İlgi alanları düzenleme
  Future<void> _editInterests(
      BuildContext context, List<String> currentInterests) async {
    SnackBarService.showSnackBar(context,
        message: 'İlgi alanları düzenleme ekranı açılacak.',
        type: SnackBarType.info);
  }

  // Profilin tamamlanma yüzdesini hesaplar
  double _calculateProfileStrength() {
    if (_userProfileData == null) return 0.0;

    int completedFields = 0;
    int totalFields =
        10; // Örnek olarak saydığımız önemli alanlar (daha sonra detaylandırılabilir)

    if (_userProfileData!['profileImageUrl'] != null &&
        _userProfileData!['profileImageUrl'].isNotEmpty) completedFields++;
    if (_userProfileData!['name'] != null &&
        _userProfileData!['name'].isNotEmpty) completedFields++;
    if (_userProfileData!['age'] != null && _userProfileData!['age'] > 0)
      completedFields++;
    if (_userProfileData!['gender'] != null &&
        _userProfileData!['gender'].isNotEmpty) completedFields++;
    if (_userProfileData!['bio'] != null && _userProfileData!['bio'].isNotEmpty)
      completedFields++;
    if (_userProfileData!['interests'] != null &&
        _userProfileData!['interests'].isNotEmpty) completedFields++;
    if (_userProfileData!['work'] != null &&
        _userProfileData!['work'].isNotEmpty) completedFields++;
    if (_userProfileData!['education'] != null &&
        _userProfileData!['education'].isNotEmpty) completedFields++;
    if (_userProfileData!['location'] != null &&
        _userProfileData!['location'].isNotEmpty) completedFields++;
    if (_userProfileData!['height'] != null &&
        (_userProfileData!['height'] is int
            ? _userProfileData!['height'] > 0
            : false)) completedFields++; // int kontrolü eklendi

    return (completedFields / totalFields) * 100;
  }

  // Çıkış yapma fonksiyonu
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      SnackBarService.showSnackBar(
        context,
        message: 'Başarıyla çıkış yapıldı!',
        type: SnackBarType.success,
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Çıkış yapma hatası: $e');
      SnackBarService.showSnackBar(
        context,
        message: 'Çıkış yapılırken bir hata oluştu: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userProfileData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Profiliniz bulunamadı.',
              style: TextStyle(color: AppColors.primaryText),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileSetupScreen(),
                  ),
                );
              },
              child: const Text('Profili Oluştur'),
            ),
          ],
        ),
      );
    }

    final String name = _userProfileData!['name'] ?? 'Bilinmiyor';
    final int age = _userProfileData!['age'] ?? 0;
    final String gender = _userProfileData!['gender'] ?? 'Belirtilmedi';
    final String bio = _userProfileData!['bio'] ?? '';
    final String location = _userProfileData!['location'] ?? 'Belirtilmedi';
    final List<String> interests =
        List<String>.from(_userProfileData!['interests'] ?? []);
    final String profileImageUrl = _userProfileData!['profileImageUrl'] ??
        'https://placehold.co/150x150/CCCCCC/000000?text=Profil';
    final List<String> otherImageUrls =
        List<String>.from(_userProfileData!['otherImageUrls'] ?? []);
    final String work = _userProfileData!['work'] ?? '';
    final String education = _userProfileData!['education'] ?? '';
    final String hometown = _userProfileData!['hometown'] ?? '';
    final int height = _userProfileData!['height'] ?? 0;
    final String exercise = _userProfileData!['exercise'] ?? '';
    final String educationLevel = _userProfileData!['educationLevel'] ?? '';
    final String drinking = _userProfileData!['drinking'] ?? '';
    final String smoking = _userProfileData!['smoking'] ?? '';

    double profileStrength = _calculateProfileStrength();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: false,
        actions: [
          IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                SnackBarService.showSnackBar(context,
                    message: 'Profil paylaşım yakında!',
                    type: SnackBarType.info);
              }),
          IconButton(
              icon: const Icon(Icons.crop_free),
              onPressed: () {
                SnackBarService.showSnackBar(context,
                    message: 'Fotoğraf düzenleme yakında!',
                    type: SnackBarType.info);
              }),
          IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                SnackBarService.showSnackBar(context,
                    message: 'Ayarlar yakında!', type: SnackBarType.info);
              }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanıcı Adı ve Profil Gücü Başlığı
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(profileImageUrl),
                  backgroundColor: AppColors.grey.withOpacity(0.2),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    Text(
                      '${profileStrength.toStringAsFixed(0)}% complete',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Profil Gücü Barı
            GestureDetector(
              onTap: () {
                SnackBarService.showSnackBar(context,
                    message: 'Profil gücünü tamamlamak için alanları doldurun.',
                    type: SnackBarType.info);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.grey.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Profile strength',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: profileStrength / 100,
                            backgroundColor: AppColors.grey.withOpacity(0.3),
                            color: AppColors.accentPink,
                            minHeight: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.arrow_forward_ios,
                        size: 18, color: AppColors.secondaryText),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Fotoğraflar ve Videolar
            Text('Photos and videos',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (context, index) {
                  String? imageUrl;
                  if (index == 0) {
                    imageUrl = profileImageUrl;
                  } else if (index - 1 < otherImageUrls.length) {
                    imageUrl = otherImageUrls[index - 1];
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: () {
                        SnackBarService.showSnackBar(context,
                            message: 'Fotoğraf düzenleme/yükleme yakında!',
                            type: SnackBarType.info);
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.grey.withOpacity(0.3)),
                          image: imageUrl != null && imageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                  onError: (error, stackTrace) => debugPrint(
                                      'Resim yüklenirken hata: $error'),
                                )
                              : null,
                        ),
                        child: imageUrl == null || imageUrl.isEmpty
                            ? Center(
                                child: Icon(Icons.add_a_photo,
                                    color: AppColors.secondaryText, size: 40))
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),

            // İlgi Alanları
            _buildSectionHeader(
                context, 'Interests', () => _editInterests(context, interests)),
            const SizedBox(height: 12),
            interests.isEmpty
                ? _buildAddButton('Add your favorite interest',
                    () => _editInterests(context, interests))
                : Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: interests.map((interest) {
                      return Chip(
                        label: Text(interest),
                        backgroundColor: AppColors.accentPink.withOpacity(0.1),
                        labelStyle: TextStyle(
                            color: AppColors.accentPink,
                            fontWeight: FontWeight.bold),
                        deleteIcon: Icon(Icons.close,
                            size: 18, color: AppColors.accentPink),
                        onDeleted: () {
                          // TODO: İlgi alanını silme
                          SnackBarService.showSnackBar(context,
                              message: '$interest silindi!',
                              type: SnackBarType.info);
                        },
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 30),

            // Biyografi
            _buildSectionHeader(
                context, 'Bio', () => _editField(context, 'Bio', bio)),
            const SizedBox(height: 12),
            bio.isEmpty
                ? _buildAddButton('Write a fun and punchy intro',
                    () => _editField(context, 'Bio', bio))
                : Text(
                    bio,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
            const SizedBox(height: 30),

            // About you
            Text('About you',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow(context, Icons.work, 'Work', work,
                () => _editField(context, 'Work', work)),
            _buildInfoRow(context, Icons.school, 'Education', education,
                () => _editField(context, 'Education', education)),
            _buildInfoRow(context, Icons.person, 'Gender', gender,
                () => _editGender(context, gender)), // <<<--- İKON DÜZELTİLDİ
            _buildInfoRow(context, Icons.location_on, 'Location', location,
                () => _editField(context, 'Location', location)),
            _buildInfoRow(context, Icons.home, 'Hometown', hometown,
                () => _editField(context, 'Hometown', hometown)),
            const SizedBox(height: 30),

            // More about you
            Text('More about you',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
              'Cover the things most people are curious about.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
                context,
                Icons.height,
                'Height',
                height > 0 ? '$height cm' : '',
                () => _editField(context, 'Height', height.toString(),
                    keyboardType: TextInputType.number)),
            _buildInfoRow(context, Icons.fitness_center, 'Exercise', exercise,
                () => _editField(context, 'Exercise', exercise)),
            _buildInfoRow(
                context,
                Icons.cast_for_education,
                'Education level',
                educationLevel,
                () => _editField(context, 'Education level', educationLevel)),
            _buildInfoRow(context, Icons.wine_bar, 'Drinking', drinking,
                () => _editField(context, 'Drinking', drinking)),
            _buildInfoRow(context, Icons.smoking_rooms, 'Smoking', smoking,
                () => _editField(context, 'Smoking', smoking)),
            const SizedBox(height: 40),

            Center(
              child: ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: AppColors.white),
                label: const Text('Çıkış Yap',
                    style: TextStyle(color: AppColors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Yardımcı widget: Bölüm başlığı ve düzenle butonu
  Widget _buildSectionHeader(
      BuildContext context, String title, VoidCallback onEdit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        IconButton(
          icon: Icon(Icons.edit, color: AppColors.secondaryText),
          onPressed: onEdit,
        ),
      ],
    );
  }

  // Yardımcı widget: Bilgi satırı ve düzenle butonu
  Widget _buildInfoRow(BuildContext context, IconData icon, String label,
      String value, VoidCallback onEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onEdit,
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryText, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              value.isNotEmpty ? value : 'Add',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.secondaryText),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }

  // Yardımcı widget: Ekle butonu
  Widget _buildAddButton(String text, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.grey.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.primaryText),
            ),
            Icon(Icons.add, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }
}
