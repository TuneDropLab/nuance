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
import 'package:nuance/widgets/general_button.dart';
import 'package:nuance/widgets/loader.dart';
import 'package:nuance/widgets/music_listtile.dart';

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
  // String? searchQuery;
  // AsyncValue<SessionData?>? sessionState;
  String? _loadingPlaylistId;

  bool isLoading = true;
  List<String> errorList = [];
  List<SongModel>? recommendations = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    log("STATE : ${widget.sessionState?.value?.accessToken}");

    ref.invalidate(playlistProvider);
    _fetchRecommendationsOrPlaylistTracks();
  }

  Future<void> _fetchRecommendationsOrPlaylistTracks() async {
    setState(() {
      isLoading = true;
      errorList = [];
    });

    try {
      final service = RecommendationsService();
      final accessToken = widget.sessionState?.value?.accessToken ?? "";
      final providerToken = widget.sessionState?.value?.providerToken ?? "";

      final result = widget.searchQuery != null || widget.tagQuery != null
          ? await service.getRecommendations(
              accessToken, widget.searchQuery ?? widget.tagQuery ?? "")
          : widget.playlistId != null
              ? await service.fetchPlaylistTracks(
                  accessToken, providerToken, widget.playlistId ?? "")
              : null;
      print("HIIIIIIIII: ${result?.first}");
      if (mounted) {
        setState(() {
          recommendations = result;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorList.add(e.toString());
          isLoading = false;
        });
      }
    }
  }

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
                    final addTracksState = ref.watch(addTracksProvider);
                    final trackIds = recommendations
                        .map((song) => song.trackUri ?? "")
                        .toList();

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
                                      widget.sessionState!.value!.accessToken,
                                  playlistId: playlist.id ?? "",
                                  trackIds: trackIds.map((e) => e).toList(),
                                );

                                return ListTile(
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
                                  title: Text(
                                    playlist.name ?? "",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    "${playlist.totalTracks} ${(playlist.totalTracks ?? 0) >= 2 ? "songs" : "song"} ",
                                    style: subtitleTextStyle,
                                  ),
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
                    // width: 200,
                    child: AnimatedTextField(
                      animationDuration: 4000.ms,
                      onTapOutside: (event) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      controller: nameController,
                      decoration: const InputDecoration(
                        fillColor: Color.fromARGB(255, 22, 22, 22),
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
                      fillColor: Color.fromARGB(255, 22, 22, 22),
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
                    hintTexts: const [
                      'Enter playlist descripion',
                    ],
                    onSubmitted: (value) {},
                  ),
                  const Spacer(),
                  Container(
                    width: Get.width,
                    margin: const EdgeInsets.only(
                      bottom: 30,
                    ),
                    child: GeneralButton(
                      text: "Add to Library",
                      backgroundColor: const Color(0xffD9D9D9),
                      hasPadding: true,
                      icon: isLoading
                          ? const CupertinoActivityIndicator()
                          : Icon(
                              Icons.check,
                              color: Colors.grey.shade800,
                            ),
                      onPressed: isLoading
                          ? () {}
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

                                    log("ABOUT TO ADD TO AN EXISTING PLAYLIST accessToken NOT NULL");

                                    final params = AddTracksParams(
                                      accessToken: widget
                                          .sessionState!.value!.accessToken,
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

  @override
  Widget build(BuildContext context) {
    if (widget.sessionState == null) {
      return const Scaffold(
        body: Center(child: Text('No search term found')),
      );
    }
    ref.invalidate(playlistProvider);
    final sessionData = ref.read(sessionProvider.notifier);
    int totalDuration = getTotalDuration(recommendations ?? widget.songs ?? []);
    int uniqueArtistsCount =
        getUniqueArtistsCount(recommendations ?? widget.songs ?? []);

    // final GlobalKey<ScaffoldState> globalKey = GlobalKey();

    return Scaffold(
      // key: globalKey,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            ref.invalidate(historyProvider);
            Get.back();
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
        // leadingWidth: 30,
        backgroundColor: Colors.black,
        title: Column(
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
                        'Error  loading  details',
                        style: subtitleTextStyle,
                      )
                    : Text(
                        '$uniqueArtistsCount  artists • ${recommendations?.length ?? widget.songs?.length ?? 0}  songs • ${formatMilliseconds(totalDuration)}',
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
                      globalKey.currentState!.openDrawer();
                      Get.back();
                      // sessionData.logout();
                    },
                  );
                }

                return CupertinoButton(
                  padding: const EdgeInsets.all(0),
                  onPressed: () {
                    // Get.back();
                    Get.offAll(
                      transition: Transition.leftToRight,
                      () => const HomeScreen(),
                      // fullscreenDialog: true,
                    );
                    globalKey.currentState!.openDrawer();
                    // sessionData.logout();
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
        child: SafeArea(
          child: Stack(
            children: [
              Container(
                color: Colors.black,
                child: isLoading
                    ? Center(
                        child: SpinningSvg(
                          svgWidget:
                              // SvgPicture.asset('assets/images/your_svg.svg'),
                              Image.asset(
                            'assets/hdlogo.png',
                            height: 40,
                          ),
                          // size: 10.0,
                          textList: [
                            widget.searchQuery != null
                                ? 'Searching for songs...'
                                : widget.tagQuery != null
                                    ? 'Generating playlist songs...'
                                    : widget.searchTitle != null
                                        ? 'Getting playlist songs...'
                                        : 'Loading playlist songs...',
                            'Just a moment...',
                            'Almost done...',
                          ],
                        ),
                      )
                    : errorList.isNotEmpty
                        ? const Center(
                            child: Text(
                              'Error loading playlist songs',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.only(
                              top: 24,
                              bottom: widget.tagQuery != null ? 190 : 120,
                            ),
                            itemCount: recommendations?.length ??
                                widget.songs?.length ??
                                0,
                            itemBuilder: (context, index) {
                              final song = recommendations?[index] ??
                                  widget.songs?[index];

                              return widget.playlistId != null ||
                                      widget.searchQuery != null ||
                                      widget.tagQuery != null
                                  ? Animate(
                                      effects: [
                                        FadeEffect(
                                          delay: Duration(
                                              milliseconds: 100 * index),
                                          duration:
                                              const Duration(milliseconds: 500),
                                          curve: Curves.easeInOut,
                                          begin: 0.0,
                                          end: 1.0,
                                        ),
                                      ],
                                      child: MusicListTile(
                                        isPlaying: _isPlaying &&
                                            _currentSong?.id == song?.id,
                                        trailingOnTap: () => _togglePlay(song),
                                        recommendation: song!,
                                      ),
                                    )
                                  : MusicListTile(
                                      isPlaying: _isPlaying &&
                                          _currentSong?.id == song?.id,
                                      trailingOnTap: () => _togglePlay(song),
                                      recommendation: song!,
                                    );
                            },
                          ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: Colors.black,
                  height: widget.tagQuery != null ? 140 : 80,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (widget.tagQuery != null)
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
                                text:
                                    widget.searchQuery ?? widget.tagQuery ?? "",
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
                        const CustomDivider().marginOnly(bottom: 5),
                      if (!isLoading || errorList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                            children: [
                              Expanded(
                                child: GeneralButton(
                                  backgroundColor: isLoading
                                      ? const Color.fromARGB(255, 166, 166, 166)
                                      : const Color(0xffFDAD3C),
                                  hasPadding: true,
                                  color: isLoading
                                      ? const Color.fromARGB(255, 112, 112, 112)
                                      : Colors.black,
                                  icon: SvgPicture.asset(
                                    "assets/bookmark.svg",
                                    color: isLoading
                                        ? const Color.fromARGB(
                                            255, 112, 112, 112)
                                        : Colors.black,
                                  ),
                                  onPressed: () {
                                    isLoading
                                        ? null
                                        : _showPlaylists(
                                            context,
                                            ref,
                                            widget.songs ??
                                                recommendations ??
                                                [],
                                          );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
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
