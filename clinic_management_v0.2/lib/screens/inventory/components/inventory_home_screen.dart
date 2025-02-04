import 'package:flutter/material.dart';
import 'import_inventory_screen.dart';
import 'inventory_status_screen.dart';
import 'export_inventory_screen.dart';
import 'supplier_screen.dart';

class InventoryHomeScreen extends StatelessWidget {
  const InventoryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý kho'),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        children: [
          _buildMenuCard(
            context,
            'Nhập kho',
            Icons.add_box,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ImportInventoryScreen()),
            ),
          ),
          _buildMenuCard(
            context,
            'Tồn kho',
            Icons.inventory,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const InventoryStatusScreen()),
            ),
          ),
          _buildMenuCard(
            context,
            'Xuất kho',
            Icons.outbox,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ExportInventoryScreen()),
            ),
          ),
          _buildMenuCard(
            context,
            'Nhà cung cấp',
            Icons.business,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SupplierScreen()),
            ),
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
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
