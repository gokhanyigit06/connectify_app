import 'package:flutter/material.dart';
import 'dart:io';

class OnboardingDataProvider extends ChangeNotifier {
  String _name = '';
  DateTime? _dateOfBirth;
  String? _gender;
  String _location = '';
  String _bio = '';
  int? _height;
  String? _relationshipGoal; // Yeni: İlişki hedefi alanı
  List<String> _interests = [];
  File? _profileImageFile;
  List<File> _otherImageFiles = [];

  // Getter'lar
  String get name => _name;
  DateTime? get dateOfBirth => _dateOfBirth;
  String? get gender => _gender;
  String get location => _location;
  String get bio => _bio;
  int? get height => _height;
  String? get relationshipGoal =>
      _relationshipGoal; // Yeni: İlişki hedefi getter
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
    _bio = bio;
    notifyListeners();
  }

  void setHeight(int height) {
    _height = height;
    notifyListeners();
  }

  void setRelationshipGoal(String relationshipGoal) {
    // Yeni: İlişki hedefi setter
    _relationshipGoal = relationshipGoal;
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
    }
  }

  void removeOtherImageFile(File file) {
    _otherImageFiles.remove(file);
    notifyListeners();
  }

  // Tüm verileri sıfırlama
  void reset() {
    _name = '';
    _dateOfBirth = null;
    _gender = null;
    _location = '';
    _bio = '';
    _height = null;
    _relationshipGoal = null; // Sıfırlama
    _interests = [];
    _profileImageFile = null;
    _otherImageFiles = [];
    notifyListeners();
  }
}
