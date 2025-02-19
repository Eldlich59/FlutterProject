import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class PostFooterWidget extends StatefulWidget {
  const PostFooterWidget({super.key});

  @override
  State<PostFooterWidget> createState() => _PostFooterWidgetState();
}

class _PostFooterWidgetState extends State<PostFooterWidget> {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          ReactionComponent(
            reactionAmount: 2,
            hasReaction: true,
          ),
          SizedBox(width: 16),
          ComentComponent(),
        ],
      ),
    );
  }
}

class ReactionComponent extends StatefulWidget {
  const ReactionComponent(
      {super.key, required this.reactionAmount, required this.hasReaction});

  final int reactionAmount;
  final bool hasReaction; // true: đã thích, false: chưa thích

  @override
  State<ReactionComponent> createState() => _ReactionComponentState();
}

class _ReactionComponentState extends State<ReactionComponent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFf9f9f9),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            widget.hasReaction
                ? 'assets/icons/medium_heart_icon.svg'
                : 'assets/icons/heart_icon.svg',
            colorFilter: ColorFilter.mode(
                widget.hasReaction
                    ? const Color(0xFFfe0037)
                    : const Color(0xFF6b6b6b),
                BlendMode.srcIn),
          ),
          SizedBox(width: 4),
          Text(
            'Thích',
            style: GoogleFonts.beVietnamPro().copyWith(
              color: widget.hasReaction
                  ? const Color(0xFF740a12)
                  : const Color(0xFF6b6b6b),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          ...widget.reactionAmount > 0
              ? [
                  SvgPicture.asset(
                    'assets/icons/short_divider_icon.svg',
                    colorFilter:
                        ColorFilter.mode(Color(0xFFdfdfdf), BlendMode.srcIn),
                  ),
                  SvgPicture.asset(
                    'assets/icons/small_heart_icon.svg',
                    colorFilter:
                        ColorFilter.mode(Color(0xFFfe0428), BlendMode.srcIn),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${widget.reactionAmount}',
                    style: GoogleFonts.beVietnamPro().copyWith(
                      color: const Color(0xFF6b6b6b),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ]
              : []
        ],
      ),
    );
  }
}

class ComentComponent extends StatefulWidget {
  const ComentComponent({super.key});

  @override
  State<ComentComponent> createState() => _ComentComponentState();
}

class _ComentComponentState extends State<ComentComponent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFf9f9f9),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/message_icon.svg',
            colorFilter:
                ColorFilter.mode(const Color(0xFF585858), BlendMode.srcIn),
          ),
          const SizedBox(width: 4),
          Text(
            '1',
            style: GoogleFonts.beVietnamPro().copyWith(
              color: const Color(0xFF585858),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          )
        ],
      ),
    );
  }
}
