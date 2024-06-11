import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/services/recomedation_service.dart';

class AddTracksParams {
  final String accessToken;
  final String playlistId;
  final List<String> trackIds;

  AddTracksParams({
    required this.accessToken,
    required this.playlistId,
    required this.trackIds,
  });
}

class AddTracksNotifier extends AsyncNotifier<void> {
  late final AddTracksParams addTracksParams;

  @override
  FutureOr<void> build() {}

  Future<void> addTracksToPlaylist(AddTracksParams params) async {
    state = const AsyncValue.loading();
    try {
      await RecommendationsService().addTracksToExistingPlaylist(
        params.accessToken,
        params.playlistId,
        params.trackIds,
      );
      state = const AsyncValue.data(null);
      log('Tracks added to playlist successfully');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      log("ADD TRACKS PROVIDER ERROR: $e");
    }
  }
}

final addTracksProvider = AsyncNotifierProvider<AddTracksNotifier, void>(() {
  return AddTracksNotifier();
});
