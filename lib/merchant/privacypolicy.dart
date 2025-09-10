import 'package:gb_merchant/authentication/signUp.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:flutter/material.dart';

class Agreement extends StatefulWidget {
  const Agreement({super.key});

  @override
  State<Agreement> createState() => _AgreementState();
}

class _AgreementState extends State<Agreement> {
  final ScrollController _scrollController = ScrollController();
  bool _canCheck = false;
  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!_canCheck &&
        _scrollController.offset >=
            _scrollController.position.maxScrollExtent - 10) {
      setState(() {
        _canCheck = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(251, 96, 0, 1),
              Color.fromRGBO(250, 99, 5, 1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Logo
              Center(
                child: Image.asset(
                  "assets/images/logo.png",
                  height: size.height * 0.15,
                ),
              ),

              const SizedBox(height: 8),

              // Agreement Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pill bar
                      Center(
                        child: Container(
                          width: 60,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white60,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      const Text(
                        "លក្ខខណ្ឌ និងកិច្ចព្រមព្រៀងក្នុងការប្រើប្រាស់",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'KhmerFont',
                          decoration: TextDecoration.underline,
                          decorationThickness: 0.8,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Scrollable Agreement Text
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: const Text(
                            '''
    ដោយការប្រើប្រាស់ និងចូលប្រើសេវាកម្មនេះ អ្នកយល់ព្រមនឹងគោរពតាមលក្ខខណ្ឌនៃការប្រើប្រាស់។ សេវាកម្មនេះត្រូវបានបង្កើតឡើងដើម្បីផ្តល់នូវបទពិសោធន៍ប្រើប្រាស់ដែលមានសុវត្ថិភាព ងាយស្រួល និងមានប្រសិទ្ធភាពខ្ពស់។ អ្នកប្រើប្រាស់ត្រូវមានការទទួលខុសត្រូវក្នុងការប្រើប្រាស់សេវាកម្ម និងកុំប្រើប្រាស់សម្រាប់គោលបំណងខុសច្បាប់ ឬសកម្មភាពណាដែលអាចប៉ះពាល់ដល់សិទ្ធិ និងសុវត្ថិភាពរបស់អ្នកដទៃ។

    ការប្រើប្រាស់នេះត្រូវបានគ្រប់គ្រងដោយគោលការណ៍ និងលក្ខខណ្ឌផ្តាច់មុខ ដែលអ្នកត្រូវអាន និងយល់ព្រមជាមុនសិន។ សូមអានឲ្យបានម៉ត់ចត់ ព្រោះលក្ខខណ្ឌទាំងនេះកំណត់សិទ្ធិ កាតព្វកិច្ច និងកម្រិតនៃការទទួលខុសត្រូវរបស់អ្នកប្រើប្រាស់។ ប្រសិនបើអ្នកមិនយល់ព្រមនឹងលក្ខខណ្ឌណាមួយ សូមបញ្ឈប់ការប្រើប្រាស់សេវាកម្មភ្លាមៗ។

    សេវាកម្មនេះអាចមានការផ្លាស់ប្តូរ ឬធ្វើបច្ចុប្បន្នភាពនៅពេលណាក៏បាន ដោយមិនចាំបាច់ជូនដំណឹងជាមុន។ អ្នកប្រើប្រាស់ត្រូវតែពិនិត្យ និងអនុវត្តតាមការផ្លាស់ប្តូរទាំងនោះ។ ការមិនគោរពនឹងលក្ខខណ្ឌអាចនឹងនាំឲ្យមានការបិទគណនី បោះបង់សិទ្ធិប្រើប្រាស់ ឬត្រូវទទួលខុសត្រូវតាមផ្លូវច្បាប់។

    សូមប្រើប្រាស់សេវាកម្មនេះដោយមានការទទួលខុសត្រូវ និងកុំប្រើប្រាស់ក្នុងនាមផ្ទាល់ខ្លួន ឬជាក្រុម ដើម្បីបំផ្លាញ ឬរំខានដល់ប្រព័ន្ធ សុវត្ថិភាព ឬការប្រើប្រាស់របស់អ្នកដទៃ។ ការរំលោភបំពានលើសិទ្ធិ និងលក្ខខណ្ឌអាចនឹងបណ្តាលឲ្យមានវិធានការផ្លូវច្បាប់ផ្សេងៗដែលអ្នកត្រូវទទួលខុសត្រូវទាំងស្រុង។សូមប្រើប្រាស់សេវាកម្មនេះដោយមានការទទួលខុសត្រូវ និងកុំប្រើប្រាស់ក្នុងនាមផ្ទាល់ខ្លួន ឬជាក្រុម ដើម្បីបំផ្លាញ ឬរំខានដល់ប្រព័ន្ធ សុវត្ថិភាព ឬការប្រើប្រាស់របស់អ្នកដទៃ។ ការរំលោភបំពានលើសិទ្ធិ និងលក្ខខណ្ឌអាចនឹងបណ្តាលឲ្យមានវិធានការផ្លូវច្បាប់ផ្សេងៗដែលអ្នកត្រូវទទួលខុសត្រូវទាំងស្រុង។

                            ''',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              fontFamily: 'KhmerFont',
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),

                      // Checkbox
                      InkWell(
                        onTap:
                            _canCheck
                                ? () {
                                  setState(() {
                                    _isChecked = !_isChecked;
                                  });
                                }
                                : null,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              activeColor: AppColors.primaryColor,
                              checkColor: Colors.white,
                              value: _isChecked,
                              onChanged:
                                  _canCheck
                                      ? (value) {
                                        setState(() {
                                          _isChecked = value!;
                                        });
                                      }
                                      : null,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Text(
                                  "ខ្ញុំបានអាននិងយល់ព្រមតាមលក្ខខណ្ឌ & កិច្ចព្រមព្រៀងរវាងអ្នកលក់ និងក្រុមហ៊ុន ",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'KhmerFont',
                                    color:
                                        _canCheck
                                            ? Colors.black
                                            : Colors.black38,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            label: const Text(
                              "ថយក្រោយ",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'KhmerFont',
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),

                          // Continue Button - Elevated with arrow and modern look
                          ElevatedButton.icon(
                            onPressed:
                                _isChecked
                                    ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => const SignUpPage(),
                                        ),
                                      );
                                    }
                                    : null,
                            icon: const Text(
                              "បន្ទាប់",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontFamily: 'KhmerFont',
                              ),
                            ),
                            label: const Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                              color: Colors.white,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
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

//Correct with 253 line code changes
