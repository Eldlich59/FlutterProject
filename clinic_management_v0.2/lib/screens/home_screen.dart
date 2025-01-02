import 'package:flutter/material.dart';
import 'patient/patient_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'examination/examination_list_screen.dart';
import 'medicine/medicine_list_screen.dart';
import 'auth/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phòng Khám'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
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
            'Hóa đơn',
            Icons.receipt_long,
            () {
              // TODO: Navigate to billing screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
