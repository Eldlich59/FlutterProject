import 'package:flutter/material.dart';
import 'package:state_flutter_provider/feature.dart';
import 'package:provider/provider.dart';

class Box23 extends StatefulWidget {
  const Box23({super.key});

  @override
  Box23State createState() => Box23State();
}

class Box23State extends State<Box23> {
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 100,
        width: 200,
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: context.watch<Feature>().count % 2 == 0
              ? Colors.blue
              : Colors.red,
        ),
        child: Center(
          child: Text(
            context.watch<Feature>().count.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
        ));
  }
}
