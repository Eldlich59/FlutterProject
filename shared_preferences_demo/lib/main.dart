import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SharedPreferences Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SharedPreferencesDemo(),
    );
  }
}

class SharedPreferencesDemo extends StatefulWidget {
  @override
  _SharedPreferencesDemoState createState() => _SharedPreferencesDemoState();
}

class _SharedPreferencesDemoState extends State<SharedPreferencesDemo> {
  // Controllers cho các text field
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  // Biến để lưu trữ dữ liệu
  String _savedName = '';
  int _savedAge = 0;

  @override
  void initState() {
    super.initState();
    // Tải dữ liệu đã lưu khi khởi động ứng dụng
    _loadSavedData();
  }

  // Phương thức lưu dữ liệu
  _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      // Lưu tên
      prefs.setString('name', _nameController.text);
      // Lưu tuổi
      prefs.setInt('age', int.parse(_ageController.text));

      // Cập nhật giá trị hiển thị
      _savedName = _nameController.text;
      _savedAge = int.parse(_ageController.text);
    });
  }

  // Phương thức tải dữ liệu đã lưu
  _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      // Lấy tên đã lưu, mặc định là chuỗi rỗng nếu chưa có
      _savedName = prefs.getString('name') ?? '';
      // Lấy tuổi đã lưu, mặc định là 0 nếu chưa có
      _savedAge = prefs.getInt('age') ?? 0;
    });
  }

  // Phương thức xóa dữ liệu
  _clearData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      // Xóa toàn bộ dữ liệu
      prefs.clear();

      // Đặt lại các giá trị hiển thị
      _savedName = '';
      _savedAge = 0;

      // Xóa nội dung text field
      _nameController.clear();
      _ageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SharedPreferences Demo'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Text field nhập tên
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nhập tên',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // Text field nhập tuổi
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Nhập tuổi',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // Nút lưu dữ liệu
            ElevatedButton(
              onPressed: _saveData,
              child: Text('Lưu Dữ Liệu'),
            ),

            // Nút xóa dữ liệu
            ElevatedButton(
              onPressed: _clearData,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Xóa Dữ Liệu'),
            ),

            SizedBox(height: 16),

            // Hiển thị dữ liệu đã lưu
            Text(
              'Tên đã lưu: $_savedName',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Tuổi đã lưu: $_savedAge',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  // Giải phóng bộ nhớ cho các controller
  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}
