import 'package:gb_merchant/authentication/verify_code.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text(
            'ភ្លេចពាក្យសម្ងាត់',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'សូមបញ្ចូលលេខទូរស័ព្ទរបស់អ្នកដើម្បីកំណត់ពាក្យសម្ងាត់របស់អ្នកឡើងវិញ',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 60),
              TextField(
                decoration: InputDecoration(
                  labelText: 'លេខទូរស័ព្ទ',
                  labelStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                  hintText: 'បញ្ចូលលេខទូរស័ព្ទរបស់អ្នក',
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  prefixIcon: Icon(Icons.phone, color: Colors.grey[600]),
                ),
                style: const TextStyle(fontSize: 18, color: Colors.black),
              ),
              const SizedBox(height: 80),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => VerifyCode()),
                    );
                  },
                  child: const Text(
                    'ទទួលយកកូដ',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
