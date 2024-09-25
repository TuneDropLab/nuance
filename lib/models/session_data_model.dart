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

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      expiresAt: json['expires_at'].toString(),
      user: json['user'],
      providerToken: json['provider_token'],
      provider: json['user']['app_metadata']['provider'],
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
