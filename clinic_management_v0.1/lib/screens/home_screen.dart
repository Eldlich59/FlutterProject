// lib/screens/home_screen.dart
import 'package:clinic_management/screens/medicines_screen.dart';
import 'package:flutter/material.dart';
import 'patients_screen.dart';
import 'prescriptions_screen.dart';
import 'medical_records_screen.dart';
import 'invoices_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phần mềm Quản lý Phòng khám'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  // Module 1: Quản lý bệnh nhân
                  _buildModuleCard(
                    context: context,
                    title: 'Quản lý Bệnh nhân',
                    icon: Icons.person,
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PatientsScreen()),
                    ),
                    features: [
                      'Tiếp nhận bệnh nhân',
                      'Tìm kiếm bệnh nhân',
                      'Cập nhật thông tin',
                    ],
                  ),

                  // Module 2: Quản lý khám bệnh
                  _buildModuleCard(
                    context: context,
                    title: 'Quản lý Khám bệnh',
                    icon: Icons.medical_services,
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MedicalRecordsScreen()),
                    ),
                    features: [
                      'Lập phiếu khám',
                      'Tìm phiếu khám',
                      'Cập nhật phiếu khám',
                    ],
                  ),

                  // Module 3: Quản lý toa thuốc
                  _buildModuleCard(
                    context: context,
                    title: 'Quản lý Đơn thuốc',
                    icon: Icons.receipt,
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PrescriptionsScreen()),
                    ),
                    features: [
                      'Lập đơn thuốc',
                      'In đơn thuốc',
                      'Quản lý thuốc',
                    ],
                  ),

                  // Module 3: Quản lý thuốc
                  _buildModuleCard(
                    context: context,
                    title: 'Quản lý thuốc',
                    icon: Icons.medication,
                    color: Colors.red,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MedicinesScreen()),
                    ),
                    features: [],
                  ),

                  // Module 4: Quản lý hóa đơn
                  _buildModuleCard(
                    context: context,
                    title: 'Quản lý Hóa đơn',
                    icon: Icons.payment,
                    color: Colors.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const InvoicesScreen()),
                    ),
                    features: [
                      'Lập hóa đơn thuốc',
                      'In hóa đơn thuốc',
                      'Báo cáo doanh thu',
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                '© 2024 Phần mềm Quản lý Phòng khám',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required List<String> features,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '• $feature',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.left,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
