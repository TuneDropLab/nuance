import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FlutterSecureStorage secureStorage;

  AuthService(this.secureStorage);

  Future<void> storeSessionData(String sessionData) async {
    final sessionJson = jsonDecode(sessionData) as Map<String, dynamic>;
    final accessToken =
        sessionJson['access_token'] ?? sessionJson['accessToken'];
    final refreshToken =
        sessionJson['refresh_token'] ?? sessionJson['refreshToken'];
    final providerToken =
        sessionJson['provider_token'] ?? sessionJson['providerToken'];
    final expiresAt = sessionJson['expires_at'] ?? sessionJson['expiresAt'];
    final user = sessionJson['user'];
    final provider = sessionJson['provider'] ??
        ((user is Map && user['app_metadata'] is Map)
            ? (user['app_metadata'] as Map)['provider']
            : null) ??
        'google';

    if (accessToken != null) {
      await secureStorage.write(
          key: 'access_token', value: accessToken.toString());
    }
    if (refreshToken != null) {
      await secureStorage.write(
          key: 'refresh_token', value: refreshToken.toString());
    }
    if (providerToken != null) {
      await secureStorage.write(
          key: 'provider_token', value: providerToken.toString());
    }
    if (expiresAt != null) {
      await secureStorage.write(
          key: 'expires_at', value: expiresAt.toString());
    }
    if (user != null) {
      await secureStorage.write(key: 'user', value: jsonEncode(user));
    }
    await secureStorage.write(key: 'provider', value: provider.toString());
  }

  Future<Map<String, dynamic>?> getSessionData() async {
    final accessToken = await secureStorage.read(key: 'access_token');
    final refreshToken = await secureStorage.read(key: 'refresh_token');
    final providerToken = await secureStorage.read(key: 'provider_token');
    final expiresAt = await secureStorage.read(key: 'expires_at');
    final user = await secureStorage.read(key: 'user');
    final provider = await secureStorage.read(key: 'provider');

    if (accessToken != null && user != null) {
      int expiryMs = 0;
      if (expiresAt != null) {
        final parsed = int.tryParse(expiresAt);
        if (parsed != null) {
          expiryMs = parsed < 10000000000 ? parsed * 1000 : parsed;
        } else {
          expiryMs = DateTime.tryParse(expiresAt)?.millisecondsSinceEpoch ?? 0;
        }
      }

      return {
        'access_token': accessToken,
        'refresh_token': refreshToken ?? '',
        'provider_token': providerToken ?? '',
        'expires_at': expiryMs,
        'user': jsonDecode(user),
        'provider': provider ?? 'google',
      };
    }
    return null;
  }

  Future<void> logout() async {
    await secureStorage.deleteAll();
  }
}
