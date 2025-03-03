import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/app_enum.dart';

class PostHeaderWidget extends StatelessWidget {
  const PostHeaderWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/image/ely.jpg"),
                    fit: BoxFit.cover,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Elysiaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                      style: GoogleFonts.beVietnamPro().copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Row(
                      children: [
                        Text(
                          'Hôm qua lúc 13:07 - ',
                          style: GoogleFonts.beVietnamPro().copyWith(
                            color: const Color(0xFF6e6e6e),
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        postTypeComponent(postType: PostType.friends),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SvgPicture.asset(
          'assets/icons/more_icon.svg',
          colorFilter: ColorFilter.mode(Color(0xFF6a6a6a), BlendMode.srcIn),
          height: 16,
          width: 16,
        ),
      ],
    );
  }

  Widget postTypeComponent({
    required PostType postType,
  }) {
    switch (postType) {
      case PostType.private:
        return Row(
          children: [
            SvgPicture.asset(
              'assets/icons/private_icon.svg',
              colorFilter: ColorFilter.mode(Color(0xFF6a6a6a), BlendMode.srcIn),
              height: 16,
              width: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Chỉ mình tôi',
              style: GoogleFonts.beVietnamPro().copyWith(
                color: const Color(0xFF6a6a6a),
                fontSize: 14,
              ),
            ),
          ],
        );
      case PostType.public:
        return Row(
          children: [
            SvgPicture.asset(
              'assets/icons/public_icon.svg',
              colorFilter: ColorFilter.mode(Color(0xFF6a6a6a), BlendMode.srcIn),
              height: 16,
              width: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Công khai',
              style: GoogleFonts.beVietnamPro().copyWith(
                color: const Color(0xFF6a6a6a),
                fontSize: 14,
              ),
            ),
          ],
        );
      case PostType.friends:
        return Row(
          children: [
            SvgPicture.asset(
              'assets/icons/friend_icon.svg',
              colorFilter: ColorFilter.mode(Color(0xFF6a6a6a), BlendMode.srcIn),
              height: 16,
              width: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Chỉ bạn bè',
              style: GoogleFonts.beVietnamPro().copyWith(
                color: const Color(0xFF6a6a6a),
                fontSize: 14,
              ),
            ),
          ],
        );
    }
  }
}
