import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/models/playlist_model.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/services/recomedation_service.dart';

final playlistProvider = FutureProvider<List<PlaylistModel>>((ref) async {
  try {
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();

    if (sessionData == null) {
      throw Exception('User not authenticated');
    }

    final userId = sessionData['user']["user_metadata"]["provider_id"];
    final playlists = await RecommendationsService()
        .getPlaylists(sessionData['access_token'], userId);
    return playlists;
  } catch (e) {
    throw Exception('Failed to load playlists');
  }
});

final createPlaylistProvider =
    FutureProvider.family<PlaylistModel, Map<String, String>>(
        (ref, data) async {
  try {
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();

    if (sessionData == null) {
      throw Exception('User not authenticated');
    }

    final userId = sessionData['user']["user_metadata"]["provider_id"];
    final newPlaylist = await RecommendationsService().createPlaylist(
      sessionData['access_token'],
      userId,
      data['name']!,
      data['description']!,
      data['image']!,
    );
    return newPlaylist;
  } catch (e) {
    throw Exception('Failed to create playlist');
  }
});
