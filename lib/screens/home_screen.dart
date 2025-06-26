import 'package:flutter/material.dart';
import 'package:connectify_app/screens/profile/user_profile_screen.dart';
import 'package:connectify_app/screens/discover_screen.dart';
import 'package:connectify_app/screens/people_screen.dart';
import 'package:connectify_app/screens/liked_you_screen.dart';
import 'package:connectify_app/screens/chats_screen.dart';
import 'package:connectify_app/screens/live_chat_screen.dart';
import 'package:provider/provider.dart'; // Provider paketi import edildi
import 'package:connectify_app/providers/tab_navigation_provider.dart'; // Yeni provider import edildi

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // _selectedIndex artık doğrudan state tarafından yönetilmeyecek, Provider tarafından yönetilecek.
  // int _selectedIndex = 1; // Bu satırı yorum satırı yapın veya silin

  // Alt navigasyon çubuğundaki her bir sekme için widget listesi
  static final List<Widget> _widgetOptions = <Widget>[
    const UserProfileScreen(), // 0. index: Profil
    const DiscoverScreen(), // 1. index: Keşfet (Varsayılan olarak bu açılacak)
    const PeopleScreen(), // 2. index: İnsanlar
    const LikedYouScreen(), // 3. index: Seni Beğenenler
    const ChatsScreen(), // 4. index: Sohbetler
    const LiveChatScreen(), // 5. index: Canlı Sohbet
  ];

  // _onItemTapped fonksiyonu artık TabNavigationProvider'ın setIndex metodunu çağıracak
  void _onItemTapped(int index, TabNavigationProvider provider) {
    provider.setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    // TabNavigationProvider'ı dinliyoruz
    return Consumer<TabNavigationProvider>(
      builder: (context, tabProvider, child) {
        return Scaffold(
          body: Center(
            child: _widgetOptions.elementAt(
              tabProvider.currentIndex, // Indexi provider'dan alıyoruz
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), // Profil için çizgili ikon
                activeIcon: Icon(Icons.person), // Seçildiğinde dolu ikon
                label: 'Profil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined), // Keşfet için çizgili ikon
                activeIcon: Icon(Icons.explore), // Seçildiğinde dolu ikon
                label: 'Keşfet',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group_outlined), // İnsanlar için çizgili ikon
                activeIcon: Icon(Icons.group), // Seçildiğinde dolu ikon
                label: 'İnsanlar',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.favorite_border,
                ), // Beğenenler için çizgili ikon
                activeIcon: Icon(Icons.favorite), // Seçildiğinde dolu ikon
                label: 'Beğenenler',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.chat_bubble_outline,
                ), // Sohbetler için çizgili ikon
                activeIcon: Icon(Icons.chat_bubble), // Seçildiğinde dolu ikon
                label: 'Sohbetler',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.flash_on_outlined,
                ), // Canlı Sohbet için çizgili ikon (Parlaklık, hız)
                activeIcon: Icon(Icons.flash_on), // Seçildiğinde dolu ikon
                label: 'Canlı Sohbet',
              ),
            ],
            currentIndex:
                tabProvider.currentIndex, // Indexi provider'dan alıyoruz
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
            onTap: (index) =>
                _onItemTapped(index, tabProvider), // provider'ı da gönderiyoruz
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
          ),
        );
      },
    );
  }
}
