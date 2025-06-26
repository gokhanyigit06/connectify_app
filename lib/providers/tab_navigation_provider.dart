import 'package:flutter/material.dart';

class TabNavigationProvider extends ChangeNotifier {
  int _currentIndex = 1; // Başlangıçta Keşfet (index 1) seçili

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners(); // Dinleyen widget'ları güncelle
    }
  }
}
