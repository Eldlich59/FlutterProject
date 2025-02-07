import 'package:flutter/material.dart';
import 'import_inventory_screen.dart';
import 'inventory_status_screen.dart';
import 'export_inventory_screen.dart';
import 'supplier_screen.dart';

class InventoryHomeScreen extends StatelessWidget {
  const InventoryHomeScreen({super.key});

  // Add color constants
  static const primaryColor = Color(0xFF546E7A); // BlueGrey[600]
  static const secondaryColor = Color(0xFF78909C); // BlueGrey[400]
  static const backgroundColor = Color(0xFFECEFF1); // BlueGrey[50]
  static const accentColor = Color(0xFF90A4AE); // BlueGrey[200]
  static const gradientStart = Color(0xFF546E7A); // BlueGrey[600]
  static const gradientEnd = Color(0xFF78909C); // BlueGrey[400]

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý kho',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              gradientStart,
              backgroundColor,
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
              const Color(0xFF66BB6A), // Soft Green
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
              const Color(0xFF42A5F5), // Soft Blue
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
              const Color(0xFFEC407A), // Soft Pink
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
              const Color(0xFFFFB74D), // Soft Orange
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                color.withOpacity(0.1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 45, color: color),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
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
