import 'package:flutter/material.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: Color(0xFFe9e9e9),
      indent: 16,
      endIndent: 16,
    );
  }
}
