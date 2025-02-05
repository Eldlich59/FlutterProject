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
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: GridView.count(
          padding: const EdgeInsets.all(24),
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: [
            _buildMenuCard(
              context,
              'Nhập kho',
              Icons.add_box,
              'Quản lý nhập thuốc và vật tư y tế',
              Colors.blue,
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
              'Quản lý tồn kho',
              Colors.green,
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
              'Quản lý xuất kho',
              Colors.red,
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
              'Quản lý nhà cung cấp',
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupplierScreen()),
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
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
