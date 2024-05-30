class AuthModel {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String userName;
  final String userEmail;

  AuthModel({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      userId: json['user_id'],
      userName: json['user_name'],
      userEmail: json['user_email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
    };
  }
}
