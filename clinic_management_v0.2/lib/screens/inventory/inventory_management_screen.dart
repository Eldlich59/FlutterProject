import 'package:flutter/material.dart';
import 'components/inventory_home_screen.dart';

class InventoryManagementScreen extends StatelessWidget {
  const InventoryManagementScreen({super.key});

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
      child: const InventoryHomeScreen(),
    );
  }
}
