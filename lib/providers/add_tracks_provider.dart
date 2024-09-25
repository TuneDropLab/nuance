import 'dart:async';
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
      
      
      await AllServices().addTracksToExistingPlaylist(
        params.accessToken,
        params.searchQuery,
        params.playlistId,
        params.imageUrl,
        params.trackIds,
        params.providerType,

      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final addTracksProvider = AsyncNotifierProvider<AddTracksNotifier, void>(() {
  return AddTracksNotifier();
});
