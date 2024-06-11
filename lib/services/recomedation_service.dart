import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:nuance/models/recommendation_model.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/models/playlist_model.dart';
import 'package:nuance/utils/constants.dart';

class RecommendationsService {
  Future<List<SongModel>> getRecommendations(
      String accessToken, String userMessage) async {
    try {
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

        final List<dynamic> recommendedSongsJson =
            data['recommendations']['songs'];
        log("gemini songsJson DATA: $recommendedSongsJson");
        final recommendations = recommendedSongsJson
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
    } catch (e) {
      log('Exception in getRecommendations: $e');
      rethrow;
    }
  }

  Future<List<SongModel>> getTrackInfo(
      String accessToken, List<RecommendationModel> songs) async {
    try {
      final response = await http.post(
        Uri.parse('$baseURL/spotify/tracks'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body:
            jsonEncode({'songs': songs.map((song) => song.toJson()).toList()}),
      );
      log("getTrackInfo REQUEST: ${response.request.toString()}");
      log("getTrackInfo RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> trackData = jsonDecode(response.body)['trackInfo'];
        log("spotify trackData: ${trackData[0]}");
        return trackData.map((item) => SongModel.fromJson(item)).toList();
      } else {
        log('Failed to load track info: ${response.body}');
        throw Exception('Failed to load track info');
      }
    } catch (e) {
      log('Exception in getTrackInfo: $e');
      rethrow;
    }
  }

  Future<List<PlaylistModel>> getPlaylists(
      String accessToken, String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseURL/spotify/playlists'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      log("getPlaylists REQUEST: ${response.request.toString()}");
      log("getPlaylists RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> playlistData =
            jsonDecode(response.body)['playlists'];

        // Filter playlists to only include those created by the user
        final userPlaylists = playlistData
            .where((item) => item['owner']['id'] == userId)
            .map((item) => PlaylistModel.fromJson(item))
            .toList();
        log("userPlaylists DATA: $userPlaylists");

        return userPlaylists;
      } else {
        log('Failed to load playlists: ${response.body}');
        throw Exception('Failed to load playlists');
      }
    } catch (e) {
      log('Exception in getPlaylists: $e');
      rethrow;
    }
  }

  Future<void> addTracksToExistingPlaylist(
      String accessToken, String playlistId, List<String> trackIds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseURL/spotify/playlists/$playlistId/add'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'trackIds': trackIds}),
      );

      log('ADD TRACKS TO PLAYLIST RESPONSE: ${response.body}');
      log('ADD TRACKS accessToken RESPONSE: $accessToken');
      log('ADD TRACKS playlistId RESPONSE: $playlistId');
      log('ADD TRACKS trackIds RESPONSE: ${trackIds.first}');

      if (response.statusCode == 200) {
        log('Tracks added to playlist successfully');
      } else {
        log('Failed to add tracks to playlist: ${response.body}');
        throw Exception('Failed to add tracks to playlist');
      }
    } catch (e) {
      log('Exception in addTracksToPlaylist: $e');
      rethrow;
    }
  }
}
