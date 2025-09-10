import 'package:flutter/material.dart';
import 'dart:async';
import 'firstScreen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  final int _totalPages = 3; // Number of intro pages
  bool _isAutoSliding = true;

  @override
  void initState() {
    super.initState();
    // Start auto-sliding every 5 seconds
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_isAutoSliding && _currentPage < _totalPages - 1) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else if (_isAutoSliding) {
        // On last page, navigate to Firstscreen
        _navigateToFirstScreen();
      }
    });
  }

  void _navigateToFirstScreen() {
    _timer?.cancel(); // Stop the timer
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const Firstscreen(),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView for sliding pages
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
                _isAutoSliding = false; // Pause auto-slide on manual swipe
                _timer?.cancel();
                // Restart auto-slide after a brief pause
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    _isAutoSliding = true;
                    _startAutoSlide();
                  }
                });
              });
            },
            children: [
              _buildIntroPage(
                imagePath: "assets/images/intro-design.png",
                title: "Welcome to App!",
                description: "Have a good day",
              ),
              _buildIntroPage(
                imagePath: "assets/images/intro-design2.png", // Replace with your image
                title: "Discover Amazing Features",
                description: "Explore and enjoy our unique features.",
              ),
              _buildIntroPage(
                imagePath: "assets/images/intro-design3.png", // Replace with your image
                title: "Get Started Now",
                description: "Join us and start your journey!",
              ),
            ],
          ),
          // Page Indicators
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPages, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: _currentPage == index ? 12.0 : 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? const Color.fromARGB(255, 249, 102, 0)
                        : Colors.grey.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
          // Skip Button
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: _navigateToFirstScreen,
              child: const Text(
                "Skip",
                style: TextStyle(
                  fontSize: 18,
                  color: Color.fromARGB(255, 249, 102, 0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build each intro page
  Widget _buildIntroPage({
    required String imagePath,
    required String title,
    required String description,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 250),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 249, 102, 0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color.fromARGB(255, 249, 109, 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}