// services/location_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';

class LocationService {
  static Map<String, dynamic>? _provinces;
  static Map<String, dynamic>? _districts;
  static Map<String, dynamic>? _communes;

  // Fallback data in case JSON files fail to load
  static final Map<String, dynamic> _fallbackProvinces = {
    '1': {'id': '1', 'iso': 'KH-1', 'name_kh': 'ភ្នំពេញ', 'type': '1'},
    '2': {'id': '2', 'iso': 'KH-2', 'name_kh': 'បន្ទាយមានជ័យ', 'type': '2'},
  };

  static final Map<String, dynamic> _fallbackDistricts = {
    '0101': {'geocode': '0101', 'name_kh': 'ខណ្ឌដូនពេញ', 'province_id': '1'},
    '0102': {'geocode': '0102', 'name_kh': 'ខណ្ឌ៧មករា', 'province_id': '1'},
  };

  static final Map<String, dynamic> _fallbackCommunes = {
    '010101': {
      'geocode': '010101',
      'name_kh': 'សង្កាត់ដូនពេញ',
      'district_id': '0101',
    },
    '010102': {
      'geocode': '010102',
      'name_kh': 'សង្កាត់ផ្សារដើមថ្កូវ',
      'district_id': '0101',
    },
  };

  static void printDataStructure() {
    print("=== LOCATION DATA ANALYSIS ===");

    if (_provinces != null && _provinces!.isNotEmpty) {
      final sampleProvince = _provinces!.values.first;
      print("📋 PROVINCES: ${_provinces!.length} items");
      print("   Structure: ${sampleProvince.keys}");
      print(
        "   Sample: ${sampleProvince['iso']} - ${sampleProvince['name_kh']}",
      );
      print("   All province IDs: ${_provinces!.keys.toList()}");
    }

    if (_districts != null && _districts!.isNotEmpty) {
      final sampleDistrict = _districts!.values.first;
      print("📋 DISTRICTS: ${_districts!.length} items");
      print("   Structure: ${sampleDistrict.keys}");
      print(
        "   Sample: ${sampleDistrict['geocode']} - ${sampleDistrict['name_kh']} (province_id: ${sampleDistrict['province_id']})",
      );
      print(
        "   Unique province_ids in districts: ${_districts!.values.map((d) => d['province_id']).toSet()}",
      );
    }

    if (_communes != null && _communes!.isNotEmpty) {
      final sampleCommune = _communes!.values.first;
      print("📋 COMMUNES: ${_communes!.length} items");
      print("   Structure: ${sampleCommune.keys}");
      print(
        "   Sample: ${sampleCommune['geocode']} - ${sampleCommune['name_kh']} (district_id: ${sampleCommune['district_id']})",
      );
      print(
        "   Unique district_ids in communes: ${_communes!.values.map((c) => c['district_id']).toSet()}",
      );
    }

    print("=================================");
  }

  static Future<void> loadLocationData() async {
    try {
      print("📁 Loading location data...");

      // Load provinces
      try {
        final provinceData = await rootBundle.loadString(
          'assets/location/provinces.json',
        );
        _provinces = {};
        final provinceList = json.decode(provinceData) as List;
        for (var province in provinceList) {
          // Use consistent numeric ID as key
          String numericId = getNumericProvinceId(province);
          _provinces![numericId] = {
            ...province,
            'numeric_id': numericId, // Add consistent numeric ID
          };
        }
        print("✅ Loaded ${_provinces!.length} provinces");
      } catch (e) {
        print("❌ Error loading provinces: $e");
        print("🔄 Using fallback provinces data");
        _provinces = Map.from(_fallbackProvinces);
      }

      // Load districts
      try {
        final districtData = await rootBundle.loadString(
          'assets/location/districts.json',
        );
        _districts = {};
        final districtList = json.decode(districtData) as List;
        for (var district in districtList) {
          // Use geocode as key
          _districts![district['geocode']] = district;
        }
        print("✅ Loaded ${_districts!.length} districts");
      } catch (e) {
        print("❌ Error loading districts: $e");
        print("🔄 Using fallback districts data");
        _districts = Map.from(_fallbackDistricts);
      }

      // Load communes
      try {
        final communeData = await rootBundle.loadString(
          'assets/location/communes.json',
        );
        _communes = {};
        final communeList = json.decode(communeData) as List;
        for (var commune in communeList) {
          // Use geocode as key
          _communes![commune['geocode']] = commune;
        }
        print("✅ Loaded ${_communes!.length} communes");
      } catch (e) {
        print("❌ Error loading communes: $e");
        print("🔄 Using fallback communes data");
        _communes = Map.from(_fallbackCommunes);
      }

      // Print data structure for debugging
      printDataStructure();
    } catch (e) {
      print("❌ General error loading location data: $e");
      print("🔄 Using fallback data for all location types");
      _provinces = Map.from(_fallbackProvinces);
      _districts = Map.from(_fallbackDistricts);
      _communes = Map.from(_fallbackCommunes);
    }
  }

  // Helper method to extract numeric province ID
  static String getNumericProvinceId(Map<String, dynamic> province) {
    // 1. First try to use the 'id' field if available and numeric
    if (province['id'] != null) {
      final id = province['id'].toString();
      if (id.isNotEmpty && id != 'null') {
        return id;
      }
    }

    // 2. Try to use the 'type' field if available
    if (province['type'] != null) {
      final type = province['type'].toString();
      if (type.isNotEmpty && type != 'null') {
        return type;
      }
    }

    // 3. Extract from ISO code (e.g., "KH-23" -> "23")
    final isoCode = province['iso']?.toString() ?? '';
    final match = RegExp(r'KH-(\d+)').firstMatch(isoCode);
    if (match != null) {
      return match.group(1)!;
    }

    // 4. Fallback: use a default ID
    return '1';
  }

  static List<Map<String, dynamic>> getProvinces() {
    if (_provinces == null) return [];

    // Convert dynamic maps to Map<String, dynamic>
    return _provinces!.values.map((province) {
      return Map<String, dynamic>.from(province);
    }).toList();
  }

  static List<Map<String, dynamic>> getDistrictsByProvince(String provinceId) {
    if (_districts == null) return [];

    print("🔍 Looking for districts with province_id: $provinceId");

    final districts =
        _districts!.values
            .where((district) {
              final districtProvinceId = district['province_id']?.toString();
              final matches = districtProvinceId == provinceId;
              if (matches) {
                print(
                  "✅ Found district: ${district['name_kh']} (${district['geocode']}) with province_id: $districtProvinceId",
                );
              }
              return matches;
            })
            .map(
              (district) => Map<String, dynamic>.from(district),
            ) // Convert to Map<String, dynamic>
            .toList();

    print(
      "📊 Total districts found for province $provinceId: ${districts.length}",
    );
    return districts;
  }

  static List<Map<String, dynamic>> getCommunesByDistrict(
    String districtGeocode,
  ) {
    if (_communes == null) return [];

    print("🔍 Looking for communes for district: $districtGeocode");

    // First, try to find the district by geocode to get its numeric ID
    final district = _districts?[districtGeocode];
    final districtNumericId = district?['id']?.toString();

    final communes =
        _communes!.values
            .where((commune) {
              final communeDistrictId = commune['district_id']?.toString();

              // Try multiple matching strategies:

              // 1. Match by district geocode (if commune has district_geocode field)
              if (commune['district_geocode']?.toString() == districtGeocode) {
                return true;
              }

              // 2. Match by district numeric ID (most likely case)
              if (districtNumericId != null &&
                  communeDistrictId == districtNumericId) {
                return true;
              }

              // 3. Direct string match (fallback)
              if (communeDistrictId == districtGeocode) {
                return true;
              }

              // 4. For 4-digit district codes, try matching last 2 digits with numeric ID
              if (districtGeocode.length == 4 && communeDistrictId != null) {
                final lastTwoDigits = districtGeocode.substring(2);
                if (communeDistrictId == lastTwoDigits) {
                  return true;
                }
              }

              // 5. Try numeric comparison
              try {
                final districtNum = int.tryParse(districtGeocode);
                final communeNum = int.tryParse(communeDistrictId ?? '');
                if (districtNum != null &&
                    communeNum != null &&
                    districtNum == communeNum) {
                  return true;
                }
              } catch (e) {
                // Ignore conversion errors
              }

              return false;
            })
            .map((commune) => Map<String, dynamic>.from(commune))
            .toList();

    print(
      "📊 Total communes found for district $districtGeocode: ${communes.length}",
    );

    // Debug: print what we found
    if (communes.isNotEmpty) {
      print("✅ Found communes: ${communes.map((c) => c['name_kh']).toList()}");
    } else {
      print(
        "❌ No communes found. District geocode: $districtGeocode, District numeric ID: $districtNumericId",
      );
      print(
        "Available district IDs in communes: ${_communes!.values.map((c) => c['district_id']).toSet()}",
      );
    }

    return communes;
  }

  // Find province by ID
  static Map<String, dynamic>? getProvinceById(String id) {
    return _provinces?[id];
  }

  // Find district by ID
  static Map<String, dynamic>? getDistrictById(String id) {
    return _districts?[id];
  }

  // Find commune by ID
  static Map<String, dynamic>? getCommuneById(String id) {
    return _communes?[id];
  }

  // Get province by ISO code
  static Map<String, dynamic>? getProvinceByIso(String isoCode) {
    if (_provinces == null) return null;

    return _provinces!.values.firstWhere(
      (province) => province['iso'] == isoCode,
      orElse: () => null,
    );
  }

  // Get district by name (for fallback)
  static Map<String, dynamic>? getDistrictByName(String name) {
    if (_districts == null) return null;

    return _districts!.values.firstWhere(
      (district) => district['name_kh'] == name,
      orElse: () => null,
    );
  }
}

//Correct with 328 line code changes
