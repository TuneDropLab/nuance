import 'dart:developer';

import 'package:flutter/material.dart';

@immutable
class SessionData {
  final String accessToken;
  final String refreshToken;
  final String expiresAt;
  final Map<String, dynamic> user;

  const SessionData({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  SessionData copyWith({
    String? accessToken,
    String? refreshToken,
    String? expiresAt,
    Map<String, dynamic>? user,
  }) {
    return SessionData(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      user: user ?? this.user,
    );
  }

  factory SessionData.fromJson(Map<String, dynamic> json) {
    log("SESSION DATA FROM JSON: $json");
    if (json == null) {
      throw Exception('Session data is null');
    }
    return SessionData(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      expiresAt: json['expires_at'].toString(),
      user: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt,
      'user': user,
    };
  }
}
