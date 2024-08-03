import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FlutterSecureStorage secureStorage;

  AuthService(this.secureStorage);

  Future<void> storeSessionData(String sessionData) async {
    final sessionJson = jsonDecode(sessionData);
    await secureStorage.write(
        key: 'access_token', value: sessionJson['access_token']);
    await secureStorage.write(
        key: 'refresh_token', value: sessionJson['refresh_token']);
    await secureStorage.write(
        key: 'provider_token', value: sessionJson['provider_token']);
    await secureStorage.write(
        key: 'expires_at', value: sessionJson['expires_at'].toString());
    await secureStorage.write(
        key: 'user', value: jsonEncode(sessionJson['user']));
  }

  Future<Map<String, dynamic>?> getSessionData() async {
    final accessToken = await secureStorage.read(key: 'access_token');
    final refreshToken = await secureStorage.read(key: 'refresh_token');
    final providerToken = await secureStorage.read(key: 'provider_token');
    final expiresAt = await secureStorage.read(key: 'expires_at');
    final user = await secureStorage.read(key: 'user');

    if (accessToken != null &&
        refreshToken != null &&
        expiresAt != null &&
        user != null) {
      return {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'provider_token': providerToken,
        'expires_at': int.parse(expiresAt),
        'user': jsonDecode(user),
      };
    }
    return null;
  }

  Future<void> logout() async {
    await secureStorage.deleteAll();
  }
}
