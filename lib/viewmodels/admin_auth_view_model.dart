import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAuthViewModel extends ChangeNotifier {
  late SharedPreferences _prefs;
  String _password = "0000";

  AdminAuthViewModel();

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    _password = _prefs.getString("admin_password") ?? "0000";
    notifyListeners();
  }

  bool checkPassword(String input) {
    return _password == input.trim();
  }

  Future<bool> updatePassword(String newPw, String confirmPw) async {
    final trimmedNew = newPw.trim();
    final trimmedConfirm = confirmPw.trim();

    if (trimmedNew != trimmedConfirm) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("admin_password", trimmedNew);
    _password = trimmedNew;
    notifyListeners();
    return true;
  }
}