// blog_detail_page.dart
import 'package:flutter/material.dart';
import 'package:scanprize_frontend/utils/constants.dart';
import '../widgets/modern_image_slider.dart';
import '../models/slider_model.dart';

class BlogDetailPage extends StatelessWidget {
  final SliderModel slider;

  const BlogDetailPage({super.key, required this.slider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'អត្ថបទលម្អិត',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              ModernImageSlider(imageUrls: slider.imageUrls),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  slider.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryColor,
                    letterSpacing: 0.2,
                    height: 1.28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  slider.description,
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.black.withOpacity(0.74),
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

//Correct with 72 line code changes
