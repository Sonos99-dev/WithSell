// lib/viewmodels/admin_auth_view_model.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAuthViewModel extends ChangeNotifier {
  static const String _pwKey = "admin_password";
  String _currentPassword;

  AdminAuthViewModel(this._currentPassword);
  String get currentPassword => _currentPassword;

  bool checkPassword(String input) {
    return _currentPassword == input.trim();
  }

  Future<bool> updatePassword(String newPw, String confirmPw) async {
    final trimmedNew = newPw.trim();
    final trimmedConfirm = confirmPw.trim();

    if (trimmedNew != trimmedConfirm) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pwKey, trimmedNew);
    _currentPassword = trimmedNew;
    notifyListeners();
    return true;
  }
}