import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nuance/models/auth_model.dart';
import 'package:nuance/utils/constants.dart';

class AuthService {
  // ...

  Future<AuthModel> loginWithSpotify() async {
    final response = await http.get(Uri.parse('$baseURL/auth/login'));

    print("HIIIIIII, ${response.body}");
    print("HIIIIIII, ${response.statusCode}");
    print("HIIIIIII, ${response.request}");
    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, then parse the JSON.
      // You'll need to replace this with whatever logic is appropriate
      // for your app.
      return AuthModel.fromJson(jsonDecode(response.body));
    } else {
      // If the server returns an unsuccessful response code, throw an exception.
      throw Exception('Failed to log in with Spotify');
    }
  }
}
