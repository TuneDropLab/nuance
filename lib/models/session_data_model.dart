class SessionData {
  final String id;
  final String accessToken;
  final String refreshToken;
  final String expiresAt;
  final Map<String, dynamic> user;

  SessionData({
    required this.id,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      id: json['id'],
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      expiresAt: json['expiresAt'],
      user: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt,
      'user': user,
    };
  }
}
