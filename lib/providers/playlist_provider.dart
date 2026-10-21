import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/models/playlist_model.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/providers/history_provider.dart';
import 'package:nuance/services/all_services.dart';

final playlistProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();

    if (sessionData == null) {
      return [];
    }

    final userId = sessionData['user']?["user_metadata"]?["provider_id"] ??
        sessionData['user']?['id'] ??
        '';
    final accessToken = sessionData['access_token'] ?? '';
    final providerType = sessionData['provider'] ??
        sessionData['user']?['app_metadata']?['provider'] ??
        sessionData['user']?['provider'] ??
        'google';

    if (providerType == 'spotify' || providerType == 'apple') {
      try {
        final playlists =
            await AllServices().getPlaylists(accessToken, userId, providerType);
        return playlists;
      } catch (e) {
        log("Streaming service playlists failed: $e");
      }
    }

    // For Google, Guest, Email users, or fallback: Load Nuance library playlists
    if (accessToken.isNotEmpty && !accessToken.startsWith('guest_')) {
      final historyList = await AllServices().getHistory(accessToken);
      return historyList.map((h) => PlaylistModel(
        id: h.id?.toString() ?? '',
        name: h.searchQuery ?? 'Nuance Playlist',
        description: 'Saved Nuance Soundscape',
        imageUrl: h.imageUrl ?? '',
        totalTracks: h.recommendations?.length ?? 0,
      )).toList();
    } else {
      final guestList = ref.read(guestHistoryProvider);
      return guestList.map((h) => PlaylistModel(
        id: h.id?.toString() ?? '',
        name: h.searchQuery ?? 'Nuance Playlist',
        description: 'Guest Soundscape',
        imageUrl: h.imageUrl ?? '',
        totalTracks: h.recommendations?.length ?? 0,
      )).toList();
    }
  } catch (e) {
    log("playlistProvider non-fatal error: $e");
    return [];
  }
});

final createPlaylistProvider = FutureProvider.family<dynamic, Map<String, String>>((ref, data) async {
  try {
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();

    if (sessionData == null) {
      throw Exception('User not authenticated');
    }

    final providerType = sessionData['provider'] ??
        sessionData['user']?['app_metadata']?['provider'] ??
        sessionData['user']?['provider'] ??
        'google';
    final userId = sessionData['user']?["user_metadata"]?["provider_id"] ??
        sessionData['user']?['id'] ??
        '';

    if (providerType == 'spotify' || providerType == 'apple') {
      final newPlaylist = await AllServices().createPlaylist(
        sessionData['access_token'],
        userId,
        data['name']!,
        data['description']!,
        data['image']!,
        providerType,
      );
      return newPlaylist;
    } else {
      final accessToken = sessionData['access_token'] ?? '';
      if (accessToken.isNotEmpty && !accessToken.startsWith('guest_')) {
        await AllServices().saveHistory(
          accessToken,
          data['name']!,
          data['image'] ?? '',
          [],
        );
        ref.invalidate(historyProvider);
      }
      return PlaylistModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: data['name'],
        description: data['description'],
        imageUrl: data['image'],
        totalTracks: 0,
      );
    }
  } catch (e) {
    debugPrint('Failed to create playlist, $e');
    throw Exception('Failed to create playlist, $e');
  }
});
