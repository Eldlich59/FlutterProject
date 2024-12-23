import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:state_flutter_provider/feature.dart';
import 'box21.dart';
import 'box22.dart';
import 'box23.dart';

class Box1 extends StatefulWidget {
  const Box1({super.key});

  @override
  Box1State createState() => Box1State();
}

class Box1State extends State<Box1> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Box21(),
        const Box22(),
        const Box23(),
        increaseNumber(),
      ],
    );
  }

  // Button of increasing Number
  Widget increaseNumber() {
    return ElevatedButton(
      key: const Key('increase_button'),
      child: const Text(
        "Tăng số",
        style: TextStyle(fontSize: 20),
      ),
      onPressed: () {
        context.read<Feature>().increaseCount();
      },
    );
  }
}
