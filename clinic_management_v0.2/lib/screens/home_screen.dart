import 'package:clinic_management/screens/doctor/doctor_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'patient/patient_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'examination/examination_list_screen.dart';
import 'medicine/medicine_list_screen.dart';
import 'prescription/prescription_list_screen.dart';
import 'bill/bill_list_screen.dart';
import 'specialty/specialty_list_screen.dart';
import 'auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryColor = Color(0xFF64B5F6); // Light blue primary

  // Định nghĩa map màu sắc cho từng mục
  static const Map<String, Color> menuColors = {
    'Bệnh nhân': Color(0xFF4CAF50), // Xanh lá - Màu của sự quan tâm
    'Khám bệnh': Color(0xFF2196F3), // Xanh dương - Màu của y tế
    'Thuốc': Color(0xFFE91E63), // Hồng - Màu của dược phẩm
    'Bác sĩ': Color(0xFF673AB7), // Tím - Màu của chuyên môn
    'Toa thuốc': Color(0xFFFF9800), // Cam - Màu của kê đơn
    'Hóa đơn': Color(0xFF009688), // Xanh ngọc - Màu của tài chính
    'Chuyên khoa':
        Color(0xFFBF360C), // Màu đỏ cam đậm - Màu của chuyên môn y tế
  };

  // Track hover and pressed states
  String? hoveredItem;
  String? pressedItem;

  void _onHover(String title, bool isHovered) {
    setState(() {
      hoveredItem = isHovered ? title : null;
    });
  }

  void _onPress(String title, bool isPressed) {
    setState(() {
      pressedItem = isPressed ? title : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE3F2FD), // Very light blue
            Color(0xFFF5F5F5), // Almost white
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: primaryColor,
          title: const Text(
            'Phòng Khám',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, size: 28, color: Colors.white),
              onPressed: () => _handleLogout(context),
            ),
          ],
        ),
        body: GridView.count(
          padding: const EdgeInsets.all(24),
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _buildMenuCard(
              context,
              'Bệnh nhân',
              Icons.people,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PatientListScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              'Khám bệnh',
              Icons.medical_services,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ExaminationListScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              'Thuốc',
              Icons.medication,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MedicineListScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              'Chuyên khoa',
              Icons.medical_information,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SpecialtyListScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              'Bác sĩ',
              Icons.local_hospital,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DoctorListScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              'Toa thuốc',
              Icons.medical_information,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PrescriptionListScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              'Hóa đơn',
              Icons.receipt_long,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BillListScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    final Color mainColor = menuColors[title] ?? primaryColor;
    final bool isHovered = hoveredItem == title;
    final bool isPressed = pressedItem == title;
    final double scale = isPressed
        ? 0.95
        : isHovered
            ? 1.05
            : 1.0;

    Future<void> handleTap() async {
      HapticFeedback.lightImpact();
      _onPress(title, true);

      // Thêm hiệu ứng press
      await Future.delayed(const Duration(milliseconds: 150));
      _onPress(title, false);

      // Thêm delay trước khi navigate
      await Future.delayed(const Duration(milliseconds: 200));
      if (context.mounted) {
        onTap();
      }
    }

    return Hero(
      tag: title,
      child: Material(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: scale),
          duration: const Duration(milliseconds: 200),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: mainColor.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: handleTap,
                splashColor: mainColor.withOpacity(0.1),
                highlightColor: mainColor.withOpacity(0.15),
                child: MouseRegion(
                  onEnter: (_) => _onHover(title, true),
                  onExit: (_) => _onHover(title, false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          mainColor.withOpacity(isHovered ? 0.25 : 0.15),
                        ],
                        stops: const [0.2, 1.0],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: isHovered ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            icon,
                            size: 56,
                            color: mainColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: mainColor,
                            letterSpacing: 0.5,
                          ),
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await Supabase.instance.client.auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
