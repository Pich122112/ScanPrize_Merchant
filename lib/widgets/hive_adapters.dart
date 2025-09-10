// // hive_adapters.dart
// import 'package:hive/hive.dart';
// import '../models/exchange_prize_model.dart';

// class ExchangePrizeAdapter extends TypeAdapter<ExchangePrize> {
//   @override
//   final int typeId = 1; // Changed to 1 to avoid conflicts with other adapters

//   @override
//   ExchangePrize read(BinaryReader reader) {
//     final json = reader.readMap();
//     return ExchangePrize.fromJson(Map<String, dynamic>.from(json));
//   }

//   @override
//   void write(BinaryWriter writer, ExchangePrize obj) {
//     writer.writeMap(obj.toJson());
//   }
// }
