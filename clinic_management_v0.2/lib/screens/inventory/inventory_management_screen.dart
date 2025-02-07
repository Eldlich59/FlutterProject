import 'package:flutter/material.dart';
import 'components/inventory_home_screen.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _opacity = 1.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: InventoryHomeScreen.primaryColor,
        scaffoldBackgroundColor: InventoryHomeScreen.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: InventoryHomeScreen.primaryColor,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: InventoryHomeScreen.primaryColor,
          secondary: InventoryHomeScreen.secondaryColor,
        ),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: _opacity,
        curve: Curves.easeInOut,
        child: const InventoryHomeScreen(),
      ),
    );
  }
}
