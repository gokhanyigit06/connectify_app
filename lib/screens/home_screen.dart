import 'package:flutter/material.dart';
import 'package:connectify_app/screens/profile/user_profile_screen.dart';
import 'package:connectify_app/screens/discover_screen.dart';
import 'package:connectify_app/screens/people_screen.dart';
import 'package:connectify_app/screens/liked_you_screen.dart';
import 'package:connectify_app/screens/chats_screen.dart';
import 'package:connectify_app/screens/live_chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:connectify_app/providers/tab_navigation_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // _selectedIndex artık doğrudan state tarafından yönetilmeyecek, Provider tarafından yönetilecek.
  // int _selectedIndex = 1;

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
          body: IndexedStack(
            // Burası değiştirildi: IndexedStack kullanılıyor
            index: tabProvider.currentIndex, // Aktif sekmeyi belirle
            children: _widgetOptions, // Tüm ekran widget'larını içer
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore),
                label: 'Keşfet',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group_outlined),
                activeIcon: Icon(Icons.group),
                label: 'İnsanlar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                activeIcon: Icon(Icons.favorite),
                label: 'Beğenenler',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Sohbetler',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.flash_on_outlined),
                activeIcon: Icon(Icons.flash_on),
                label: 'Canlı Sohbet',
              ),
            ],
            currentIndex:
                tabProvider.currentIndex, // Indexi provider'dan alıyoruz
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
            onTap: (index) => _onItemTapped(index, tabProvider),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
          ),
        );
      },
    );
  }
}
