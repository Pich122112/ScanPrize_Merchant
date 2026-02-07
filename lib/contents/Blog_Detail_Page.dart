import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/utils/constants.dart';
import '../widgets/modern_image_slider.dart';
import '../models/slider_model.dart';
import 'package:url_launcher/url_launcher.dart';

class BlogDetailPage extends StatefulWidget {
  final SliderModel slider;
  final List<SliderModel> allSlides;

  const BlogDetailPage({
    Key? key,
    required this.slider,
    required this.allSlides,
  }) : super(key: key);

  @override
  _BlogDetailPageState createState() => _BlogDetailPageState();
}

class _BlogDetailPageState extends State<BlogDetailPage> {
  late List<SliderModel> allSlides;
  late int initialPage;
  late PageController _pageController;
  int _currentIndex = 0;
  bool _showDownArrow = true;

  @override
  void initState() {
    super.initState();
    allSlides = widget.allSlides;
    initialPage = allSlides.indexWhere((slide) => slide.id == widget.slider.id);
    _currentIndex = initialPage;
    _pageController = PageController(initialPage: initialPage);
    _pageController.addListener(_handlePageScroll);
  }

  void _handlePageScroll() {
    final double page = _pageController.page ?? _currentIndex.toDouble();
    setState(() {
      _showDownArrow =
          (page.round() == _currentIndex) &&
          (_currentIndex < allSlides.length - 1);
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageScroll);
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildContent(SliderModel slider, int index) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [ModernImageSlider(imageUrls: slider.imageUrls)]),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              slider.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.backgroundColor,
                letterSpacing: 0.2,
                height: 1.28,
                fontFamily: 'KhmerFont',
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (slider.url.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(slider.url);

                  if (await canLaunchUrl(uri)) {
                    // Try external app first
                    final launched = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );

                    if (!launched) {
                      // Fallback to in-app browser view
                      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                    }
                  } else {
                    // Last fallback
                    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                  }
                },
                child: Text(
                  "click_link".tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                    decorationThickness: 2,
                    height: 2,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'KhmerFont',
                  ),
                ),
              ),
            ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              slider.description,
              style: TextStyle(
                fontSize: 17,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
                height: 1.7,
                fontFamily: 'KhmerFont',
              ),
            ),
          ),

          const SizedBox(height: 36),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.locale.languageCode;
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        color: AppColors.primaryColor,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                title: Text(
                  'blogdetail'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: allSlides.length,
                      onPageChanged: (i) {
                        setState(() {
                          _currentIndex = i;
                          _showDownArrow = i < allSlides.length - 1;
                        });
                      },
                      itemBuilder: (context, index) {
                        return _buildContent(allSlides[index], index);
                      },
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 350),
                      opacity: _showDownArrow ? 1.0 : 0.0,
                      child: IgnorePointer(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.5,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_currentIndex + 1}/${allSlides.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Correct with 251 line code changes
