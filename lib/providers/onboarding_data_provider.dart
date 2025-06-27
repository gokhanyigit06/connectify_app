import 'package:flutter/material.dart';
import 'dart:io'; // File tipini kullanabilmek için

class OnboardingDataProvider extends ChangeNotifier {
  String _name = '';
  DateTime? _dateOfBirth;
  String? _gender;
  String _location = '';
  String _bio = ''; // Yeni: Biyografi alanı
  List<String> _interests = [];
  File? _profileImageFile;
  List<File> _otherImageFiles =
      []; // Geçici olarak yeni eklenen resim dosyaları

  // Getter'lar
  String get name => _name;
  DateTime? get dateOfBirth => _dateOfBirth;
  String? get gender => _gender;
  String get location => _location;
  String get bio => _bio; // Yeni: Biyografi getter
  List<String> get interests => List.unmodifiable(_interests);
  File? get profileImageFile => _profileImageFile;
  List<File> get otherImageFiles => List.unmodifiable(_otherImageFiles);

  // Setter'lar ve Notifier
  void setName(String name) {
    _name = name;
    notifyListeners();
  }

  void setDateOfBirth(DateTime dateOfBirth) {
    _dateOfBirth = dateOfBirth;
    notifyListeners();
  }

  void setGender(String? gender) {
    _gender = gender;
    notifyListeners();
  }

  void setLocation(String location) {
    _location = location;
    notifyListeners();
  }

  void setBio(String bio) {
    // Yeni: Biyografi setter
    _bio = bio;
    notifyListeners();
  }

  void setInterests(List<String> interests) {
    _interests = List.from(interests);
    notifyListeners();
  }

  void setProfileImageFile(File? file) {
    _profileImageFile = file;
    notifyListeners();
  }

  void setOtherImageFiles(List<File> files) {
    _otherImageFiles = List.from(files);
    notifyListeners();
  }

  void addOtherImageFile(File file) {
    if (_otherImageFiles.length < 5) {
      _otherImageFiles.add(file);
      notifyListeners();
    } else {
      // SnackBar mesajı burada gösterilmez, PhotoUploadScreen'de gösterilir.
    }
  }

  void removeOtherImageFile(File file) {
    _otherImageFiles.remove(file);
    notifyListeners();
  }

  // Tüm verileri sıfırlama (örneğin kullanıcı çıkış yaptığında)
  void reset() {
    _name = '';
    _dateOfBirth = null;
    _gender = null;
    _location = '';
    _bio = ''; // Sıfırlama
    _interests = [];
    _profileImageFile = null;
    _otherImageFiles = [];
    notifyListeners();
  }
}
