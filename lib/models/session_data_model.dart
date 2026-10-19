import 'package:flutter/material.dart';

@immutable
class SessionData {
  final String accessToken;
  final String refreshToken;
  final String expiresAt;
  final Map<String, dynamic> user;
  final String providerToken;
  final String provider;

  const SessionData({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
    required this.providerToken,
    required this.provider,
  });

  SessionData copyWith({
    String? accessToken,
    String? refreshToken,
    String? expiresAt,
    String? providerToken,
    Map<String, dynamic>? user,
    String? provider,
  }) {
    return SessionData(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      user: user ?? this.user,
      providerToken: providerToken ?? this.providerToken,
      provider: provider ?? this.provider,
    );
  }

  bool get isGuest =>
      accessToken.startsWith('guest_') ||
      provider == 'itunes' ||
      provider == 'guest' ||
      user['id'] == 'guest_tester' ||
      (user['app_metadata'] is Map && user['app_metadata']['is_guest'] == true);

  bool get isExpired {
    if (expiresAt.isEmpty) return false;
    final int? expVal = int.tryParse(expiresAt);
    if (expVal != null) {
      final ms = expVal < 10000000000 ? expVal * 1000 : expVal;
      return DateTime.now().millisecondsSinceEpoch >= ms;
    }
    final dt = DateTime.tryParse(expiresAt);
    if (dt != null) {
      return DateTime.now().isAfter(dt);
    }
    return false;
  }

  factory SessionData.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    final appMetadata = userMap['app_metadata'] is Map<String, dynamic>
        ? userMap['app_metadata'] as Map<String, dynamic>
        : <String, dynamic>{};

    return SessionData(
      accessToken: json['access_token']?.toString() ??
          json['accessToken']?.toString() ??
          '',
      refreshToken: json['refresh_token']?.toString() ??
          json['refreshToken']?.toString() ??
          '',
      expiresAt: json['expires_at']?.toString() ??
          json['expiresAt']?.toString() ??
          '',
      user: userMap,
      providerToken: json['provider_token']?.toString() ??
          json['providerToken']?.toString() ??
          '',
      provider: appMetadata['provider']?.toString() ??
          json['provider']?.toString() ??
          'guest',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt,
      'user': user,
      'providerToken': providerToken,
      'provider': provider,
    };
  }
}
