import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(
    const MaterialApp(
      home: SafeArea(
        child: Scaffold(
          body: Body(),
        ),
      ),
    ),
  );
}

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        children: [
          Image.asset(
            'assets/images/setting.png',
            width: 150,
            height: 200,
            fit: BoxFit.fitWidth,
          ),
          SvgPicture.asset(
            "assets/images/home.svg",
            width: 150,
            height: 150,
          ),
          ClipOval(
            child: Image.asset(
              'assets/images/screen.jpg',
              width: 150,
              height: 150,
              fit: BoxFit.fitWidth,
            ),
          ),
        ],
      ),
    );
  }
}
