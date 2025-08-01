// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'signIn.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../services/user_server.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _obscureText = true;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _customerTypeController = TextEditingController();
  // ignore: unused_field
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final _apiService = ApiService();
  bool _isLoading = false;
  String? _countryCode;
  String? _phoneNumber;

  bool _isAgree = false;
  String? _agreeError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor, // Top background color
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            SizedBox(height: 100),
            // Logo
            Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: 25,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      'បង្កើតគណនី',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 30, // To balance the row alignment
                ),
              ],
            ),
            SizedBox(height: 50),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 30),
                      Title(
                        color: Colors.white,
                        child: Align(
                          alignment:
                              Alignment
                                  .centerLeft, // Aligns the text to the right
                          child: Text(
                            'សូមបំពេញបង្កើតគណនីរបស់អ្នក',
                            style: TextStyle(fontSize: 24, color: Colors.black),
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                      TextFormField(
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'សូមបញ្ចូលឈ្មោះពេញរបស់អ្នក';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'សូមបញ្ចូលឈ្មោះពេញរបស់អ្នក',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          prefixIcon: Icon(
                            Icons.person,
                            color: Colors.grey[600],
                          ),
                        ),
                        style: TextStyle(fontSize: 18, color: Colors.black),
                      ),
                      SizedBox(height: 18),
                      IntlPhoneField(
                        decoration: InputDecoration(
                          hintText: 'សូមបញ្ចូលលេខទូរស័ព្ទអ្នក',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                        ),
                        initialCountryCode: 'KH',
                        disableLengthCheck:
                            true, // Add this line to disable length validation
                        onChanged: (phone) {
                          _countryCode = phone.countryCode;
                          _phoneNumber = phone.number;
                        },
                        validator: (phone) {
                          if (phone == null || phone.number.isEmpty) {
                            return 'សូមបញ្ចូលលេខទូរស័ព្ទរបស់អ្នក';
                          }
                          if (phone.number.startsWith('0')) {
                            return 'លេខទូរស័ព្ទមិនគួរចាប់ផ្តើមដោយលេខ 0 ទេ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'បញ្ចូលលេខកូដ',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          prefixIcon: Icon(Icons.sms, color: Colors.grey[600]),
                          suffixIcon: TextButton(
                            onPressed: () {
                              // Add your logic for "Get Code" here
                              print("Get Code clicked");
                            },
                            child: Text(
                              'ទទួលយកកូដ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                        style: TextStyle(fontSize: 18, color: Colors.black),
                      ),
                      SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        value:
                            null, // Initial value (set to null to show the hint by default)
                        onChanged: (value) {
                          _addressController.text =
                              value ?? ''; // Update the controller's value
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'សូមជ្រើសរើសខេត្តរបស់អ្នក';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'សូមជ្រើសរើសខេត្តរបស់អ្នក',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: Colors.grey[600],
                          ),
                        ),
                        items:
                            [
                                  'ភ្នំពេញ',
                                  'កណ្ដាល',
                                  'កំពង់ចាម',
                                  'កំពង់ឆ្នាំង',
                                  'កំពង់ស្ពឺ',
                                  'កំពង់ធំ',
                                  'កំពត',
                                  'កែប',
                                  'កោះកុង',
                                  'ក្រចេះ',
                                  'មណ្ឌលគិរី',
                                  'ឧត្តរមានជ័យ',
                                  'បាត់ដំបង',
                                  'ប៉ៃលិន',
                                  'ព្រះសីហនុ',
                                  'ព្រះវិហារ',
                                  'ពោធិ៍សាត់',
                                  'រតនគិរី',
                                  'សៀមរាប',
                                  'ស្ទឹងត្រែង',
                                  'ស្វាយរៀង',
                                  'តាកែវ',
                                  'ត្បូងឃ្មុំ',
                                ]
                                .map(
                                  (province) => DropdownMenuItem<String>(
                                    value: province,
                                    child: Text(province),
                                  ),
                                )
                                .toList(), // Maps provinces to dropdown items
                      ),
                      SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        value:
                            null, // Initial value (set to null to show the hint by default)
                        onChanged: (value) {
                          _customerTypeController.text =
                              value ?? ''; // Update the controller's value
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'សូមជ្រើសរើសប្រភេទអ្នកប្រើប្រាស់';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'សូមជ្រើសរើសប្រភេទអ្នកប្រើប្រាស់',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          prefixIcon: Icon(
                            Icons.category,
                            color: Colors.grey[600],
                          ),
                        ),
                        items:
                            ['អតិថិជនធម្មតា', 'អ្នកលក់រាយ', 'អ្នកលក់ធំ']
                                .map(
                                  (province) => DropdownMenuItem<String>(
                                    value: province,
                                    child: Text(province),
                                  ),
                                )
                                .toList(), // Maps provinces to dropdown items
                      ),
                      SizedBox(height: 18),
                      TextFormField(
                        obscureText: _obscureText,
                        controller: _passwordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'សូមបង្កើតពាក្យសម្ងាត់អ្នក';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'បង្កើតពាក្យសម្ងាត់របស់អ្នក',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          prefixIcon: Icon(Icons.lock, color: Colors.grey[600]),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                        style: TextStyle(fontSize: 18, color: Colors.black),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: _isAgree,
                            onChanged: (value) {
                              setState(() {
                                _isAgree = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isAgree = !_isAgree;
                                });
                              },
                              child: Text(
                                'ខ្ញុំយល់ព្រមលើលក្ខខណ្ឌ និងបញ្ជាក់ថាខ្ញុំមានអាយុលើស 18 ឆ្នាំ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_agreeError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _agreeError!,
                              style: TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ),
                      const SizedBox(height: 40),
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
                          // Update your signup button onPressed:
                          onPressed:
                              _isLoading
                                  ? null
                                  : () async {
                                    // --- insert DOB validation logic here ---
                                    // Clear previous errors
                                    // --- Tickbox agreement check ---
                                    setState(() {
                                      _agreeError = null;
                                    });
                                    if (!_isAgree) {
                                      setState(() {
                                        _agreeError =
                                            'សូមយល់ព្រមលើលក្ខខណ្ឌ និងបញ្ជាក់ថាអ្នកអាយុលើស 18 ឆ្នាំ';
                                      });
                                      return;
                                    }
                                    if (_formKey.currentState!.validate()) {
                                      setState(() => _isLoading = true);
                                      try {
                                        final fullPhoneNumber =
                                            '($_countryCode) $_phoneNumber';
                                        final user = Users(
                                          fullName: _nameController.text,
                                          address: _addressController.text,
                                          phoneNumber: fullPhoneNumber,
                                          password: _passwordController.text,
                                        );

                                        final result = await _apiService.signUp(
                                          user,
                                        );
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              backgroundColor: Colors.green,
                                              content: Text(
                                                'ការចុះឈ្មោះទទួលបានជោគជ័យ!',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          );
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => LoginPage(),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(e.toString()),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isLoading = false);
                                        }
                                      }
                                    }
                                  },
                          child: Text(
                            'បង្កើតគណនី',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text("មានគណនីហើយមែនទេ ?"),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginPage(),
                                ),
                              );
                            },
                            child: Text(
                              'ចូលទៅកាន់គណនី',
                              style: TextStyle(color: AppColors.secondaryColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//Correct with 583 line code changes
