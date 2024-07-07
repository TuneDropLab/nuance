import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:nuance/models/history_model.dart';
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

      // log('ADD TRACKS TO PLAYLIST RESPONSE: ${response.body}');
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

  Future<PlaylistModel> createPlaylist(String accessToken, String userId,
      String name, String description) async {
    try {
      final response = await http.post(
        Uri.parse('$baseURL/spotify/playlists'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
            {'userId': userId, 'name': name, 'description': description}),
      );
      log("createPlaylist REQUEST: ${response.request.toString()}");
      log("createPlaylist RESPONSE: ${response.statusCode}");

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body)['playlist'];
        log("created playlist data: $data");
        return PlaylistModel.fromJson(data);
      } else {
        log('Failed to create playlist: ${response.body}');
        throw Exception('Failed to create playlist');
      }
    } catch (e) {
      log('Exception in createPlaylist: $e');
      rethrow;
    }
  }

  Future<List<HistoryModel>> getHistory(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseURL/history'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      log("getHistory REQUEST: ${response.request.toString()}");
      log("getHistory RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> historyData = jsonDecode(response.body);
        log("History Data: $historyData");
        return historyData.map((item) => HistoryModel.fromJson(item)).toList();
      } else {
        log('Failed to load history: ${response.body}');
        throw Exception('Failed to load history');
      }
    } catch (e) {
      log('Exception in getHistory: $e');
      rethrow;
    }
  }

  Future<void> deleteHistory(String accessToken, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseURL/history/$id'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      log("deleteHistory REQUEST: ${response.request.toString()}");
      log("deleteHistory RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        log('History deleted successfully');
      } else {
        log('Failed to delete history: ${response.body}');
        throw Exception('Failed to delete history');
      }
    } catch (e) {
      log('Exception in deleteHistory: $e');
      rethrow;
    }
  }

  Future<void> deleteAllHistory(String accessToken) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseURL/history'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      log("deleteAllHistory REQUEST: ${response.request.toString()}");
      log("deleteAllHistory RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        log('All history deleted successfully');
      } else {
        log('Failed to delete all history: ${response.body}');
        throw Exception('Failed to delete all history');
      }
    } catch (e) {
      log('Exception in deleteAllHistory: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getSpotifyHomeRecommendations(
      String accessToken, int page, int limit) async {
    try {
      final response = await http.get(
        Uri.parse('$baseURL/spotify/home?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      log("getSpotifyHomeRecommendations REQUEST: ${response.request.toString()}");
      log("getSpotifyHomeRecommendations RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        log("Spotify Home Recommendations Data: $data");
        return data;
      } else {
        log('Failed to load Spotify home recommendations: ${response.body}');
        throw Exception('Failed to load Spotify home recommendations');
      }
    } catch (e) {
      log('Exception in getSpotifyHomeRecommendations: $e');
      rethrow;
    }
  }

  Future<List<String>> getTags(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseURL/gemini/tags'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      log("generateRecommendationTags REQUEST: ${response.request.toString()}");
      log("generateRecommendationTags RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> tags = jsonDecode(response.body)['tags'];
        log("Generated Tags Data: $tags");
        return tags.map((tag) => tag.toString()).toList();
      } else {
        log('Failed to generate recommendation tags: ${response.body}');
        throw Exception('Failed to generate recommendation tags');
      }
    } catch (e) {
      log('Exception in generateRecommendationTags: $e');
      rethrow;
    }
  }

  Future<List<SongModel>> fetchPlaylistTracks(
      String accessToken, String providerId, String playlistId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseURL/spotify/playlist-tracks'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'playlistId': playlistId,
          'userId': providerId,
        }),
      );

      final data = jsonDecode(response.body);
      log("Playlist Tracks Data: $data");
      if (response.statusCode == 200) {
        return (data['playlistTracks'] as List)
            .map((e) => SongModel.fromJson(e))
            .toList();
      } else {
        throw Exception('Failed to load playlist tracks');
      }
    } catch (e) {
      print('Error fetching playlist tracks: $e');
      throw Exception('Failed to fetch playlist tracks');
    }
  }
}
