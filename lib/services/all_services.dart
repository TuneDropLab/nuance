import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:nuance/models/history_model.dart';
import 'package:nuance/models/recommendation_model.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/models/playlist_model.dart';
import 'package:nuance/utils/constants.dart';
import 'package:nuance/widgets/custom_snackbar.dart';
import 'package:share_plus/share_plus.dart';

class AllServices {
  final CustomSnackbar _customSnackbar = CustomSnackbar();

  // Future<bool> _isAppleProvider() async {
  //   return ProviderType.type ==
  //       'apple';
  // }

  // Future<bool> _isAppleProvider(String accessToken) async {
  //   // Logic to determine if the provider is Apple based on session data
  //   // This could involve making a request to get session data or checking a local state
  //   // Return true if Apple, false otherwise
  //   return true;
  // }

  Future<List<SongModel>> getRecommendations(
      String accessToken, String userMessage, isAppleProvider) async {
    // final isAppleProvider = await _isAppleProvider();
    // final basePath = isAppleProvider ? '/apple-music' : 'spotify';
    try {
      log("Starting getRecommendations with accessToken: $accessToken, userMessage: $userMessage, isAppleProvider: $isAppleProvider");

      final response = await http.post(
        Uri.parse('$baseURL/gemini/recommendations'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'userMessage': userMessage}),
      );

      log("Received response with status code: ${response.statusCode}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        log("Response body decoded: $data");

        final List<dynamic> recommendedSongsJson =
            data['recommendations']['songs'];
        log("Recommended songs JSON: $recommendedSongsJson");

        final recommendations = recommendedSongsJson
            .map((item) => RecommendationModel.fromJson(item))
            .toList();
        log("Recommendations mapped: $recommendations");

        final trackInfo = await getTrackInfo(accessToken, recommendations, isAppleProvider: isAppleProvider);
        log("Track info retrieved: $trackInfo");

        return trackInfo;
      } else {
        log("Error - Failed to load recommendations, status code: ${response.statusCode}");
        throw Exception('Failed to load recommendations');
      }
    } catch (e) {
      log("Exception occurred: $e");
      rethrow;
    }
  }

  Future<List<SongModel>> getMoreRecommendations(
      String accessToken,
      String userMessage,
      List<SongModel> currentSongList,
      isAppleProvider) async {
    log("GMRFN: Starting getMoreRecommendations with accessToken: $accessToken, userMessage: $userMessage, currentSongList: $currentSongList, isAppleProvider: $isAppleProvider");

    try {
      log("GMRFN: Sending POST request to $baseURL/more-recommendations");
      final response = await http.post(
        Uri.parse('$baseURL/gemini/more-recommendations'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
            {'userMessage': userMessage, 'currentSongs': currentSongList}),
      );

      log("GMRFN: Received response with status code: ${response.statusCode}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        log("GMRFN: Response body decoded: $data");

        final List<dynamic> recommendedSongsJson =
            data['recommendations']['songs'];
        log("GMRFN: Recommended songs JSON: $recommendedSongsJson");
        final recommendations = recommendedSongsJson
            .map((item) => RecommendationModel.fromJson(item))
            .toList();
        log("GMRFN: Recommendations mapped: $recommendations");

        final trackInfo = await getTrackInfo(accessToken, recommendations,
            currentSongList: currentSongList, // Use named parameter here,
            isAppleProvider: isAppleProvider
            );
        log("GMRFN: Track info retrieved: $trackInfo");

        return trackInfo;
      } else {
        log("GMRFN: Error - Failed to load recommendations, status code: ${response.statusCode}");
        throw Exception('Failed to load recommendations');
      }
    } catch (e) {
      log("GMRFN: Exception occurred: $e");
      rethrow;
    }
  }

  Future<List<SongModel>> getTrackInfo(
      String accessToken, List<RecommendationModel> songs,
      {List<SongModel>? currentSongList, isAppleProvider}) async {
    final basePath = isAppleProvider == 'apple' ? '/apple-music' : '/spotify';
    try {
      final Map<String, dynamic> requestBody = {
        'songs': songs,
      };

      if (currentSongList != null) {
        requestBody['currentSongs'] = currentSongList;
      }

      

      final response = await http.post(
        Uri.parse('$baseURL$basePath/tracks'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      log("Sending request to $baseURL$basePath/tracks with body: $requestBody");

      log("Received response with status code 123333: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> trackData = jsonDecode(response.body)['trackInfo'];
        log("Track data decoded: $trackData");
        return trackData.map((item) => SongModel.fromJson(item)).toList();
      } else {
        log("Error - Failed to load track info, status code: ${response.statusCode}");
        throw Exception('Failed to load track info');
      }
    } catch (e) {
      log("Exception occurred: $e");
      rethrow;
    }
  }

  Future<List<PlaylistModel>> getPlaylists(
      String accessToken, String userId, isAppleProvider) async {
    // final isAppleProvider = await _isAppleProvider();
    final basePath = isAppleProvider == 'apple' ? '/apple-music' : '/spotify';

    try {
      final response = await http.get(
        Uri.parse('$baseURL$basePath/playlists'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> playlistData =
            jsonDecode(response.body)['playlists'];

        // Filter playlists to only include those created by the user
        final userPlaylists = playlistData
            .where((item) => item['owner']['id'] == userId)
            .map((item) => PlaylistModel.fromJson(item))
            .toList();

        return userPlaylists;
      } else {
        throw Exception('Failed to load playlists');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addTracksToExistingPlaylist(
    String accessToken,
    String searchQuery,
    String playlistId,
    String image,
    List<String> trackIds,
    isAppleProvider,
  ) async {
    // final isAppleProvider = await _isAppleProvider();
    final basePath = isAppleProvider == 'apple' ? '/apple-music' : '/spotify';
    try {
      final response = await http.post(
        Uri.parse('$baseURL$basePath/playlists/$playlistId/add'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
            {'trackIds': trackIds, 'query': searchQuery, 'imageUrl': image}),
      );

      if (response.statusCode == 200) {
      } else {
        throw Exception('Failed to add tracks to playlist');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<PlaylistModel> createPlaylist(
    String accessToken,
    String userId,
    String name,
    String description,
    String imageUrl,
    isAppleProvider,
  ) async {
    // final isAppleProvider = await _isAppleProvider();
    final basePath = isAppleProvider == 'apple' ? '/apple-music' : '/spotify';
    try {
      final response = await http.post(
        Uri.parse('$baseURL$basePath/playlists'),
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

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body)['playlist'];
        debugPrint("created playlist data: $data");
        await setPlaylistCoverImage(
            accessToken, data['id'], imageUrl, isAppleProvider);
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
    String accessToken,
    String playlistId,
    String imageUrl,
    isAppleProvider,
  ) async {
    // final isAppleProvider = await _isAppleProvider();
    final basePath = isAppleProvider == 'apple' ? '/apple-music' : '/spotify';
    try {
      final response = await http.post(
        Uri.parse('$baseURL$basePath/playlists/$playlistId/cover-image'),
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
    // final isAppleProvider = await _isAppleProvider();
    // final basePath = isAppleProvider ? '/apple-music' : '';
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
        return historyData.map((item) => HistoryModel.fromJson(item)).toList();
      } else {
        _customSnackbar.show('Failed to get history');
        throw Exception('Failed to load history');
      }
    } catch (e) {
      _customSnackbar.show('Failed to get history');

      rethrow;
    }
  }

  Future<void> deleteHistory(
    String accessToken,
    int id,
    // isAppleProvider,
  ) async {
    // final isAppleProvider = await _isAppleProvider();
    // final basePath = isAppleProvider ? '/apple-music' : '';
    try {
      final response = await http.delete(
        Uri.parse('$baseURL/history/$id'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
      } else {
        throw Exception('Failed to delete history');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAllHistory(
    String accessToken,
  ) async {
    // final isAppleProvider = await _isAppleProvider();
    // final basePath = isAppleProvider ? '/apple-music' : '';
    try {
      final response = await http.delete(
        Uri.parse('$baseURL/history'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
      } else {
        throw Exception('Failed to delete all history');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getSpotifyHomeRecommendations(
    String accessToken,
    isAppleProvider,
  ) async {
    // final isAppleProvider = await _isAppleProvider();
    final basePath = isAppleProvider == 'apple' ? '/apple-music' : '/spotify';
    try {
      final response = await http.get(
        Uri.parse('$baseURL$basePath/home'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        _customSnackbar.show('Failed to generate recommendations');
        throw Exception('Failed to load Spotify home recommendations');
      }
    } catch (e) {
      _customSnackbar.show('Failed to generate recommendations');
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
        return tags.map((tag) => tag.toString()).toList();
      } else {
        _customSnackbar.show('Failed to generate recommendation tags');
        throw Exception('Failed to generate recommendation tags');
      }
    } catch (e) {
      _customSnackbar.show('Failed to generate recommendation tags');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchPlaylistTracks(
    String accessToken,
    String providerId,
    String playlistId,
    isAppleProvider,
  ) async {
    // final isAppleProvider = await _isAppleProvider();
    final basePath = isAppleProvider == 'apple' ? '/apple-music' : '/spotify';
    try {
      final response = await http.post(
        Uri.parse('$baseURL$basePath/playlist-tracks'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'playlistId': playlistId,
          'userId': providerId,
        }),
      );

      // log("FETCH PLAYLIST TRACKS RESPONSE: $response");

      final data = jsonDecode(response.body);
      // log("FETCH PLAYLIST TRACKS DATA: $data");
      if (response.statusCode == 200) {
        final playlistImage = data['playlistImage']?.replaceAll('{w}x{h}', '1024x1024');
        log("FETCH PLAYLIST TRACKS PLAYLIST IMAGE: $playlistImage");
        final tracks = (data['playlistTracks'] as List)
            .map((e) => SongModel.fromJson(e))
            .toList();
        log("FETCH PLAYLIST TRACKS : $tracks");
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
          RegExp(r'^http:\/\/(localhost:3000|api\.discovernuance\.com|https:\/\/api\.discovernuance\.com)'), 'nuanceapp://');
      Share.share(
        modifiedLink,
        subject: "Check out this recommendation",
        sharePositionOrigin: Rect.fromPoints(
          const Offset(2, 2),
          const Offset(3, 3),
        ),
      );
    } else {
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
      log("GET SHARED RECOMMENDATION BODY: $body");
      final recommendationData = body;
      return recommendationData;
    } else {
      throw Exception('Failed to retrieve share link data');
    }
  }

  Future<void> followSpotifyPlaylist(
    String accessToken,
    String playlistId,
    isAppleProvider,
  ) async {
    // final isAppleProvider = await _isAppleProvider();
    final basePath = isAppleProvider == 'apple' ? '/apple-music' : '/spotify';
    try {
      final response = await http.post(
        Uri.parse(
          '$baseURL$basePath/playlists/$playlistId/follow',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      final String message = responseBody['message'];
      if (response.statusCode == 200) {
        CustomSnackbar().show(
          message,
          icon: SvgPicture.asset(
            "assets/spotifylogoblack.svg",
            color: Colors.white,
            height: 20,
          ),
        );
      } else {
        throw Exception('Failed to follow playlist: $message');
      }
    } catch (e) {
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

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        CustomSnackbar().show(
          'Failed to fetch user profile',
        );
        throw Exception('Failed to fetch user profile');
      }
    } catch (e) {
      CustomSnackbar().show(
        'Failed to fetch user profile',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(
    String accessToken,
    String name,
  ) async {
    // final isAppleProvider = await _isAppleProvider();
    // final basePath = isAppleProvider ? '/apple-music' : '';
    try {
      final response = await http.put(
        Uri.parse('$baseURL/user/profile'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update user profile');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getGeneratedImage(
    String accessToken,
    String promptMessage,
  ) async {
    // final isAppleProvider = await _isAppleProvider();
    // final basePath = isAppleProvider ? '/apple-music' : '';
    log("BASE URL FROM GET GENERATED IMAGE: $baseURL");
    try {
      final response = await http.post(
        Uri.parse('$baseURL/gemini/image'),
        headers: {
          // set referer header
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'promptMessage': promptMessage}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        final String image = data['image'];

        return image;
      } else {
        log("Error generating image: ${response.statusCode}");
        log("Error generating image: ${response.body}");
        log("Error generating image: ${response.headers}");
        log("Error generating image: ${response.request}");
        throw Exception('Failed to generate image');
      }
    } catch (e) {
      rethrow;
    }
  }
}