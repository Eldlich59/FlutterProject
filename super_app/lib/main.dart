import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_app/widget/post/post_body_widget.dart';
import 'package:super_app/widget/post/post_footer_widget.dart';
import 'package:super_app/widget/post/post_header_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<HeaderFeature> headerFeatures = [
    HeaderFeature('Ảnh', 'assets/icons/gallery_icon.svg', Color(0xFF467017)),
    HeaderFeature('Video', 'assets/icons/video_icon.svg', Color(0xFFe82c3a)),
    HeaderFeature('Album', 'assets/icons/album_icon.svg', Color(0xFF6c6c24)),
    HeaderFeature('Nhạc', 'assets/icons/melody_icon.svg', Color(0xFFf4a81b)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leadingWidth: 40,
          backgroundColor: Colors.lightBlue,
          leading: Padding(
            padding: const EdgeInsets.only(
              left: 16,
            ),
            child: SvgPicture.asset(
              "assets/icons/search_icon.svg",
            ),
          ),
          centerTitle: false,
          title: Text(
            'Tìm kiếm',
            style: GoogleFonts.beVietnamPro().copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w100,
              fontSize: 18,
            ),
          ),
          actions: [
            SvgPicture.asset(
              "assets/icons/edit_icon.svg",
            ),
            const SizedBox(
              width: 16,
            ),
            SvgPicture.asset(
              "assets/icons/bell_icon.svg",
            ),
            const SizedBox(
              width: 16,
            ),
          ],
        ),
        backgroundColor: const Color(0xFFf3f3f3),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                "assets/image/avatar.jpg",
                              ),
                              fit: BoxFit.cover,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        Text(
                          'Tết của bạn thế nào?',
                          style: GoogleFonts.beVietnamPro().copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    SizedBox(
                      height: 30,
                      child: ListView.separated(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final item = headerFeatures[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFf9f4de),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(32)),
                            ),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  item.icon,
                                  colorFilter: ColorFilter.mode(
                                      item.color, BlendMode.srcIn),
                                ),
                                const SizedBox(
                                  width: 4,
                                ),
                                Text(
                                  item.name,
                                  style: GoogleFonts.beVietnamPro().copyWith(
                                    color: Colors.black,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (context, index) {
                          return const SizedBox(
                            width: 8,
                          );
                        },
                        itemCount: headerFeatures.length,
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 18,
                    ),
                    Text(
                      'Khoảnh khắc',
                      style: GoogleFonts.beVietnamPro().copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 16 * 2) / 3,
                      height:
                          ((MediaQuery.of(context).size.width - 16 * 2) / 3) *
                              1.5,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: ShaderMask(
                              shaderCallback: (rect) {
                                return LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.grey.shade100,
                                    const Color(0xFF040402),
                                  ],
                                ).createShader(Rect.fromLTWH(
                                    0, 0, rect.width, rect.height));
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  image: DecorationImage(
                                    image:
                                        AssetImage("assets/image/avatar.jpg"),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFF0798fd),
                                    Color(0xFFba66f7)
                                  ]),
                                  border: Border.all(
                                      color: Colors.grey, width: 2.5),
                                ),
                                child: SvgPicture.asset(
                                  "assets/icons/record_icon.svg",
                                ),
                              ),
                              SizedBox(
                                height: 4,
                              ),
                              Text('Tạo mới',
                                  style: GoogleFonts.beVietnamPro().copyWith(
                                    color: Colors.white,
                                    fontSize: 14,
                                  )),
                              const SizedBox(
                                height: 8,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                color: Colors.white,
                child: const Column(
                  children: [
                    PostHeaderWidget(),
                    PostBodyWidget(
                      hasPostImage: true, //hien thi anh
                    ),
                    PostFooterWidget(),
                  ],
                ),
              )
            ],
          ),
        ));
  }
}

class HeaderFeature {
  HeaderFeature(this.name, this.icon, this.color);
  final String name;
  final String icon;
  final Color color;
}
