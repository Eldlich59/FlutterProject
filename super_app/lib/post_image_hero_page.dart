import 'package:flutter/material.dart';

class PostImageHeroPage extends StatelessWidget {
  const PostImageHeroPage({super.key, required this.tag, required this.path});

  final String tag;
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Draggable(
        childWhenDragging: const SizedBox(),
        onDragEnd: (details) {
          Navigator.of(context).pop();
        },
        feedback: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Image.asset(path)),
        child: Center(
          child: Hero(
            tag: tag,
            child: Image.asset(path),
          ),
        ),
      ),
    );
  }
}
