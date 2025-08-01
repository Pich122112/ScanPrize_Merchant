import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:scanprize_frontend/utils/constants.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ModernImageSlider extends StatefulWidget {
  final List<String> imageUrls;
  const ModernImageSlider({super.key, required this.imageUrls});

  @override
  State<ModernImageSlider> createState() => _ModernImageSliderState();
}

class _ModernImageSliderState extends State<ModernImageSlider> {
  int activeIndex = 0;
  final CarouselSliderController _controller = CarouselSliderController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                CarouselSlider(
                  carouselController: _controller,
                  items:
                      widget.imageUrls.map((url) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // NEW (CORRECT for network images)
                              Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        Container(color: Colors.grey[300]),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(22),
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.18),
                                        Colors.black.withOpacity(0.30),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  options: CarouselOptions(
                    height: 220,
                    autoPlay: true,
                    viewportFraction: 1,
                    enlargeCenterPage: true,
                    autoPlayInterval: const Duration(seconds: 5),
                    enableInfiniteScroll: true,
                    onPageChanged: (index, reason) {
                      setState(() {
                        activeIndex = index;
                      });
                    },
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSmoothIndicator(
            activeIndex: activeIndex,
            count: widget.imageUrls.length,
            effect: ExpandingDotsEffect(
              dotHeight: 10,
              dotWidth: 10,
              activeDotColor: AppColors.primaryColor,
              dotColor: Colors.grey.shade300,
              spacing: 8,
              expansionFactor: 3.2,
            ),
            onDotClicked: (index) {
              _controller.animateToPage(index);
            },
          ),
        ],
      ),
    );
  }
}

//Correct with 129 line code changes
