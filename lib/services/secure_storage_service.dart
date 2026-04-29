import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String _tokenKey = 'access_token';
  static const String _userIdKey = 'user_id';
  static const String _phoneNumberKey = 'phone_number';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _qrPayloadKey = 'qr_payload';
  static const String _userNameKey = 'user_name'; 


  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences:
          true, // Enable encrypted shared preferences on Android
    ),
    iOptions: IOSOptions(
      accessibility:
          KeychainAccessibility.first_unlock, // iOS Keychain accessibility
    ),
  );

  // Store token securely
  Future<void> setToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Get token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Store user ID
  Future<void> setUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  // Get user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  // Store phone number
  Future<void> setPhoneNumber(String phoneNumber) async {
    await _storage.write(key: _phoneNumberKey, value: phoneNumber);
  }

  // Get phone number
  Future<String?> getPhoneNumber() async {
    return await _storage.read(key: _phoneNumberKey);
  }

    // Store user name
  Future<void> setUserName(String userName) async {
    await _storage.write(key: _userNameKey, value: userName);
  }

  // Get user name
  Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }


  // Store refresh token
  Future<void> setRefreshToken(String refreshToken) async {
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // Clear all secure storage (logout)
  Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _phoneNumberKey);
    await _storage.delete(key: _refreshTokenKey);
        await _storage.delete(key: _userNameKey); 
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Delete specific keys
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> deleteUserId() async {
    await _storage.delete(key: _userIdKey);
  }

  Future<void> deletePhoneNumber() async {
    await _storage.delete(key: _phoneNumberKey);
  }

  Future<void> setQrPayload(String qrPayload) async {
    await _storage.write(key: _qrPayloadKey, value: qrPayload);
  }

  Future<String?> getQrPayload() async {
    return await _storage.read(key: _qrPayloadKey);
  }
}
