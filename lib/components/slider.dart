// slider.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:scanprize_frontend/contents/Blog_Detail_Page.dart';
import 'package:scanprize_frontend/utils/constants.dart';
import '../services/slider_service.dart';
import 'package:scanprize_frontend/models/slider_model.dart';

class ImageSlider extends StatefulWidget {
  const ImageSlider({super.key});
  @override
  ImageSliderState createState() => ImageSliderState();
}

class ImageSliderState extends State<ImageSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  List<SliderModel> slides = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSliders();
  }

  Future<void> refreshSlider() async {
    await _fetchSliders();
  }

  Future<void> _fetchSliders() async {
    try {
      final fetchedSlides = await ApiService().getSliders();
      setState(() {
        slides = fetchedSlides;
        isLoading = false;
      });
      if (slides.isNotEmpty) {
        _startAutoPlay();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle error
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < slides.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (slides.isEmpty) {
      return const SizedBox(); // Return empty if no slides
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 25, bottom: 16),
          child: Text(
            "ដំណឹង & ព័ត៍មានផ្សេងៗ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return _buildSlide(
                    slide.imageUrls.isNotEmpty ? slide.imageUrls[0] : '',
                    slide.title,
                    slide.subtitle,
                    slide.actionButton,
                    slide,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlide(
    String imageUrl,
    String title,
    String subtitle,
    String actionButton,
    SliderModel slider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade100, Colors.purple.shade100],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 30, right: 30),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => BlogDetailPage(slider: slider),
                          ),
                        );
                      },
                      child: Text(
                        actionButton,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Container(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Correct with 219 line code changes
