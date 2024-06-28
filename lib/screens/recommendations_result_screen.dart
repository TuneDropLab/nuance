import 'dart:developer';
import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/providers/recommendation_provider.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/providers/playlist_provider.dart';
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

  bool _isButtonVisible = false;

  void _toggleButtonVisibility() {
    setState(() {
      _isButtonVisible = !_isButtonVisible;
    });
  }

  void _togglePlay(SongModel song) async {
    if (song.previewUrl?.isEmpty ?? true) {
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
      await _audioPlayer.play(UrlSource(song.previewUrl ?? ""));
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
          child: CupertinoPageScaffold(
            backgroundColor: Colors.black54,
            child: Center(
                child: CachedNetworkImage(
              imageUrl: artworkUrl,
              errorWidget: (context, url, error) {
                return Container(
                  alignment: Alignment.center,
                  child: const Icon(Icons.error),
                );
              },
              placeholder: (context, url) {
                return Container(
                  alignment: Alignment.center,
                  child: const CupertinoActivityIndicator(),
                );
              },
            )),
          ),
        );
      },
    );
  }

  void _showPlaylists(
      BuildContext context, WidgetRef ref, List<SongModel> recommendations) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      useSafeArea: true,
      showDragHandle: true,
      useRootNavigator: true,
      routeSettings: const RouteSettings(name: '/playlists'),
      context: context,
      isScrollControlled: true,
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 400),
      ),
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
                color: Colors.white,
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
                    final addTracksState = ref.watch(addTracksProvider);
                    final trackIds =
                        recommendations.map((song) => song.trackUri).toList();

                    return playlistsState.when(
                      data: (playlists) {
                        return Stack(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              itemCount: playlists.length,
                              itemBuilder: (context, index) {
                                final playlist = playlists[index];
                                final isCurrentLoading =
                                    _loadingPlaylistId == playlist.id;
                                final params = AddTracksParams(
                                  accessToken: sessionState!.value!.accessToken,
                                  playlistId: playlist.id ?? "",
                                  trackIds: trackIds.map((e) => e!).toList(),
                                );

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
                                      imageUrl: playlist.imageUrl ?? "",
                                      placeholder: (context, url) {
                                        return Container(
                                            alignment: Alignment.center,
                                            child:
                                                const CupertinoActivityIndicator());
                                      },
                                      errorWidget: (context, url, error) {
                                        return Container(
                                          alignment: Alignment.center,
                                          child: const Icon(Icons.error),
                                        );
                                      }),
                                  title: Text(playlist.name ?? ""),
                                  subtitle: Text(
                                      "${playlist.totalTracks} ${(playlist.totalTracks ?? 0) >= 2 ? "songs" : "song"} "),
                                  // enabled: !isCurrentLoading &&
                                  //     addTracksState.maybeWhen(
                                  //       loading: () => false,
                                  //       orElse: () => true,
                                  //     ),
                                  onTap: () {
                                    if (sessionState?.value?.accessToken !=
                                        null) {
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
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Successfully added tracks to ${playlist.name} playlist.')),
                                        );

                                        // Navigator.pop(context); // Navigate back to home screen
                                      }).catchError(
                                        (error) {
                                          setState(() {
                                            _loadingPlaylistId = null;
                                          });
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Failed to add tracks to playlist.'),
                                            ),
                                          );
                                        },
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
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
                            ),
                            Positioned(
                              bottom: 30.0,
                              right: Get.width / 2 - 26.0,
                              child: FloatingActionButton(
                                elevation: 0,
                                backgroundColor: AppTheme.primaryColor,
                                // color: AppTheme.textColor,
                                onPressed: () {
                                  // Get.back();
                                  // delay 1 second
                                  // Get.offAllNamed(Routes.HOME);
                                  _showCreatePlaylistForm(context, ref,
                                      trackIds.map((e) => e!).toList());
                                },
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
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

  void _showCreatePlaylistForm(
      BuildContext context, WidgetRef ref, List<String> trackIds) {
    final nameController = TextEditingController(text: "$searchTerm");
    final descriptionController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      backgroundColor: Colors.white,
      useSafeArea: true,
      showDragHandle: true,
      useRootNavigator: true,
      routeSettings: const RouteSettings(name: '/add_playlists'),
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              decoration: const BoxDecoration(
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
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      "Create New Playlist",
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    // width: 200,
                    child: AnimatedTextField(
                      onTapOutside: (event) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      controller: nameController,
                      decoration: const InputDecoration(
                        filled: true,
                        contentPadding: EdgeInsets.all(12),
                      ),
                      hintTextStyle: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 14,
                      ),
                      hintTexts: const [
                        'Enter playlist name',
                      ],
                      onSubmitted: (value) {
                        // submit();
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedTextField(
                    onTapOutside: (event) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      filled: true,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    hintTextStyle: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 14,
                    ),
                    hintTexts: const [
                      'Enter playlist descripion',
                    ],
                    onSubmitted: (value) {
                      // submit();
                    },
                  ),
                  const Spacer(),
                  FloatingActionButton(
                    backgroundColor: AppTheme.primaryColor,
                    elevation: 0,
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              isLoading = true;
                            });
                            final name = nameController.text.trim();
                            final description =
                                descriptionController.text.trim();
                            if (name.isNotEmpty) {
                              final Map<String, String> data = {
                                'name': name,
                                'description': description,
                              };
                              ref
                                  .read(createPlaylistProvider(data).future)
                                  .then((newPlaylist) {
                                final isCurrentLoading =
                                    _loadingPlaylistId == newPlaylist.id;
                                // add to playlist
                                log("BEFORE ABOUT TO ADD TO AN EXISTING PLAYLIST");
                                if (sessionState?.value?.accessToken != null) {
                                  setState(() {
                                    _loadingPlaylistId = newPlaylist.id;
                                  });
                                  log("LOG PLAYLIST DETAILS: ${newPlaylist.id}");
                                  // setState(() {
                                  //   // _loadingPlaylistId = playlist.id;
                                  // });
                                  log("ABOUT TO ADD TO AN EXISTING PLAYLIST accessToken NOT NULL");

                                  final params = AddTracksParams(
                                    accessToken:
                                        sessionState!.value!.accessToken,
                                    playlistId: newPlaylist.id ?? "",
                                    trackIds: trackIds,
                                  );

                                  ref
                                      .read(addTracksProvider.notifier)
                                      .addTracksToPlaylist(params);

                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Successfully created ${newPlaylist.name} playlist.',
                                      ),
                                    ),
                                  );

                                  setState(() {
                                    isLoading = false;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('No access token found.')),
                                  );
                                }
                                // Navigator.pop(context); // Close the modal
                                // ScaffoldMessenger.of(context).showSnackBar(
                                //   const SnackBar(
                                //     content: Text('Playlist created successfully'),
                                //   ),
                                // );
                              }).catchError((error) {
                                setState(() {
                                  isLoading = false;
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Failed to create playlist: $error'),
                                  ),
                                );
                              });
                            } else {
                              setState(() {
                                isLoading = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please provide a name for the playlist'),
                                ),
                              );
                            }
                          },
                    child: isLoading
                        ? const CupertinoActivityIndicator(
                            color: Colors.white,
                          )
                        : const Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                  ).marginSymmetric(
                    // horizontal: 16,
                    vertical: 30,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String formatMilliseconds(int milliseconds) {
    Duration duration = Duration(milliseconds: milliseconds);

    int days = duration.inDays;
    int hours = duration.inHours % 24;
    int minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    if (searchTerm == null) {
      return const Scaffold(
        body: Center(child: Text('No search term found')),
      );
    }
    final sessionData = ref.read(sessionProvider.notifier);

    final recommendationsState =
        ref.watch(recommendationsProvider(searchTerm!));

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: SizedBox(
            // width: 50,
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 10.0,
              child: Image.asset(
                "assets/backbtn.png",
                height: 40.0,
                width: 40.0,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
        // leadingWidth: 30,
        backgroundColor: Colors.black,
        title: recommendationsState.when(
          data: (recommendations) {
            log("Log screen result: $recommendations");

            // Calculate total duration, number of songs, and unique artists
            int totalDuration = 0;
            int numberOfSongs = recommendations.length;
            Set<String> uniqueArtists = {};

            for (var song in recommendations) {
              if (song.durationMs != null) {
                totalDuration += song.durationMs!;
              }
              if (song.artist != null) {
                uniqueArtists.addAll(
                    song.artist!.split(',').map((artist) => artist.trim()));
              }
            }

            // String formattedDuration = _formatDuration(totalDuration);
            int numberOfArtists = uniqueArtists.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capitalizeFirst(searchTerm ?? ""),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                ),
                Text(
                  '$numberOfArtists artists • $numberOfSongs songs • ${formatMilliseconds(totalDuration)}',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.8,
                        color: Colors.grey.shade500,
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
        ),
        automaticallyImplyLeading: false,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: sessionState!.when(
              data: (data) {
                if (data == null) {
                  return CupertinoButton(
                    child: const CircleAvatar(
                      radius: 40,
                    ),
                    onPressed: () {
                      sessionData.logout();
                    },
                  );
                }

                return CupertinoButton(
                  padding: const EdgeInsets.all(0),
                  onPressed: () {
                    sessionData.logout();
                  },
                  child: CachedNetworkImage(
                    imageBuilder: (context, imageProvider) => Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: imageProvider,
                        ),
                      ),
                    ),
                    fit: BoxFit.fill,
                    height: 150,
                    imageUrl: data.user["user_metadata"]["avatar_url"] ?? "",
                    placeholder: (context, url) => const Center(
                      child: CupertinoActivityIndicator(
                          // color: AppTheme.textColor,
                          ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black12,
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CupertinoActivityIndicator(
                  color: AppTheme.textColor,
                ),
              ),
              error: (error, stack) => const CircleAvatar(
                radius: 30,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: recommendationsState.when(
          data: (recommendations) {
            log("Log screen result: $recommendations");
            return ListView.builder(
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final recommendation = recommendations[index];
                return ListTile(
                  leading: GestureDetector(
                    onTap: () => _showArtworkOverlay(
                        context, recommendation.artworkUrl ?? ""),
                    // child: Image.network(
                    //   recommendation.artworkUrl,
                    //   width: 50,
                    //   height: 50,
                    // ),
                    child: CachedNetworkImage(
                      height: 50,
                      width: 50,
                      imageUrl: recommendation.artworkUrl ?? "",
                      placeholder: (context, url) {
                        return Container(
                            alignment: Alignment.center,
                            child: const CupertinoActivityIndicator());
                      },
                    ),
                  ),
                  title: Text(recommendation.title ?? ""),
                  subtitle: Text(recommendation.artist ?? ""),
                  trailing: (recommendation.explicit ?? false)
                      ? const Icon(Icons.explicit)
                      : null,
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
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
