import 'package:flutter/material.dart';

class MySettings extends ChangeNotifier {
  bool _isDark = false;

  get isDark => _isDark;

  void setBrightness(bool value) {
    _isDark = value;
    notifyListeners();
  }
}
