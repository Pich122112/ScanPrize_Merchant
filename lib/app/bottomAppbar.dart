// // import 'package:flutter/material.dart';
// // import 'package:gb_merchant/main/ProfilePage.dart';
// // import 'package:gb_merchant/utils/constants.dart';
// // import 'package:gb_merchant/widgets/customDrawer.dart';
// // import '../main/HomePage.dart';
// // // import '../main/SpinWheelPage.dart';
// // import '../widgets/appbar_widget.dart';
// // import '../authentication/signUp.dart';
// // import '../main/Scan_PopUp.dart';
// // import '../components/user_dashboard.dart';
// // import 'package:connectivity_plus/connectivity_plus.dart';
// // import 'package:easy_localization/easy_localization.dart';
// // import 'package:shared_preferences/shared_preferences.dart';

// // class RomlousApp extends StatefulWidget {
// //   const RomlousApp({super.key});

// //   @override
// //   State<RomlousApp> createState() => _RomlousAppState();
// // }

// // class _RomlousAppState extends State<RomlousApp> {
// //   int _selectedIndex = 0;
// //   bool _centerButtonActive = false;
// //   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
// //   final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
// //   String _phoneNumber = '';

// //   bool _noInternet = false;
// //   final GlobalKey<ThreeBoxSectionState> dashboardKey =
// //       GlobalKey<ThreeBoxSectionState>();
// //   bool _isLoggedIn = true;

// //   late final List<Widget> _widgetOptions;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadPhoneNumber();

// //     _widgetOptions = <Widget>[
// //       HomePage(dashboardKey: dashboardKey),
// //       ContactUsPage(),
// //     ];

// //     // Connectivity listener
// //     Connectivity().onConnectivityChanged.listen((results) {
// //       setState(() {
// //         _noInternet =
// //             results.isEmpty ||
// //             results.every((r) => r == ConnectivityResult.none);
// //       });
// //     });

// //     // Initial check
// //     Connectivity().checkConnectivity().then((results) {
// //       setState(() {
// //         _noInternet =
// //             results.isEmpty ||
// //             results.every((r) => r == ConnectivityResult.none);
// //       });
// //     });
// //   }

// //   Future<void> _loadPhoneNumber() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     setState(() {
// //       // Make sure you use the same key you use in sign-in/sign-up: usually "phoneNumber"
// //       _phoneNumber = prefs.getString('phoneNumber') ?? '';
// //     });
// //   }

// //   void _handleLogout() {
// //     setState(() {
// //       _isLoggedIn = false;
// //     });
// //   }

// //   void _onItemTapped(int index) {
// //     setState(() {
// //       _selectedIndex = index;
// //       _centerButtonActive = false;
// //       _navigatorKey.currentState?.popUntil((route) => route.isFirst);
// //     });
// //   }

// //   void _onCenterButtonPressed() async {
// //     await Navigator.of(context).push(
// //       MaterialPageRoute(
// //         builder:
// //             (context) => OpenScan(
// //               onPrizeScanned: (issuer, newAmount) async {
// //                 await dashboardKey.currentState?.refreshBalances();
// //               },
// //             ),
// //       ),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     if (!_isLoggedIn) {
// //       return SignUpPage();
// //     }

// //     final screenWidth = MediaQuery.of(context).size.width;
// //     final screenHeight = MediaQuery.of(context).size.height;
// //     final isTablet = screenWidth > 600;

// //     return Scaffold(
// //       key: _scaffoldKey,
// //       appBar: CustomAppBar(
// //         onMenuPressed: () {
// //           _scaffoldKey.currentState?.openDrawer();
// //         },
// //         phoneNumber: _phoneNumber,
// //       ),
// //       drawer: ProfileDrawer(
// //         phoneNumber: _phoneNumber,
// //         onLogout: () {
// //           Navigator.pop(context);
// //           _handleLogout();
// //         },
// //       ),
// //       body: Column(
// //         children: [
// //           if (_noInternet)
// //             Container(
// //               width: double.infinity,
// //               padding: EdgeInsets.symmetric(
// //                 vertical: screenHeight * 0.018,
// //                 horizontal: screenWidth * 0.04,
// //               ),
// //               decoration: BoxDecoration(
// //                 color: Colors.red.shade600,
// //                 borderRadius: BorderRadius.circular(8),
// //                 boxShadow: [
// //                   BoxShadow(
// //                     color: Colors.black26,
// //                     blurRadius: 4,
// //                     offset: Offset(0, 2),
// //                   ),
// //                 ],
// //               ),
// //               margin: EdgeInsets.all(screenWidth * 0.04),
// //               child: Row(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   Icon(
// //                     Icons.wifi_off,
// //                     color: Colors.white,
// //                     size: isTablet ? 28 : 22,
// //                   ),
// //                   SizedBox(width: screenWidth * 0.03),
// //                   Expanded(
// //                     child: Text(
// //                       "គ្មានការតភ្ជាប់អ៊ីនធឺណិត សូមពិនិត្យការកំណត់បណ្ដាញរបស់អ្នក។",
// //                       style: TextStyle(
// //                         color: Colors.white,
// //                         fontWeight: FontWeight.w600,
// //                         fontSize: isTablet ? 18 : 14,
// //                         fontFamily: 'KhmerFont',
// //                       ),
// //                       textAlign: TextAlign.center,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),

// //           Expanded(
// //             child: PopScope(
// //               child: Navigator(
// //                 key: _navigatorKey,
// //                 onGenerateRoute: (settings) {
// //                   return MaterialPageRoute(
// //                     builder:
// //                         (context) => _widgetOptions.elementAt(_selectedIndex),
// //                   );
// //                 },
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),

// //       // ✅ Responsive Bottom Navigation Bar
// //       bottomNavigationBar: Container(
// //         height: screenHeight * 0.085,
// //         margin: EdgeInsets.only(
// //           bottom: screenHeight * 0.06,
// //           left: screenWidth * 0.04,
// //           right: screenWidth * 0.04,
// //         ),
// //         decoration: BoxDecoration(
// //           color: AppColors.primaryColor,
// //           borderRadius: BorderRadius.circular(50),
// //           boxShadow: [
// //             BoxShadow(
// //               color: Colors.black.withOpacity(0.2),
// //               blurRadius: 10,
// //               offset: const Offset(0, 4),
// //             ),
// //           ],
// //         ),
// //         padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
// //         child: Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: <Widget>[
// //             _buildNavItem(0, Icons.home, "home", screenWidth, isTablet),
// //             _buildCenterButton(screenWidth),
// //             _buildNavItem(
// //               1,
// //               Icons.support_agent,
// //               "Contact",
// //               screenWidth,
// //               isTablet,
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildNavItem(
// //     int index,
// //     IconData icon,
// //     String key,
// //     double screenWidth,
// //     bool isTablet,
// //   ) {
// //     final bool isSelected = _selectedIndex == index;
// //     final localeCode = context.locale.languageCode;

// //     return GestureDetector(
// //       onTap: () => _onItemTapped(index),
// //       child: AnimatedContainer(
// //         duration: const Duration(milliseconds: 300),
// //         padding: EdgeInsets.symmetric(
// //           horizontal: screenWidth * 0.04,
// //           vertical: screenWidth * 0.015,
// //         ),
// //         decoration: BoxDecoration(
// //           color: isSelected ? Colors.black : Colors.transparent,
// //           border: Border.all(color: Colors.white, width: 1.8),
// //           borderRadius: BorderRadius.circular(30),
// //         ),
// //         child: Row(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Icon(icon, color: Colors.white, size: isTablet ? 26 : 20),
// //             SizedBox(width: screenWidth * 0.015),
// //             Text(
// //               key.tr(),
// //               style: TextStyle(
// //                 fontSize: isTablet ? 16 : 13,
// //                 color: Colors.white,
// //                 fontWeight: FontWeight.bold,
// //                 fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildCenterButton(double screenWidth) {
// //     final buttonSize = screenWidth * 0.18;

// //     return GestureDetector(
// //       onTap: _onCenterButtonPressed,
// //       child: AnimatedContainer(
// //         duration: const Duration(milliseconds: 300),
// //         width: buttonSize,
// //         height: buttonSize,
// //         decoration: BoxDecoration(
// //           color: _centerButtonActive ? Colors.black : AppColors.primaryColor,
// //           shape: BoxShape.circle,
// //           border: Border.all(color: Colors.white, width: 3.5),
// //         ),
// //         child: Icon(
// //           Icons.center_focus_strong,
// //           color: Colors.white,
// //           size: buttonSize * 0.55,
// //         ),
// //       ),
// //     );
// //   }
// // }

// // //Correct with 292 line code changes

// import 'dart:convert';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gb_merchant/main/ProfilePage.dart';
import 'package:gb_merchant/screens/firstScreen.dart';
import 'package:gb_merchant/services/firebase_service.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:gb_merchant/widgets/customDrawer.dart';
import '../main/HomePage.dart';
// import '../main/SpinWheelPage.dart';
import '../services/user_server.dart';
import '../widgets/appbar_widget.dart';
// ignore: unused_import
import '../authentication/signUp.dart';
import '../main/Scan_PopUp.dart';
import '../components/user_dashboard.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RomlousApp extends StatefulWidget {
  const RomlousApp({super.key});

  @override
  State<RomlousApp> createState() => _RomlousAppState();
}

class _RomlousAppState extends State<RomlousApp> {
  int _selectedIndex = 0;
  bool _centerButtonActive = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String _phoneNumber = '';

  bool _noInternet = false;
  final GlobalKey<ThreeBoxSectionState> dashboardKey =
      GlobalKey<ThreeBoxSectionState>();
  bool _isLoggedIn = true;

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _loadPhoneNumber();
    _refreshUserDataAndCheckStatus(); // Add this line

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

  // Add this method to check user status from SharedPreferences
  Future<int?> _getUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      try {
        final userData = json.decode(userDataString);
        return userData['data']['status'] as int?;
      } catch (e) {
        print('Error parsing user data: $e');
      }
    }
    return null;
  }

  Future<void> _loadPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Make sure you use the same key you use in sign-in/sign-up: usually "phoneNumber"
      _phoneNumber = prefs.getString('phoneNumber') ?? '';
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

  // Add this method to show approval dialog
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

  // Modify the _onCenterButtonPressed method to refresh user data before checking status
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

  // Add this method to refresh user data and check status
  Future<void> _refreshUserDataAndCheckStatus() async {
    try {
      // Refresh user data from API
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        final userProfile = await ApiService.getUserProfile(token);
        // ignore: unnecessary_null_comparison
        if (userProfile != null && userProfile['success'] == true) {
          // Save updated user data
          await prefs.setString('user_data', jsonEncode(userProfile));

          // Check if status changed from 2 to 1
          final newStatus = userProfile['data']['status'] as int?;
          if (newStatus == 1) {
            print('DEBUG: User status updated from 2 to 1 - approval granted');
            // You could show a success message here if needed
          }
        }
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  // Add this method to refresh balances
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
                color: Colors.red.shade600,
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
                    size: isTablet ? 28 : 22,
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Text(
                      "no_internet_connection".tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 18 : 14,
                        fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                      ),
                      textAlign: TextAlign.center,
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
          bottom: screenHeight * 0.025,
          left: screenWidth * 0.04,
          right: screenWidth * 0.04,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
              "Contact",
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
          vertical: screenWidth * 0.015,
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
      onTap: _onCenterButtonPressed, // Use the modified method
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: _centerButtonActive ? Colors.black : AppColors.primaryColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3.5),
        ),
        child: Icon(
          Icons.center_focus_strong,
          color: Colors.white,
          size: buttonSize * 0.55,
        ),
      ),
    );
  }
}

//Correct with 720 line code changes

// import 'package:flutter/material.dart';
// import 'package:gb_merchant/main/ProfilePage.dart';
// import 'package:gb_merchant/utils/constants.dart';
// import 'package:gb_merchant/widgets/customDrawer.dart';
// import '../main/HomePage.dart';
// // import '../main/SpinWheelPage.dart';
// import '../widgets/appbar_widget.dart';
// import '../authentication/signUp.dart';
// import '../main/Scan_PopUp.dart';
// import '../components/user_dashboard.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class RomlousApp extends StatefulWidget {
//   const RomlousApp({super.key});

//   @override
//   State<RomlousApp> createState() => _RomlousAppState();
// }

// class _RomlousAppState extends State<RomlousApp> {
//   int _selectedIndex = 0;
//   bool _centerButtonActive = false;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
//   String _phoneNumber = '';

//   bool _noInternet = false;
//   final GlobalKey<ThreeBoxSectionState> dashboardKey =
//       GlobalKey<ThreeBoxSectionState>();
//   bool _isLoggedIn = true;

//   late final List<Widget> _widgetOptions;

//   @override
//   void initState() {
//     super.initState();
//     _loadPhoneNumber();

//     _widgetOptions = <Widget>[
//       HomePage(dashboardKey: dashboardKey),
//       ContactUsPage(),
//     ];

//     // Connectivity listener
//     Connectivity().onConnectivityChanged.listen((results) {
//       setState(() {
//         _noInternet =
//             results.isEmpty ||
//             results.every((r) => r == ConnectivityResult.none);
//       });
//     });

//     // Initial check
//     Connectivity().checkConnectivity().then((results) {
//       setState(() {
//         _noInternet =
//             results.isEmpty ||
//             results.every((r) => r == ConnectivityResult.none);
//       });
//     });
//   }

//   Future<void> _loadPhoneNumber() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       // Make sure you use the same key you use in sign-in/sign-up: usually "phoneNumber"
//       _phoneNumber = prefs.getString('phoneNumber') ?? '';
//     });
//   }

//   void _handleLogout() {
//     setState(() {
//       _isLoggedIn = false;
//     });
//   }

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//       _centerButtonActive = false;
//       _navigatorKey.currentState?.popUntil((route) => route.isFirst);
//     });
//   }

//   void _onCenterButtonPressed() async {
//     await Navigator.of(context).push(
//       MaterialPageRoute(
//         builder:
//             (context) => OpenScan(
//               onPrizeScanned: (issuer, newAmount) async {
//                 await dashboardKey.currentState?.refreshBalances();
//               },
//             ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isLoggedIn) {
//       return SignUpPage();
//     }

//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final isTablet = screenWidth > 600;

//     return Scaffold(
//       key: _scaffoldKey,
//       appBar: CustomAppBar(
//         onMenuPressed: () {
//           _scaffoldKey.currentState?.openDrawer();
//         },
//         phoneNumber: _phoneNumber,
//       ),
//       drawer: ProfileDrawer(
//         phoneNumber: _phoneNumber,
//         onLogout: () {
//           Navigator.pop(context);
//           _handleLogout();
//         },
//       ),
//       body: Column(
//         children: [
//           if (_noInternet)
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.symmetric(
//                 vertical: screenHeight * 0.018,
//                 horizontal: screenWidth * 0.04,
//               ),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade600,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black26,
//                     blurRadius: 4,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               margin: EdgeInsets.all(screenWidth * 0.04),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.wifi_off,
//                     color: Colors.white,
//                     size: isTablet ? 28 : 22,
//                   ),
//                   SizedBox(width: screenWidth * 0.03),
//                   Expanded(
//                     child: Text(
//                       "គ្មានការតភ្ជាប់អ៊ីនធឺណិត សូមពិនិត្យការកំណត់បណ្ដាញរបស់អ្នក។",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                         fontSize: isTablet ? 18 : 14,
//                         fontFamily: 'KhmerFont',
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//           Expanded(
//             child: PopScope(
//               child: Navigator(
//                 key: _navigatorKey,
//                 onGenerateRoute: (settings) {
//                   return MaterialPageRoute(
//                     builder:
//                         (context) => _widgetOptions.elementAt(_selectedIndex),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),

//       // ✅ Responsive Bottom Navigation Bar
//       bottomNavigationBar: Container(
//         height: screenHeight * 0.085,
//         margin: EdgeInsets.only(
//           bottom: screenHeight * 0.06,
//           left: screenWidth * 0.04,
//           right: screenWidth * 0.04,
//         ),
//         decoration: BoxDecoration(
//           color: AppColors.primaryColor,
//           borderRadius: BorderRadius.circular(50),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.2),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: <Widget>[
//             _buildNavItem(0, Icons.home, "home", screenWidth, isTablet),
//             _buildCenterButton(screenWidth),
//             _buildNavItem(
//               1,
//               Icons.support_agent,
//               "contactus",
//               screenWidth,
//               isTablet,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem(
//     int index,
//     IconData icon,
//     String key,
//     double screenWidth,
//     bool isTablet,
//   ) {
//     final bool isSelected = _selectedIndex == index;
//     final localeCode = context.locale.languageCode;

//     return GestureDetector(
//       onTap: () => _onItemTapped(index),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         padding: EdgeInsets.symmetric(
//           horizontal: screenWidth * 0.04,
//           vertical: screenWidth * 0.015,
//         ),
//         decoration: BoxDecoration(
//           color: isSelected ? Colors.black : Colors.transparent,
//           border: Border.all(color: Colors.white, width: 1.8),
//           borderRadius: BorderRadius.circular(30),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, color: Colors.white, size: isTablet ? 26 : 20),
//             SizedBox(width: screenWidth * 0.015),
//             Text(
//               key.tr(),
//               style: TextStyle(
//                 fontSize: isTablet ? 16 : 13,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCenterButton(double screenWidth) {
//     final buttonSize = screenWidth * 0.18;

//     return GestureDetector(
//       onTap: _onCenterButtonPressed,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         width: buttonSize,
//         height: buttonSize,
//         decoration: BoxDecoration(
//           color: _centerButtonActive ? Colors.black : AppColors.primaryColor,
//           shape: BoxShape.circle,
//           border: Border.all(color: Colors.white, width: 3.5),
//         ),
//         child: Icon(
//           Icons.center_focus_strong,
//           color: Colors.white,
//           size: buttonSize * 0.55,
//         ),
//       ),
//     );
//   }
// }

// //Correct with 292 line code changes
