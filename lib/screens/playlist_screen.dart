import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';
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
// import 'package:music_kit/music_kit.dart';
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/providers/playlist_provider.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/providers/add_tracks_provider.dart';
import 'package:nuance/screens/home_screen.dart';
import 'package:nuance/services/all_services.dart';
import 'package:nuance/utils/constants.dart';
import 'package:nuance/widgets/custom_divider.dart';
import 'package:nuance/widgets/custom_snackbar.dart';
import 'package:nuance/widgets/general_button.dart';
import 'package:nuance/widgets/loader.dart';
import 'package:nuance/widgets/music_listtile.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaylistScreen extends ConsumerStatefulWidget {
  const PlaylistScreen({
    super.key,
    this.searchQuery,
    this.tagQuery,
    this.searchTitle,
    this.playlistId,
    this.sessionState,
    this.songs,
    this.imageUrl,
    this.playlistUrl,
  });

  static const routeName = '/recommendations-result';

  final String? imageUrl;
  final String? playlistId;
  final String? playlistUrl;
  final String? searchQuery;
  final String? searchTitle;
  final AsyncValue<SessionData?>? sessionState;
  final List<SongModel>? songs;
  final String? tagQuery;

  @override
  ConsumerState<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends ConsumerState<PlaylistScreen>
    with TickerProviderStateMixin {
// }    with TickerProviderStateMixin {
  int? currentlyPlayingSongId;

  // how errors are tracked in the page
  List<String> errorList = [];

  // the generated image; if its a generate playlist card
  String? generatedImage;

// to control showing loading indicator on the page
  bool isLoading = true;

  // the playlist image from spotify; if its a playlist card
  String? playlistImage;

  // the controlled list of songs shown on the screen
  List<SongModel>? recommendations = [];

  final service = AllServices();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Color _backgroundColor = Colors.black;
  late AnimationController _controller; // Animation controller
  final String _countryCode = '';
  SongModel? _currentSong;
  // final MusicKit _musicKitPlugin = MusicKit();
  final String _developerToken = '';

  bool _isGeneratingMore = false;
  bool _isLoading = false; // Loading state
  bool _isPlaying = false;
  bool _isSelectionMode = false;
  String? _loadingPlaylistId;
  PaletteGenerator? _paletteGenerator;
  late AnimationController _refreshAnimationController; // Animation controller
  final Set<String> _selectedItems = {};
  final bool _stretch = true;

  // @override
  // void initState() {
  //   super.initState();

  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.invalidate(playlistProvider);
    // _fetchRecommendationsOrPlaylistTracks();

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

    _fetchRecommendationsOrPlaylistTracks().then((_) {
      if (playlistImage != null && playlistImage!.isNotEmpty) {
        _updatePaletteGenerator();
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();

    _controller.dispose(); // Dispose the controller when the widget is disposed

    _refreshAnimationController
        .dispose(); // Dispose the controller when the widget is disposed
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _refreshAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(); // Repeat the animation indefinitely

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(); // Repeat the animation indefinitely
    _refreshAnimationController.forward();
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
    return s.length > 30
        ? ("${s[0].toUpperCase()}${s.substring(1, 30)}...")
        : s[0].toUpperCase() + s.substring(1);
  }

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

  SliverAppBar normalAppBarWithNoImage(
      BuildContext context, int uniqueArtistsCount, int totalDuration) {
    return SliverAppBar(
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
      title: Column(
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
                      style: subtitleTextStyle.copyWith(
                        color: Colors.grey.shade300,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
        ],
      ),
    );
  }

  SliverAppBar spotifyPlaylistAppBar(
      BuildContext context, int uniqueArtistsCount, int totalDuration) {
    final sessionStateFromProvider = ref.read(sessionProvider);
    final provider = sessionStateFromProvider.value?.provider;
    return SliverAppBar(
      stretch: false,
      automaticallyImplyLeading: false,
      centerTitle: false,
      backgroundColor:
          Colors.transparent, // Set to transparent so gradient shows
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
      actions: [
        IconButton(
          onPressed: () async {
            // playlistUrl
            final url = widget.playlistUrl;
            if (url != null && await canLaunch(url)) {
              await launch(url);
            } else {
              // Handle the error if the URL cannot be launched
            }
          },
          icon: provider == 'spotify'
              ? SvgPicture.asset(
                  "assets/spotifylogoblack.svg",
                  color: Colors.white,
                  width: 20,
                )
              : SvgPicture.asset(
                  "assets/applemusiclogoblack.svg",
                  color: Colors.white,
                  width: 30,
                ).marginOnly(right: 8),
        )
      ],
      expandedHeight: 330.0,
      floating: true,
      pinned: true,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double shrinkOffset = constraints.maxHeight - kToolbarHeight;
          const double maxExtent = 330.0; // Should match expandedHeight
          const double fadeStart = maxExtent - kToolbarHeight * 2;
          const double fadeEnd = maxExtent - kToolbarHeight;

          final double titleAlignmentShift = 60.0 -
              (41.0 *
                  ((shrinkOffset - fadeStart) / (fadeEnd - fadeStart))
                      .clamp(0.0, 1.0));

          return Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(
                              _paletteGenerator?.dominantColor?.color ??
                                  Colors.black,
                              Colors.black,
                              0.8) ??
                          Colors.black,
                      Color.lerp(
                              _paletteGenerator?.dominantColor?.color ??
                                  Colors.black,
                              Colors.black,
                              0.96) ??
                          Colors.black,
                      const Color.fromARGB(255, 1, 1, 1),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: CachedNetworkImage(
                  imageUrl: playlistImage ?? widget.imageUrl ?? "",
                  imageBuilder: (context, imageProvider) => Container(
                    margin: const EdgeInsets.only(
                      top: 60,
                      bottom: 80,
                    ),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    return const SizedBox.shrink();
                  },
                  placeholder: (context, url) {
                    return Shimmer.fromColors(
                      baseColor: const Color.fromARGB(131, 158, 158, 158),
                      highlightColor: const Color.fromARGB(50, 224, 224, 224),
                      child: const SizedBox(
                        height: 200,
                        width: 200,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 0.0 +
                    ((shrinkOffset / maxExtent) * maxExtent)
                        .clamp(0.0, maxExtent + 26),
                left: titleAlignmentShift,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Tooltip(
                          message: widget.searchQuery ??
                              widget.tagQuery ??
                              widget.searchTitle ??
                              "",
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 250),
                            child: Text(
                              capitalizeFirst(widget.searchQuery ??
                                  widget.tagQuery ??
                                  widget.searchTitle ??
                                  ""),
                              style: headingTextStyle,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Text(
                            '$uniqueArtistsCount artists • ${recommendations?.length ?? widget.songs?.length ?? 0} songs • ${formatMilliseconds(totalDuration)}',
                            style: subtitleTextStyle.copyWith(
                                color: Colors.grey.shade300, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ).marginOnly(left: 1.5),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar generatedPlaylistCardAppBar(
      BuildContext context, int uniqueArtistsCount, int totalDuration) {
    return SliverAppBar(
      stretch: false,
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
          (widget.playlistId == null || widget.playlistId == "")
              ? Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.delete,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: _deleteSelected,
                    ),
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.memories_badge_plus,
                        size: 28,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        final selectedSongs = recommendations
                            ?.where((song) => _selectedItems.contains(song.id))
                            .toList();
                        dev.log("selectedSongs: $selectedSongs");
                        if (selectedSongs != null && selectedSongs.isNotEmpty) {
                          _isSelectionMode = false;
                          dev.log("selectedSongs 2: $selectedSongs");
                          recommendations = selectedSongs;
                          _generateMore(seeds: selectedSongs);
                        } else {
                          CustomSnackbar().show("No songs selected");
                        }
                      },
                    ),
                    const SizedBox(
                      width: 15,
                    )
                  ],
                )
              : const SizedBox.shrink()
        else
          (widget.playlistId == null || widget.playlistId == "")
              ? IconButton(
                  icon: const Icon(
                    CupertinoIcons.list_bullet,
                    size: 18,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = true;
                    });
                  },
                )
              : const SizedBox.shrink(),
      ],
      expandedHeight: 280.0,
      floating: true,
      pinned: true,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double shrinkOffset = constraints.maxHeight - kToolbarHeight;
          const double maxExtent = 280.0; // Should match expandedHeight
          const double fadeStart = maxExtent - kToolbarHeight * 2;
          const double fadeEnd = maxExtent - kToolbarHeight;

          final double titleAlignmentShift = 60.0 -
              (41.0 *
                  ((shrinkOffset - fadeStart) / (fadeEnd - fadeStart))
                      .clamp(0.0, 1.0));

          // Calculate the opacity for the app bar background color
          final double appBarOpacity =
              1 - (shrinkOffset / maxExtent).clamp(-1.1, 1.0);

          return Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.black.withOpacity(0.5),
                child: CachedNetworkImage(
                  imageUrl: widget.playlistId != null
                      // if we pass playlist id we use the spotify image
                      ? playlistImage ?? ""
                      : widget.imageUrl ?? generatedImage ?? "",
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
                color: Colors.black.withOpacity(appBarOpacity),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.8),
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
                    ? ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 250),
                        child: Transform.translate(
                          offset: const Offset(0, 0),
                          child: Text(
                            "${_selectedItems.length} selected",
                            style: subtitleTextStyle,
                          ),
                        ))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Tooltip(
                                message: widget.searchQuery ??
                                    widget.tagQuery ??
                                    widget.searchTitle ??
                                    "",
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 250),
                                  child: Text(
                                    capitalizeFirst(widget.searchQuery ??
                                        widget.tagQuery ??
                                        widget.searchTitle ??
                                        ""),
                                    style: headingTextStyle,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                              isLoading
                                  ? const SizedBox.shrink()
                                  : ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 200),
                                      child: Text(
                                        '$uniqueArtistsCount artists • ${recommendations?.length ?? widget.songs?.length ?? 0} songs • ${formatMilliseconds(totalDuration)}',
                                        style: subtitleTextStyle.copyWith(
                                          color: Colors.grey.shade300,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      ),
              ),
              if ((widget.playlistId == null || widget.playlistId == "") &&
                  widget.songs == null &&
                  _isSelectionMode == false)
                Positioned(
                  bottom: -30,
                  right: 30,
                  child: Transform.translate(
                    offset: const Offset(0, 0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AnimatedBuilder(
                        animation: _refreshAnimationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _refreshAnimationController.value * 2 * pi,
                            child: child,
                          );
                        },
                        child: IconButton(
                          onPressed: () {
                            recommendations = [];
                            _generateMore();
                          },
                          icon: SvgPicture.asset(
                            "assets/refresh.svg",
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
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
      // isLoading = true;
      errorList = [];
    });

    try {
      final accessToken = widget.sessionState?.value?.accessToken ??
          sessionStateFromProvider.value?.providerToken ??
          "";
      final providerToken = widget.sessionState?.value?.providerToken ??
          sessionStateFromProvider.value?.providerToken ??
          "";

      // Retrieve providerType from session data
      final provider = sessionStateFromProvider.value?.provider;

      dev.log("Access token: $accessToken");
      dev.log("Provider token: $providerToken");
      dev.log("Provider: $provider");

      if ((widget.playlistId == null || widget.playlistId == "") &&
          widget.songs == null) {
        dev.log("Fetching generated image...");
        generatedImage = await service.getGeneratedImage(accessToken,
            widget.searchTitle ?? widget.searchQuery ?? widget.tagQuery ?? "");
        dev.log("Generated image fetched: $generatedImage");
      }

      final result = widget.songs != null
          ? widget.songs!
          : widget.searchQuery != null || widget.tagQuery != null
              ? await service.getRecommendations(
                  accessToken,
                  widget.searchQuery ?? widget.tagQuery ?? "",
                  provider,
                )
              : widget.playlistId != null
                  ? await service.fetchPlaylistTracks(
                      accessToken,
                      providerToken,
                      widget.playlistId ?? "",
                      provider,
                    )
                  : null;

      if (mounted) {
        dev.log("Result: $result");
        setState(() {
          if (result != null) {
            if (result is List<SongModel>) {
              recommendations = result;
              dev.log("Recommendations updated: $recommendations");
            } else if (result is Map<String, dynamic>) {
              playlistImage = result['playlistImage'] as String?;
              recommendations = result['playlistTracks'] as List<SongModel>;
              dev.log("Playlist image: $playlistImage");
              dev.log(
                  "Playlist tracks: ${recommendations?.map((e) => e.toJson()).toList()}");
            }
          }
          isLoading = false;
        });
      }
    } catch (e) {
      dev.log("Error occurred: $e");
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
    try {
      final accessToken = widget.sessionState?.value?.accessToken ??
          ref.read(sessionProvider).value?.providerToken ??
          "";

      final provider = widget.sessionState?.value?.provider ??
          ref.read(sessionProvider).value?.provider ??
          "";

      await service.followSpotifyPlaylist(accessToken, playlistId, provider);

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      CustomSnackbar().show("Error: ${e.toString()}");
      if (mounted) {
        setState(() {
          errorList.add(e.toString());
          isLoading = false;
        });
      }
    }
  }

  Future<void> _generateMore({
    List<SongModel>? seeds,
  }) async {
    if (_isGeneratingMore) return;
    _refreshAnimationController.repeat();
    debugPrint("Animation controller refreshed");

    setState(() {
      _isSelectionMode = false;
      debugPrint("Selection mode set to: $_isSelectionMode");
      _selectedItems.clear();
      debugPrint("Selected items cleared: $_selectedItems");
      _isGeneratingMore = true;
      debugPrint("Generating more set to1: $_isGeneratingMore");
      // isLoading = true; // Set isLoading to true to trigger loading interface
    });

    try {
      final sessionStateFromProvider = ref.read(sessionProvider);
      debugPrint("Session state from provider: $sessionStateFromProvider");
      final accessToken = widget.sessionState?.value?.accessToken ??
          sessionStateFromProvider.value?.providerToken ??
          "";
      debugPrint("Access token: $accessToken");
      final provider = widget.sessionState?.value?.provider ??
          sessionStateFromProvider.value?.provider ??
          "";
      debugPrint("Provider: $provider");

      List<SongModel>? newRecommendations;

      if (seeds != null && seeds.isNotEmpty) {
        // Generate new recommendations based on the selected songs
        newRecommendations = await service.getMoreRecommendations(
            accessToken,
            "", // Empty string as we're using seed tracks
            seeds,
            provider);
        debugPrint("New recommendations from seeds: $newRecommendations");
      } else if (widget.searchQuery != null || widget.tagQuery != null) {
        newRecommendations = await service.getMoreRecommendations(
          accessToken,
          widget.searchQuery ?? widget.tagQuery ?? "",
          recommendations ?? [],
          provider,
        );
        debugPrint("New recommendations from search/tag: $newRecommendations");
      }

      if (mounted) {
        if (newRecommendations != null && newRecommendations.isNotEmpty) {
          setState(() {
            recommendations = [...?recommendations, ...?newRecommendations];
            debugPrint("Updated recommendations: $recommendations");
            _isGeneratingMore = false;
            debugPrint("Generating more set to2: $_isGeneratingMore");
          });
        } else {
          CustomSnackbar().show("No recommendations generated");
        }
      }
    } catch (e) {
      debugPrint("Error occurred: $e");
      if (mounted) {
        setState(() {
          errorList.add(e.toString());
          debugPrint("Error list updated: $errorList");
          _isGeneratingMore = false;
          debugPrint("Generating more set to3: $_isGeneratingMore");
          isLoading = false;
          debugPrint("Loading set to: $isLoading");
        });
        CustomSnackbar().show("Failed to generate recommendations");
      }
    } finally {
      setState(() {
        _isGeneratingMore = false;
        // debugPrint("Generating more set to: $_isGeneratingMore");
        isLoading = false;
        // debugPrint("Loading set to: $isLoading");
      });
      _refreshAnimationController.stop(); // Stop spinning
      // debugPrint("Animation controller stopped");
    }
  }

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
                      "Add to your library",
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

                    final sessionStateFromProvider = ref.read(sessionProvider);
                    final provider = sessionStateFromProvider.value?.provider;

                    final trackIds = recommendations.map((song) {
                      if (provider == 'spotify') {
                        return song.trackUri ?? "";
                      } else {
                        return song.id ?? "";
                      }
                    }).toList();

                    dev.log("TRACK IDs: ${trackIds.join(', ')}");

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
                                dev.log("IDDDDD:   ${playlist.id}");
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
                                  imageUrl:
                                      widget.imageUrl ?? generatedImage ?? "",
                                  trackIds: trackIds.map((e) => e).toList(),
                                  providerType: sessionStateFromProvider
                                          .value?.provider ??
                                      "",
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
                                          width: 40.0,
                                          height: 40.0,
                                          decoration: const BoxDecoration(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5.0)),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color.fromARGB(
                                                    255, 215, 129, 0),
                                                Color.fromARGB(
                                                    255, 255, 222, 59),
                                              ],
                                            ),
                                            color: Colors.orange,
                                          ),
                                        );
                                      }),
                                  title: Text(
                                    playlist.name ?? "",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  // subtitle: Text(
                                  //   "${playlist.totalTracks} ${(playlist.totalTracks ?? 0) >= 2 ? "songs" : "song"} ",
                                  //   style: subtitleTextStyle,
                                  // ),
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
                                        Get.back();
                                        CustomSnackbar().show(
                                            "Successfully added tracks to ${playlist.name} playlist.");
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
                            'Getting your playlists ...',
                            'Just a moment ...',
                            'Almost done ...',
                            'Getting your bangers ...',
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
                              ? 'Adding playlist songs  ...'
                              : widget.tagQuery != null
                                  ? 'Generating playlist songs ...'
                                  : widget.searchTitle != null
                                      ? 'Getting playlist songs ...'
                                      : 'Loading playlist songs ...',
                          'Just a moment...',
                          'Getting playlist songs ...',
                          'Almost done ...',
                          'Getting your bangers ...',
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
                            "Create a new playlist",
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
                            animationDuration: const Duration(seconds: 2),
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
                          animationDuration: const Duration(seconds: 2),
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
                                  'image':
                                      widget.imageUrl ?? generatedImage ?? "",
                                };
                                dev.log("CREATE PLAYLIST DATA screen: $data");
                                dev.log(
                                    "CREATE PLAYLIST DATA name: ${data["name"]}");

                                // Call the createPlaylistProvider
                                ref
                                    .read(createPlaylistProvider(data).future)
                                    .then((newPlaylist) {
                                  // Playlist created successfully
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
                                      imageUrl: widget.imageUrl ??
                                          generatedImage ??
                                          "",
                                      trackIds: trackIds,
                                      providerType: ref
                                              .read(sessionProvider)
                                              .value
                                              ?.provider ??
                                          "",
                                    );

                                    // Add tracks to playlist
                                    ref
                                        .read(addTracksProvider.notifier)
                                        .addTracksToPlaylist(params)
                                        .then((_) {
                                      Get.back();
                                      Get.back(); // Close modal
                                      CustomSnackbar().show(
                                        'Successfully created ${newPlaylist.name} playlist.',
                                      );
                                    }).catchError((error) {
                                      // Handle error in adding tracks
                                      debugPrint("Error adding tracks: $error");
                                      CustomSnackbar().show(
                                        "Failed to add tracks to playlist: $error",
                                      );
                                    });
                                  } else {
                                    CustomSnackbar().show(
                                      "No access token found.",
                                    );
                                  }
                                }).catchError((error) {
                                  // Handle error in playlist creation
                                  debugPrint("Error creating playlist: $error");
                                  CustomSnackbar().show(
                                    "Failed to create playlist: $error",
                                  );
                                }).whenComplete(() {
                                  // Reset loading state
                                  setState(() {
                                    isLoading = false;
                                  });
                                });
                              } else {
                                // Reset loading state
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

  Future<void> _updatePaletteGenerator() async {
    // final imageUrl = playlistImage;

    if (playlistImage != null && (playlistImage ?? "").isNotEmpty) {
      try {
        final paletteGenerator = await PaletteGenerator.fromImageProvider(
          CachedNetworkImageProvider((playlistImage ?? "")),
        );
        setState(() {
          _paletteGenerator = paletteGenerator;
        });
      } catch (e) {
        print('Error generating palette: $e');
        setState(() {
          _paletteGenerator = null;
        });
      }
    } else {
      setState(() {
        _paletteGenerator = null;
      });
    }
  }

  Future<void> _authenticate() async {
    final authUrl = '$baseURL/auth/login';
    const callbackUrlScheme = "nuance";

    setState(() {
      _isLoading = true;
    });

    try {
      // First, initialize MusicKit
      // await _initializeMusicKit();

      final result = await FlutterWebAuth.authenticate(
        url: authUrl,
        callbackUrlScheme: callbackUrlScheme,
      );

      final uri = Uri.parse(result);
      final sessionData = uri.queryParameters['session'];

      if (sessionData != null) {
        final sessionMap = jsonDecode(sessionData);
        final accessToken = sessionMap['access_token'];

        try {
          final profile = await service.getUserProfile(accessToken);
          final name = profile['user']['name'];
          final email = profile['user']['email'];

          // Request MusicKit user token
          // final musicKitUserToken = await _requestMusicKitUserToken();

          // final musicKitData = {
          //   'musicKitUserToken': musicKitUserToken,
          //   'developerToken': _developerToken,
          //   'countryCode': _countryCode,
          // };

          // await ref.read(sessionProvider.notifier).storeSessionAndSaveToState(
          //       sessionData: sessionData,
          //       name: name,
          //       email: email,
          //       musicKitData: musicKitData,
          //     );

          await Get.to(
            () => const HomeScreen(),
            transition: Transition.fade,
            curve: Curves.easeInOut,
          );
        } catch (error) {
          debugPrint("Error in profile fetching or MusicKit process: $error");
          _showErrorSnackBar("Error in authentication process: $error");
        }
      }
    } on PlatformException catch (e) {
      debugPrint("PlatformException in authentication: ${e.message}");
      _showErrorSnackBar("Authentication failed: ${e.message}");
    } catch (e) {
      debugPrint("Unexpected error in authentication: $e");
      _showErrorSnackBar("Unexpected error occurred");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Future<void> _initializeMusicKit() async {
  //   try {
  //     final status = await _musicKitPlugin.authorizationStatus;
  //     if (status != MusicAuthorizationStatus.authorized) {
  //       final newStatus = await _musicKitPlugin.requestAuthorizationStatus();
  //       if (newStatus != MusicAuthorizationStatus.authorized) {
  //         throw Exception(
  //             "MusicKit authorization not granted. Status: $newStatus");
  //       }
  //     }

  //     _developerToken = await _musicKitPlugin.requestDeveloperToken();
  //     _countryCode = await _musicKitPlugin.currentCountryCode;

  //     print("MusicKit initialized successfully. Country code: $_countryCode");
  //   } catch (e) {
  //     print("Error initializing MusicKit: $e");
  //     throw Exception("Failed to initialize MusicKit: $e");
  //   }
  // }

  // Future<String> _requestMusicKitUserToken() async {
  //   try {
  //     final userToken = await _musicKitPlugin.requestUserToken(_developerToken);
  //     if (userToken.isEmpty) {
  //       throw Exception("Received null or empty MusicKit user token");
  //     }
  //     print("MusicKit user token obtained successfully");
  //     return userToken;
  //   } catch (e) {
  //     print("Error requesting MusicKit user token: $e");
  //     throw Exception("Failed to obtain MusicKit user token: $e");
  //   }
  // }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // bool for is a history playlist
    // final sessionData = ref.read(sessionProvider.notifier);
    final sessionState = ref.watch(sessionProvider);
    if (widget.sessionState == null && sessionState.value == null) {}
    ref.invalidate(playlistProvider);
    int totalDuration = getTotalDuration(recommendations ?? widget.songs ?? []);
    int uniqueArtistsCount =
        getUniqueArtistsCount(recommendations ?? widget.songs ?? []);
    // print("IMAGE URL!!!!!!!!!!!!!!!!!!!!!!!: ${widget.imageUrl}");

    return Scaffold(
      bottomNavigationBar: Container(
        color: Colors.black,
        height: widget.tagQuery != null ? 140 : 80,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (widget.tagQuery != null)
                if (!isLoading && sessionState.value?.accessToken != null ||
                    widget.sessionState != null)
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
                if (!isLoading && sessionState.value?.accessToken != null ||
                    widget.sessionState != null)
                  const CustomDivider().marginOnly(bottom: 5),
              if (!isLoading && sessionState.value?.accessToken != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
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
                          onPressed: () {
                            isLoading
                                ? null
                                : service.shareRecommendation(
                                    context,
                                    widget.searchQuery ??
                                        widget.tagQuery ??
                                        widget.searchTitle ??
                                        "",
                                    recommendations ?? widget.songs ?? [],
                                    widget.imageUrl ??
                                        generatedImage ??
                                        playlistImage ??
                                        "",
                                    widget.playlistId ?? "",
                                  );
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
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
        child: NestedScrollView(
          physics: isLoading
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              !isLoading && widget.playlistId != null
                  ? spotifyPlaylistAppBar(
                      context, uniqueArtistsCount, totalDuration)
                  : !isLoading &&
                          (widget.playlistId == null || widget.playlistId == "")
                      ? generatedPlaylistCardAppBar(
                          context, uniqueArtistsCount, totalDuration)
                      : normalAppBarWithNoImage(
                          context, uniqueArtistsCount, totalDuration)
            ];
          },
          body: ListView.builder(
            padding: const EdgeInsets.only(
              top: 25,
              bottom: 100,
            ),
            itemCount: isLoading
                ? 1
                : (recommendations?.length ?? widget.songs?.length ?? 0) + 1,
            itemBuilder: (BuildContext context, int index) {
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
                          ? 'Searching for songs ...'
                          : widget.tagQuery != null
                              ? 'Generating playlist songs ...'
                              : widget.searchTitle != null
                                  ? 'Getting playlist songs ...'
                                  : 'Loading playlist songs ...',
                      'Just a moment ...',
                      'Getting playlist songs ...',
                      'Almost done ...',
                      'Getting your bangers ...',
                    ],
                  ),
                );
              }

              if (index == (recommendations?.length ?? widget.songs?.length)) {
                if ((widget.playlistId == null || widget.playlistId == "")) {
                  return Padding(
                    padding: const EdgeInsets.all(26.0),
                    child: _isGeneratingMore
                        ? SizedBox(
                            height: 30,
                            child: RotationTransition(
                              turns: _controller,
                              child: Image.asset(
                                fit: BoxFit.contain,
                                'assets/whitelogo.png',
                                width: 10,
                                height: 10,
                              ),
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
                } else {
                  return const SizedBox.shrink();
                }
              }

              final song = recommendations?[index] ?? widget.songs![index];

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
                        isFromSpotifyPlaylistCard: widget.playlistId != null,
                        isPlaying: _isPlaying && _currentSong?.id == song.id,
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
                      isFromSpotifyPlaylistCard: widget.playlistId != null,
                      isPlaying: _isPlaying && _currentSong?.id == song.id,
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
                        setState(
                          () {
                            recommendations
                                ?.removeWhere((s) => s.id == song.id);
                          },
                        );
                      },
                    );
            },
          ),
        ),
      ),
    );
  }
}
