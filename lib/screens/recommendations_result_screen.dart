import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/providers/recommendation_provider.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/providers/playlist_provider.dart';
import 'package:nuance/models/playlist_model.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/providers/add_tracks_provider.dart';

class RecommendationsResultScreen extends ConsumerStatefulWidget {
  static const routeName = '/recommendations-result';

  const RecommendationsResultScreen({super.key});

  @override
  ConsumerState<RecommendationsResultScreen> createState() =>
      _RecommendationsResultScreenState();
}

class _RecommendationsResultScreenState
    extends ConsumerState<RecommendationsResultScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  SongModel? _currentSong;
  String? searchTerm;
  AsyncValue<SessionData?>? sessionState;
  String? _loadingPlaylistId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)!.settings.arguments as Map;
    searchTerm = arguments['search_term'] as String?;
    sessionState = arguments['sessionState'] as AsyncValue<SessionData?>?;
    log("STATE : ${sessionState?.value?.accessToken}");
  }

  void _togglePlay(SongModel song) async {
    if (song.previewUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No preview available for this song.')),
      );
      return;
    }

    if (_isPlaying && _currentSong?.id == song.id) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      if (_currentSong != null) {
        await _audioPlayer.stop();
      }
      await _audioPlayer.play(UrlSource(song.previewUrl));
      setState(() {
        _isPlaying = true;
        _currentSong = song;
      });
    }
  }

  void _showArtworkOverlay(BuildContext context, String artworkUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Scaffold(
            backgroundColor: Colors.black54,
            body: Center(
              child: Image.network(
                artworkUrl,
                width: MediaQuery.of(context).size.width * 0.5,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPlaylists(BuildContext context, List<SongModel> recommendations) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.93,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Text("Add to Playlist"),
              ),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final playlistsState = ref.watch(playlistProvider);
                    final addTracksState = ref.watch(addTracksProvider);

                    return playlistsState.when(
                      data: (playlists) {
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = playlists[index];
                            final isCurrentLoading =
                                _loadingPlaylistId == playlist.id;

                            return ListTile(
                              // leading: Image.network(
                              //   playlist.imageUrl,
                              //   width: 50,
                              //   height: 50,
                              //   fit: BoxFit.cover,
                              // ),
                              leading: CachedNetworkImage(
                                height: 40,
                                width: 40,
                                imageUrl: playlist.imageUrl,
                                placeholder: (context, url) {
                                  return Container(
                                      alignment: Alignment.center,
                                      child:
                                          const CupertinoActivityIndicator());
                                },
                              ),
                              title: Text(playlist.name),
                              subtitle: Text(
                                  "${playlist.totalTracks} ${playlist.totalTracks >= 2 ? "songs" : "song"} "),
                              enabled: !isCurrentLoading &&
                                  addTracksState.maybeWhen(
                                    loading: () => false,
                                    orElse: () => true,
                                  ),
                              onTap: () {
                                if (sessionState?.value?.accessToken != null) {
                                  final trackIds = recommendations
                                      .map((song) => song.trackUri)
                                      .toList();

                                  final params = AddTracksParams(
                                    accessToken:
                                        sessionState!.value!.accessToken,
                                    playlistId: playlist.id,
                                    trackIds: trackIds,
                                  );

                                  setState(() {
                                    _loadingPlaylistId = playlist.id;
                                  });

                                  ref
                                      .read(addTracksProvider.notifier)
                                      .addTracksToPlaylist(params)
                                      .then((_) {
                                    setState(() {
                                      _loadingPlaylistId = null;
                                    });
                                    Navigator.pop(context); // Close modal
                                    // Navigator.pop(context); // Navigate back to home screen
                                  }).catchError((error) {
                                    setState(() {
                                      _loadingPlaylistId = null;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Failed to add tracks to playlist.')),
                                    );
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('No access token found.')),
                                  );
                                }
                              },
                              trailing: isCurrentLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CupertinoActivityIndicator(
                                          // strokeWidth: 2,
                                          ),
                                    )
                                  : null,
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CupertinoActivityIndicator(),
                      ),
                      error: (error, stack) => Center(
                        child: Text('Error: $error'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (searchTerm == null) {
      return const Scaffold(
        body: Center(child: Text('No search term found')),
      );
    }

    final recommendationsState =
        ref.watch(recommendationsProvider(searchTerm!));

    return Scaffold(
      appBar: AppBar(
        title: Text(searchTerm ?? ''),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_play),
            onPressed: () {
              recommendationsState.when(
                data: (recommendations) {
                  _showPlaylists(context, recommendations);
                },
                loading: () {
                  // Handle loading state if needed
                },
                error: (error, stack) {
                  // Handle error state if needed
                },
              );
            },
          ),
        ],
      ),
      body: recommendationsState.when(
        data: (recommendations) {
          log("Log screen result: $recommendations");
          return ListView.builder(
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final recommendation = recommendations[index];
              return ListTile(
                leading: GestureDetector(
                  onTap: () =>
                      _showArtworkOverlay(context, recommendation.artworkUrl),
                  // child: Image.network(
                  //   recommendation.artworkUrl,
                  //   width: 50,
                  //   height: 50,
                  // ),
                  child: CachedNetworkImage(
                    height: 40,
                    width: 40,
                    imageUrl: recommendation.artworkUrl,
                    placeholder: (context, url) {
                      return Container(
                          alignment: Alignment.center,
                          child: const CupertinoActivityIndicator());
                    },
                  ),
                ),
                title: Text(recommendation.name),
                subtitle: Text(recommendation.artists.join(', ')),
                trailing:
                    recommendation.explicit ? const Icon(Icons.explicit) : null,
                onTap: () => _togglePlay(recommendation),
              );
            },
          );
        },
        loading: () => const Center(
          child: CupertinoActivityIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
