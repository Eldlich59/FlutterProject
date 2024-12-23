import 'package:flutter/material.dart';
import 'package:state_flutter_provider/feature.dart';
import 'package:provider/provider.dart';

class Box21 extends StatefulWidget {
  const Box21({super.key});

  @override
  Box21State createState() => Box21State();
}

class Box21State extends State<Box21> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      height: 100,
      width: 200,
      decoration: BoxDecoration(
        color:
            context.watch<Feature>().count % 2 == 0 ? Colors.blue : Colors.red,
      ),
      child: Center(
        child: Text(
          context.watch<Feature>().count.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}
