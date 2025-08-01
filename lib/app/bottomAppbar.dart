import 'package:flutter/material.dart';
import 'package:scanprize_frontend/main/TransactionPage.dart';
import 'package:scanprize_frontend/main/ProfilePage.dart';
import 'package:scanprize_frontend/utils/constants.dart';
import 'package:scanprize_frontend/widgets/customDrawer.dart';
import '../main/HomePage.dart';
// import '../main/SpinWheelPage.dart';
import '../widgets/appbar_widget.dart';
import '../authentication/signIn.dart';
import '../main/Scan_PopUp.dart';
import '../components/user_dashboard.dart'; // <-- Needed for ThreeBoxSectionState

class RomlousApp extends StatefulWidget {
  final String phoneNumber;
  const RomlousApp({super.key, required this.phoneNumber});

  @override
  State<RomlousApp> createState() => _RomlousAppState();
}

class _RomlousAppState extends State<RomlousApp> {
  int _selectedIndex = 0;
  bool _centerButtonActive = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // Use the public state class in the key!
  final GlobalKey<ThreeBoxSectionState> dashboardKey =
      GlobalKey<ThreeBoxSectionState>();
  bool _isLoggedIn = true;

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomePage(dashboardKey: dashboardKey),
      // Spinwheelpage(),
      Giftpage(),
      ProfilePage(phoneNumber: widget.phoneNumber, onLogout: _handleLogout),
    ];
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

  void _onCenterButtonPressed() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const OpenScan()));
    dashboardKey.currentState?.refreshBalances();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginPage();
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        onMenuPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        phoneNumber: widget.phoneNumber,
      ),
      drawer: CustomDrawer(),
      body: PopScope(
        child: Navigator(
          key: _navigatorKey,
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => _widgetOptions.elementAt(_selectedIndex),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: 45, left: 16, right: 16),
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
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _buildNavItem(0, Icons.home, "ទំព័រដើម"),
            // _buildNavItem(1, Icons.card_membership, "បង្វិល"),
            const SizedBox(width: 4),
            _buildCenterButton(),
            _buildNavItem(1, Icons.notifications_outlined, "ប្រតិបត្តិការ"),
            _buildNavItem(2, Icons.person_outline, "ប្រូហ្វាល់"),
          ],
        ),
      ),
    );
  }

  // Widget _buildNavItem(int index, IconData icon, String label) {
  //   final bool isSelected = _selectedIndex == index && !_centerButtonActive;

  //   return GestureDetector(
  //     onTap: () => _onItemTapped(index),
  //     child: AnimatedContainer(
  //       duration: const Duration(milliseconds: 300),
  //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //       decoration: BoxDecoration(
  //         color: isSelected ? Colors.black : Colors.transparent,
  //         borderRadius: BorderRadius.circular(30),
  //       ),
  //       child: Row(
  //         children: [
  //           Icon(icon, color: Colors.white, size: 24),
  //           const SizedBox(width: 6),
  //           Text(
  //             label,
  //             style: const TextStyle(
  //               color: Colors.white,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            if (isSelected) const SizedBox(width: 6),
            if (isSelected)
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: _onCenterButtonPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: _centerButtonActive ? Colors.black : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.center_focus_strong,
          color: _centerButtonActive ? Colors.white : AppColors.textColor,
          size: 30,
        ),
      ),
    );
  }
}

//Correct with 208 line code changes

// import 'package:flutter/material.dart';
// import 'package:scanprize_frontend/main/TransactionPage.dart';
// import 'package:scanprize_frontend/main/ProfilePage.dart';
// import 'package:scanprize_frontend/utils/constants.dart';
// import 'package:scanprize_frontend/widgets/customDrawer.dart';
// import '../main/HomePage.dart';
// import '../main/SpinWheelPage.dart';
// import '../widgets/appbar_widget.dart';
// import '../authentication/signIn.dart';
// import '../main/Scan_PopUp.dart';
// import '../components/user_dashboard.dart'; // <-- Needed for ThreeBoxSectionState

// class RomlousApp extends StatefulWidget {
//   final String userName;
//   const RomlousApp({super.key, required this.userName});

//   @override
//   State<RomlousApp> createState() => _RomlousAppState();
// }

// class _RomlousAppState extends State<RomlousApp> {
//   int _selectedIndex = 0;
//   bool _centerButtonActive = false;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

//   // Use the public state class in the key!
//   final GlobalKey<ThreeBoxSectionState> dashboardKey =
//       GlobalKey<ThreeBoxSectionState>();
//   bool _isLoggedIn = true;

//   late final List<Widget> _widgetOptions;

//   @override
//   void initState() {
//     super.initState();
//     _widgetOptions = <Widget>[
//       HomePage(dashboardKey: dashboardKey),
//       Spinwheelpage(),
//       Giftpage(),
//       ProfilePage(userName: widget.userName, onLogout: _handleLogout),
//     ];
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
//     setState(() {
//       _centerButtonActive = true;
//     });
//     await Navigator.of(
//       context,
//     ).push(MaterialPageRoute(builder: (context) => const OpenScan()));
//     dashboardKey.currentState?.refreshSummary();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isLoggedIn) {
//       return LoginPage();
//     }

//     return Scaffold(
//       key: _scaffoldKey,
//       appBar: CustomAppBar(
//         onMenuPressed: () {
//           _scaffoldKey.currentState?.openDrawer();
//         },
//         userName: widget.userName,
//       ),
//       drawer: CustomDrawer(),
//       body: PopScope(
//         child: Navigator(
//           key: _navigatorKey,
//           onGenerateRoute: (settings) {
//             return MaterialPageRoute(
//               builder: (context) => _widgetOptions.elementAt(_selectedIndex),
//             );
//           },
//         ),
//       ),
//       bottomNavigationBar: Container(
//         height: 80,
//         margin: const EdgeInsets.only(bottom: 45, left: 16, right: 16),
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
//         padding: const EdgeInsets.symmetric(horizontal: 25),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: <Widget>[
//             // Home
//             _buildNavItem(0, Icons.home, "ទំព័រមុខ"),
//             _buildNavItem(1, Icons.card_giftcard, "បង្វិល"),
//             // Center Scan Button
//             _buildCenterButton(),
//             // Gift/Transaction (was index 1)
//             _buildNavItem(
//               2,
//               Icons.notifications_none_outlined,
//               "ប្រតិបត្តិការ",
//             ),
//             // Profile (was index 2)
//             _buildNavItem(3, Icons.person, "ប្រូហ្វាល់"),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem(int index, IconData icon, String label) {
//     final bool isSelected = _selectedIndex == index && !_centerButtonActive;
//     return Expanded(
//       child: GestureDetector(
//         onTap: () => _onItemTapped(index),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.end,
//           children: [
//             Icon(
//               icon,
//               color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
//               size: 28,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 color:
//                     isSelected ? Colors.white : Colors.white.withOpacity(0.7),
//                 fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                 fontSize: 12,
//               ),
//               textAlign: TextAlign.center,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 10),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCenterButton() {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10.0),
//       child: GestureDetector(
//         onTap: _onCenterButtonPressed,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 300),
//           width: 62,
//           height: 62,
//           decoration: BoxDecoration(
//             color: _centerButtonActive ? Colors.black : Colors.white,
//             shape: BoxShape.circle,
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.2),
//                 blurRadius: 10,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.center_focus_strong,
//                 color: _centerButtonActive ? Colors.white : AppColors.textColor,
//                 size: 35,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
