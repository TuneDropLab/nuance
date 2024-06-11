import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/providers/recommendation_provider.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/providers/playlist_provider.dart';
import 'package:nuance/models/playlist_model.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/providers/add_tracks_provider.dart';
import 'package:nuance/theme.dart';

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
        const SnackBar(
            content: Text('Use spotify Premium to preview this song')),
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

  void _showPlaylists(
      BuildContext context, WidgetRef ref, List<SongModel> recommendations) {
    showModalBottomSheet(
      useSafeArea: true,
      showDragHandle: true,
      useRootNavigator: true,
      routeSettings: const RouteSettings(name: '/playlists'),
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          // height: MediaQuery.of(context).size.height * 0.93,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                alignment: Alignment.bottomLeft,
                color: Colors.grey.withOpacity(0.011),
                padding: const EdgeInsets.only(
                  top: 25,
                  bottom: 20,
                  left: 15,
                  right: 15,
                ),
                child: const Text(
                  "Add to your Music Library",
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
              ),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final playlistsState = ref.watch(playlistProvider);

                    return playlistsState.when(
                      data: (playlists) {
                        return Stack(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              itemCount: playlists.length,
                              itemBuilder: (context, index) {
                                final playlist = playlists[index];

                                return ListTile(
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
                                  onTap: () {
                                    if (sessionState?.value?.accessToken !=
                                        null) {
                                      final trackIds = recommendations
                                          .map((song) => song.trackUri)
                                          .toList();

                                      final params = AddTracksParams(
                                        accessToken:
                                            sessionState!.value!.accessToken,
                                        playlistId: playlist.id,
                                        trackIds: trackIds,
                                      );

                                      ref
                                          .read(addTracksProvider.notifier)
                                          .addTracksToPlaylist(params)
                                          .then((_) {
                                        Navigator.pop(context); // Close modal
                                      }).catchError((error) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Failed to add tracks to playlist.')),
                                        );
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('No access token found.')),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                            Positioned(
                              bottom: 30.0,
                              right: Get.width / 2 - 16.0,
                              child: FloatingActionButton(
                                elevation: 0,
                                backgroundColor: AppTheme.primaryColor,
                                // color: AppTheme.textColor,
                                onPressed: () {
                                  _showCreatePlaylistForm(context, ref);
                                },
                                child: const Icon(Icons.add),
                              ),
                            ),
                          ],
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

  void _showCreatePlaylistForm(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Create New Playlist",
                style: TextStyle(color: AppTheme.textColor, fontSize: 16),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Playlist Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final description = descriptionController.text.trim();
                  if (name.isNotEmpty) {
                    final data = {
                      'name': name,
                      'description': description,
                    };
                    ref
                        .read(createPlaylistProvider(data).future)
                        .then((newPlaylist) {
                      Navigator.pop(context); // Close the modal
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Playlist created successfully'),
                        ),
                      );
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to create playlist: $error'),
                        ),
                      );
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please provide a name for the playlist'),
                      ),
                    );
                  }
                },
                child: const Text('Create'),
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
        centerTitle: false,
        title: Text(
          searchTerm ?? '',
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.playlist_play,
            ),
            onPressed: () {
              recommendationsState.when(
                data: (recommendations) {
                  _showPlaylists(context, ref, recommendations);
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
