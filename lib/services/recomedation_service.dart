import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:nuance/models/history_model.dart';
import 'package:nuance/models/recommendation_model.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/models/playlist_model.dart';
import 'package:nuance/utils/constants.dart';
import 'package:nuance/widgets/custom_snackbar.dart';
import 'package:share_plus/share_plus.dart';

class RecommendationsService {
  final CustomSnackbar _customSnackbar = CustomSnackbar();
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

  Future<List<SongModel>> getMoreRecommendations(String accessToken,
      String userMessage, List<SongModel> currentSongList) async {
    try {
      final response = await http.post(
        Uri.parse('$baseURL/gemini/more-recommendations'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
            {'userMessage': userMessage, 'currentSongs': currentSongList}),
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

        final trackInfo = await getTrackInfo(accessToken, recommendations,
            currentSongList: currentSongList // Use named parameter here
            );
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
      String accessToken, List<RecommendationModel> songs,
      {List<SongModel>? currentSongList}) async {
    try {
      final Map<String, dynamic> requestBody = {
        'songs': songs,
      };

      if (currentSongList != null) {
        requestBody['currentSongs'] = currentSongList;
        log("currentSongList: $currentSongList");
      }

      final response = await http.post(
        Uri.parse('$baseURL/spotify/tracks'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      log("getTrackInfo REQUEST: ${response.request.toString()}");
      log("getTrackInfo RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> trackData = jsonDecode(response.body)['trackInfo'];
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
      String accessToken,
      String searchQuery,
      String playlistId,
      String image,
      List<String> trackIds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseURL/spotify/playlists/$playlistId/add'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
            {'trackIds': trackIds, 'query': searchQuery, 'imageUrl': image}),
      );

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

  Future<PlaylistModel> createPlaylist(
    String accessToken,
    String userId,
    String name,
    String description,
    String imageUrl,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseURL/spotify/playlists'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'name': name,
          'description': description,
        }),
      );

      debugPrint("createPlaylist REQUEST: ${response.request.toString()}");
      debugPrint("createPlaylist RESPONSE: ${response.statusCode}");

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body)['playlist'];
        debugPrint("created playlist data: $data");

        // Set the playlist cover image
        await setPlaylistCoverImage(accessToken, data['id'], imageUrl);

        return PlaylistModel.fromJson(data);
      } else {
        debugPrint('Failed to create playlist: ${response.body}');
        throw Exception('Failed to create playlist');
      }
    } catch (e) {
      debugPrint('Exception in createPlaylist: $e');
      rethrow;
    }
  }

  Future<Uint8List> getImageBytes(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load image');
    }
  }

  Future<void> setPlaylistCoverImage(
      String accessToken, String playlistId, String imageUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$baseURL/spotify/playlists/$playlistId/cover-image'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'baseImageUrl': imageUrl,
          'logoUrl':
              'https://uploads-ssl.webflow.com/668ee73d58f89c3cfa7bdf1c/668ee7d41a8ace1e7243b0ed_Nuances%20Frame%208%20(1).png'
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to set playlist cover image: ${response.body}');
        throw Exception('Failed to set playlist cover image');
      }
      debugPrint('SET PLAYLIST COVER IMAGE: $response');
    } catch (e) {
      debugPrint('Exception in setPlaylistCoverImage: $e');
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

      if (response.statusCode == 200) {
        final List<dynamic> historyData = jsonDecode(response.body);
        debugPrint("History Data: $historyData");
        return historyData.map((item) => HistoryModel.fromJson(item)).toList();
      } else {
        _customSnackbar.show('Failed to get history');
        log('Failed to load history: ${response.body}');
        throw Exception('Failed to load history');
      }
    } catch (e) {
      _customSnackbar.show('Failed to get history');

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
      String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseURL/spotify/home'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        log("Spotify Home Recommendations Data: $data");
        return data;
      } else {
        _customSnackbar.show('Failed to generate recommendations');
        log('Failed to load Spotify home recommendations: ${response.body}');
        throw Exception('Failed to load Spotify home recommendations');
      }
    } catch (e) {
      _customSnackbar.show('Failed to generate recommendations');
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

      if (response.statusCode == 200) {
        final List<dynamic> tags = jsonDecode(response.body)['tags'];
        log("Generated Tags Data: $tags");
        return tags.map((tag) => tag.toString()).toList();
      } else {
        _customSnackbar.show('Failed to generate recommendation tags');
        log('Failed to generate recommendation tags: ${response.body}');
        throw Exception('Failed to generate recommendation tags');
      }
    } catch (e) {
      _customSnackbar.show('Failed to generate recommendation tags');
      log('Exception in generateRecommendationTags: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchPlaylistTracks(
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
        final playlistImage = data['playlistImage'];
        final tracks = (data['playlistTracks'] as List)
            .map((e) => SongModel.fromJson(e))
            .toList();

        return {
          'playlistImage': playlistImage,
          'playlistTracks': tracks,
        };
      } else {
        _customSnackbar.show('Failed to get playlist songs');
        throw Exception('Failed to load playlist songs');
      }
    } catch (e) {
      _customSnackbar.show('Failed to get playlist songs');

      debugPrint('Error fetching playlist tracks: $e');
      throw Exception('Failed to fetch playlist tracks');
    }
  }

  Future<void> shareRecommendation(BuildContext context, String playlistName,
      List<dynamic> songs, String playlistImageUrl) async {
    final url = Uri.parse('$baseURL/share/generate');
    final recommendationData = {
      'searchQuery': playlistName,
      'songs': songs,
      'image': playlistImageUrl,
    };
    final response = await http.post(url,
        body: jsonEncode({
          'recommendationData': recommendationData,
        }),
        headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final shareLink = body['link'];

      final modifiedLink = shareLink.replaceFirst(
          RegExp(r'^http:\/\/localhost:3000'), 'nuanceapp://');
      Share.share(
        modifiedLink,
        subject: "Check out this recommendation",
        sharePositionOrigin: Rect.fromPoints(
          const Offset(2, 2),
          const Offset(3, 3),
        ),
      );
    } else {
      log("status code!!!!!: ${response.statusCode}");
      CustomSnackbar().show(
        'Failed to generate share link',
      );
    }
  }

  Future<Map<String, dynamic>> getSharedRecommendation(String shareId) async {
    final url = Uri.parse('$baseURL/share/$shareId');

    final response =
        await http.get(url, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final recommendationData = body;
      return recommendationData;
    } else {
      log("Failed to retrieve share link data. Status code: ${response.statusCode}");
      throw Exception('Failed to retrieve share link data');
    }
  }

  Future<void> followSpotifyPlaylist(
      String accessToken, String playlistId) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseURL/spotify/playlists/$playlistId/follow',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      log("followSpotifyPlaylist REQUEST: ${response.request.toString()}");
      log("followSpotifyPlaylist RESPONSE: ${response.body}");

      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      final String message = responseBody['message'];
      if (response.statusCode == 200) {
        log('Playlist followed successfully');
        CustomSnackbar().show(message);
      } else {
        log('Failed to follow playlist: $message');
        throw Exception('Failed to follow playlist: $message');
      }
    } catch (e) {
      log('Exception in followSpotifyPlaylist: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserProfile(
    String accessToken,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseURL/user/profile'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      log("getUserProfile REQUEST: ${response.request.toString()}");
      log("getUserProfile RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        log('Failed to fetch user profile: ${response.body}');
        CustomSnackbar().show(
          'Failed to fetch user profile',
        );
        throw Exception('Failed to fetch user profile');
      }
    } catch (e) {
      CustomSnackbar().show(
        'Failed to fetch user profile',
      );
      log('Exception in getUserProfile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(
    String accessToken,
    String name,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseURL/user/profile'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name}),
      );

      log("updateUserProfile REQUEST: ${response.request.toString()}");
      log("updateUserProfile RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        log('Failed to update user profile: ${response.body}');
        throw Exception('Failed to update user profile');
      }
    } catch (e) {
      log('Exception in updateUserProfile: $e');
      rethrow;
    }
  }

  Future<String> getGeneratedImage(
    String accessToken,
    String promptMessage,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseURL/gemini/image'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'promptMessage': promptMessage}),
      );
      log("REQUEST: ${response.request.toString()}");
      log("RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        log("RESPONSE DATA: ${response.statusCode}");
        final Map<String, dynamic> data = jsonDecode(response.body);

        log("RESPONSE DATA: $data");

        final String image = data['image'];
        log("Generated image DATA: $image");

        return image;
      } else {
        log('Failed to generate image: ${response.body}');
        throw Exception('Failed to generate image');
      }
    } catch (e) {
      log('Exception in getGeneratedImage: $e');
      rethrow;
    }
  }
}
