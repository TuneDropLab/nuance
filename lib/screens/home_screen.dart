import 'dart:developer';
import 'dart:math' as math;
import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nuance/services/vibe_cam_service.dart';
import 'package:nuance/widgets/vibe_cam/vibe_cam_scanner_sheet.dart';
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/widgets/music_listtile.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/screens/auth/login_screen.dart';
import 'package:nuance/screens/playlist_screen.dart';
import 'package:nuance/services/all_services.dart';
import 'package:nuance/services/guest_quota_service.dart';
import 'package:nuance/services/sonic_memory_service.dart';
import 'package:nuance/widgets/unlock_nuance_modal.dart';
import 'package:nuance/widgets/tune_soundscape_modal.dart';
import 'package:nuance/utils/theme.dart';
import 'package:nuance/utils/constants.dart';
import 'package:nuance/widgets/custom_dialog.dart';
import 'package:nuance/widgets/custom_divider.dart';
import 'package:nuance/widgets/custom_drawer.dart';
import 'package:nuance/widgets/general_button.dart';
import 'package:nuance/widgets/generate_playlist_card.dart';
import 'package:nuance/widgets/myindicator.dart';
import 'package:nuance/widgets/spotify_playlist_card.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nuance/providers/history_provider.dart';

final GlobalKey<ScaffoldState> globalKey = GlobalKey();

class HomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _controller = TextEditingController(text: '');
  final _tagQuery = TextEditingController();
  final _generatedRecQuery = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _openVibeCamPicker() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF14141B).withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: const Color(0xFFFF7043).withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "📸 VIBE CAM",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Snap your atmosphere, lighting, and scene into a tailored soundscape",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7043).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.camera_fill,
                    color: Color(0xFFFF7043)),
              ),
              title: const Text(
                "Take Photo",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                "Capture current room, view, or atmosphere",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () async {
                Navigator.of(ctx).pop();
                final file =
                    await VibeCamService().pickImage(ImageSource.camera);
                if (file != null && mounted) {
                  final bytes = await file.readAsBytes();
                  VibeCamScannerSheet.show(context, imageBytes: bytes);
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE040FB).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.photo_fill_on_rectangle_fill,
                    color: Color(0xFFE040FB)),
              ),
              title: const Text(
                "Choose from Library / Files",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                "Select existing photo, sunset, or aesthetic scene",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () async {
                Navigator.of(ctx).pop();
                final file =
                    await VibeCamService().pickImage(ImageSource.gallery);
                if (file != null && mounted) {
                  final bytes = await file.readAsBytes();
                  VibeCamScannerSheet.show(context, imageBytes: bytes);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVibeCamFeatureCard() {
    return GestureDetector(
      onTap: _openVibeCamPicker,
      child: Container(
        margin: const EdgeInsets.only(bottom: 25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2A1635),
              Color(0xFF140D1E),
              Color(0xFF0F0B18),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFE040FB).withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE040FB).withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFF7043).withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF7043), Color(0xFFE040FB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFE040FB).withValues(alpha: 0.4),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.camera_viewfinder,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE040FB)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFE040FB)
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: const Text(
                                  "VISION ➜ SOUND",
                                  style: TextStyle(
                                    color: Color(0xFFFF80AB),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Vibe Cam",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Snap room atmosphere, lighting & mood into a soundscape",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_right,
                      color: Colors.white60,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int currentPage = 1;
  bool isLoading = false;
  bool isMoreLoading = false;
  List<dynamic> recommendations = [];
  List<dynamic> tags = [];
  int _remainingGuestGenerations = 3;

  @override
  void initState() {
    super.initState();
    recommendations.clear();
    tags.clear();
    _scrollController.addListener(_onScroll);
    _loadGuestQuota();
    _fetchRecommendations();
  }

  Future<void> _loadGuestQuota() async {
    final remaining = await GuestQuotaService().getRemainingGenerations();
    if (mounted) {
      setState(() => _remainingGuestGenerations = remaining);
    }
  }

  List<dynamic> _interleaveDiversePrompts(List<dynamic> rawPrompts) {
    if (rawPrompts.length <= 1) return rawPrompts;

    final Map<String, List<dynamic>> buckets = {};
    for (var p in rawPrompts) {
      final cat = (p is Map ? p['category'] : null)?.toString() ?? 'vibe';
      buckets.putIfAbsent(cat, () => []).add(p);
    }

    final List<dynamic> result = [];
    String? lastCategory;

    while (buckets.values.any((list) => list.isNotEmpty)) {
      String? selectedKey;
      for (var key in buckets.keys) {
        if (buckets[key]!.isNotEmpty && key != lastCategory) {
          selectedKey = key;
          break;
        }
      }

      selectedKey ??= buckets.keys.firstWhere((k) => buckets[k]!.isNotEmpty);
      final item = buckets[selectedKey]!.removeAt(0);
      result.add(item);
      lastCategory = selectedKey;
    }

    return result;
  }

  @override
  void dispose() {
    recommendations.clear();
    tags.clear();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchMoreRecommendations();
    }
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      recommendations.clear();
      tags.clear();
      isLoading = true;
    });
    try {
      final discover = await AllServices().getGeminiDiscover();
      final geminiPrompts = discover['prompts'] as List<dynamic>? ?? [];
      final geminiTags = discover['tags'] as List<dynamic>? ?? [];

      if (mounted) {
        setState(() {
          recommendations = _interleaveDiversePrompts(geminiPrompts);
          tags = List.from(geminiTags);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching Gemini dynamic discover: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMoreRecommendations() async {
    if (isMoreLoading) return;

    setState(() {
      isMoreLoading = true;
    });

    try {
      final discover = await AllServices().getGeminiDiscover();
      final morePrompts = discover['prompts'] as List<dynamic>? ?? [];
      if (morePrompts.isNotEmpty && mounted) {
        final interleaved = _interleaveDiversePrompts(morePrompts);
        setState(() {
          recommendations.addAll(interleaved);
          currentPage++;
          isMoreLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint("More Gemini cards error: $e");
    } finally {
      if (mounted) {
        setState(() {
          isMoreLoading = false;
        });
      }
    }
  }

  Future onRefresh() async {
    setState(() {
      ref.invalidate(historyProvider);
      tags.clear();
      recommendations.clear();
    });

    await _fetchRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);

    final List<LinearGradient> cardGradients = List.generate(
      recommendations.length,
      (index) => gradients[math.Random().nextInt(gradients.length)],
    );
    final focusNode = FocusNode();
    void submit(String type, {String? image, int? bpm, String? energy}) async {
      focusNode.unfocus();
      String? tagQuery;
      String? generatedRecQuery;

      final isGuest = sessionState.value?.isGuest == true;
      if (isGuest && _remainingGuestGenerations <= 0) {
        UnlockNuanceModal.show(
          context,
          title: 'Guest Trial Complete',
          subtitle:
              'You have enjoyed your 3 free guest soundscapes. Sign in for free to unlock unlimited creations & cloud library sync.',
        );
        return;
      }

      if (type == 'userMessage') {
        final promptText = _controller.text.trim();
        if (promptText.isEmpty) {
          return;
        }

        TuneSoundscapeModal.show(
          context,
          prompt: promptText,
          onConfirm: (params) async {
            if (isGuest) {
              await GuestQuotaService().consumeGeneration();
              _loadGuestQuota();
            }
            SonicMemoryService().recordPrompt(promptText);
            final enriched = params.buildEnrichedQuery(promptText);
            Get.to(() => PlaylistScreen(
                  searchQuery: enriched,
                  tagQuery: null,
                  imageUrl: image,
                  sessionState: sessionState,
                ));
          },
        );
        return;
      }

      if (isGuest) {
        await GuestQuotaService().consumeGeneration();
        _loadGuestQuota();
      }

      if (type == 'tagQuery') {
        tagQuery = _tagQuery.text;
        if (tagQuery.isEmpty) {
          return;
        }
        SonicMemoryService().recordPrompt(tagQuery);
        Get.to(() => PlaylistScreen(
              searchQuery: null,
              tagQuery: tagQuery,
              imageUrl: image,
              sessionState: sessionState,
            ));
      } else if (type == 'generatedRecQuery') {
        generatedRecQuery = _generatedRecQuery.text;
        if (generatedRecQuery.isEmpty) {
          return;
        }
        SonicMemoryService().recordPrompt(generatedRecQuery);
        final finalQuery = (bpm != null && energy != null)
            ? '$generatedRecQuery (~$bpm BPM $energy)'
            : generatedRecQuery;
        Get.to(() => PlaylistScreen(
              searchQuery: finalQuery,
              tagQuery: null,
              imageUrl: image,
              sessionState: sessionState,
            ));
      }
    }

    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          key: globalKey,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          drawerEnableOpenDragGesture: true,
          drawer: MyCustomDrawer(sessionState: sessionState),
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: sessionState.when(
              data: (data) {
                final userMetadata =
                    data?.user["user_metadata"] as Map<String, dynamic>?;
                final rawName = userMetadata?["full_name"]?.toString() ??
                    data?.user["name"]?.toString() ??
                    (data?.isGuest == true ? "Guest" : "User");
                final firstName = rawName.trim().isNotEmpty
                    ? rawName.trim().split(" ").first
                    : (data?.isGuest == true ? "Guest" : "User");

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Animate(
                          effects: const [
                            MoveEffect(
                              begin: Offset(0, -5),
                              end: Offset(0, 0),
                              delay: Duration(
                                milliseconds: 2000,
                              ),
                              duration: Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                            ),
                            FadeEffect(
                              begin: 0.0,
                              end: 1.0,
                            ),
                          ],
                          child: Text(
                            'Welcome',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade500,
                                ),
                          ),
                        ),
                        Animate(
                          effects: const [
                            MoveEffect(
                              begin: Offset(0, -5),
                              end: Offset(0, 0),
                              duration: Duration(
                                seconds: 2,
                              ),
                              delay: Duration(
                                milliseconds: 2500,
                              ),
                              curve: Curves.easeOut,
                            ),
                            FadeEffect(
                              begin: 0.0,
                              end: 1.0,
                            ),
                          ],
                          child: Text(
                            ' $firstName',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade500,
                                ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Animate(
                          effects: const [
                            MoveEffect(
                              begin: Offset(0, -5),
                              end: Offset(0, 0),
                              duration: Duration(milliseconds: 500),
                              delay: Duration(milliseconds: 3500),
                              curve: Curves.easeOut,
                            ),
                            FadeEffect(
                              begin: 0.0,
                              end: 1.0,
                            ),
                          ],
                          child: Text(
                            'Discover',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                        Animate(
                          effects: const [
                            MoveEffect(
                              begin: Offset(0, -5),
                              end: Offset(0, 0),
                              duration: Duration(
                                milliseconds: 500,
                              ),
                              delay: Duration(
                                milliseconds: 4000,
                              ),
                              curve: Curves.easeOut,
                            ),
                            FadeEffect(
                              begin: 0.0,
                              end: 1.0,
                            ),
                          ],
                          child: Text(
                            ' Playlists',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => Center(
                child: Text('Loading...',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              error: (error, stack) => Text('Error loading user data',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            actions: [
              if (sessionState.value?.isGuest == true)
                GestureDetector(
                  onTap: () => UnlockNuanceModal.show(context),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8, top: 12, bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kUiGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kUiGreen.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.bolt_fill, size: 12, color: kUiGreen),
                        const SizedBox(width: 4),
                        Text(
                          '$_remainingGuestGenerations Free',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              circularAvatar(sessionState, ref),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Stack(children: [
            Container(
              child: recommendations.isEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.only(top: 24),
                      itemCount: 30,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          child: Shimmer.fromColors(
                            baseColor: const Color.fromARGB(51, 255, 255, 255),
                            highlightColor:
                                const Color.fromARGB(65, 255, 255, 255),
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              height: 190,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ).marginOnly(bottom: 25),
                          ),
                        );
                      },
                    )
                  : CheckMarkIndicator(
                      onRefresh: onRefresh,
                      child: RawScrollbar(
                        fadeDuration: 500.ms,
                        radius: const Radius.circular(20),
                        timeToFade: 500.ms,
                        trackBorderColor: Colors.grey,
                        controller: _scrollController,
                        interactive: true,
                        child: ListView.builder(
                          itemCount: recommendations.length + 2,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _buildVibeCamFeatureCard();
                            }
                            final recIndex = index - 1;
                            if (recIndex < recommendations.length) {
                              final recommendation = recommendations[recIndex];
                              if (recommendation is SongModel) {
                                return MusicListTile(
                                  recommendation: recommendation,
                                  isPlaying: false,
                                  isSelected: false,
                                  onTap: () {},
                                );
                              } else if (recommendation is Map &&
                                  (recommendation['type'] == 'playlist' ||
                                      recommendation['type'] == 'playlists')) {
                                // Check if it's an Apple Music playlist
                                if (recommendation.containsKey('attributes')) {
                                  // Apple Music playlist
                                  final attributes =
                                      recommendation['attributes'];
                                  return PlaylistCard(
                                    trackListHref: attributes['playParams'][
                                        'id'], // Use playParams id for Apple Music
                                    playlistId: recommendation['id'],
                                    playlistName: attributes[
                                        'name'], // Access name from attributes
                                    artistNames: attributes['curatorName'] ??
                                        '', // Use curatorName or fallback
                                    onClick: () {
                                      log("RECOMMENDATION: ${attributes['url']}");
                                      Get.to(
                                        PlaylistScreen(
                                          sessionState: sessionState,
                                          searchTitle: attributes['name'],
                                          playlistId: recommendation['id'],
                                          playlistUrl: attributes[
                                              'url'], // Use the URL from attributes
                                        ),
                                      );
                                    },
                                  ).marginOnly(bottom: 25);
                                } else {
                                  // Spotify playlist
                                  return PlaylistCard(
                                    trackListHref: recommendation['tracks']
                                        ['href'],
                                    playlistId: recommendation['id'],
                                    playlistName: recommendation['name'],
                                    artistNames: recommendation['description'],
                                    onClick: () {
                                      log("RECOMMENDATION: ${recommendation['external_urls']['spotify']}");
                                      Get.to(
                                        PlaylistScreen(
                                          sessionState: sessionState,
                                          searchTitle: recommendation['name'],
                                          playlistId: recommendation['id'],
                                          playlistUrl:
                                              recommendation['external_urls']
                                                  ['spotify'],
                                        ),
                                      );
                                    },
                                  ).marginOnly(bottom: 25);
                                }
                              } else {
                                return GeneratePlaylistCard(
                                  prompt: recommendation['text'],
                                  image: recommendation['image'],
                                  category: recommendation['category']?.toString(),
                                  initialBpm: recommendation['bpm'] is int
                                      ? recommendation['bpm']
                                      : (int.tryParse(recommendation['bpm']?.toString() ?? '') ?? 95),
                                  initialEnergy: recommendation['energy']?.toString(),
                                  gradient: cardGradients[recIndex % cardGradients.length],
                                  onGenerate: (bpm, energy) {
                                    _generatedRecQuery.text =
                                        recommendation['text'];
                                    submit('generatedRecQuery',
                                        image: recommendation['image'],
                                        bpm: bpm,
                                        energy: energy);
                                  },
                                ).marginOnly(bottom: 25);
                              }
                            } else {
                              return const Center(
                                child: CupertinoActivityIndicator(
                                  color: Colors.white,
                                ),
                              );
                            }
                          },
                          padding: const EdgeInsets.only(
                              bottom: 200, left: 20, right: 20, top: 20),
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                        ),
                      ),
                    ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.black,
                height: 150,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: tags.isNotEmpty
                          ? ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                final List<Color> colors = [
                                  const Color(0xffFFBB00),
                                  const Color(0xffFF4500),
                                  const Color(0xffFF006D),
                                  const Color(0xff8E33F5),
                                  const Color(0xff0088FF),
                                ];
                                final Color randomColor = colors[
                                    math.Random().nextInt(colors.length)];
                                return InkWell(
                                  onTap: () {
                                    _tagQuery.text = tags[index];
                                    submit('tagQuery');
                                  },
                                  child: Chip(
                                    side: BorderSide.none,
                                    avatar: SvgPicture.asset(
                                        "assets/icon4star.svg",
                                        color: randomColor),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    label: Text(tags[index]),
                                    backgroundColor: Colors.grey[900],
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                  ),
                                );
                              },
                              separatorBuilder: (context, index) {
                                return const SizedBox(width: 5);
                              },
                              itemCount: tags.length,
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemCount: 5, // Number of shimmer items
                              itemBuilder: (context, index) {
                                return Shimmer.fromColors(
                                  baseColor:
                                      const Color.fromARGB(51, 255, 255, 255),
                                  highlightColor:
                                      const Color.fromARGB(65, 255, 255, 255),
                                  child: Chip(
                                    side: BorderSide.none,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    label: const Text("Loading..."),
                                    backgroundColor: Colors.grey[900],
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                  ),
                                );
                              },
                              separatorBuilder: (context, index) {
                                return const SizedBox(width: 5);
                              },
                            ),
                    ),
                    const CustomDivider(),
                    const SizedBox(height: 5),
                    AnimatedTextField(
                      animationDuration: const Duration(seconds: 2),
                      animationType: Animationtype.slide,
                      focusNode: focusNode,
                      onTapOutside: (event) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      controller: _controller,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(
                            borderSide: BorderSide.none),
                        filled: false,
                        suffixIcon: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _openVibeCamPicker,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF7043),
                                        Color(0xFFE040FB)
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE040FB)
                                            .withValues(alpha: 0.45),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.camera_fill,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                              GeneralButton(
                                text: "Generate",
                                backgroundColor: Colors.white,
                                onPressed: () {
                                  submit('userMessage');
                                },
                              ),
                            ],
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      hintTextStyle: const TextStyle(
                        color: Color(0xFFFAFAFA),
                        fontSize: 14,
                      ),
                      style: const TextStyle(
                        color: Color(0xFFFAFAFA),
                        fontSize: 14,
                      ),
                      hintTexts: const [
                        'What do you like to listen to?',
                        'Songs like Owl City Fireflies',
                        '1970\'s RnB For Long Drives',
                        'Songs to Help Me Sleep',
                      ],
                      onSubmitted: (value) {
                        submit('userMessage');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    ),
  ),
);
  }
}

Padding circularAvatar(AsyncValue<SessionData?> sessionState, WidgetRef ref) {
  return Padding(
    padding: const EdgeInsets.only(right: 15),
    child: sessionState.when(
      data: (data) {
        if (data == null) {
          // IN THIS STATE THE USER IS SIGNED OUT
          return GestureDetector(
            child: Container(
              width: 40.0,
              height: 40.0,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 215, 129, 0),
                    Color.fromARGB(255, 255, 222, 59),
                  ],
                ),
                color: Colors.orange,
              ),
            ),
            onTap: () {
              // OPEN A dialog to sign them back in
              Get.dialog(
                ConfirmDialog(
                  heading: 'Sign in',
                  subtitle:
                      "You are currently signed out. Would you like to sign in?",
                  confirmText: "Sign in",
                  onConfirm: () {
                    Get.back();
                    Get.offAll(() => const LoginScreen());
                  },
                ),
              );
            },
          );
        }

        final userMetadata =
            data.user["user_metadata"] as Map<String, dynamic>?;
        final avatarUrl = userMetadata?["avatar_url"]?.toString() ?? "";
        final fullName = userMetadata?["full_name"]?.toString() ??
            data.user["name"]?.toString() ??
            (data.isGuest ? "Guest Listener" : "Nuance User");
        final initialLetter = fullName.isNotEmpty
            ? fullName.substring(0, 1).toUpperCase()
            : (data.isGuest ? "G" : "N");

        Widget avatarWidget;
        if (avatarUrl.isNotEmpty) {
          avatarWidget = CachedNetworkImage(
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
            height: 40,
            imageUrl: avatarUrl,
            placeholder: (context, url) => const Center(
              child: CupertinoActivityIndicator(color: AppTheme.textColor),
            ),
            errorWidget: (context, url, error) => Container(
              width: 40.0,
              height: 40.0,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange,
                    Color.fromARGB(255, 255, 222, 59),
                    Color.fromARGB(255, 225, 153, 47),
                    Colors.red,
                  ],
                ),
                color: Colors.orange,
              ),
              child: Center(
                child: Text(
                  initialLetter,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        } else {
          avatarWidget = Container(
            width: 40.0,
            height: 40.0,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange,
                  Color.fromARGB(255, 255, 222, 59),
                  Color.fromARGB(255, 225, 153, 47),
                  Colors.red,
                ],
              ),
              color: Colors.orange,
            ),
            child: Center(
              child: Text(
                initialLetter,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
          );
        }

        return CupertinoButton(
          padding: const EdgeInsets.all(0),
          onPressed: () {
            globalKey.currentState!.openDrawer();
            ref.invalidate(historyProvider);
          },
          child: avatarWidget,
        );
      },
      loading: () => const Center(
        child: CupertinoActivityIndicator(color: AppTheme.textColor),
      ),
      error: (error, stack) => GestureDetector(
        child: Container(
          width: 40.0,
          height: 40.0,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange,
          ),
        ),
        onTap: () {
          globalKey.currentState!.openDrawer();
        },
      ),
    ),
  );
}
