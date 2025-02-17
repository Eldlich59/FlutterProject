import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PostBodyWidget extends StatefulWidget {
  const PostBodyWidget({super.key});

  @override
  State<PostBodyWidget> createState() => _PostBodyWidgetState();
}

class _PostBodyWidgetState extends State<PostBodyWidget> {
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 12,
        ),
        PostTextComponent(),
        SizedBox(
          height: 12,
        ),
        PostImageComponent(),
      ],
    );
  }
}

class PostTextComponent extends StatelessWidget {
  const PostTextComponent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Text(
        'Summer time',
        style: GoogleFonts.beVietnamPro().copyWith(
          fontSize: 16,
        ),
      ),
    );
  }
}

class PostImageComponent extends StatefulWidget {
  const PostImageComponent({super.key});

  @override
  State<PostImageComponent> createState() => _PostImageComponentState();
}

class _PostImageComponentState extends State<PostImageComponent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height / 1.2,
          child:
              Image.asset('assets/image/acheron_summer.jpg', fit: BoxFit.cover),
        ),
        const SizedBox(
          height: 8,
        ),
        IndicatorDotsWidget(),
        const SizedBox(
          height: 8,
        ),
      ],
    );
  }
}

class IndicatorDotsWidget extends StatelessWidget {
  const IndicatorDotsWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 4),
          decoration: const BoxDecoration(
            color: Color(0xFF008dff),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 4),
          decoration: const BoxDecoration(
            color: Color(0xFF6e6e6e),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF6e6e6e),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
