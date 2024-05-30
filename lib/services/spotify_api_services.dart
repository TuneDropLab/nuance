import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nuance/models/recommendation_model.dart';


class ApiService {
  final String baseUrl = 'https://your-express-server.com';

  Future<List<RecommendationModel>> fetchRecommendations(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/recommendations'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => RecommendationModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load recommendations');
    }
  }
}
