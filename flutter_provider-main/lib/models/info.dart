import 'package:flutter/foundation.dart';

enum gioi_tinh { nam, nu }
enum bang_cap { CaoDang, DaiHoc, ThacSi, TienSi }

class GioiTinh extends ChangeNotifier {
  gioi_tinh? _gioiTinh = gioi_tinh.nam;

  gioi_tinh? get gioiTinh => _gioiTinh;

  set gioiTinh(gioi_tinh? value) {
    _gioiTinh = value;
    notifyListeners();
  }
}

class BangCap extends ChangeNotifier {
  bang_cap? _bangCap = bang_cap.DaiHoc;

  bang_cap? get bangCap => _bangCap;

  set bangCap(value) {
    _bangCap = value;
    notifyListeners();
  }
}
