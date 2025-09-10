// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:gb_merchant/utils/constants.dart';
// import '../models/exchange_prize_model.dart';
// import '../services/exchange_prize_service.dart';

// class AllExchangePrizeList extends StatefulWidget {
//   final Map<String, dynamic> userBalances;
//   final Function(ExchangePrize) onPrizeSelected;
//   final bool isLoadingBalances;

//   const AllExchangePrizeList({
//     required this.userBalances,
//     required this.onPrizeSelected,
//     required this.isLoadingBalances,
//     Key? key,
//   }) : super(key: key);

//   @override
//   State<AllExchangePrizeList> createState() => _AllExchangePrizeListState();
// }

// class _AllExchangePrizeListState extends State<AllExchangePrizeList> {
//   late Future<List<ExchangePrize>> _prizesFuture;
//   final ExchangePrizeService _service = ExchangePrizeService();

//   @override
//   void initState() {
//     super.initState();
//     // Load prizes without force refresh initially
//     _prizesFuture = _service.fetchExchangePrizes(forceRefresh: false);
//   }

//   String getPrizeImage(ExchangePrize prize) {
//     switch (prize.walletName.toLowerCase()) {
//       case 'gb':
//         return 'assets/images/snow.png';
//       case 'bs':
//         return 'assets/images/bscan.png';
//       case 'id':
//         return 'assets/images/CanIdol.png';
//       case 'dm':
//         return 'assets/images/dollas.png';
//       default:
//         return 'assets/images/default.png';
//     }
//   }

//   // Add this helper method to translate units
//   String _translateUnit(String unit, BuildContext context) {
//     final localeCode = context.locale.languageCode;
//     if (localeCode == 'km' && unit.toLowerCase() == 'can') {
//       return 'កំប៉ុង';
//     }
//     return unit;
//   }

//   // Add this helper method to map prize wallet names to balance keys
//   String _mapWalletNameToBalanceKey(String walletName) {
//     switch (walletName.toLowerCase()) {
//       case 'gb':
//         return 'ganzberg';
//       case 'bs':
//         return 'boostrong';
//       case 'id':
//         return 'idol';
//       case 'dm':
//         return 'diamond';
//       default:
//         return walletName.toLowerCase();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<List<ExchangePrize>>(
//       future: _prizesFuture,
//       builder: (context, snapshot) {
//         // Show prizes immediately if we have them
//         if (snapshot.hasData && snapshot.data!.isNotEmpty) {
//           return _buildPrizeGrid(snapshot.data!);
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         return Center(child: Text('No Exchange Prize Available'.tr()));
//       },
//     );
//   }

//   Widget _buildPrizeGrid(List<ExchangePrize> prizes) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final isTablet = screenWidth > 600;
//     final isDesktop = screenWidth > 1024;
//     final localeCode = context.locale.languageCode;

//     int crossAxisCount = 2;
//     if (isTablet) crossAxisCount = 3;
//     if (isDesktop) crossAxisCount = 4;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: EdgeInsets.symmetric(
//             horizontal: screenWidth * 0.04,
//             vertical: screenHeight * 0.010,
//           ),
//           child: Text(
//             'allexchangeprizelist'.tr(),
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: isTablet ? 22 : 18,
//               color: Colors.grey,
//               fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
//             ),
//           ),
//         ),
//         GridView.builder(
//           padding: EdgeInsets.symmetric(
//             horizontal: screenWidth * 0.04,
//             vertical: screenHeight * 0.004,
//           ),
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           itemCount: prizes.length,
//           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: crossAxisCount,
//             childAspectRatio: isTablet ? 0.85 : 0.75, // Increased aspect ratio
//             crossAxisSpacing: screenWidth * 0.03,
//             mainAxisSpacing: screenWidth * 0.03,
//           ),
//           itemBuilder: (context, index) {
//             final prize = prizes[index];
//             final walletKey = _mapWalletNameToBalanceKey(prize.walletName);
//             final userBalance = widget.userBalances[walletKey] ?? 0;
//             final canExchange = userBalance >= prize.point;

//             return GestureDetector(
//               onTap: () => canExchange ? widget.onPrizeSelected(prize) : null,
//               child: MouseRegion(
//                 cursor: SystemMouseCursors.click,
//                 child: Container(
//                   margin: const EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(12),
//                     color: canExchange ? Colors.white : Colors.grey[300],
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey.withOpacity(0.3),
//                         spreadRadius: 1,
//                         blurRadius: 10,
//                         offset: const Offset(0, 3),
//                       ),
//                       if (canExchange)
//                         BoxShadow(
//                           color: AppColors.primaryColor.withOpacity(0.2),
//                           spreadRadius: 3,
//                           blurRadius: 10,
//                           offset: const Offset(0, 3),
//                         ),
//                     ],
//                   ),
//                   child: Padding(
//                     padding: EdgeInsets.all(screenWidth * 0.03),
//                     child: Column(
//                       mainAxisAlignment:
//                           MainAxisAlignment
//                               .spaceBetween, // Changed to spaceBetween
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         if (canExchange)
//                           Align(
//                             alignment: Alignment.topRight,
//                             child: Container(
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: screenWidth * 0.02,
//                                 vertical: screenHeight * 0.005,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: AppColors.primaryColor,
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Text(
//                                 "${(userBalance / prize.point).floor()} ${_translateUnit(prize.unit, context)}",
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: isTablet ? 14 : 12,
//                                   fontWeight: FontWeight.bold,
//                                   fontFamily: 'KhmerFont',
//                                 ),
//                               ),
//                             ),
//                           ),
//                         if (!canExchange)
//                           SizedBox(
//                             height: screenHeight * 0.015,
//                           ), // Add spacer for non-exchangeable items
//                         Expanded(
//                           flex: 3, // Give more space to the image
//                           child: Image.network(
//                             prize.imageUrl,
//                             fit: BoxFit.contain,
//                             loadingBuilder: (context, child, loadingProgress) {
//                               print("🖼️ Loading image: ${prize.imageUrl}");
//                               if (loadingProgress == null) return child;
//                               return Center(
//                                 child: CircularProgressIndicator(
//                                   value:
//                                       loadingProgress.expectedTotalBytes != null
//                                           ? loadingProgress
//                                                   .cumulativeBytesLoaded /
//                                               loadingProgress
//                                                   .expectedTotalBytes!
//                                           : null,
//                                 ),
//                               );
//                             },
//                             errorBuilder: (context, error, stackTrace) {
//                               print(
//                                 "❌ Image load error: ${prize.imageUrl}, error: $error",
//                               );
//                               return SizedBox.expand(
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                     color: Colors.grey[200],
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Icon(
//                                     Icons.image_not_supported,
//                                     size: 50,
//                                     color: Colors.grey[400],
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                         SizedBox(height: screenHeight * 0.01),
//                         Column(
//                           children: [
//                             Text(
//                               "${prize.point} ${prize.walletName}",
//                               style: TextStyle(
//                                 fontSize: isTablet ? 20 : 16,
//                                 fontWeight: FontWeight.w600,
//                                 fontFamily: 'KhmerFont',
//                                 color:
//                                     canExchange
//                                         ? Colors.blueGrey[800]
//                                         : Colors.red[400],
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                             if (!canExchange) ...[
//                               SizedBox(height: screenHeight * 0.01),
//                               Text(
//                                 "notenoughbalance".tr(),
//                                 style: TextStyle(
//                                   color: Colors.red,
//                                   fontSize: isTablet ? 14 : 12,
//                                   fontWeight: FontWeight.w500,
//                                   fontFamily:
//                                       localeCode == 'km' ? 'KhmerFont' : null,
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }
// }

// //Correct with 290 line code changes

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/utils/constants.dart';
import '../models/exchange_prize_model.dart';
import '../services/exchange_prize_service.dart';

class AllExchangePrizeList extends StatefulWidget {
  final Map<String, dynamic> userBalances;
  final Function(ExchangePrize) onPrizeSelected;
  final bool isLoadingBalances;
  final VoidCallback? onRefresh;

  const AllExchangePrizeList({
    required this.userBalances,
    required this.onPrizeSelected,
    required this.isLoadingBalances,
    this.onRefresh,
    Key? key,
  }) : super(key: key);

  @override
  AllExchangePrizeListState createState() => AllExchangePrizeListState();
}

class AllExchangePrizeListState extends State<AllExchangePrizeList> {
  late Future<List<ExchangePrize>> _prizesFuture;
  final ExchangePrizeService _service = ExchangePrizeService();

  @override
  void initState() {
    super.initState();
    // Load prizes without force refresh initially
    _prizesFuture = _service.fetchExchangePrizes(forceRefresh: false);
  }

  void refreshPrizes({bool forceRefresh = false}) {
    setState(() {
      _prizesFuture = _service.fetchExchangePrizes(forceRefresh: forceRefresh);
    });
  }

  // Add this helper method to translate units
  String _translateUnit(String unit, BuildContext context) {
    final localeCode = context.locale.languageCode;
    if (localeCode == 'km' && unit.toLowerCase() == 'can') {
      return 'កំប៉ុង';
    }
    return unit;
  }

  // Add this helper method to map prize wallet names to balance keys
  String _mapWalletNameToBalanceKey(String walletName) {
    switch (walletName.toLowerCase()) {
      case 'gb':
        return 'ganzberg';
      case 'bs':
        return 'boostrong';
      case 'id':
        return 'idol';
      case 'dm':
        return 'diamond';
      default:
        return walletName.toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ExchangePrize>>(
      future: _prizesFuture,
      builder: (context, snapshot) {
        // Show prizes immediately if we have them
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return _buildPrizeGrid(snapshot.data!);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        return Center(child: Text('No Exchange Prize Available'.tr()));
      },
    );
  }

  Widget _buildPrizeGrid(List<ExchangePrize> prizes) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;
    final localeCode = context.locale.languageCode;

    int crossAxisCount = 2;
    if (isTablet) crossAxisCount = 3;
    if (isDesktop) crossAxisCount = 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.010,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'allexchangeprizelist'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 22 : 17.5,
                    color: Colors.grey,
                    fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.004,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: prizes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: isTablet ? 0.85 : 0.75, // Increased aspect ratio
            crossAxisSpacing: screenWidth * 0.03,
            mainAxisSpacing: screenWidth * 0.03,
          ),
          itemBuilder: (context, index) {
            final prize = prizes[index];
            final walletKey = _mapWalletNameToBalanceKey(prize.walletName);
            final userBalance = widget.userBalances[walletKey] ?? 0;
            final canExchange = userBalance >= prize.point;

            return GestureDetector(
              onTap: () => canExchange ? widget.onPrizeSelected(prize) : null,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: canExchange ? Colors.white : Colors.grey[300],
                    boxShadow: [
                      if (canExchange)
                        BoxShadow(
                          color: AppColors.textColor.withOpacity(
                            0.14,
                          ), // soft shadow
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: const Offset(0, 3), // only bottom
                        ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween, // Changed to spaceBetween
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (canExchange)
                          Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.02,
                                vertical: screenHeight * 0.005,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${(userBalance / prize.point).floor()} ${_translateUnit(prize.unit, context)}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 14 : 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'KhmerFont',
                                ),
                              ),
                            ),
                          ),
                        if (!canExchange)
                          SizedBox(
                            height: screenHeight * 0.015,
                          ), // Add spacer for non-exchangeable items
                        Expanded(
                          flex: 3, // Give more space to the image
                          child: CachedNetworkImage(
                            imageUrl: prize.imageUrl,
                            fit: BoxFit.contain,
                            placeholder:
                                (context, url) =>
                                    Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) {
                              print(
                                "❌ Cached image load error: ${prize.imageUrl}, error: $error",
                              );
                              return SizedBox.expand(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Column(
                          children: [
                            Text(
                              "${prize.point} ${prize.walletName}",
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'KhmerFont',
                                color:
                                    canExchange
                                        ? Colors.blueGrey[800]
                                        : Colors.red[400],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (!canExchange) ...[
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                "notenoughbalance".tr(),
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: isTablet ? 14 : 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamily:
                                      localeCode == 'km' ? 'KhmerFont' : null,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

//Correct with 569 line code changes
