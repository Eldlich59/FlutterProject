import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'box1.dart';
import 'feature.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => Feature()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Box1(),
            ),
          ),
        ));
  }
}
