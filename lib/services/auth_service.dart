import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nuance/models/auth_model.dart';
import 'package:nuance/utils/constants.dart';

class AuthService {
  final String clientId = 'YOUR_CLIENT_ID';
  final String clientSecret = 'YOUR_CLIENT_SECRET';
  final String redirectUri = 'nuance://callback';
  final String tokenUrl = '$baseURL/oauth/token';

  Future<AuthModel> authenticate(String code) async {
    final response = await http.post(
      Uri.parse(tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'client_secret': clientSecret,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return AuthModel.fromJson(data);
    } else {
      throw Exception('Failed to authenticate');
    }
  }
}
