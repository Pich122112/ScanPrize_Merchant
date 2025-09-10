import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gb_merchant/merchant/user_information.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gb_merchant/components/privacy_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class ProfileDrawer extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback onLogout;

  const ProfileDrawer({
    super.key,
    required this.phoneNumber,
    required this.onLogout,
  });

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
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

  String formatPhoneNumber(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('855')) digits = digits.substring(3);
    if (!digits.startsWith('0')) digits = '0$digits';

    if (digits.length == 9) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    } else if (digits.length == 10) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }

    return digits;
  }

  Future<void> _removeProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profileImagePath');
    setState(() {
      _profileImagePath = null;
    });
  }

  void _showFullImage(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "ProfileImage",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.95),
          body: SafeArea(
            child: Stack(
              children: [
                // Fullscreen image (no rounded shape)
                Center(
                  child: Hero(
                    tag: "profileImage",
                    child: InteractiveViewer(
                      child:
                          _profileImagePath != null
                              ? Image.file(
                                File(_profileImagePath!),
                                fit: BoxFit.contain, // show full image nicely
                              )
                              : Image.asset(
                                "assets/images/user.png",
                                fit: BoxFit.contain,
                              ),
                    ),
                  ),
                ),

                // Top bar actions
                Positioned(
                  top: 20,
                  right: 20,
                  child: Row(
                    children: [
                      if (_profileImagePath != null)
                        _buildActionButton(
                          icon: Icons.delete,
                          color: Colors.red,
                          onTap: () {
                            Navigator.pop(context);
                            _removeProfileImage();
                          },
                        ),
                      const SizedBox(width: 12),
                      _buildActionButton(
                        icon: Icons.close,
                        color: Colors.white,
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  /// Rounded frosted-glass style action button
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }

  Widget _buildLanguageTile({
    required String flag,
    required String languageName,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor, // Messenger blue
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Flag
            Text(
              flag,
              style: const TextStyle(
                fontSize: 28,
                fontFamily: 'KhmerFont',
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(width: 16),

            // Language Name
            Expanded(
              child: Text(
                languageName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'KhmerFont',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      backgroundColor: Colors.white,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Small drag handle
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 40),
              _buildLanguageTile(
                flag: '🇰🇭',
                languageName: 'khmer'.tr(),
                onTap: () => Navigator.pop(context, 'km'),
              ),

              SizedBox(height: 16),

              _buildLanguageTile(
                flag: '🇺🇸',
                languageName: 'english'.tr(),
                onTap: () => Navigator.pop(context, 'en'),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );

    if (selected != null && selected != context.locale.languageCode) {
      await context.setLocale(Locale(selected));
      if (mounted) setState(() {});
    }
  }

  // Add this method to get user name from SharedPreferences
  Future<String?> _getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      try {
        final userData = json.decode(userDataString);
        return userData['data']['name'] as String?;
      } catch (e) {
        print('Error parsing user name: $e');
      }
    }
    return null;
  }

  Future<void> _openMessenger() async {
    const messengerUrl = "https://m.me/moeys.gov.kh"; // official Messenger link
    final uri = Uri.parse(messengerUrl);

    if (await canLaunchUrl(uri)) {
      // Try opening Messenger app
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback: open in browser
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    } else {
      // Last fallback: force open in browser
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  Future<void> _showContactDialog(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Small drag handle
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 40),

              // Messenger button card
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _openMessenger();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor, // Messenger blue
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/images/messengerlogo.png",
                        height: 28,
                        width: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Chat with us on Messenger",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.locale.languageCode; // 'km' or 'en'

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: FutureBuilder<String?>(
              future: _getUserName(),
              builder: (context, snapshot) {
                final userName = snapshot.data ?? 'UnknowName';
                final formattedPhone = formatPhoneNumber(widget.phoneNumber);

                return Column(
                  children: [
                    Stack(
                      children: [
                        const SizedBox(height: 50),
                        GestureDetector(
                          onTap: () => _showFullImage(context),
                          child: Container(
                            width: 124,
                            height: 124,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundImage:
                                  _profileImagePath != null
                                      ? FileImage(File(_profileImagePath!))
                                      : const AssetImage(
                                            'assets/images/user.png',
                                          )
                                          as ImageProvider,
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Show phone number and name together in format "09885765.Name"
                    Text(
                      userName.isNotEmpty
                          ? '$formattedPhone . $userName'
                          : formattedPhone,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 40),
          // ... rest of your build method remains the same
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMenuCard(Icons.person, 'userinformation'.tr(), () {
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: "User Info",
                    pageBuilder: (context, anim1, anim2) {
                      return const UserInformation();
                    },
                  );
                }),
                _buildMenuCard(Icons.description, 'policyprivacy'.tr(), () {
                  // Open Privacy Policy dialog (same as ProfilePage)
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: "PrivacyPolicy",
                    transitionDuration: Duration.zero,
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return const Scaffold(body: PrivacyPolicy());
                    },
                  );
                }),
                _buildMenuCard(Icons.support_agent, 'contactus'.tr(), () {
                  _showContactDialog(context);
                }),
                _buildMenuCard(Icons.language, 'language'.tr(), () {
                  _showLanguageDialog(context);
                }),
                const SizedBox(height: 40),
                // Logout button
                Padding(
                  padding: const EdgeInsets.all(0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                      elevation: 2,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            title: Text(
                              'logout'.tr(),
                              style: const TextStyle(
                                fontFamily: 'KhmerFont',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Text(
                              'confirmlogout'.tr(),
                              style: const TextStyle(fontFamily: 'KhmerFont'),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pop(); // Close the dialog
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

                                  Navigator.of(context).pop(); // Close dialog
                                  widget.onLogout(); // Call logout callback
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
                    label: Text(
                      'logout'.tr(),
                      style: TextStyle(
                        fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String title, VoidCallback onTap) {
    final localeCode = context.locale.languageCode; // 'km' or 'en'
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryColor),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}

//Correct wirh 598 line code changes
