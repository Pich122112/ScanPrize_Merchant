import 'dart:io'; // Required for File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:shared_preferences/shared_preferences.dart';
import '../components/ProfileButton.dart';
import '../components/privacy_policy.dart'; // Import your PrivacyPolicy widget

class ProfilePage extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback onLogout;

  const ProfilePage({
    super.key,
    required this.phoneNumber,
    required this.onLogout,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  String formatPhoneNumber(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');

    // Remove 855 country code if present at the start
    if (digits.startsWith('855')) {
      digits = digits.substring(3);
    }
    // Remove leading + if any (already handled by \D above)
    // Add leading zero if not present
    if (!digits.startsWith('0')) {
      digits = '0$digits';
    }
    // Format 3-3-3 for Cambodian numbers
    if (digits.length == 9) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }
    // fallback for other lengths
    return digits;
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImagePath = prefs.getString('profileImagePath');
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImagePath = pickedFile.path;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', pickedFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    const khmerFont = 'KhmerFont';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          // <-- Make whole content scrollable
          child: Column(
            children: [
              const SizedBox(height: 40),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 90,
                      backgroundImage:
                          _profileImagePath != null
                              ? FileImage(File(_profileImagePath!))
                              : const AssetImage('assets/images/user.png')
                                  as ImageProvider,
                    ),
                    Positioned(
                      bottom: 4,
                      right: 16,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                formatPhoneNumber(widget.phoneNumber),
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 50),

              // Buttons
              const ProfileButton(
                icon: Icons.person,
                text: 'ព័ត៍មានផ្ទាល់ខ្លួនអ្នក',
              ),
              ProfileButton(
                icon: Icons.description,
                text: 'គោលការណ៍ & ឯកជនភាព',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicy(),
                    ),
                  );
                },
              ),
              const ProfileButton(
                icon: Icons.photo_album,
                text: 'ទាក់ទងមកកាន់ក្រុមហ៊ុន',
              ),

              const SizedBox(height: 20),
              // Logout button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30.0,
                  vertical: 25,
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Colors.white,
                          title: const Text(
                            'ចាកចេញ',
                            style: TextStyle(
                              fontFamily: 'KhmerFont',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: const Text(
                            'តើអ្នកប្រាកដថាចង់ចាកចេញមែនទេ?',
                            style: TextStyle(fontFamily: 'KhmerFont'),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: const Text(
                                'បោះបង់',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: 'KhmerFont',
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.clear();

                                Navigator.of(context).pop(); // Close the dialog
                                widget.onLogout(); // Call the logout callback
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'បាទ/ចាស',
                                style: TextStyle(fontFamily: 'KhmerFont'),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'ចាកចេញ',
                    style: TextStyle(fontFamily: khmerFont, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
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
