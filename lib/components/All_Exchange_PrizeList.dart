
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:gb_merchant/widgets/modern_btn_ui.dart';
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
  Timer? _snackBarDebounceTimer;
  bool _isShowingSnackBar = false;

  @override
  void initState() {
    super.initState();
    // Load prizes without force refresh initially
    _prizesFuture = _service.fetchExchangePrizes(forceRefresh: false);
  }

  @override
  void dispose() {
    _snackBarDebounceTimer?.cancel();
    super.dispose();
  }

  void refreshPrizes({bool forceRefresh = false}) {
    setState(() {
      _prizesFuture = _service.fetchExchangePrizes(forceRefresh: forceRefresh);
    });
  }

  String _translateUnit(String unit, BuildContext context) {
    final localeCode = context.locale.languageCode;
    final normalized = unit.toLowerCase();

    if (normalized == 'can') {
      return localeCode == 'km' ? 'កំប៉ុង' : 'Can';
    }
    if (normalized == 'case') {
      return localeCode == 'km' ? 'កេស' : 'Case';
    }
    if (normalized == 'bottle') {
      return localeCode == 'km' ? 'ដប' : 'Bottle';
    }
    if (normalized == 'shirt') {
      return localeCode == 'km' ? 'អាវ' : 'Shirt';
    }
    if (normalized == 'ball') {
      return localeCode == 'km' ? 'បាល់' : 'Ball';
    }
    if (normalized == 'umbrella') {
      return localeCode == 'km' ? 'ឆ័ត្រ' : 'Umbrella';
    }
    if (normalized == 'dolla') {
      return localeCode == 'km' ? 'ដុល្លា' : 'Dollar';
    }
    if (normalized == 'helmet') {
      return localeCode == 'km' ? 'មួក' : 'Helmet';
    }
    if (normalized == 'bucket') {
      return localeCode == 'km' ? 'ធុងទឹកកក' : 'Bucket';
    }
    if (normalized == 'motor') {
      return localeCode == 'km' ? 'ម៉ូតូ' : 'Motor';
    }
    if (normalized == 'car') {
      return localeCode == 'km' ? 'ឡាន' : 'Car';
    }
    if (normalized == 'piece') {
      return localeCode == 'km' ? 'ប្រអប់' : 'Piece';
    }
    if (normalized == 'pack') {
      return localeCode == 'km' ? 'ប៉ាក' : 'Pack';
    }

    return unit;
  }

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

  void _showFullScreenImage(int initialIndex, List<String> imageUrls) {
    final PageController pageController = PageController(
      initialPage: initialIndex,
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "FullscreenImage",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: const Color.fromARGB(
            255,
            34,
            34,
            34,
          ).withOpacity(0.9),
          body: SafeArea(
            child: Stack(
              children: [
                // Swipeable gallery
                PageView.builder(
                  controller: pageController,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      panEnabled: true,
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      minScale: 0.5,
                      maxScale: 5.0,
                      child: Center(
                        child: Image.network(
                          imageUrls[index],
                          fit: BoxFit.contain, 
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              width: 80,
                              height: 80,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.white,
                                size: 60,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),

                // Close button
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final double titleSize = width * 0.045; 

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
                    fontSize: titleSize,
                    color: isDarkMode ? Colors.white : Colors.white,
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
            vertical: screenHeight * 0.006,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: prizes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: isTablet ? 0.85 : 0.65, // Increased aspect ratio
            crossAxisSpacing: screenWidth * 0.03,
            mainAxisSpacing: screenWidth * 0.03,
          ),
          itemBuilder: (context, index) {
            final prize = prizes[index];
            final walletKey = _mapWalletNameToBalanceKey(prize.walletName);
            final userBalance = widget.userBalances[walletKey] ?? 0;
            final canExchange = userBalance >= prize.point;

            return GestureDetector(
              onTap: () {
                if (canExchange) {
                  widget.onPrizeSelected(prize);
                } else {
                  if (!_isShowingSnackBar) {
                    _isShowingSnackBar = true;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              "notenoughbalance".tr(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'KhmerFont',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.black,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                  // Reset flag after a short time so snackbar can be shown again if user waits
                  _snackBarDebounceTimer?.cancel();
                  _snackBarDebounceTimer = Timer(
                    const Duration(seconds: 2),
                    () {
                      _isShowingSnackBar = false;
                    },
                  );
                }
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
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
                        // Top row: Eye (left) + Unit badge (right)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 👁 Eye Icon
                            InkWell(
                              borderRadius: BorderRadius.circular(50),
                              onTap:
                                  () => _showFullScreenImage(
                                    index,
                                    prizes.map((p) => p.imageUrl).toList(),
                                  ),
                              child: Container(
                                padding: EdgeInsets.all(screenWidth * 0.012),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.remove_red_eye,
                                  color: Colors.black38,
                                  size: 18,
                                ),
                              ),
                            ),
                            // 📦 Unit Badge (only if exchangeable)
                            if (canExchange)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.02,
                                  vertical: screenHeight * 0.005,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  borderRadius: BorderRadius.circular(50),
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
                          ],
                        ),
                        Expanded(
                          flex: 5, // Give more space to the image
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: prize.imageUrl,
                              fit: BoxFit.fill,
                              placeholder:
                                  (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
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
                        ),
                        Column(
                          children: [
                            // Text(
                            //   "${prize.point} ${prize.walletName}",
                            //   style: TextStyle(
                            //     fontSize: isTablet ? 20 : 18,
                            //     fontWeight: FontWeight.bold,
                            //     fontFamily: 'KhmerFont',
                            //     color:
                            //         canExchange
                            //             ? Colors.blueGrey[800]
                            //             : Colors.grey[600],
                            //   ),
                            //   textAlign: TextAlign.center,
                            // ),
                            // if (!canExchange) ...[
                            //   SizedBox(height: screenHeight * 0.01),
                            //   Text(
                            //     "notenoughbalance".tr(),
                            //     style: TextStyle(
                            //       color: Colors.grey[600],
                            //       fontSize: isTablet ? 16 : 14,
                            //       fontWeight: FontWeight.w600,
                            //       fontFamily:
                            //           localeCode == 'km' ? 'KhmerFont' : null,
                            //     ),
                            //   ),
                            // ],
                          ],
                        ),
                        const SizedBox(height: 14),
                        AnimatedGradientButton(
                          text: "${prize.point} ${prize.walletName}",
                          onPressed: () {
                            if (canExchange) {
                              widget.onPrizeSelected(prize);
                            }
                          },
                          disabled:
                              !canExchange, // button turns grey if user can't exchange
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

//Correct with 766 line code changes
