import 'package:clinic_management/screens/doctor/doctor_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'patient/patient_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'price_packages_screen.dart';
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
  static const Map<String, Color> menuColors = {
    'Bệnh nhân': Color(0xFF4CAF50), // Material Green
    'Khám bệnh': Color(0xFF2196F3), // Material Blue
    'Thuốc': Color(0xFFF44336), // Material Red
    'Bác sĩ': Color(0xFF673AB7), // Material Deep Purple
    'Toa thuốc': Color(0xFFFF9800), // Material Orange
    'Hóa đơn': Color(0xFF009688), // Material Teal
    'Chuyên khoa': Color(0xFF795548), // Material Brown
    'Quản lý kho': Color(0xFF607D8B), // Material Blue Grey
    'Bảng giá khám bệnh': Color(0xFFE91E63), // Material Pink
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!,
            Colors.blue[100]!,
            Colors.purple[50]!,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70.0),
          child: AppBar(
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue[700]!,
                    Colors.blue[800]!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_hospital, size: 32),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue[700],
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(
                    'Đăng xuất',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _handleLogout(context),
                ),
              ),
            ],
          ),
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 1200
              ? 4
              : constraints.maxWidth > 800
                  ? 3
                  : 2;

          return GridView.count(
            padding: const EdgeInsets.all(24),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
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
                'Bảng giá khám bệnh',
                Icons.price_change,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PricePackagesScreen()),
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
                  MaterialPageRoute(
                      builder: (context) => const BillListScreen()),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    final Color mainColor = menuColors[title] ?? Colors.blue;
    final bool isHovered = hoveredItem == title;
    final bool isPressed = pressedItem == title;
    final double scale = isPressed
        ? 0.95
        : isHovered
            ? 1.03
            : 1.0;

    return Hero(
      tag: title,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: scale),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: mainColor.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  _onPress(title, true);
                  await Future.delayed(const Duration(milliseconds: 150));
                  _onPress(title, false);
                  if (context.mounted) onTap();
                },
                onHover: (value) => _onHover(title, value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
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
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: mainColor.withOpacity(0.1),
                          boxShadow: isHovered
                              ? [
                                  BoxShadow(
                                    color: mainColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ]
                              : [],
                        ),
                        child: Icon(
                          icon,
                          size: 40,
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
