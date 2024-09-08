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
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/providers/home_recommedations_provider.dart';
import 'package:nuance/providers/recommendation_tags_provider.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/screens/playlist_screen.dart';
import 'package:nuance/services/all_services.dart';
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

  int currentPage = 1;
  bool isLoading = false;
  bool isMoreLoading = false;
  List<dynamic> recommendations = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchRecommendations();
  }

  @override
  void dispose() {
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
      isLoading = true;
    });
    try {
      final newRecommendations =
          await ref.read(spotifyHomeRecommendationsProvider.future);

      setState(() {
        recommendations = List.from(newRecommendations);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("ERROR initial fetch: $e");
      throw Exception('Failed to load intial recommendations');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchMoreRecommendations() async {
    if (isMoreLoading) return;

    setState(() {
      isMoreLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final sessionData = await authService.getSessionData();

      if (sessionData == null) {
        throw Exception('User not authenticated');
      }

      final accessToken = sessionData['access_token'];

      final newRecommendations =
          await AllServices().getSpotifyHomeRecommendations(accessToken);

      setState(() {
        recommendations = List.from(recommendations)
          ..addAll(newRecommendations); // Append new recommendations
        currentPage++;
        isMoreLoading = false;
      });
    } catch (e) {
      debugPrint("ERROR extra fetch: $e");
      throw Exception('Failed to load more recommendations');
    } finally {
      setState(() {
        isMoreLoading = false;
      });
    }
  }

  Future onRefresh() async {
    setState(() {
      ref.invalidate(spotifyHomeRecommendationsProvider);
      ref.invalidate(historyProvider);
    });

    await Future.delayed(const Duration(seconds: 2));
    _fetchRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);

    final tagsRecommendations = ref.watch(recommendationTagsProvider);

    final List<LinearGradient> cardGradients = List.generate(
      recommendations.length,
      (index) => gradients[math.Random().nextInt(gradients.length)],
    );
    final focusNode = FocusNode();
    void submit(String type) {
      focusNode.unfocus();
      String? userMessage;
      String? tagQuery;
      String? generatedRecQuery;

      if (type == 'userMessage') {
        userMessage = _controller.text;
        if (userMessage.isEmpty) {
          return;
        }
        Get.to(() => PlaylistScreen(
              searchQuery: userMessage!.trim(),
              tagQuery: null,
              sessionState: sessionState,
            ));
      } else if (type == 'tagQuery') {
        tagQuery = _tagQuery.text;
        if (tagQuery.isEmpty) {
          return;
        }
        Get.to(() => PlaylistScreen(
              searchQuery: null,
              tagQuery: tagQuery,
              sessionState: sessionState,
            ));
      } else if (type == 'generatedRecQuery') {
        generatedRecQuery = _generatedRecQuery.text;
        if (generatedRecQuery.isEmpty) {
          return;
        }
        Get.to(() => PlaylistScreen(
              searchQuery: generatedRecQuery,
              tagQuery: null,
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
                            ' ${data?.user["user_metadata"]["full_name"].split(" ")[0]}',
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
            automaticallyImplyLeading: false,
            centerTitle: false,
            actions: [
              circularAvatar(sessionState, ref),
            ],
          ),
          body: Stack(children: [
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
                          itemCount: recommendations.length + 1,
                          itemBuilder: (context, index) {
                            if (index < recommendations.length) {
                              final recommendation = recommendations[index];
                              if (recommendation['type'] == 'playlist') {
                                return SpotifyPlaylistCard(
                                  trackListHref: recommendation['tracks']
                                      ['href'],
                                  playlistId: recommendation['id'],
                                  playlistName: recommendation['name'],
                                  artistNames: recommendation['description'],
                                  onClick: () {
                                    log("RECOMMEDATION: ${recommendation['external_urls']['spotify']}");
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
                              } else {
                                return GeneratePlaylistCard(
                                  prompt: recommendation['text'],
                                  image: recommendation['image'],
                                  gradient: cardGradients[index],
                                  onClick: () {
                                    _generatedRecQuery.text =
                                        recommendation['text'];
                                    submit('generatedRecQuery');
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
                      child: tagsRecommendations.when(
                        data: (data) {
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              final Color randomColor =
                                  colors[math.Random().nextInt(colors.length)];
                              return InkWell(
                                onTap: () {
                                  _tagQuery.text = data[index];
                                  submit('tagQuery');
                                },
                                child: Chip(
                                  side: BorderSide.none,
                                  avatar: SvgPicture.asset(
                                      "assets/icon4star.svg",
                                      color: randomColor),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  label: Text(data[index]),
                                  backgroundColor: Colors.grey[900],
                                  labelStyle:
                                      const TextStyle(color: Colors.white),
                                ),
                              );
                            },
                            separatorBuilder: (context, index) {
                              return const SizedBox(width: 5);
                            },
                            itemCount: data.length,
                          );
                        },
                        error: (error, stackTrace) {
                          return Center(
                            child: Text(
                              "Error loading tags",
                              style: subtitleTextStyle.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                        loading: () {
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: 9,
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
                                  label: const Text("             "),
                                  backgroundColor: Colors.grey[900],
                                  labelStyle:
                                      const TextStyle(color: Colors.white),
                                ),
                              );
                            },
                            separatorBuilder: (context, index) {
                              return const SizedBox(width: 5);
                            },
                          );
                        },
                      ),
                    ),
                    const CustomDivider(),
                    const SizedBox(height: 5),
                    AnimatedTextField(
                      animationDuration: const Duration(milliseconds: 98000),
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
                          child: GeneralButton(
                            text: "Generate",
                            backgroundColor: Colors.white,
                            onPressed: () {
                              submit('userMessage');
                            },
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
                  },
                ),
              );
            },
          );
        }
        return CupertinoButton(
          padding: const EdgeInsets.all(0),
          onPressed: () {
            globalKey.currentState!.openDrawer();

            ref.invalidate(historyProvider);
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
              child: CupertinoActivityIndicator(color: AppTheme.textColor),
            ),
            errorWidget: (context, url, error) => GestureDetector(
              child: Container(
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
                    data.user["user_metadata"]["full_name"]
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              onTap: () {
                globalKey.currentState!.openDrawer();
              },
            ),
          ),
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
