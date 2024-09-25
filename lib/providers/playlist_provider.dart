import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/models/playlist_model.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/services/all_services.dart';

final playlistProvider = FutureProvider<List<PlaylistModel>>((ref) async {
  try {
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();

    if (sessionData == null) {
      throw Exception('User not authenticated');
    }

    final userId = sessionData['user']["user_metadata"]["provider_id"];
    final accessToken = sessionData['access_token'];
    final providerType = sessionData['user']['app_metadata']['provider'];
    final playlists =
        await AllServices().getPlaylists(accessToken, userId, providerType);
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

    // final accessToken = sessionData['access_token'];
    final providerType = sessionData['user']['app_metadata']['provider'];
    final userId = sessionData['user']["user_metadata"]["provider_id"];
    final newPlaylist = await AllServices().createPlaylist(
      sessionData['access_token'],
      userId,
      data['name']!,
      data['description']!,
      data['image']!,
      providerType,
    );
    return newPlaylist;
  } catch (e) {
    throw Exception('Failed to create playlist');
  }
});
