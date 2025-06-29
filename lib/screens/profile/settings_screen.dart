import 'package:flutter/material.dart';
import 'package:connectify_app/utils/app_colors.dart';
import 'package:connectify_app/services/snackbar_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Genel Ayarlar',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              title: 'Dil Seçimi',
              subtitle: 'Uygulama dilini değiştir',
              onTap: () {
                SnackBarService.showSnackBar(context,
                    message: 'Dil seçimi yakında!', type: SnackBarType.info);
              },
              icon: Icons.language,
            ),
            _buildSettingTile(
              title: 'Bildirimler',
              subtitle: 'Bildirim ayarlarını yönet',
              onTap: () {
                SnackBarService.showSnackBar(context,
                    message: 'Bildirim ayarları yakında!',
                    type: SnackBarType.info);
              },
              icon: Icons.notifications,
            ),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Hesap Ayarları',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              title: 'Hesabı Sil',
              subtitle: 'Hesabınızı kalıcı olarak silin',
              onTap: () {
                SnackBarService.showSnackBar(context,
                    message: 'Hesap silme özelliği yakında!',
                    type: SnackBarType.info);
              },
              icon: Icons.delete_forever,
              iconColor: AppColors.red,
            ),
            const Divider(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
      {required String title,
      required String subtitle,
      required VoidCallback onTap,
      required IconData icon,
      Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.secondaryText),
      title: Text(title, style: TextStyle(color: AppColors.primaryText)),
      subtitle:
          Text(subtitle, style: TextStyle(color: AppColors.secondaryText)),
      trailing: Icon(Icons.arrow_forward_ios, color: AppColors.secondaryText),
      onTap: onTap,
    );
  }
}
