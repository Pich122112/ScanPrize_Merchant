import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gb_merchant/models/exchange_prize_model.dart';
import 'package:gb_merchant/utils/constants.dart';
import '../components/Enter_Quantity.dart';

class WalletPointsTab extends StatelessWidget {
  final Map<String, dynamic> userBalances;
  final String phoneNumber;
  final String scannedQr;
  final String userId;

  const WalletPointsTab({
    super.key,
    required this.userBalances,
    required this.phoneNumber,
    required this.scannedQr,
    required this.userId,
  });

  String getWalletImage(String walletName) {
    switch (walletName.toLowerCase()) {
      case 'ganzberg':
        return 'assets/images/gblogo.png';
      case 'boostrong':
        return 'assets/images/newbslogo.png';
      case 'idol':
        return 'assets/images/idollogo.png';
      case 'diamond':
        return 'assets/images/dmond.png';
      default:
        return 'assets/images/gblogo.png';
    }
  }

  String getWalletDisplayName(String walletKey) {
    switch (walletKey) {
      case 'ganzberg':
        return 'Ganzberg';
      case 'boostrong':
        return 'Boostrong';
      case 'idol':
        return 'Idol';
      case 'diamond':
        return 'Diamond';
      default:
        return walletKey;
    }
  }

  String formatPoints(dynamic value) {
    if (value == null) return '0';
    if (value is double && value == value.floorToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  String getPointsUnit(String walletKey) {
    return walletKey.toLowerCase() == 'diamond' ? 'D' : 'score'.tr();
  }

  // Helper method to map wallet key to wallet type ID
  String _getWalletTypeId(String walletKey) {
    switch (walletKey.toLowerCase()) {
      case 'ganzberg':
        return '1'; // Replace with actual wallet type ID for Ganzberg
      case 'boostrong':
        return '2'; // Replace with actual wallet type ID for Boostrong
      case 'idol':
        return '3'; // Replace with actual wallet type ID for Idol
      case 'diamond':
        return '4'; // Replace with actual wallet type ID for Diamond
      default:
        return '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.locale.languageCode;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      children: [
        const SizedBox(height: 20),
        Text(
          'please_select_wallet'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
          ),
        ),
        SizedBox(height: 30),
        // Ganzberg Wallet
        _buildWalletCard(
          context: context,
          image: getWalletImage('ganzberg'),
          name: getWalletDisplayName('ganzberg'),
          points: userBalances['ganzberg']?.toString() ?? '0',
          unit: getPointsUnit('ganzberg'),
          walletKey: 'ganzberg',
        ),
        SizedBox(height: 14),
        // Idol Wallet
        _buildWalletCard(
          context: context,
          image: getWalletImage('idol'),
          name: getWalletDisplayName('idol'),
          points: userBalances['idol']?.toString() ?? '0',
          unit: getPointsUnit('idol'),
          walletKey: 'idol',
        ),
        SizedBox(height: 14),
        // Boostrong Wallet
        _buildWalletCard(
          context: context,
          image: getWalletImage('boostrong'),
          name: getWalletDisplayName('boostrong'),
          points: userBalances['boostrong']?.toString() ?? '0',
          unit: getPointsUnit('boostrong'),
          walletKey: 'boostrong',
        ),
        SizedBox(height: 14),
        // Diamond Wallet
        _buildWalletCard(
          context: context,
          image: getWalletImage('diamond'),
          name: getWalletDisplayName('diamond'),
          points: formatPoints(userBalances['diamond']),
          unit: getPointsUnit('diamond'),
          walletKey: 'diamond',
        ),
      ],
    );
  }

  // In the WalletPointsTab widget, update the _buildWalletCard method
  Widget _buildWalletCard({
    required BuildContext context,
    required String image,
    required String name,
    required String points,
    required String unit,
    required String walletKey,
  }) {
    final balance = double.tryParse(points) ?? 0;
    final canTransfer = balance > 0;
    final localeCode = context.locale.languageCode;

    return GestureDetector(
      onTap: () {
        if (canTransfer) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => EnterQuantityDialog(
                    prize: ExchangePrize(
                      prizeId: 0,
                      prizeName: name,
                      brandId: 0,
                      brandName: '',
                      walletType: _getWalletTypeId(walletKey),
                      walletName: walletKey,
                      point: 1,
                      sku: '',
                      unit: 'unit',
                      thumbnail:
                          '', // This should be the image URL for the wallet
                      status: true,
                    ),
                    phoneNumber: phoneNumber,
                    scannedQr: scannedQr,
                    receiverId: userId,
                    walletId: _getWalletTypeId(walletKey),
                    fromWalletTab:
                        true, // Add this flag to indicate it's from wallet tab
                  ),
            ),
          );
        }
      },
      child: Opacity(
        opacity: canTransfer ? 1.0 : 0.6,
        child: Container(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(image, width: 50, height: 50, fit: BoxFit.contain),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'KhmerFont',
                        color: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$points $unit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'KhmerFont',
                        color:
                            canTransfer ? AppColors.primaryColor : Colors.grey,
                      ),
                    ),
                    if (!canTransfer)
                      Text(
                        'notenoughbalance'.tr(),
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: canTransfer ? Colors.grey : Colors.grey[100],
                ),
                onPressed: canTransfer ? () {} : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Correct with 255 line code changes
