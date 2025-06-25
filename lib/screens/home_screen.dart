import 'package:flutter/material.dart';
import 'package:connectify_app/screens/profile/user_profile_screen.dart';
import 'package:connectify_app/screens/discover_screen.dart'; // Yeni DiscoverScreen
import 'package:connectify_app/screens/people_screen.dart'; // Yeni PeopleScreen
import 'package:connectify_app/screens/liked_you_screen.dart'; // Yeni LikedYouScreen
import 'package:connectify_app/screens/chats_screen.dart'; // Yeni ChatsScreen
import 'package:connectify_app/screens/live_chat_screen.dart'; // Yeni LiveChatScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex =
      1; // Başlangıçta Keşfet (Discover) sekmesi seçili (index 1)

  // Alt navigasyon çubuğundaki her bir sekme için widget listesi
  static final List<Widget> _widgetOptions = <Widget>[
    const UserProfileScreen(), // 0. index: Profil
    const DiscoverScreen(), // 1. index: Keşfet (Varsayılan olarak bu açılacak)
    const PeopleScreen(), // 2. index: İnsanlar
    const LikedYouScreen(), // 3. index: Seni Beğenenler
    const ChatsScreen(), // 4. index: Sohbetler
    const LiveChatScreen(), // 5. index: Canlı Sohbet
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar her sekme için kendi içinde olacak, bu yüzden burada bir AppBar yok
      // (DiscoverScreen'in kendi AppBar'ı var mesela)
      body: Center(
        child: _widgetOptions.elementAt(
          _selectedIndex,
        ), // Seçili sekmenin içeriğini göster
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: 'Keşfet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            label: 'İnsanlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            label: 'Beğenenler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Sohbetler',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.auto_awesome_outlined,
            ), // Canlı sohbet veya rastgele ikon
            label: 'Canlı Sohbet',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(
          context,
        ).primaryColor, // Seçili öğenin rengi
        unselectedItemColor: Colors.grey, // Seçili olmayan öğelerin rengi
        onTap: _onItemTapped,
        type: BottomNavigationBarType
            .fixed, // Tüm öğelerin görünür kalmasını sağlar
        backgroundColor: Colors.white,
      ),
    );
  }
}
