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
