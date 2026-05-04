import 'dart:convert';

class QrCodeParser {
  static Map<String, dynamic> parseTransferQr(String rawQr) {
    print('🔍 Parsing QR: $rawQr');

    try {
      // First try to parse as JSON format
      try {
        final jsonData = json.decode(rawQr) as Map<String, dynamic>;
        if (jsonData.containsKey('userId') &&
            jsonData.containsKey('phoneNumber')) {
          print('✅ Detected JSON format');
          return _parseJsonFormat(jsonData, rawQr);
        }
      } catch (e) {
        // Not JSON format, continue to other formats
      }

      // Try to parse as ABA-style TLV format with CRC
      final abaResult = _parseAbaTlvFormat(rawQr);
      if (abaResult['phoneNumber'] != 'Unknown') {
        return abaResult;
      }

      // Try the OLD signature format first
      final oldFormatResult = _parseOldSignatureFormat(rawQr);
      if (oldFormatResult['phoneNumber'] != 'Unknown') {
        return oldFormatResult;
      }

      // Fallback: try generic phone number extraction
      return _extractPhoneFromAnyPattern(rawQr);
    } catch (e) {
      print('❌ Error parsing QR: $e');
      return _getFallbackData(rawQr);
    }
  }

  // --- OLD signature format parsing ---
  static Map<String, dynamic> _parseOldSignatureFormat(String rawQr) {
    print('🔍 Attempting to parse as OLD signature format');

    if (rawQr.startsWith('59') && rawQr.length >= 4) {
      print('✅ Detected signature format with tag 59');

      final lengthStr = rawQr.substring(2, 4);
      final phoneLength = int.tryParse(lengthStr) ?? 0;

      if (phoneLength <= 0 ||
          phoneLength > 20 ||
          rawQr.length < 4 + phoneLength) {
        print('❌ Invalid phone number length: $phoneLength');
        return _getFallbackData(rawQr);
      }

      final phonePart = rawQr.substring(4, 4 + phoneLength);
      final phoneNumber = formatPhoneNumber(phonePart);

      final remaining = rawQr.substring(4 + phoneLength);
      String name = 'Default Name';
      String signature = remaining;

      if (remaining.length >= 4 && remaining.startsWith('99')) {
        final nameLengthStr = remaining.substring(2, 4);
        final nameLength = int.tryParse(nameLengthStr) ?? 0;

        if (nameLength > 0 && remaining.length >= 4 + nameLength) {
          name = remaining.substring(4, 4 + nameLength);
          signature = remaining.substring(4 + nameLength);
        }
      }

      final operator = detectOperator(phoneNumber);

      return {
        'phoneNumber': phoneNumber,
        'operator': operator,
        'name': name,
        'signature': signature,
        'raw': rawQr,
        'format': 'old_signature',
        'isValid': true,
      };
    }

    return _getFallbackData(rawQr);
  }

  // --- JSON QR format ---
  static Map<String, dynamic> _parseJsonFormat(
    Map<String, dynamic> jsonData,
    String rawQr,
  ) {
    final phone = formatPhoneNumber(jsonData['phoneNumber']?.toString() ?? '');
    final operator = detectOperator(phone);

    return {
      'phoneNumber': phone,
      'operator': operator,
      'name': jsonData['name']?.toString() ?? 'Unknown',
      'signature': jsonData['signature']?.toString() ?? rawQr,
      'userId': jsonData['userId']?.toString() ?? '0',
      'raw': rawQr,
      'format': 'json',
      'isValid': true,
    };
  }

  // --- ABA TLV format parsing ---
  static Map<String, dynamic> _parseAbaTlvFormat(String rawQr) {
    print('🔍 Attempting to parse as ABA TLV format');

    if (rawQr.length < 12) {
      print('❌ String too short for ABA format');
      return _getFallbackData(rawQr);
    }

    try {
      final String dataPayload = rawQr.substring(0, rawQr.length - 4);
      final String receivedCrcHex = rawQr.substring(rawQr.length - 4);

      final int calculatedCrcValue = _crc16CcittFalse(dataPayload);
      final String calculatedCrcHex = calculatedCrcValue
          .toRadixString(16)
          .toUpperCase()
          .padLeft(4, '0');

      if (receivedCrcHex != calculatedCrcHex) {
        print(
          '❌ CRC mismatch. Received: $receivedCrcHex, Expected: $calculatedCrcHex',
        );
        return _getFallbackData(rawQr);
      }

      String remainingData = dataPayload;
      String phoneNumber = 'Unknown';
      String name = 'Unknown';

      while (remainingData.length >= 4) {
        final String id = remainingData.substring(0, 2);
        final int length = int.tryParse(remainingData.substring(2, 4)) ?? 0;

        if (length <= 0 || remainingData.length < 4 + length) break;

        final String value = remainingData.substring(4, 4 + length);

        if (id == '59') {
          phoneNumber = formatPhoneNumber(value);
        } else if (id == '99') {
          name = value;
        }

        remainingData = remainingData.substring(4 + length);
      }

      if (phoneNumber != 'Unknown') {
        final operator = detectOperator(phoneNumber);
        return {
          'phoneNumber': phoneNumber,
          'operator': operator,
          'name': name,
          'signature': rawQr,
          'raw': rawQr,
          'format': 'aba_tlv',
          'isValid': true,
          'crcValid': true,
        };
      }
    } catch (e) {
      print('❌ Error parsing ABA format: $e');
    }

    return _getFallbackData(rawQr);
  }

  // --- Generic pattern fallback ---
  static Map<String, dynamic> _extractPhoneFromAnyPattern(String rawQr) {
    print('🔍 Attempting generic phone extraction');

    final patterns = [
      RegExp(r'855\d{8}'),
      RegExp(r'855\d{9}'),
      RegExp(r'0\d{8}'),
      RegExp(r'0\d{9}'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(rawQr);
      if (match != null) {
        final phoneDigits = match.group(0)!;
        final phone = formatPhoneNumber(phoneDigits);
        final operator = detectOperator(phone);

        return {
          'phoneNumber': phone,
          'operator': operator,
          'name': 'Unknown',
          'signature': rawQr,
          'raw': rawQr,
          'format': 'generic',
          'isValid': false,
        };
      }
    }

    return _getFallbackData(rawQr);
  }

  static Map<String, dynamic> _getFallbackData(String rawQr) {
    return {
      'phoneNumber': 'Unknown',
      'operator': 'Unknown',
      'name': 'Unknown',
      'signature': rawQr,
      'raw': rawQr,
      'format': 'unknown',
      'isValid': false,
    };
  }

  // --- Phone number formatter ---
  static String formatPhoneNumber(String phone) {
    return _formatPhoneNumber(phone);
  }

  static String _formatPhoneNumber(String phone) {
    if (phone == 'Unknown' || phone.isEmpty) return phone;

    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    while (cleanPhone.startsWith('855855')) {
      cleanPhone = cleanPhone.substring(3);
    }

    if (cleanPhone.startsWith('0')) {
      cleanPhone = '855${cleanPhone.substring(1)}';
    }

    if (!cleanPhone.startsWith('855')) {
      cleanPhone = '855$cleanPhone';
    }

    if (cleanPhone.length == 11) {
      return '${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3, 5)} '
          '${cleanPhone.substring(5, 8)} ${cleanPhone.substring(8)}';
    } else if (cleanPhone.length == 12) {
      return '${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3, 5)} '
          '${cleanPhone.substring(5, 8)} ${cleanPhone.substring(8)}';
    }

    return cleanPhone;
  }

  // --- Operator detection (Smart, Cellcard, Metfone) ---
  static String detectOperator(String formattedPhone) {
    if (formattedPhone == 'Unknown') return 'Unknown';

    final digits = formattedPhone.replaceAll(RegExp(r'\s+'), '');
    if (!digits.startsWith('855')) return 'Unknown';

    final prefix = digits.substring(3, 6);

    const cellcard = [
      '011',
      '012',
      '014',
      '017',
      '018',
      '085',
      '089',
      '092',
      '095',
      '099',
    ];
    const smart = [
      '010',
      '015',
      '016',
      '069',
      '070',
      '071',
      '081',
      '086',
      '087',
      '093',
      '096',
      '098',
    ];
    const metfone = ['031', '060', '066', '067', '068', '071', '088', '097'];

    if (cellcard.contains(prefix)) return 'Cellcard';
    if (smart.contains(prefix)) return 'Smart';
    if (metfone.contains(prefix)) return 'Metfone';
    return 'Unknown';
  }

  // --- CRC calculation ---
  static int _crc16CcittFalse(String data) {
    int crc = 0xFFFF;
    for (int i = 0; i < data.length; i++) {
      crc ^= data.codeUnitAt(i) << 8;
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc = crc << 1;
        }
      }
    }
    return crc & 0xFFFF;
  }

  static bool verifyCrc(String qrString) {
    if (qrString.length < 4) return false;

    try {
      final String dataPayload = qrString.substring(0, qrString.length - 4);
      final String receivedCrcHex = qrString.substring(qrString.length - 4);
      final int calculatedCrcValue = _crc16CcittFalse(dataPayload);
      final String calculatedCrcHex = calculatedCrcValue
          .toRadixString(16)
          .toUpperCase()
          .padLeft(4, '0');

      return receivedCrcHex == calculatedCrcHex;
    } catch (e) {
      return false;
    }
  }
}

//Correct with 333 line code changes
