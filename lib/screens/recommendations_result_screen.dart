import 'dart:developer';
import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/providers/recommendation_provider.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/providers/playlist_provider.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/providers/add_tracks_provider.dart';
import 'package:nuance/services/recomedation_service.dart';
import 'package:nuance/theme.dart';
import 'package:nuance/utils/constants.dart';
import 'package:nuance/widgets/custom_divider.dart';
import 'package:nuance/widgets/general_button.dart';
import 'package:nuance/widgets/music_listtile.dart';

class RecommendationsResultScreen extends ConsumerStatefulWidget {
  static const routeName = '/recommendations-result';
  final String? tagQuery;
  final String? searchQuery;
  final AsyncValue<SessionData?>? sessionState;

  const RecommendationsResultScreen({
    super.key,
    this.searchQuery,
    this.sessionState,
    this.tagQuery,
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
  // String? searchQuery;
  // AsyncValue<SessionData?>? sessionState;
  String? _loadingPlaylistId;

  bool isLoading = true;
  List<String> errorList = [];
  List<SongModel> recommendations = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // final arguments = ModalRoute.of(context)!.settings.arguments as Map;
    // searchQuery = arguments['search_term'] as String?;
    // sessionState = arguments['sessionState'] as AsyncValue<SessionData?>?;
    log("STATE : ${widget.sessionState?.value?.accessToken}");

    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      isLoading = true;
      errorList = [];
    });

    try {
      // final sessionData = ref.read(authProvider.notifier).state;
      final service = RecommendationsService();
      final result = await service.getRecommendations(
          widget.sessionState?.value?.accessToken ?? "",
          widget.searchQuery ?? widget.tagQuery ?? "");
      setState(() {
        recommendations = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorList.add(e.toString());
        isLoading = false;
      });
    }
  }

  // bool _isButtonVisible = false;

  // void _toggleButtonVisibility() {
  //   setState(() {
  //     _isButtonVisible = !_isButtonVisible;
  //   });
  // }

  void _togglePlay(SongModel song) async {
    if (song.previewUrl?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Use Spotify Premium to preview this song')),
      );
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
                                  accessToken:
                                      widget.sessionState!.value!.accessToken,
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
                                    if (widget
                                            .sessionState?.value?.accessToken !=
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
    final nameController = TextEditingController(text: "${widget.searchQuery}");
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
                                if (widget.sessionState?.value?.accessToken !=
                                    null) {
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
                                        widget.sessionState!.value!.accessToken,
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

  // calculateArtists(List<String> artists) {
  //   Set<String> uniqueArtists = {};
  //   for (var song in recommendations) {
  //     if (song.durationMs != null) {
  //       totalDuration += song.durationMs!;
  //     }
  //     if (song.artist != null) {
  //       uniqueArtists
  //           .addAll(song.artist!.split(',').map((artist) => artist.trim()));
  //     }
  //   }
  //   // String formattedDuration = _formatDuration(totalDuration);
  //   int numberOfArtists = uniqueArtists.length;
  // }

  int? currentlyPlayingSongId;

  // // log("Log screen result: $recommendations");

  // // Calculate total duration, number of songs, and unique artists
  // int totalDuration = 0;
  // int numberOfSongs = recommendations.length;
  // Set<String> uniqueArtists = {};

  // for (var song in recommendations) {
  //   if (song.durationMs != null) {
  //     totalDuration += song.durationMs!;
  //   }
  //   if (song.artist != null) {
  //     uniqueArtists.addAll(
  //         song.artist!.split(',').map((artist) => artist.trim()));
  //   }
  // }

  // // String formattedDuration = _formatDuration(totalDuration);
  // int numberOfArtists = uniqueArtists.length;
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

  @override
  Widget build(BuildContext context) {
    if (widget.sessionState == null) {
      return const Scaffold(
        body: Center(child: Text('No search term found')),
      );
    }
    final sessionData = ref.read(sessionProvider.notifier);
    int totalDuration = getTotalDuration(recommendations);
    int uniqueArtistsCount = getUniqueArtistsCount(recommendations);
    // final recommendationsState =
    //     ref.watch(recommendationsProvider(searchQuery!));

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              capitalizeFirst(widget.searchQuery ?? widget.tagQuery ?? ""),
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
            ),
            isLoading
                ? const Center(
                    // child: CupertinoActivityIndicator(
                    // color: Colors.white,
                    // )
                    )
                : errorList.isNotEmpty
                    ? Center(child: Text('Error: ${errorList.join(', ')}'))
                    : Text(
                        '$uniqueArtistsCount artists • ${recommendations.length} songs • ${formatMilliseconds(totalDuration)}',
                        style: subtitleTextStyle,
                      ),
          ],
        ),
        automaticallyImplyLeading: false,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: widget.sessionState!.when(
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
      body: Center(
        child: Stack(
          children: [
            Container(
              color: Colors.black,
              child: isLoading
                  ? const Center(
                      child: CupertinoActivityIndicator(
                      color: Colors.white,
                    ))
                  : errorList.isNotEmpty
                      ? Center(child: Text('Error: ${errorList.join(', ')}'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 24, bottom: 200),
                          itemCount: recommendations.length,
                          itemBuilder: (context, index) {
                            final song = recommendations[index];
                            return MusicListTile(
                              isPlaying:
                                  _isPlaying && _currentSong?.id == song.id,
                              trailingOnTap: () => _togglePlay(song),
                              recommendation: song,
                            );
                          },
                        ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.black,
                height: 150,
                child: Column(
                  children: [
                    if (widget.searchQuery == null)
                      Row(
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
                          )
                        ],
                      ),

                    const SizedBox(height: 10),
                    const CustomDivider(),
                    const SizedBox(height: 10),
                    // const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        children: [
                          Expanded(
                            child: GeneralButton(
                              hasPadding: true,
                              text: "Share",
                              icon: SvgPicture.asset("assets/sendto.svg"),
                              backgroundColor: const Color(0xffD9D9D9),
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child: GeneralButton(
                              backgroundColor: const Color(0xffFDAD3C),
                              hasPadding: true,
                              icon: SvgPicture.asset("assets/bookmark.svg"),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                    // const SizedBox(
                    //   height: 5,
                    // ),
                    // const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
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
}
