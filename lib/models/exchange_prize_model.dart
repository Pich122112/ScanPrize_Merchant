class ExchangePrize {
  final int exchangePrizeListID;
  final String exchangePrizeName;
  final String exchangePrizeValue;
  final String imageFileName;
  final int productCategoryID; // Now using this to map to company categories
  final String companyCategoryName;
  final int? companyCategoryID;

  ExchangePrize({
    required this.exchangePrizeListID,
    required this.exchangePrizeName,
    required this.exchangePrizeValue,
    required this.imageFileName,
    required this.productCategoryID,
    required this.companyCategoryName,
    this.companyCategoryID,
  });

  factory ExchangePrize.fromJson(Map<String, dynamic> json) {
    try {
      return ExchangePrize(
        exchangePrizeListID: json['ExchangePrizeListID'] as int? ?? 0,
        exchangePrizeName: json['ExchangePrizeName'] as String? ?? '',
        exchangePrizeValue: json['ExchangePrizeValue'] as String? ?? '0',
        imageFileName: json['ImageFileName'] as String? ?? '',
        productCategoryID: json['ProductCategoryID'] as int? ?? 0,
        companyCategoryName: json['CompanyCategoryName'] as String? ?? '',
        companyCategoryID: json['CompanyCategoryID'] as int?,
      );
    } catch (e) {
      print('Error parsing ExchangePrize: $e');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  String get displayText => '$exchangePrizeValue = $exchangePrizeName';
}

//Correct with 40 line code changes
