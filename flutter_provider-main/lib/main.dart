import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/info.dart';

void main(List<String> args) {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => GioiTinh()),
      ChangeNotifierProvider(create: (_) => BangCap())
    ],
    child: MaterialApp(home: MyApp()),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Radio Demo'),
        ),
        body: Consumer2<GioiTinh, BangCap>(
          builder: (context, infoGioiTinh, infoBangCap, child) {
            return Column(
              children: [
                Text('Gioi Tinh'),
                RadioListTile<gioi_tinh?>(
                    value: gioi_tinh.nam,
                    title: Text('Nam'),
                    secondary: Icon(Icons.male),
                    groupValue: infoGioiTinh.gioiTinh,
                    onChanged: (value) {
                      infoGioiTinh.gioiTinh = value;
                    }),
                RadioListTile<gioi_tinh?>(
                    value: gioi_tinh.nu,
                    title: Text('Nu'),
                    secondary: Icon(Icons.female),
                    groupValue: infoGioiTinh.gioiTinh,
                    onChanged: (value) {
                      infoGioiTinh.gioiTinh = value;
                    }),
                Text('Bang Cap'),
                RadioListTile<bang_cap?>(
                    value: bang_cap.CaoDang,
                    title: Text('Cao Dang'),
                    groupValue: infoBangCap.bangCap,
                    onChanged: (value) {
                      infoBangCap.bangCap = value;
                    }),
                RadioListTile<bang_cap?>(
                    value: bang_cap.DaiHoc,
                    title: Text('Dai Hoc'),
                    groupValue: infoBangCap.bangCap,
                    onChanged: (value) {
                      infoBangCap.bangCap = value;
                    }),
                RadioListTile<bang_cap?>(
                    value: bang_cap.ThacSi,
                    title: Text('Thac Si'),
                    groupValue: infoBangCap.bangCap,
                    onChanged: (value) {
                      infoBangCap.bangCap = value;
                    }),
                RadioListTile<bang_cap?>(
                    value: bang_cap.TienSi,
                    title: Text('Tien Si'),
                    groupValue: infoBangCap.bangCap,
                    onChanged: (value) {
                      infoBangCap.bangCap = value;
                    }),
                Divider(
                  height: 100,
                ),
                Center(
                  child: Text(
                    'Thong tin ca nhan: ${infoGioiTinh.gioiTinh}, ${infoBangCap.bangCap} ',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              ],
            );
          },
        ));
  }
}
