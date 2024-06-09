import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:nuance/models/recommendation_model.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/utils/constants.dart';

class RecommendationsService {
  Future<List<SongModel>> getRecommendations(
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
      log("RESPONSE DATA: ${response.statusCode}");
      final Map<String, dynamic> data = jsonDecode(response.body);

      log("RESPONSE DATA: $data");

      final List<dynamic> recommededSongsJson =
          data['recommendations']['songs'];
      log("gemini songsJson DATA: $recommededSongsJson");
      final recommendations = recommededSongsJson
          .map((item) => RecommendationModel.fromJson(item))
          .toList();
      log("recommendations DATA: $recommendations");

      // Get track information for the recommendations
      final trackInfo = await getTrackInfo(accessToken, recommendations);
      log("trackInfo DATA: $trackInfo");

      return trackInfo;
    } else {
      log('Failed to load recommendations: ${response.body}');
      throw Exception('Failed to load recommendations');
    }
  }

  Future<List<SongModel>> getTrackInfo(
      String accessToken, List<RecommendationModel> songs) async {
    final response = await http.post(
      Uri.parse('$baseURL/spotify/tracks'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'songs': songs.map((song) => song.toJson()).toList()}),
    );
    log("getTrackInfo REQUEST: ${response.request.toString()}");
    log("getTrackInfo RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> trackData = jsonDecode(response.body)['trackInfo'];
      log("spotify rackData: ${trackData[0]}");
      return trackData.map((item) => SongModel.fromJson(item)).toList();
    } else {
      log('Failed to load track info: ${response.body}');
      throw Exception('Failed to load track info');
    }
  }
}
