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
import 'inventory/inventory_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryColor = Color(0xFF1A73E8); // Google Blue

  static const Map<String, Color> menuColors = {
    'Bệnh nhân': Color(0xFF34A853), // Google Green
    'Khám bệnh': Color(0xFF1A73E8), // Google Blue
    'Thuốc': Color(0xFFEA4335), // Google Red
    'Bác sĩ': Color(0xFF9C27B0), // Purple
    'Toa thuốc': Color(0xFFFBBC04), // Google Yellow
    'Hóa đơn': Color(0xFF00ACC1), // Cyan
    'Chuyên khoa': Color(0xFFFF5722), // Orange
    'Quản lý kho': Color(0xFF4CAF50), // Add new color for inventory
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
            Color(0xFFE8F5E9),
            Color(0xFFE3F2FD),
            Color(0xFFF3E5F5),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Row(
            children: [
              const Icon(Icons.local_hospital, size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Phòng Khám',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Hệ thống quản lý',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Đăng xuất'),
                onPressed: () => _handleLogout(context),
              ),
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
              'Quản lý kho',
              Icons.inventory,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InventoryManagementScreen(),
                ),
              ),
            ),
            _buildMenuCard(
              context,
              'Toa thuốc',
              Icons.description, // Changed from Icons.medical_information
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
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: mainColor.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: mainColor.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: -2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  _onPress(title, true);
                  await Future.delayed(const Duration(milliseconds: 150));
                  _onPress(title, false);
                  if (context.mounted) onTap();
                },
                splashColor: mainColor.withOpacity(0.1),
                highlightColor: mainColor.withOpacity(0.15),
                child: MouseRegion(
                  onEnter: (_) => _onHover(title, true),
                  onExit: (_) => _onHover(title, false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          mainColor.withOpacity(isHovered ? 0.15 : 0.05),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: mainColor.withOpacity(0.1),
                          ),
                          child: Icon(
                            icon,
                            size: 48,
                            color: mainColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: mainColor,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false, // This removes all previous routes
      );
    }
  }
}
