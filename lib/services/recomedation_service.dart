import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:nuance/models/recommendation_model.dart';
import 'package:nuance/utils/constants.dart';

class RecommendationsService {
  Future<List<RecommendationModel>> getRecommendations(
      String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseURL/recommendations'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    log("RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['recommendations'];
      return data.map((json) => RecommendationModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load recommendations');
    }
  }
}
