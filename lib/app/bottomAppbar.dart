import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gb_merchant/main/ProfilePage.dart';
import 'package:gb_merchant/screens/firstScreen.dart';
import 'package:gb_merchant/services/firebase_service.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:gb_merchant/widgets/customDrawer.dart';
import '../main/HomePage.dart';
import '../services/user_server.dart';
import '../widgets/appbar_widget.dart';
import '../main/Scan_PopUp.dart';
import '../components/user_dashboard.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/version_service.dart';
import '../widgets/update_bottom_sheet.dart';
import '../services/secure_storage_service.dart';

class RomlousApp extends StatefulWidget {
  const RomlousApp({super.key});

  @override
  State<RomlousApp> createState() => _RomlousAppState();
}

class _RomlousAppState extends State<RomlousApp>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _centerButtonActive = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String _phoneNumber = '';
  late AnimationController _shimmerController;

  bool _noInternet = false;
  final GlobalKey<ThreeBoxSectionState> dashboardKey =
      GlobalKey<ThreeBoxSectionState>();
  bool _isLoggedIn = true;

  late final List<Widget> _widgetOptions;
  late VersionService _versionService;
  // ignore: unused_field
  bool _hasCheckedUpdate = false;
  late SecureStorageService _secureStorage;

  @override
  void initState() {
    super.initState();
    _secureStorage = SecureStorageService();
    _versionService = VersionService();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadPhoneNumber();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });

    _refreshUserDataAndCheckStatus();

    _widgetOptions = <Widget>[
      HomePage(dashboardKey: dashboardKey),
      ContactUsPage(),
    ];

    // Connectivity listener
    Connectivity().onConnectivityChanged.listen((results) {
      setState(() {
        _noInternet =
            results.isEmpty ||
            results.every((r) => r == ConnectivityResult.none);
      });
    });

    // Initial check
    Connectivity().checkConnectivity().then((results) {
      setState(() {
        _noInternet =
            results.isEmpty ||
            results.every((r) => r == ConnectivityResult.none);
      });
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    print("🔍 _checkForUpdate() called");

    _hasCheckedUpdate = false;

    print("📱 Getting update status...");
    final updateStatus = await _versionService.checkUpdateAvailability();

    print("📊 Update Status: needsUpdate=${updateStatus.needsUpdate}");
    print("📊 Current Version: ${updateStatus.currentVersion}");
    print("📊 Latest Version: ${updateStatus.latestVersion}");
    print("📊 Is Force Update: ${updateStatus.isForceUpdate}");

    if (!updateStatus.needsUpdate) {
      print("❌ No update needed, returning");
      return;
    }

    if (!mounted) {
      print("⚠️ Widget not mounted, returning");
      return;
    }

    print("⏰ Waiting 500ms before showing bottom sheet...");
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) {
      print("⚠️ Widget not mounted after delay, returning");
      return;
    }

    print("🎉 Showing update bottom sheet!");
    showModalBottomSheet(
      context: context,
      isDismissible: !updateStatus.isForceUpdate,
      enableDrag: !updateStatus.isForceUpdate,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => UpdateBottomSheet(
            currentVersion: updateStatus.currentVersion,
            latestVersion: updateStatus.latestVersion,
            isForceUpdate: updateStatus.isForceUpdate,
            onSkip: () async {
              if (context.mounted) Navigator.pop(context);
            },
          ),
    );
  }

  Future<int?> _getUserStatus() async {
    // ✅ Use secure storage for token
    final token = await _secureStorage.getToken();

    if (token != null) {
      try {
        final userProfile = await ApiService.getUserProfile(token);
        // ignore: unnecessary_null_comparison
        if (userProfile != null && userProfile['success'] == true) {
          return userProfile['data']['status'] as int?;
        }
      } catch (e) {
        print('Error parsing user data: $e');
      }
    }
    return null;
  }

  Future<void> _loadPhoneNumber() async {
    final phoneNumber = await _secureStorage.getPhoneNumber();
    setState(() {
      _phoneNumber = phoneNumber ?? '';
    });
  }

  void _handleLogout() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _centerButtonActive = false;
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    });
  }

  void _showApprovalRequiredDialog(BuildContext context) {
    final localeCode = context.locale.languageCode;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 60, color: Colors.orange),
                  const SizedBox(height: 20),
                  Text(
                    'សូមអភ័យទោស អ្នកមិនអាចដំណើរការមុខងារនេះបានទេ!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'សូមរង់ចាំការអនុញ្ញាតពីក្រុមហ៊ុនជាមុនសិន',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'យល់ព្រម',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _onCenterButtonPressed() async {
    // Refresh user data first to get latest status
    await _refreshUserDataAndCheckStatus();

    // Check user status from SharedPreferences
    final userStatus = await _getUserStatus();
    print('DEBUG: User status from prefs: $userStatus');

    if (userStatus == 2) {
      // Show approval dialog for pending users
      _showApprovalRequiredDialog(context);
      return; // Stop here for pending approval users
    }

    // If status is 1 or any other value, proceed normally
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => OpenScan(
              onPrizeScanned: (issuer, newAmount) async {
                await dashboardKey.currentState?.refreshBalances();
              },
              onReturnFromScan: _refreshUserBalances, // Add this callback
            ),
      ),
    );
    // Also refresh when the page returns (in case user used back gesture)
    _refreshUserBalances();
  }

  Future<void> _refreshUserDataAndCheckStatus() async {
    try {
      // ✅ Use secure storage for token
      final token = await _secureStorage.getToken();

      if (token != null) {
        final userProfile = await ApiService.getUserProfile(token);
        // ignore: unnecessary_null_comparison
        if (userProfile != null && userProfile['success'] == true) {
          // ✅ Store only non-sensitive data in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(userProfile));

          // Also update secure storage with any updated info
          final userData = userProfile['data'];
          if (userData['phone_number'] != null) {
            await _secureStorage.setPhoneNumber(userData['phone_number']);
          }

          // Check if status changed from 2 to 1
          final newStatus = userData['status'] as int?;
          if (newStatus == 1) {
            print('DEBUG: User status updated from 2 to 1 - approval granted');
          }
        }
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  Future<void> _refreshUserBalances() async {
    try {
      // Force refresh balances using the same mechanism as notifications
      await FirebaseService.handleNotificationData({});
      dashboardKey.currentState?.refreshBalances();
    } catch (e) {
      print('Error refreshing balances: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return Firstscreen();
    }

    final localeCode = context.locale.languageCode; // 'km' or 'en'
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      key: _scaffoldKey,
      appBar: CustomAppBar(
        onMenuPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        phoneNumber: _phoneNumber,
      ),
      drawer: ProfileDrawer(
        phoneNumber: _phoneNumber,
        onLogout: () {
          Navigator.pop(context);
          _handleLogout();
        },
      ),
      body: Column(
        children: [
          if (_noInternet)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.018,
                horizontal: screenWidth * 0.04,
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              margin: EdgeInsets.all(screenWidth * 0.04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off,
                    color: Colors.white,
                    size: isTablet ? 32 : 32,
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Text(
                      "no_internet_connection".tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 18 : 16,
                        fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _noInternet = false;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: isTablet ? 20 : 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: PopScope(
              child: Navigator(
                key: _navigatorKey,
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder:
                        (context) => _widgetOptions.elementAt(_selectedIndex),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // ✅ Responsive Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: screenHeight * 0.085,
        margin: EdgeInsets.only(
          top: screenHeight * 0.015,
          bottom: screenHeight * 0.028,
          left: screenWidth * 0.04,
          right: screenWidth * 0.04,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(229, 255, 255, 255),
              blurRadius: 6,
              spreadRadius: 2, // makes it expand in all directions
              offset: Offset(0, 0), // no shift
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _buildNavItem(0, Icons.home, "home", screenWidth, isTablet),
            _buildCenterButton(screenWidth),
            _buildNavItem(
              1,
              Icons.support_agent,
              "contactus",
              screenWidth,
              isTablet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String key,
    double screenWidth,
    bool isTablet,
  ) {
    final bool isSelected = _selectedIndex == index;
    final localeCode = context.locale.languageCode;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenWidth * 0.020,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          border: Border.all(color: Colors.white, width: 1.8),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: isTablet ? 26 : 20),
            SizedBox(width: screenWidth * 0.015),
            Text(
              key.tr(),
              style: TextStyle(
                fontSize: isTablet ? 16 : 13,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton(double screenWidth) {
    final buttonSize = screenWidth * 0.18;

    return GestureDetector(
      onTap: _onCenterButtonPressed,
      child: SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer gradient shimmer border
                Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: const [
                        Colors.cyanAccent,
                        Colors.pinkAccent,
                        Colors.cyanAccent,
                      ],
                      stops: [
                        (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                        _shimmerController.value,
                        (_shimmerController.value + 0.3).clamp(0.0, 1.0),
                      ],
                    ),
                  ),
                ),
                // Inner circle
                Container(
                  width: buttonSize - 7, // border width
                  height: buttonSize - 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _centerButtonActive
                            ? Colors.black
                            : AppColors.primaryColor,
                  ),
                  child: Icon(
                    Icons.center_focus_strong,
                    color: Colors.white,
                    size: (buttonSize - 7) * 0.60,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

//Correct with 557 line code changes
