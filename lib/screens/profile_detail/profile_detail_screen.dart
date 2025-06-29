// lib/src/screens/profile_detail/profile_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:connectify_app/services/snackbar_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Callback'ler için typedef
typedef ProfileInteractionCallback = void Function(String userId);
typedef ComplimentCallback = void Function(String userId, String comment);

class ProfileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final ProfileInteractionCallback? onLike;
  final ProfileInteractionCallback? onPass;
  final ProfileInteractionCallback? onSuperLike;
  final ComplimentCallback? onCompliment;

  const ProfileDetailScreen({
    Key? key,
    required this.userData,
    this.onLike,
    this.onPass,
    this.onSuperLike,
    this.onCompliment,
  }) : super(key: key);

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _complimentController = TextEditingController();

  String get _fullName => widget.userData['name'] ?? 'Bilinmeyen Kullanıcı';
  int get _age => widget.userData['age'] ?? 0;
  String? get _bio => widget.userData['bio'];
  List<String>? get _interests => (widget.userData['interests'] as List?)
      ?.map((e) => e.toString())
      .toList();
  String? get _location => widget.userData['location'];
  String? get _profilePictureUrl => widget.userData['profileImageUrl'];
  List<String>? get _otherPictureUrls =>
      (widget.userData['otherImageUrls'] as List?)
          ?.map((e) => e.toString())
          .toList();
  bool get _isVerified => widget.userData['isVerified'] ?? false;
  String get _targetUserId => widget.userData['uid'] ?? '';

  @override
  void dispose() {
    _complimentController.dispose();
    super.dispose();
  }

  void _showComplimentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Özel Yorum Gönder'),
          content: TextField(
            controller: _complimentController,
            decoration: const InputDecoration(
              // const ekledik
              hintText: 'Yorumunuzu buraya yazın...',
              border: OutlineInputBorder(),
            ),
            maxLength: 100,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _complimentController.clear();
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_complimentController.text.trim().isNotEmpty) {
                  widget.onCompliment
                      ?.call(_targetUserId, _complimentController.text.trim());
                  Navigator.pop(dialogContext);
                  _complimentController.clear();
                } else {
                  SnackBarService.showSnackBar(dialogContext,
                      message: 'Yorum boş olamaz!', type: SnackBarType.error);
                }
              },
              child: const Text('Gönder'),
            ),
          ],
        ); // <<<--- EKSİK OLAN KAPANIŞ PARANTEZİ BURADAYDI
      }, // <<<--- EKSİK OLAN KAPANIŞ SÜSLÜ PARANTEZ BURADAYDI
    ); // <<<--- EKSİK OLAN KAPANIŞ PARANTEZ BURADAYDI
  }

  // --- Rapolama Diyalog Metodu ---
  void _showReportDialog(BuildContext context) {
    // Bu metot daha önce doğru görünüyordu, ama yine de kod bloklarını düzgün bir şekilde kapatmak için buraya ekleyelim.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Bildir'),
        content: const Text(
            'Bu kullanıcıyı uygunsuz davranış veya içerik nedeniyle bildirdiğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentUser = _auth.currentUser;
              if (currentUser != null) {
                try {
                  await _firestore.collection('reports').add({
                    'reporterId': currentUser.uid,
                    'reportedUserId': _targetUserId,
                    'reason': 'Genel Uygunsuzluk (Detaylandırılabilecek)',
                    'timestamp': FieldValue.serverTimestamp(),
                    'status': 'pending',
                  });
                  SnackBarService.showSnackBar(context,
                      message: 'Kullanıcı bildirildi. Teşekkür ederiz!',
                      type: SnackBarType.success);
                  Navigator.pop(context);
                  Navigator.pop(context);
                } catch (e) {
                  SnackBarService.showSnackBar(context,
                      message:
                          'Bildirim gönderilirken hata oluştu: ${e.toString()}',
                      type: SnackBarType.error);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child:
                const Text('Bildir', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }
  // --- Rapolama Diyalog Metodu Sonu ---

  @override
  Widget build(BuildContext context) {
    List<String> allPictures = [];
    if (_profilePictureUrl != null) {
      allPictures.add(_profilePictureUrl!);
    }
    if (_otherPictureUrls != null) {
      allPictures.addAll(_otherPictureUrls!);
    }

    List<String> lookingForList = (widget.userData['lookingFor'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        ['Belirtilmemiş'];
    String aboutMe = _bio ?? 'Henüz bir biyografi eklemedi.';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          if (widget.onSuperLike != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: AppColors.white.withOpacity(0.2),
                child: IconButton(
                  icon: const Icon(Icons.star, color: AppColors.primaryYellow),
                  onPressed: () {
                    widget.onSuperLike?.call(_targetUserId);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(
              context,
              allPictures.isNotEmpty
                  ? allPictures[0]
                  : 'https://via.placeholder.com/400x500?text=No+Image',
              _fullName,
              _age,
              _isVerified,
              _location,
              aboutMe,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aradığım Kişi',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: lookingForList
                        .map((text) => _buildLookingForChip(text))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'İlgi Alanlarım',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _interests
                            ?.map((interest) => Chip(
                                  label: Text(interest),
                                  backgroundColor:
                                      AppColors.accentPink.withOpacity(0.1),
                                  labelStyle: TextStyle(
                                      color: AppColors.accentPink,
                                      fontWeight: FontWeight.bold),
                                  side: BorderSide(
                                      color: AppColors.accentPink, width: 0.5),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                ))
                            .toList() ??
                        [],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            for (int i = 1; i < allPictures.length; i++)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSection(
                    context,
                    allPictures[i],
                    '',
                    0,
                    false,
                    null,
                    null,
                    showGradient: false,
                  ),
                  const SizedBox(height: 20),
                  if (i == 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tutkum',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.userData['passion'] ??
                                'Henüz bir tutku eklemedi.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 18, color: AppColors.secondaryText),
                        const SizedBox(width: 5),
                        Text(
                          _location ?? 'Konum Belirtilmemiş',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(Icons.close, AppColors.red, () {
                    widget.onPass?.call(_targetUserId);
                    Navigator.pop(context);
                  }),
                  _buildActionButton(Icons.star, AppColors.primaryYellow, () {
                    widget.onSuperLike?.call(_targetUserId);
                    Navigator.pop(context);
                  }),
                  _buildActionButton(Icons.check, AppColors.accentTeal, () {
                    widget.onLike?.call(_targetUserId);
                    Navigator.pop(context);
                  }),
                ],
              ),
            ),
            if (widget.onCompliment != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _showComplimentDialog(context),
                    icon: Icon(Icons.message, color: AppColors.accentPink),
                    label: Text('Özel Yorum Gönder',
                        style: TextStyle(color: AppColors.primaryText)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 0.5), // <<<--- BURASI DÜZELTİLDİ
                      elevation: 2,
                    ),
                  ),
                ),
              ),
            Center(
              child: Column(
                children: [
                  TextButton(
                    onPressed: () {
                      _showReportDialog(context);
                    },
                    child: Text(
                      'Gizle ve Bildir',
                      style: TextStyle(
                          color: AppColors.secondaryText,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      SnackBarService.showSnackBar(context,
                          message: 'Arkadaşına tavsiye edildi!',
                          type: SnackBarType.info);
                    },
                    child: Text(
                      'Arkadaşına Tavsiye Et',
                      style: TextStyle(
                          color: AppColors.secondaryText,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context, String imageUrl, String name,
      int age, bool isVerified, String? location, String? bio,
      {bool showGradient = true}) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            debugPrint('Resim yüklenirken hata: $exception');
          },
        ),
      ),
      child: Stack(
        children: [
          if (showGradient)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          if (name.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$name, $age',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 8),
                      if (isVerified)
                        const Icon(Icons.check_circle,
                            color: AppColors.blue, size: 24),
                    ],
                  ),
                  if (location != null && location.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: AppColors.white, size: 18),
                          const SizedBox(width: 5),
                          Text(
                            location,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: AppColors.white),
                          ),
                        ],
                      ),
                    ),
                  if (bio != null && bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        bio,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.white.withOpacity(0.8)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          Positioned(
            bottom: 20,
            right: 20,
            child: CircleAvatar(
              backgroundColor: AppColors.primaryYellow,
              radius: 25,
              child: IconButton(
                icon: const Icon(Icons.star, color: AppColors.white, size: 30),
                onPressed: () {
                  widget.onSuperLike?.call(_targetUserId);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLookingForChip(String text) {
    return Chip(
      label: Text(text),
      backgroundColor: AppColors.background,
      labelStyle:
          TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
      side: BorderSide(
          color: Colors.grey.shade300, width: 0.5), // <<<--- BURASI DÜZELTİLDİ
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildActionButton(
      IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 30),
        padding: const EdgeInsets.all(18),
        onPressed: onPressed,
      ),
    );
  }
}
