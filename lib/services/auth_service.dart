import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FlutterSecureStorage secureStorage;

  AuthService(this.secureStorage);

  Future<void> storeSessionData(String sessionData) async {
    try {
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

      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        if (accessToken != null) await prefs.setString('access_token', accessToken.toString());
        if (refreshToken != null) await prefs.setString('refresh_token', refreshToken.toString());
        if (providerToken != null) await prefs.setString('provider_token', providerToken.toString());
        if (expiresAt != null) await prefs.setString('expires_at', expiresAt.toString());
        if (user != null) await prefs.setString('user', jsonEncode(user));
        await prefs.setString('provider', provider.toString());
        return;
      }

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
    } catch (e) {
      debugPrint("storeSessionData error: $e");
    }
  }

  Future<Map<String, dynamic>?> getSessionData() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final accessToken = prefs.getString('access_token');
        final refreshToken = prefs.getString('refresh_token');
        final providerToken = prefs.getString('provider_token');
        final expiresAt = prefs.getString('expires_at');
        final user = prefs.getString('user');
        final provider = prefs.getString('provider');

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

      final accessToken = await secureStorage.read(key: 'access_token').timeout(const Duration(milliseconds: 1500), onTimeout: () => null);
      final refreshToken = await secureStorage.read(key: 'refresh_token').timeout(const Duration(milliseconds: 1500), onTimeout: () => null);
      final providerToken = await secureStorage.read(key: 'provider_token').timeout(const Duration(milliseconds: 1500), onTimeout: () => null);
      final expiresAt = await secureStorage.read(key: 'expires_at').timeout(const Duration(milliseconds: 1500), onTimeout: () => null);
      final user = await secureStorage.read(key: 'user').timeout(const Duration(milliseconds: 1500), onTimeout: () => null);
      final provider = await secureStorage.read(key: 'provider').timeout(const Duration(milliseconds: 1500), onTimeout: () => null);

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
    } catch (e) {
      debugPrint("getSessionData error: $e");
    }
    return null;
  }

  Future<void> logout() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
        await prefs.remove('provider_token');
        await prefs.remove('expires_at');
        await prefs.remove('user');
        await prefs.remove('provider');
        return;
      }
      await secureStorage.deleteAll();
    } catch (e) {
      debugPrint("logout storage error: $e");
    }
  }
}
