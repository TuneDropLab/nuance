import 'dart:convert';
import 'dart:developer';
import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:get/get.dart';
import 'package:nuance/main.dart';
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/providers/history_provider.dart';
import 'package:nuance/providers/recommendation_provider.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/providers/playlist_provider.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/providers/add_tracks_provider.dart';
import 'package:nuance/screens/home_screen.dart';
import 'package:nuance/services/recomedation_service.dart';
import 'package:nuance/theme.dart';
import 'package:nuance/utils/constants.dart';
import 'package:nuance/widgets/custom_divider.dart';
import 'package:nuance/widgets/custom_snackbar.dart';
import 'package:nuance/widgets/general_button.dart';
import 'package:nuance/widgets/loader.dart';
import 'package:nuance/widgets/music_listtile.dart';
import 'package:shimmer/shimmer.dart';

class RecommendationsResultScreen extends ConsumerStatefulWidget {
  static const routeName = '/recommendations-result';
  final String? tagQuery;
  final String? searchQuery;
  final String? searchTitle;
  final String? playlistId;
  final AsyncValue<SessionData?>? sessionState;
  final List<SongModel>? songs;

  const RecommendationsResultScreen({
    super.key,
    this.searchQuery,
    this.tagQuery,
    this.searchTitle,
    this.playlistId,
    this.sessionState,
    this.songs,
  });

  @override
  ConsumerState<RecommendationsResultScreen> createState() =>
      _RecommendationsResultScreenState();
}

class _RecommendationsResultScreenState
    extends ConsumerState<RecommendationsResultScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  SongModel? _currentSong;
  String? _loadingPlaylistId;

  bool isLoading = true;
  List<String> errorList = [];
  List<SongModel>? recommendations = [];
  String? generatedImage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.invalidate(playlistProvider);
    _fetchRecommendationsOrPlaylistTracks();

    // Listen to audio player state changes
    _audioPlayer.onPlayerStateChanged.listen((playerState) {
      if (playerState == PlayerState.playing) {
        setState(() {
          _isPlaying = true;
        });
      } else {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  void _togglePlay(SongModel song) async {
    if (song.previewUrl?.isEmpty ?? true) {
      CustomSnackbar().show("Can't play this song right now");
      return;
    }

    if (_isPlaying && _currentSong?.id == song.id) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
        _currentSong = null;
      });
    } else {
      await _audioPlayer.play(UrlSource(song.previewUrl ?? ""));
      setState(() {
        _isPlaying = true;
        _currentSong = song;
      });
    }
  }

  Future<void> _fetchRecommendationsOrPlaylistTracks() async {
    final sessionStateFromProvider = ref.read(sessionProvider);
    setState(() {
      isLoading = true;
      errorList = [];
    });

    try {
      final service = RecommendationsService();
      final accessToken = widget.sessionState?.value?.accessToken ??
          sessionStateFromProvider.value?.providerToken ??
          "";
      final providerToken = widget.sessionState?.value?.providerToken ??
          sessionStateFromProvider.value?.providerToken ??
          "";

      generatedImage = await RecommendationsService().getGeneratedImage(
          accessToken,
          widget.searchTitle ?? widget.searchQuery ?? widget.tagQuery ?? "");

      log("CACHED GENERATED IMAGE generatedImage: $generatedImage");

      final result = widget.searchQuery != null || widget.tagQuery != null
          ? await service.getRecommendations(
              accessToken, widget.searchQuery ?? widget.tagQuery ?? "")
          : widget.playlistId != null
              ? await service.fetchPlaylistTracks(
                  accessToken, providerToken, widget.playlistId ?? "")
              : null;
      if (mounted) {
        setState(() {
          recommendations = result;
          isLoading = false;
        });
      }
    } catch (e) {
      log("Error: ${e.toString()}");
      if (mounted) {
        setState(() {
          errorList.add(e.toString());
          isLoading = false;
        });
      }
    }
  }

  void _followPlaylist(String playlistId) async {
    setState(() {
      isLoading = true;
      errorList = [];
    });
    log("Follow Playlist PLAYLISTID: $playlistId");
    try {
      final service = RecommendationsService();
      final accessToken = widget.sessionState?.value?.accessToken ??
          ref.read(sessionProvider).value?.providerToken ??
          "";

      await service.followSpotifyPlaylist(accessToken, playlistId);

      if (mounted) {
        setState(() {
          // recommendations = result;
          isLoading = false;
        });
      }
      // CustomSnackbar().show("Playlist followed successfully");
    } catch (e) {
      log("Error: ${e.toString()}");
      CustomSnackbar().show("Error: ${e.toString()}");
      if (mounted) {
        setState(() {
          errorList.add(e.toString());
          isLoading = false;
        });
      }
    }
  }

  bool _isGeneratingMore = false;

  Future<void> _generateMore() async {
    if (_isGeneratingMore) return;

    setState(() {
      _isGeneratingMore = true;
    });

    try {
      final service = RecommendationsService();
      final sessionStateFromProvider = ref.read(sessionProvider);
      final accessToken = widget.sessionState?.value?.accessToken ??
          sessionStateFromProvider.value?.providerToken ??
          "";
      final providerToken = widget.sessionState?.value?.providerToken ??
          sessionStateFromProvider.value?.providerToken ??
          "";

      List<SongModel>? newRecommendations;

      if (widget.searchQuery != null || widget.tagQuery != null) {
        newRecommendations = await service.getMoreRecommendations(
          accessToken,
          widget.searchQuery ?? widget.tagQuery ?? "",
          recommendations ?? [],
        );
      } else if (widget.playlistId != null) {
        newRecommendations = await service.fetchPlaylistTracks(
          accessToken,
          providerToken,
          widget.playlistId ?? "",
        );
      }

      if (mounted && newRecommendations != null) {
        setState(() {
          recommendations = [...?recommendations, ...?newRecommendations];
          _isGeneratingMore = false;
        });
      }
    } catch (e) {
      log("Error generating more: ${e.toString()}");
      if (mounted) {
        setState(() {
          errorList.add(e.toString());
          _isGeneratingMore = false;
        });
        CustomSnackbar().show("Failed to generate more recommendations");
      }
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

  final Set<String> _selectedItems = {};
  bool _isSelectionMode = false;

  void _toggleSelection(String songId) {
    setState(() {
      if (_selectedItems.contains(songId)) {
        _selectedItems.remove(songId);
      } else {
        _selectedItems.add(songId);
      }
      _isSelectionMode = _selectedItems.isNotEmpty;
    });
  }

  void _deleteSelected() {
    setState(() {
      recommendations?.removeWhere((song) => _selectedItems.contains(song.id));
      _selectedItems.clear();
      _isSelectionMode = false;
    });
  }

  void _showPlaylists(
      BuildContext context, WidgetRef ref, List<SongModel> recommendations) {
    showModalBottomSheet(
      backgroundColor: const Color.fromARGB(255, 22, 22, 22),
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
          decoration: const BoxDecoration(
            color: Colors.transparent,
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
                color: Colors.transparent,
                padding: const EdgeInsets.only(
                  top: 25,
                  bottom: 20,
                  left: 15,
                  right: 15,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Add to your Library",
                      style: headingTextStyle.copyWith(
                        wordSpacing: 0.1,
                        letterSpacing: 0.11,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      "Select an exisiting playlist",
                      style: subtitleTextStyle.copyWith(
                        wordSpacing: 0.1,
                        letterSpacing: 0.11,
                        // fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final playlistsState = ref.watch(playlistProvider);
                    // final addTracksState = ref.watch(addTracksProvider);
                    final trackIds = recommendations
                        .map((song) => song.trackUri ?? "")
                        .toList();

                    final sessionStateFromProvider = ref.read(sessionProvider);

                    return playlistsState.when(
                      data: (playlists) {
                        return Stack(
                          children: [
                            ListView.builder(
                              padding: const EdgeInsets.only(bottom: 150),
                              shrinkWrap: true,
                              itemCount: playlists.length,
                              itemBuilder: (context, index) {
                                final playlist = playlists[index];
                                final isCurrentLoading =
                                    _loadingPlaylistId == playlist.id;
                                final params = AddTracksParams(
                                  accessToken:
                                      widget.sessionState?.value!.accessToken ??
                                          sessionStateFromProvider
                                              .value?.accessToken ??
                                          "",
                                  searchQuery: widget.searchQuery ??
                                      widget.tagQuery ??
                                      widget.searchTitle ??
                                      "",
                                  playlistId: playlist.id ?? "",
                                  trackIds: trackIds.map((e) => e).toList(),
                                );

                                return ListTile(
                                  leading: CachedNetworkImage(
                                      height: 40,
                                      width: 40,
                                      imageUrl: playlist.imageUrl ?? "",
                                      imageBuilder: (context, imageProvider) {
                                        return Container(
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            image: DecorationImage(
                                              image: imageProvider,
                                            ),
                                          ),
                                        );
                                      },
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
                                  title: Text(
                                    playlist.name ?? "",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    "${playlist.totalTracks} ${(playlist.totalTracks ?? 0) >= 2 ? "songs" : "song"} ",
                                    style: subtitleTextStyle,
                                  ),
                                  onTap: () {
                                    if (widget.sessionState?.value
                                                ?.accessToken !=
                                            null ||
                                        sessionStateFromProvider
                                                .value!.accessToken !=
                                            '') {
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
                                        // Navigator.pop(context); // Close modal
                                        Get.back();
                                        // ScaffoldMessenger.of(context)
                                        //     .showSnackBar(
                                        //   SnackBar(
                                        //       content: Text(
                                        //           'Successfully added tracks to ${playlist.name} playlist.')),
                                        // );
                                        CustomSnackbar().show(
                                            "Successfully added tracks to ${playlist.name} playlist.");

                                        // Navigator.pop(context); // Navigate back to home screen
                                      }).catchError(
                                        (error) {
                                          setState(() {
                                            _loadingPlaylistId = null;
                                          });
                                          CustomSnackbar().show(
                                            "Failed to add tracks to playlist",
                                          );
                                        },
                                      );
                                    } else {
                                      CustomSnackbar().show(
                                        "No access token found.",
                                      );
                                    }
                                  },
                                  trailing: isCurrentLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CupertinoActivityIndicator(
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                );
                              },
                            ),
                            Positioned(
                              bottom: 30.0,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                width: Get.width,
                                child: GeneralButton(
                                  text: "New Playlist",
                                  backgroundColor: const Color(0xffD9D9D9),
                                  hasPadding: true,
                                  icon: Icon(
                                    Icons.playlist_add_check_rounded,
                                    color: Colors.grey.shade800,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    widget.songs == null
                                        ? _showCreatePlaylistForm(
                                            context,
                                            ref,
                                            trackIds,
                                          )
                                        : _showCreatePlaylistForm(
                                            context,
                                            ref,
                                            (widget.songs ?? [])
                                                .map((song) =>
                                                    song.trackUri ?? "")
                                                .toList(),
                                          );
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => Center(
                        child: SpinningSvg(
                          svgWidget: Image.asset(
                            'assets/hdlogo.png',
                            height: 40,
                          ),
                          // size: 10.0,
                          textList: const [
                            'Getting your playlists...',
                            'Just a moment...',
                            'Almost done...',
                          ],
                        ),
                      ),
                      error: (error, stack) => const Center(
                        child: Text(
                          'Error loading playlist',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
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
    final nameController = TextEditingController(
        text: "${widget.searchQuery ?? widget.tagQuery ?? widget.searchTitle}");
    final descriptionController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      backgroundColor: const Color.fromARGB(255, 22, 22, 22),
      useSafeArea: true,
      showDragHandle: true,
      useRootNavigator: true,
      routeSettings: const RouteSettings(name: '/add_playlists'),
      context: context,
      isDismissible: !isLoading,
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
              child: isLoading
                  ? Center(
                      child: SpinningSvg(
                        svgWidget: Image.asset(
                          'assets/hdlogo.png',
                          height: 40,
                        ),
                        textList: [
                          widget.searchQuery != null
                              ? 'Adding playlist songs...'
                              : widget.tagQuery != null
                                  ? 'Generating playlist songs...'
                                  : widget.searchTitle != null
                                      ? 'Getting playlist songs...'
                                      : 'Loading playlist songs...',
                          'Just a moment...',
                          'Getting playlist songs...',
                          'Almost done...',
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Create New Playlist",
                            style: headingTextStyle.copyWith(
                              wordSpacing: 0.1,
                              letterSpacing: 0.11,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          child: AnimatedTextField(
                            animationDuration: 4000.ms,
                            onTapOutside: (event) {
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                            controller: nameController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Color.fromARGB(98, 34, 34, 34),
                              filled: true,
                              contentPadding: EdgeInsets.all(12),
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            hintTextStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            hintTexts: const ['Enter playlist name'],
                            onSubmitted: (value) {},
                          ),
                        ),
                        const SizedBox(height: 20),
                        AnimatedTextField(
                          onTapOutside: (event) {
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                              borderSide: BorderSide.none,
                            ),
                            fillColor: Color.fromARGB(98, 34, 34, 34),
                            filled: true,
                            contentPadding: EdgeInsets.all(12),
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          hintTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          hintTexts: const ['Description'],
                          onSubmitted: (value) {},
                        ),
                        const Spacer(),
                        Container(
                          width: Get.width,
                          margin: const EdgeInsets.only(bottom: 30),
                          child: GeneralButton(
                            text: "Add to Library",
                            backgroundColor: const Color(0xffD9D9D9),
                            hasPadding: true,
                            icon: Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.grey.shade800,
                            ),
                            onPressed: () {
                              setState(() {
                                isLoading = true;
                              });
                              final name = nameController.text.trim();
                              final description =
                                  descriptionController.text.trim();
                              if (name.isNotEmpty) {
                                final Map<String, String> data = {
                                  'name': name,
                                  'description': description.isEmpty
                                      ? "Powered by Nuance"
                                      : description,
                                    'image': generatedImage ?? "",
                                };
                                ref
                                    .read(createPlaylistProvider(data).future)
                                    .then((newPlaylist) {
                                  if (widget.sessionState?.value?.accessToken !=
                                      null) {
                                    setState(() {
                                      _loadingPlaylistId = newPlaylist.id;
                                    });
                                    final params = AddTracksParams(
                                      accessToken: widget
                                          .sessionState!.value!.accessToken,
                                      searchQuery: widget.searchQuery ??
                                          widget.tagQuery ??
                                          widget.searchTitle ??
                                          "",
                                      playlistId: newPlaylist.id ?? "",
                                      trackIds: trackIds,
                                    );
                                    ref
                                        .read(addTracksProvider.notifier)
                                        .addTracksToPlaylist(params);
                                    Get.back();
                                    Get.back();
                                    CustomSnackbar().show(
                                      'Successfully created ${newPlaylist.name} playlist.',
                                    );
                                    setState(() {
                                      isLoading = false;
                                    });
                                  } else {
                                    CustomSnackbar().show(
                                      "No access token found.",
                                    );
                                  }
                                }).catchError((error) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  CustomSnackbar().show(
                                    "Failed to create playlist: $error",
                                  );
                                });
                              } else {
                                setState(() {
                                  isLoading = false;
                                });
                                CustomSnackbar().show(
                                  'Please provide a name for the playlist',
                                );
                              }
                            },
                          ),
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
      return '${days}d  ${hours}h  ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h  ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  int? currentlyPlayingSongId;
  int getTotalDuration(List<SongModel> songs) {
    return songs.fold(0, (sum, song) => sum + (song.durationMs ?? 0));
  }

  int getUniqueArtistsCount(List<SongModel> songs) {
    Set<String> uniqueArtists = {};
    for (var song in songs) {
      if (song.artist != null) {
        uniqueArtists
            .addAll(song.artist!.split(',').map((artist) => artist.trim()));
      }
    }
    return uniqueArtists.length;
  }

  final bool _stretch = true;

  @override
  Widget build(BuildContext context) {
    final sessionData = ref.read(sessionProvider.notifier);
    final sessionState = ref.watch(sessionProvider);
    if (widget.sessionState == null && sessionState.value == null) {
      // return;
      // const Scaffold(
      //   body: Center(
      //     child: Text('No search term found'),
      //   ),
      // );
    }
    ref.invalidate(playlistProvider);
    int totalDuration = getTotalDuration(recommendations ?? widget.songs ?? []);
    int uniqueArtistsCount =
        getUniqueArtistsCount(recommendations ?? widget.songs ?? []);

    // final GlobalKey<ScaffoldState> globalKey = GlobalKey();

    return Scaffold(
      // key: globalKey,
//       appBar: AppBar(
//         leading: _isSelectionMode
//             ? IconButton(
//                 icon: const Icon(
//                   CupertinoIcons.xmark,
//                   color: Colors.white,
//                 ),
//                 onPressed: () {
//                   setState(() {
//                     _selectedItems.clear();
//                     _isSelectionMode = false;
//                   });
//                 },
//               )
//             : GestureDetector(
//                 onTap: () {
//                   Get.back();
//                 },
//                 child: CircleAvatar(
//                   backgroundColor: Colors.transparent,
//                   radius: 10.0,
//                   child: Image.asset(
//                     "assets/backbtn.png",
//                     height: 40.0,
//                     width: 40.0,
//                     fit: BoxFit.fill,
//                   ),
//                 ),
//               ),
//         backgroundColor: Colors.black,
//         title: _isSelectionMode
//             ? Text(
//                 "${_selectedItems.length} selected",
//                 style: headingTextStyle,
//               )
//             : Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Tooltip(
//                     message: widget.searchQuery ??
//                         widget.tagQuery ??
//                         widget.searchTitle ??
//                         "",
//                     child: Text(
//                       capitalizeFirst(widget.searchQuery ??
//                           widget.tagQuery ??
//                           widget.searchTitle ??
//                           ""),
//                       style: headingTextStyle,
//                     ),
//                   ),
//                   isLoading
//                       ? const SizedBox.shrink()
//                       : errorList.isNotEmpty
//                           ? Text(
//                               'Error  loading  details',
//                               style: subtitleTextStyle,
//                             )
//                           : Text(
//                               '$uniqueArtistsCount  artists • ${recommendations?.length ?? widget.songs?.length ?? 0}  songs • ${formatMilliseconds(totalDuration)}',
//                               style: subtitleTextStyle,
//                             ),
//                 ],
//               ),
//         actions: [
//           if (_isSelectionMode)
//             IconButton(
//               icon: const Icon(
//                 CupertinoIcons.delete,
//                 size: 18,
//                 color: Colors.white,
//               ),
//               onPressed: _deleteSelected,
//             )
//           else
//             IconButton(
//               icon: const Icon(
//                 CupertinoIcons.delete,
//                 size: 18,
//               ),
//               onPressed: () {
//                 setState(() {
//                   _isSelectionMode = true;
//                 });
//               },
//             ),
// //TODO: REMOVE AND USE IMAGE AS PARALLAX BG FOR APPBAR TESTING IMAGE
//           CachedNetworkImage(
//             imageUrl: generatedImage ?? "",
//             height: 50,
//             width: 50,
//           )
//           // newMethod(ref.read(sessionProvider)),
//         ],
//       ),
      bottomNavigationBar: Container(
        color: Colors.black,
        height: widget.tagQuery != null ? 140 : 80,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (widget.tagQuery != null)
                if (!isLoading && sessionState.value?.accessToken != null)
                  Animate(
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Get.back();
                          },
                          icon: SvgPicture.asset(
                            "assets/x.svg",
                          ),
                        ),
                        GeneralButton(
                          text: widget.searchQuery ?? widget.tagQuery ?? "",
                          backgroundColor: Colors.white,
                          icon: SvgPicture.asset(
                            "assets/icon4star.svg",
                            color: const Color(0xffFFBB00),
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
              if (widget.tagQuery != null)
                if (!isLoading && sessionState.value?.accessToken != null)
                  const CustomDivider().marginOnly(bottom: 5),
              if (!isLoading && sessionState.value?.accessToken != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      // if (!isLoading)
                      Expanded(
                        child: GeneralButton(
                          hasPadding: true,
                          backgroundColor: isLoading
                              ? const Color.fromARGB(255, 166, 166, 166)
                              : const Color(0xffD9D9D9),
                          text: "Share",
                          color: isLoading
                              ? const Color.fromARGB(255, 112, 112, 112)
                              : Colors.black,
                          icon: SvgPicture.asset(
                            "assets/sendto.svg",
                            color: isLoading
                                ? const Color.fromARGB(
                                    255,
                                    112,
                                    112,
                                    112,
                                  )
                                : Colors.black,
                          ),
                          // backgroundColor: const Color(0xffD9D9D9),
                          onPressed: () {
                            // print(
                            //     "Share details: ${widget.searchQuery}");
                            // print(
                            //     "Share details: ${widget.songs ?? recommendations}");
                            isLoading
                                ? null
                                : RecommendationsService().shareRecommendation(
                                    context,
                                    widget.searchQuery ??
                                        widget.tagQuery ??
                                        widget.searchTitle ??
                                        "",
                                    recommendations ?? widget.songs ?? []);
                          },
                        ),
                      ),
                      // if (!isLoading)
                      const SizedBox(
                        width: 5,
                      ),
                      // if (!isLoading)
                      Expanded(
                        child: GeneralButton(
                          backgroundColor: const Color(0xffFDAD3C),
                          hasPadding: true,
                          color: Colors.black,
                          icon: SvgPicture.asset(
                            "assets/bookmark.svg",
                            color: isLoading
                                ? const Color.fromARGB(
                                    255,
                                    112,
                                    112,
                                    112,
                                  )
                                : Colors.black,
                          ),
                          onPressed: () {
                            isLoading
                                ? null
                                // : recommendations?.isEmpty ?? true
                                //     ? null
                                : widget.playlistId != null
                                    ? _followPlaylist(widget.playlistId!)
                                    : _showPlaylists(
                                        context,
                                        ref,
                                        widget.songs ?? recommendations ?? [],
                                      );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              if (sessionState.value?.accessToken == null)
                Container(
                  width: Get.width,
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  child: CupertinoButton.filled(
                    pressedOpacity: 0.3,
                    onPressed: () {
                      _authenticate();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icon4star.svg',
                          width: 10,
                          height: 10,
                        ),
                        const SizedBox(width: 8),
                        const Text('Sign in with Spotify'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),

      body: Container(
        color: Colors.black,
        child: CustomScrollView(
          slivers: <Widget>[
            if (!isLoading)
              SliverAppBar(
                stretch: true,
                // snap: true,
                automaticallyImplyLeading: false,
                centerTitle: false,
                backgroundColor: Colors.black,
                leading: _isSelectionMode
                    ? IconButton(
                        icon: const Icon(
                          CupertinoIcons.xmark,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedItems.clear();
                            _isSelectionMode = false;
                          });
                        },
                      )
                    : GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
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
                actions: [
                  if (_isSelectionMode)
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.delete,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: _deleteSelected,
                    )
                  else
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.delete,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = true;
                        });
                      },
                    ),
                ],
                expandedHeight: 280.0,
                floating: true,
                pinned: true,
                flexibleSpace: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double shrinkOffset =
                        constraints.maxHeight - kToolbarHeight;
                    const double maxExtent =
                        280.0; // Should match expandedHeight
                    const double fadeStart = maxExtent - kToolbarHeight * 2;
                    const double fadeEnd = maxExtent - kToolbarHeight;

                    // Calculate the opacity of the title based on the shrinkOffset
                    // final double titleOpacity = 1.0 -
                    //     ((shrinkOffset - fadeStart) / (fadeStart - fadeEnd))
                    //         .clamp(0.0, 1.0);

                    // Calculate the shift value for title alignment
                    final double titleAlignmentShift = 60.0 -
                        (41.0 *
                            ((shrinkOffset - fadeStart) / (fadeEnd - fadeStart))
                                .clamp(0.0, 1.0));

                    // Calculate the opacity for the app bar background color
                    final double appBarOpacity =
                        1 - (shrinkOffset / maxExtent).clamp(-1.1, 1.0);

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: Colors.black.withOpacity(0.5),
                          child: CachedNetworkImage(
                            imageUrl: generatedImage ?? "",
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) {
                              return const SizedBox.shrink();
                            },
                            placeholder: (context, url) {
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        Container(
                          color: Colors.black.withOpacity(
                              appBarOpacity), // This ensures it becomes fully black.
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.5),
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0.0 +
                              ((shrinkOffset / maxExtent) * maxExtent)
                                  .clamp(0.0, maxExtent - 6),
                          left: titleAlignmentShift,
                          child: _isSelectionMode
                              ? Text(
                                  "${_selectedItems.length} selected",
                                  style: headingTextStyle,
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Tooltip(
                                      message: widget.searchQuery ??
                                          widget.tagQuery ??
                                          widget.searchTitle ??
                                          "",
                                      child: Text(
                                        capitalizeFirst(widget.searchQuery ??
                                            widget.tagQuery ??
                                            widget.searchTitle ??
                                            ""),
                                        style: headingTextStyle,
                                      ),
                                    ),
                                    isLoading
                                        ? const SizedBox.shrink()
                                        : errorList.isNotEmpty
                                            ? Text(
                                                'Error loading details',
                                                style:
                                                    subtitleTextStyle.copyWith(
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                '$uniqueArtistsCount artists • ${recommendations?.length ?? widget.songs?.length ?? 0} songs • ${formatMilliseconds(totalDuration)}',
                                                style:
                                                    subtitleTextStyle.copyWith(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                  ],
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            // appbar to show when loading is true
            if (isLoading)
              SliverAppBar(
                backgroundColor: Colors.black,
                centerTitle: false,
                leading: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
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
                title: Container(
                  // color: Colors.black,
                  // top: 0.0 +
                  //     ((shrinkOffset / maxExtent) * maxExtent)
                  //         .clamp(0.0, 280.0),
                  // left: titleAlignmentShift,
                  child: _isSelectionMode
                      ? Text(
                          "${_selectedItems.length} selected",
                          style: headingTextStyle,
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Tooltip(
                              message: widget.searchQuery ??
                                  widget.tagQuery ??
                                  widget.searchTitle ??
                                  "",
                              child: Text(
                                capitalizeFirst(widget.searchQuery ??
                                    widget.tagQuery ??
                                    widget.searchTitle ??
                                    ""),
                                style: headingTextStyle,
                              ),
                            ),
                            isLoading
                                ? const SizedBox.shrink()
                                : errorList.isNotEmpty
                                    ? Text(
                                        'Error loading details',
                                        style: subtitleTextStyle,
                                      )
                                    : Text(
                                        '$uniqueArtistsCount artists • ${recommendations?.length ?? widget.songs?.length ?? 0} songs • ${formatMilliseconds(totalDuration)}',
                                        style: subtitleTextStyle,
                                      ),
                          ],
                        ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.only(
                top: 32,
                bottom: 100,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    if (isLoading) {
                      return Container(
                        height: Get.height * 0.75,
                        alignment: Alignment.bottomCenter,
                        child: SpinningSvg(
                          svgWidget: Image.asset(
                            'assets/hdlogo.png',
                            height: 40,
                          ),
                          textList: [
                            widget.searchQuery != null
                                ? 'Searching for songs...'
                                : widget.tagQuery != null
                                    ? 'Generating playlist songs...'
                                    : widget.searchTitle != null
                                        ? 'Getting playlist songs...'
                                        : 'Loading playlist songs...',
                            'Just a moment...',
                            'Getting playlist songs...',
                            'Almost done...',
                          ],
                        ),
                      );
                    }

                    if (errorList.isNotEmpty) {
                      return const Center(
                        child: Text(
                          'Error loading playlist songs',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      );
                    }

                    if (index ==
                        (recommendations?.length ?? widget.songs?.length)) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _isGeneratingMore
                            ? const SizedBox(
                                height: 50,
                                child: CupertinoActivityIndicator(
                                  color: Colors.white,
                                  radius: 10,
                                ),
                              )
                            : Center(
                                child: SizedBox(
                                  width: 190,
                                  child: GeneralButton(
                                    hasPadding: true,
                                    backgroundColor: const Color(0xffD9D9D9),
                                    text: "Generate More",
                                    color: Colors.black,
                                    onPressed: _generateMore,
                                  ),
                                ),
                              ),
                      );
                    }

                    final song =
                        recommendations?[index] ?? widget.songs![index];

                    return widget.playlistId != null ||
                            widget.searchQuery != null ||
                            widget.tagQuery != null
                        ? Animate(
                            effects: [
                              FadeEffect(
                                delay: Duration(
                                    milliseconds: (50 * (index % 5)).toInt()),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                begin: 0.0,
                                end: 1.0,
                              ),
                            ],
                            child: MusicListTile(
                              isPlaying:
                                  _isPlaying && _currentSong?.id == song.id,
                              trailingOnTap: () => _togglePlay(song),
                              recommendation: song,
                              onPlaybackStateChanged: (isPlaying) {
                                setState(() {
                                  _isPlaying = isPlaying;
                                });
                              },
                              isSelected: _selectedItems.contains(song.id),
                              onTap: () {
                                if (_isSelectionMode) {
                                  _toggleSelection(song.id ?? '');
                                } else {
                                  _togglePlay(song);
                                }
                              },
                              onDismissed: () {
                                setState(() {
                                  recommendations
                                      ?.removeWhere((s) => s.id == song.id);
                                });
                              },
                            ),
                          )
                        : MusicListTile(
                            isPlaying:
                                _isPlaying && _currentSong?.id == song.id,
                            trailingOnTap: () => _togglePlay(song),
                            recommendation: song,
                            onPlaybackStateChanged: (isPlaying) {
                              setState(() {
                                _isPlaying = isPlaying;
                              });
                            },
                            isSelected: _selectedItems.contains(song.id),
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleSelection(song.id ?? '');
                              } else {
                                _togglePlay(song);
                              }
                            },
                            onDismissed: () {
                              setState(() {
                                recommendations
                                    ?.removeWhere((s) => s.id == song.id);
                              });
                            },
                          );
                  },
                  childCount: isLoading
                      ? 1
                      : (recommendations?.length ?? widget.songs?.length ?? 0) +
                          1,
                ),
              ),
            ),

            // Scaffold(
            //   backgroundColor: Colors.black,
            //   body: Container(
            //     color: Colors.black,
            //     child: CustomScrollView(
            //       slivers: <Widget>[
            //         SliverAppBar(
            //           leading: _isSelectionMode
            //               ? IconButton(
            //                   icon: const Icon(
            //                     CupertinoIcons.xmark,
            //                     color: Colors.white,
            //                   ),
            //                   onPressed: () {
            //                     setState(() {
            //                       _selectedItems.clear();
            //                       _isSelectionMode = false;
            //                     });
            //                   },
            //                 )
            //               : GestureDetector(
            //                   onTap: () {
            //                     Navigator.of(context).pop();
            //                   },
            //                   child: CircleAvatar(
            //                     backgroundColor: Colors.transparent,
            //                     radius: 10.0,
            //                     child: Image.asset(
            //                       "assets/backbtn.png",
            //                       height: 40.0,
            //                       width: 40.0,
            //                       fit: BoxFit.fill,
            //                     ),
            //                   ),
            //                 ),
            //           backgroundColor: Colors.black,
            //           title: _isSelectionMode
            //               ? Text(
            //                   "${_selectedItems.length} selected",
            //                   style: headingTextStyle,
            //                 )
            //               : Column(
            //                   crossAxisAlignment: CrossAxisAlignment.start,
            //                   children: [
            //                     Tooltip(
            //                       message: widget.searchQuery ??
            //                           widget.tagQuery ??
            //                           widget.searchTitle ??
            //                           "",
            //                       child: Text(
            //                         capitalizeFirst(widget.searchQuery ??
            //                             widget.tagQuery ??
            //                             widget.searchTitle ??
            //                             ""),
            //                         style: headingTextStyle,
            //                       ),
            //                     ),
            //                     isLoading
            //                         ? const SizedBox.shrink()
            //                         : errorList.isNotEmpty
            //                             ? Text(
            //                                 'Error loading details',
            //                                 style: subtitleTextStyle,
            //                               )
            //                             : Text(
            //                                 '$uniqueArtistsCount  artists • ${recommendations?.length ?? widget.songs?.length ?? 0}  songs • ${formatMilliseconds(totalDuration)}',
            //                                 style: subtitleTextStyle,
            //                               ),
            //                   ],
            //                 ),
            //           actions: [
            //             if (_isSelectionMode)
            //               IconButton(
            //                 icon: const Icon(
            //                   CupertinoIcons.delete,
            //                   size: 18,
            //                   color: Colors.white,
            //                 ),
            //                 onPressed: _deleteSelected,
            //               )
            //             else
            //               IconButton(
            //                 icon: const Icon(
            //                   CupertinoIcons.delete,
            //                   size: 18,
            //                 ),
            //                 onPressed: () {
            //                   setState(() {
            //                     _isSelectionMode = true;
            //                   });
            //                 },
            //               ),
            //             CachedNetworkImage(
            //               imageUrl: generatedImage ?? "",
            //               height: 50,
            //               width: 50,
            //             ),
            //           ],
            //           expandedHeight: 150.0,
            //           floating: true,
            //           pinned: true,
            //           flexibleSpace: FlexibleSpaceBar(
            //             background: Container(
            //               color: Colors.black,
            //               child: Center(
            //                 child: CachedNetworkImage(
            //                   imageUrl: generatedImage ?? "",
            //                   fit: BoxFit.cover,
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),

            // SliverList(
            //   delegate: SliverChildBuilderDelegate(
            //     (BuildContext context, int index) {
            //       return Container(
            //         // color: index.isOdd ? Colors.white : Colors.black12,
            //         // height: 100.0,
            //         child: Center(
            //           child: Text('$index',
            //               textScaler: const TextScaler.linear(5.0)),
            //         ),
            //       );
            //     },
            //     childCount: 20,
            //   ),
            // ),

            // SliverList
            // Container(
            //   color: Colors.black,
            //   child: isLoading
            //       ? Center(
            //           child: SpinningSvg(
            //             svgWidget:
            //                 // SvgPicture.asset('assets/images/your_svg.svg'),
            //                 Image.asset(
            //               'assets/hdlogo.png',
            //               height: 40,
            //             ),
            //             // size: 10.0,
            //             textList: [
            //               widget.searchQuery != null
            //                   ? 'Searching for songs...'
            //                   : widget.tagQuery != null
            //                       ? 'Generating playlist songs...'
            //                       : widget.searchTitle != null
            //                           ? 'Getting playlist songs...'
            //                           : 'Loading playlist songs...',
            //               'Just a moment...',
            //               'Getting playlist songs...',
            //               'Almost done...',
            //             ],
            //           ),
            //         )
            //       : errorList.isNotEmpty
            //           ? const Center(
            //               child: Text(
            //                 'Error loading playlist songs',
            //                 style: TextStyle(
            //                   color: Colors.white,
            //                 ),
            //               ),
            //             )
            //           : ListView.builder(
            //               padding: EdgeInsets.only(
            //                 top: 24,
            //                 bottom: widget.tagQuery != null ? 190 : 120,
            //               ),
            //               itemCount:
            //                   (recommendations?.length ?? widget.songs?.length)! +
            //                           1 ??
            //                       0,
            //               itemBuilder: (context, index) {
            //                 if (index == recommendations!.length) {
            //                   return Padding(
            //                     padding: const EdgeInsets.all(16.0),
            //                     child: _isGeneratingMore
            //                         ? const SizedBox(
            //                             height: 50,
            //                             child: CupertinoActivityIndicator(
            //                               color: Colors.white,
            //                               radius: 10,
            //                             ),
            //                           )
            //                         : Center(
            //                             child: SizedBox(
            //                               width: 190,
            //                               child: GeneralButton(
            //                                 hasPadding: true,
            //                                 backgroundColor:
            //                                     const Color(0xffD9D9D9),
            //                                 text: "Generate More",
            //                                 color: Colors.black,
            //                                 // icon: const Icon(
            //                                 //   Icons.blur_on_sharp,
            //                                 //   color: Colors.black,
            //                                 //   // size: 40,
            //                                 // ),
            //                                 onPressed: _generateMore,
            //                               ),
            //                             ),
            //                           ),
            //                   );
            //                 }

            //                 final song =
            //                     recommendations?[index] ?? widget.songs?[index];

            //                 return widget.playlistId != null ||
            //                         widget.searchQuery != null ||
            //                         widget.tagQuery != null
            //                     ? Animate(
            //                         effects: [
            //                           FadeEffect(
            //                             delay: Duration(
            //                                 milliseconds:
            //                                     (50 * (index % 5)).toInt()),
            //                             duration:
            //                                 const Duration(milliseconds: 300),
            //                             curve: Curves.easeInOut,
            //                             begin: 0.0,
            //                             end: 1.0,
            //                           ),
            //                         ],
            //                         child: MusicListTile(
            //                           isPlaying: _isPlaying &&
            //                               _currentSong?.id == song?.id,
            //                           trailingOnTap: () => _togglePlay(song),
            //                           recommendation: song!,
            //                           onPlaybackStateChanged: (isPlaying) {
            //                             setState(() {
            //                               _isPlaying = isPlaying;
            //                             });
            //                           },
            //                           isSelected:
            //                               _selectedItems.contains(song.id),
            //                           onTap: () {
            //                             if (_isSelectionMode) {
            //                               _toggleSelection(song.id ?? '');
            //                             } else {
            //                               _togglePlay(song);
            //                             }
            //                           },
            //                           onDismissed: () {
            //                             setState(() {
            //                               recommendations?.removeWhere(
            //                                   (s) => s.id == song.id);
            //                             });
            //                           },
            //                         ),
            //                       )
            //                     : MusicListTile(
            //                         isPlaying: _isPlaying &&
            //                             _currentSong?.id == song?.id,
            //                         trailingOnTap: () => _togglePlay(song),
            //                         recommendation: song!,
            //                         onPlaybackStateChanged: (isPlaying) {
            //                           setState(() {
            //                             _isPlaying = isPlaying;
            //                           });
            //                         },
            //                         isSelected: _selectedItems.contains(song.id),
            //                         onTap: () {
            //                           if (_isSelectionMode) {
            //                             _toggleSelection(song.id ?? '');
            //                           } else {
            //                             _togglePlay(song);
            //                           }
            //                         },
            //                         onDismissed: () {
            //                           setState(() {
            //                             recommendations
            //                                 ?.removeWhere((s) => s.id == song.id);
            //                           });
            //                         },
            //                       );
            //               },
            //             ),
            // ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  late String _status;

  Future<void> _authenticate() async {
    const authUrl = '$baseURL/auth/login';
    const callbackUrlScheme = "nuance";

    try {
      final result = await FlutterWebAuth.authenticate(
        url: authUrl,
        callbackUrlScheme: callbackUrlScheme,
      );
      _status = "Alright";

      final uri = Uri.parse(result);
      final sessionData = uri.queryParameters['session'];

      log("Session data: $sessionData");

      if (sessionData != null) {
        final sessionMap = jsonDecode(sessionData);
        final accessToken = sessionMap['access_token'];

        // Fetch user profile details
        try {
          final profile =
              await RecommendationsService().getUserProfile(accessToken);
          final name = profile['user']['name'];
          final email = profile['user']['email'];

          // Update session data
          await ref
              .read(sessionProvider.notifier)
              .storeSessionAndSaveToState(sessionData, name, email);

          // Navigate to HomeScreen
          await Get.to(
            () => const HomeScreen(),
            transition: Transition.fade,
            curve: Curves.easeInOut,
          );
        } catch (error) {
          debugPrint("Error fetching user profile: $error");
          setState(() {
            _status = 'Error fetching user profile';
          });
        }
      }
    } on PlatformException catch (e) {
      setState(() {
        debugPrint("ERROR MESSAGE: ${e.message}");
        _status = 'Error: ${e.message}';
      });
    }
  }
}
