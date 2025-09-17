import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserInformation extends StatefulWidget {
  const UserInformation({super.key});

  @override
  State<UserInformation> createState() => _UserInformationState();
}

class _UserInformationState extends State<UserInformation> {
  String _phoneNumber = '';
  String _userName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load phone number
    setState(() {
      _phoneNumber = prefs.getString('phoneNumber') ?? '';
    });

    // Load user name from user_data
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      try {
        final userData = json.decode(userDataString);
        setState(() {
          _userName = userData['data']['name'] ?? '';
          _isLoading = false;
        });
      } catch (e) {
        print('Error parsing user data: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String formatPhoneNumber(String raw) {
    if (raw.isEmpty) return '';
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (!digits.startsWith('855')) digits = '855$digits';
    final localPart = digits.substring(3);
    return '+855 $localPart';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', pickedFile.path);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully')),
      );
    }
  }

  Future<void> _showFullImage() async {
    final prefs = await SharedPreferences.getInstance();
    final profileImagePath = prefs.getString('profileImagePath');

    if (profileImagePath != null) {
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
                  Center(
                    child: Hero(
                      tag: "profileImage",
                      child: InteractiveViewer(
                        child: Image.file(
                          File(profileImagePath),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Row(
                      children: [
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
      );
    }
  }

  Future<void> _removeProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profileImagePath');
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile image removed')));
  }

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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: AppColors.primaryColor,
      child: Scaffold(
        backgroundColor: AppColors.primaryColor,
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "ព័ត៍មានរបស់ខ្ញុំ",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'KhmerFont',
            ),
          ),
          centerTitle: true,
        ),
        body:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Profile Image
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          GestureDetector(
                            onTap: _showFullImage,
                            child: FutureBuilder(
                              future: SharedPreferences.getInstance(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final prefs = snapshot.data!;
                                  final profileImagePath = prefs.getString(
                                    'profileImagePath',
                                  );
                                  return CircleAvatar(
                                    radius: 80,
                                    backgroundImage:
                                        profileImagePath != null
                                            ? FileImage(File(profileImagePath))
                                            : const AssetImage(
                                                  'assets/images/user.png',
                                                )
                                                as ImageProvider,
                                  );
                                }
                                return const CircleAvatar(
                                  radius: 80,
                                  backgroundImage: AssetImage(
                                    'assets/images/user.png',
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 20,
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
                      const SizedBox(height: 40),

                      // Phone Number
                      buildInfoTile(
                        context,
                        icon: Icons.phone,
                        text: formatPhoneNumber(_phoneNumber),
                      ),

                      const SizedBox(height: 14),

                      // Full Name
                      buildInfoTile(
                        context,
                        icon: Icons.person,
                        text: _userName.isNotEmpty ? _userName : "UnknowName",
                        editable: true,
                      ),

                      const SizedBox(height: 14),

                      // Address
                      buildInfoTile(
                        context,
                        icon: Icons.location_on,
                        text: "ទីតាំង, ភូមិអង្គ, ស្រុកសំរោង, កំពង់ស្ពឺ",
                        editable: true,
                      ),

                      const SizedBox(height: 14),

                      // Bank
                      buildInfoTile(
                        context,
                        icon: Icons.store,
                        text: "មួយណាក៏បាន",
                        editable: true,
                      ),

                      const SizedBox(height: 14),

                      // ID Card
                      buildInfoTile(
                        context,
                        icon: Icons.credit_card_rounded,
                        text:
                            "អត្តសញ្ញាណប័ណ្ណ(មុខ)​\n033763883\nដល់កាលបរិច្ឆេទ 06 April 2030",
                        editable: true,
                      ),

                      const SizedBox(height: 14),

                      // Passport
                      buildInfoTile(
                        context,
                        icon: Icons.credit_card_rounded,
                        text:
                            "អត្តសញ្ញាណប័ណ្ណ(ក្រោយ)\n033763883\nដល់កាលបរិច្ឆេទ 06 April 2030",
                        editable: true,
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String text,
    bool editable = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'KhmerFont',
              ),
            ),
          ),
          if (editable)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white, size: 25),
              onPressed: () {
                _showEditDialog(context, text);
              },
            ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String currentValue) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: const [
              Icon(Icons.edit, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text(
                "ស្នើរសុំប្តូរព័ត៌មាន",
                style: TextStyle(
                  fontFamily: 'KhmerFont',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "បញ្ចូលព័ត៌មានថ្មី",
                  labelStyle: const TextStyle(
                    fontFamily: 'KhmerFont',
                    color: AppColors.primaryColor,
                  ),
                  prefixIcon: const Icon(Icons.text_fields),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.primaryColor,
                      width: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.red),
              label: const Text(
                "បោះបង់",
                style: TextStyle(color: Colors.red, fontFamily: 'KhmerFont'),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: () {
                String updatedValue = controller.text.trim();
                Navigator.pop(context, updatedValue);
                // TODO: update state or save to SharedPreferences
              },
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                "រក្សាទុក",
                style: TextStyle(color: Colors.white, fontFamily: 'KhmerFont'),
              ),
            ),
          ],
        );
      },
    );
  }
}
