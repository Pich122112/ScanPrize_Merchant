class ExchangePrize {
  final int prizeId;
  final String prizeName;
  final int brandId;
  final String brandName;
  final String walletType;
  final String walletName;
  final int point;
  final String sku;
  final String unit; // Add unit field
  final String thumbnail; // Add thumbnail field
  final bool status;

  ExchangePrize({
    required this.prizeId,
    required this.prizeName,
    required this.brandId,
    required this.brandName,
    required this.walletType,
    required this.walletName,
    required this.point,
    required this.sku,
    required this.unit, // Add unit parameter
    required this.thumbnail, // Add thumbnail parameter
    required this.status,
  });

  factory ExchangePrize.fromJson(Map<String, dynamic> json) {
    return ExchangePrize(
      prizeId: json['prize_id'],
      prizeName: json['prize_name'],
      brandId: json['brand_id'],
      brandName: json['brand_name'],
      walletType: json['wallet_type'].toString(),
      walletName: json['wallet_name'],
      point: json['point'],
      sku: json['sku'],
      unit: json['unit'] ?? 'can', // Default to 'can' if null
      thumbnail: json['thumbnail'] ?? '', // Add thumbnail from JSON
      status: json['status'],
    );
  }

  // Update the imageUrl getter to use the thumbnail from API
  String get imageUrl =>
      thumbnail.isNotEmpty ? thumbnail : 'assets/images/default.png';
}

//Correct with 39 line code changes
