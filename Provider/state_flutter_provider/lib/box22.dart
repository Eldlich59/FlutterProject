import 'package:flutter/material.dart';

class Box22 extends StatefulWidget {
  const Box22({super.key});

  @override
  Box22State createState() => Box22State();
}

class Box22State extends State<Box22> {
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 100,
        width: 200,
        margin: const EdgeInsets.only(top: 10),
        decoration: const BoxDecoration(
          color: Colors.grey,
        ),
        child: const Center(
          child: Text(
            "Không dùng Provider",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ));
  }
}
