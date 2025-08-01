import 'package:flutter/material.dart';
import '../components/slider.dart';
import '../components/user_dashboard.dart';

class HomePage extends StatelessWidget {
  final GlobalKey<ThreeBoxSectionState> dashboardKey;
  HomePage({required this.dashboardKey, super.key});
  final GlobalKey<ImageSliderState> sliderKey = GlobalKey<ImageSliderState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.orange),
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 50),
              ThreeBoxSection(key: dashboardKey, sliderKey: sliderKey),
              const SizedBox(height: 20),
              ImageSlider(key: sliderKey),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

//Correct with 33 line code changes
