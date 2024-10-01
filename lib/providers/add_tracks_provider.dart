import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/services/all_services.dart';

class AddTracksParams {
  final String accessToken;
  final String playlistId;
  final List<String> trackIds;
  // final provider type 
  final String providerType;

  final String searchQuery;
  final String imageUrl;

  AddTracksParams({
    required this.accessToken,
    required this.playlistId,
    required this.trackIds,
    required this.searchQuery,
    required this.imageUrl,
    required this.providerType,
  });
}

class AddTracksNotifier extends AsyncNotifier<void> {
  late final AddTracksParams addTracksParams;

  @override
  FutureOr<void> build() {}

  Future<void> addTracksToPlaylist(AddTracksParams params) async {
    state = const AsyncValue.loading();
    try {
      log("Adding tracks with params: $params");
      await AllServices().addTracksToExistingPlaylist(
        params.accessToken,
        params.searchQuery,
        params.playlistId,
        params.imageUrl,
        params.trackIds,
        params.providerType, // Ensure this is passed
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      log("Error adding tracks: $e");
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final addTracksProvider = AsyncNotifierProvider<AddTracksNotifier, void>(() {
  return AddTracksNotifier();
});
