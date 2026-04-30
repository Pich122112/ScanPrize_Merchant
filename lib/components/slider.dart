import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gb_merchant/contents/Blog_Detail_Page.dart';
import '../services/slider_service.dart';
import 'package:gb_merchant/models/slider_model.dart';

class ImageSlider extends StatefulWidget {
  const ImageSlider({super.key});
  @override
  ImageSliderState createState() => ImageSliderState();
}

class ImageSliderState extends State<ImageSlider>
    with AutomaticKeepAliveClientMixin<ImageSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  List<SliderModel> slides = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSliders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (slides.isNotEmpty) {
      _startAutoPlay();
    }
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> refreshSlider() async {
    await fetchSliders(forceRefresh: true);
  }

  Future<void> fetchSliders({bool forceRefresh = false}) async {
    await _fetchSliders(forceRefresh: forceRefresh);
  }

  Future<void> _fetchSliders({bool forceRefresh = false}) async {
    // If we already have slides and no force refresh requested, keep them and resume autoplay
    if (!forceRefresh && slides.isNotEmpty) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = null;
        });
      }
      _startAutoPlay();
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final fetchedSlides = await ApiService().getSliders(
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          slides = fetchedSlides;
          isLoading = false;
          errorMessage = null;
        });
      }

      if (slides.isNotEmpty) {
        _startAutoPlay();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < slides.length - 1) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.jumpToPage(0);
        _currentPage = 0;
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    _timer?.cancel();
    _startAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final localeCode = context.locale.languageCode;
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // scale sizes based on screen width
    final double slideHeight =
        height * 0.18; // Increased height for better visibility
    final double slideContainerWidth = width * 0.92;
    final double borderRadius = 22.0;
    final double titleSize = width * 0.045;
    final double subtitleSize = width * 0.040;
    final double descSize = width * 0.04;
    final double cardImageSize = width * 0.32;
    final double dotSize = height * 0.011;
    final double dotSpacing = width * 0.012;

    // Show error message
    if (errorMessage != null) {
      return Container(
        height: slideHeight,
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load slider',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'KhmerFont',
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _fetchSliders,
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontFamily: 'KhmerFont',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state
    if (!isLoading && slides.isEmpty) {
      return Container(
        margin: EdgeInsets.only(left: 14, right: 12, top: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color.fromARGB(153, 229, 229, 229)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF083A75), // darker shade
              Color(0xFF0D55A8), // main color
              Color(0xFF4A8DFF), // lighter highlight
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        height: slideHeight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.announcement, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              Text(
                'no_announcement_available'.tr(),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.white,
                  fontFamily: 'KhmerFont',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: width * 0.040,
              right: width * 0.04,
              top: height * 0.015,
              bottom: height * 0.01,
            ),
            child: Text(
              'announcement'.tr(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: titleSize,
                color: isDarkMode ? Colors.white : Colors.white,
                fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(height: height * 0.006),
          SizedBox(
            height: slideHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: slides.length,
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    return _buildSlideCard(
                      slide.imageUrls.isNotEmpty ? slide.imageUrls[0] : '',
                      slide.title,
                      slide.subtitle,
                      slide.actionButton,
                      slide,
                      slideContainerWidth,
                      slideHeight,
                      borderRadius,
                      titleSize,
                      subtitleSize,
                      descSize,
                      cardImageSize,
                      localeCode,
                    );
                  },
                ),
                Positioned(
                  bottom: height * 0.010,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(slides.length, (index) {
                      bool isActive = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: dotSpacing),
                        height: dotSize,
                        width: isActive ? dotSize * 2.1 : dotSize,
                        decoration: BoxDecoration(
                          color:
                              isActive
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(dotSize * 0.7),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideCard(
    String imageUrl,
    String title,
    String subtitle,
    String actionButton,
    SliderModel slider,
    double containerWidth,
    double containerHeight,
    double borderRadius,
    double titleSize,
    double subtitleSize,
    double descSize,
    double cardImageSize,
    String localeCode,
  ) {
    return Center(
      child: GestureDetector(
        onTap: () {
          showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel: "BlogDetail",
            transitionDuration: Duration.zero,
            pageBuilder: (context, animation, secondaryAnimation) {
              return Scaffold(
                body: BlogDetailPage(slider: slider, allSlides: slides),
              );
            },
          );
        },
        child: Container(
          width: containerWidth,
          height: containerHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: const Color.fromARGB(153, 229, 229, 229),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF083A75), // darker shade
                Color(0xFF0D55A8), // main color
                Color(0xFF4A8DFF), // lighter highlight
              ],
              stops: [0.0, 0.4, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: containerWidth * 0.050,
                  vertical: containerHeight * 0.14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title.toUpperCase(),
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily:
                                  localeCode == 'km' ? 'KhmerFont' : null,
                              letterSpacing: 0.5,
                              height: 1.18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: containerHeight * 0.15),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: subtitleSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                              fontFamily: 'KhmerFont',
                              height: 1.17,
                            ),
                            maxLines: 2, // Increased to 2 lines
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: containerWidth * 0.06),
                    if (slider.imageUrls.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          slider.imageUrls[0],
                          height: cardImageSize,
                          width: cardImageSize,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: cardImageSize,
                              width: cardImageSize,
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: cardImageSize,
                              width: cardImageSize,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.image_not_supported,
                                size: cardImageSize * 0.4,
                                color: Colors.grey[500],
                              ),
                            );
                          },
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

//Correct with 467 line code changes
