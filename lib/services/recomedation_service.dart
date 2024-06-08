import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:nuance/models/recommendation_model.dart';
import 'package:nuance/utils/constants.dart';

class RecommendationsService {
  Future<List<RecommendationModel>> getRecommendations(
      String accessToken, String userMessage) async {
    final response = await http.post(
      Uri.parse('$baseURL/gemini/recommendations'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'userMessage': userMessage}),
    );
    log("REQUEST: ${response.request.toString()}");
    log("RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['recommendations'];
      return data.map((json) => RecommendationModel.fromJson(json)).toList();
    } else {
      log('Failed to load recommendations: ${response.body}');
      throw Exception('Failed to load recommendations');
    }
  }
}
