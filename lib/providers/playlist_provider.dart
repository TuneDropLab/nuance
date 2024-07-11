import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/models/playlist_model.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/services/recomedation_service.dart';

final playlistProvider = FutureProvider<List<PlaylistModel>>((ref) async {
  try {
    log("PLAYLIST PROVIDER CALLED");
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();
    log("PLAYLIST PROVIDER SESSION DATA:!!! $sessionData");

    if (sessionData == null) {
      log("SESSION DATA IS NULL:!!! $sessionData");
      throw Exception('User not authenticated');
    }

    final userId = sessionData['user']["user_metadata"]["provider_id"];
    log("USERID PASSED TO GET PLAYLISTS: $sessionData");
    log("USERID PASSED TO GET PLAYLISTS: $userId");
    log("SESSION DATA PASSED TO GET PLAYLISTS: ${sessionData['access_token']}");
    final playlists = await RecommendationsService()
        .getPlaylists(sessionData['access_token'], userId);
    log("PLAYLISTS RETURNED:!!! $playlists");
    return playlists;
  } catch (e) {
    log("PLAYLIST PROVIDER ERROR: $e");
    throw Exception('Failed to load playlists');
  }
});

final createPlaylistProvider =
    FutureProvider.family<PlaylistModel, Map<String, String>>(
        (ref, data) async {
  try {
    log("CREATE PLAYLIST PROVIDER CALLED");
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();
    log("CREATE PLAYLIST PROVIDER SESSION DATA:!!! $sessionData");

    if (sessionData == null) {
      log("SESSION DATA IS NULL:!!! $sessionData");
      throw Exception('User not authenticated');
    }

    final userId = sessionData['user']["user_metadata"]["provider_id"];
    log("USERID PASSED TO CREATE PLAYLIST: $sessionData");
    log("USERID PASSED TO CREATE PLAYLIST: $userId");
    log("SESSION DATA PASSED TO CREATE PLAYLIST: ${sessionData['access_token']}");
    final newPlaylist = await RecommendationsService().createPlaylist(
      sessionData['access_token'],
      userId,
      data['name']!,
      data['description']!,
      // data['image']!,
    );
    log("NEW PLAYLIST RETURNED:!!! $newPlaylist");
    return newPlaylist;
  } catch (e) {
    log("CREATE PLAYLIST PROVIDER ERROR: $e");
    throw Exception('Failed to create playlist');
  }
});
