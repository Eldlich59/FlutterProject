import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_app/post_image_hero_page.dart';
import 'package:super_app/utils/app_divider.dart';

class PostBodyWidget extends StatefulWidget {
  const PostBodyWidget({super.key, required this.hasPostImage});
  final bool hasPostImage;
  @override
  State<PostBodyWidget> createState() => _PostBodyWidgetState();
}

class _PostBodyWidgetState extends State<PostBodyWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 12,
        ),
        const PostTextComponent(),

        ...widget.hasPostImage
            ? [
                const SizedBox(
                  height: 12,
                ),
                const PostImageComponent(),
              ]
            : [const AppDivider()],

        // widget.hasPostImage == true ? const SizedBox() : const AppDivider(),
        // const SizedBox(
        //   height: 12,
        // ),
        // widget.hasPostImage == true ? const PostImageComponent() : const SizedBox(),
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
  int activeIndex = 0;
  final ValueNotifier<int> activeIndexNotifier = ValueNotifier<int>(0);
  List<String> imagesPath = [
    'assets/image/acheron_summer.jpg',
    'assets/image/clone_queen.jpg',
    'assets/image/feixiao_summer.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    debugPrint('Rebuilt image time');
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height / 1.8,
          child: PageView.builder(
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              final item = imagesPath[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return PostImageHeroPage(
                          tag: 'item-$index',
                          path: item,
                        );
                      },
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                    ),
                  );
                },
                child: Hero(
                    tag: 'item-$index',
                    child: Image.asset(item, fit: BoxFit.cover)),
              );
            },
            onPageChanged: (value) {
              // setState(() {
              //   activeIndex = value;
              // });
              activeIndexNotifier.value = value;
              debugPrint('Page changed: ${activeIndexNotifier.value}');
            },
            itemCount: imagesPath.length,
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        ValueListenableBuilder<int>(
          valueListenable: activeIndexNotifier,
          builder: (BuildContext context, int currentValue, Widget? child) {
            return IndicatorDotsWidget(
              activeIndex: currentValue,
              imagesPath: imagesPath,
            );
          },
        ),
        const SizedBox(
          height: 8,
        ),
      ],
    );
  }
}

class IndicatorDotsWidget extends StatefulWidget {
  const IndicatorDotsWidget({
    super.key,
    required this.activeIndex,
    required this.imagesPath,
  });
  final int activeIndex;
  final List<String> imagesPath;

  @override
  State<IndicatorDotsWidget> createState() => _IndicatorDotsWidgetState();
}

class _IndicatorDotsWidgetState extends State<IndicatorDotsWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.imagesPath.asMap().entries.map((x) {
        final index = x.key;
        final isActive = index == widget.activeIndex;
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF008dff) : Colors.grey,
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }
}
