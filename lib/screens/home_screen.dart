import 'dart:developer';
import 'dart:math' as math;

import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:nuance/models/history_model.dart';
import 'package:nuance/providers/home_recommedations_provider.dart';
import 'package:nuance/providers/recommendation_tags_provider.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/screens/recommendations_result_screen.dart';
import 'package:nuance/theme.dart';
import 'package:nuance/utils/constants.dart';
import 'package:nuance/widgets/custom_divider.dart';
import 'package:nuance/widgets/custom_drawer.dart';
import 'package:nuance/widgets/general_button.dart';
import 'package:nuance/widgets/generate_playlist_card.dart';
import 'package:nuance/widgets/myindicator.dart';
import 'package:nuance/widgets/spotify_playlist_card.dart';
// import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
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
  // final GlobalKey<ScaffoldState> _key = GlobalKey();
  // final RefreshController _refreshController =
  //     RefreshController(initialRefresh: false);
  // final focusNode = FocusNode();

  final ScrollController _scrollController = ScrollController();

  int currentPage = 1; // Track current page number
  bool isLoading = false; // Track loading state
  bool isMoreLoading = true; // Track loading state for pagination
  List<dynamic> recommendations = []; // List to store recommendations
  // final sessionState = ref.watch(sessionProvider);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    Future.delayed(Duration.zero, () {
      // this._getCategories();
      // ref.invalidate(historyProvider);
    });
    _fetchRecommendations();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the scroll controller
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      print("IsLoaiding before fetching more recommedations on scroll!!!!!!!");
      _fetchMoreRecommendations();
    }
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      recommendations.clear();
      isLoading = true;
    });
    //    Future.delayed(Duration.zero, () {
    //     // this._getCategories();
    //   ref.invalidate(historyProvider);
    //  });
    try {
      final newRecommendations =
          await ref.read(spotifyHomeRecommendationsProvider.future);
      setState(() {
        recommendations = newRecommendations;
        isLoading = false;
      });
      log("Recommendations: $recommendations");
    } catch (e) {
      rethrow;
    } finally {
      // print('Error loading recommendations: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchMoreRecommendations() async {
    if (currentPage >= 14) return;
    print("Current page is $currentPage");

    setState(() {
      isMoreLoading = true;
    });
    try {
      final newRecommendations =
          await ref.read(spotifyHomeRecommendationsProvider.future);
      setState(() {
        recommendations = List.from(recommendations)
          ..addAll(newRecommendations);
        currentPage++;
        isMoreLoading = false;
      });
      print({newRecommendations});
    } catch (e) {
      log('Error loading more recommendations: $e');
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

    // await Future.delayed(const Duration(seconds: 6));
    // _refreshController.refreshCompleted();
    _fetchRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);
    final sessionData = ref.read(sessionProvider.notifier);
    final homeRecommendations = ref.watch(spotifyHomeRecommendationsProvider);
    final tagsRecommendations = ref.watch(recommendationTagsProvider);
    // ref.invalidate(historyProvider);
    final focusNode = FocusNode();

    void submit() {
      focusNode.unfocus();
      final userMessage = _controller.text;
      // final tagQuery = _tagQuery.text;
      if (userMessage.isEmpty) {
        return;
      }

      // Navigator.pushNamed(
      //   context,
      //   RecommendationsResultScreen.routeName,
      //   arguments: {
      //     'search_term': userMessage.trim(),
      //     'tag_query': tagQuery,
      //     'sessionState': sessionState,
      //   },
      // ).then((value) => setState(() {}));

      Get.to(() => RecommendationsResultScreen(
            searchQuery: userMessage.trim(),
            tagQuery: null,
            sessionState: sessionState,
          ));
    }

    void submitTagQuery() {
      focusNode.unfocus();
      // final userMessage = _controller.text;
      final tagQuery = _tagQuery.text;
      if (tagQuery.isEmpty) {
        return;
      }
      Get.to(() => RecommendationsResultScreen(
            searchQuery: null,
            tagQuery: tagQuery,
            sessionState: sessionState,
          ));
    }

    void submitGeneratedQuery() {
      focusNode.unfocus();
      // final userMessage = _controller.text;
      final generatedRecQuery = _generatedRecQuery.text;
      if (generatedRecQuery.isEmpty) {
        return;
      }

      // Navigator.pushNamed(
      //   context,
      //   RecommendationsResultScreen.routeName,
      //   arguments: {
      //     'search_term': userMessage.trim(),
      //     'tag_query': tagQuery,
      //     'sessionState': sessionState,
      //   },
      // ).then((value) => setState(() {}));

      Get.to(() => RecommendationsResultScreen(
            searchQuery: generatedRecQuery,
            tagQuery: null,
            sessionState: sessionState,
          ));
    }

    // final historyAsyncValue = ref.watch(historyProvider);

    final historyProviderRef = ref.watch(historyProvider);
    final List<HistoryModel>? historyList = historyProviderRef.value;
    String? lastGeneratedQuery = historyList != null && historyList.isNotEmpty
        ? historyList.first.searchQuery
        : '';

    // Sort the history list in ascending order based on searchQuery
    // historyList?.sort((a, b) => a.searchQuery!.compareTo(b.searchQuery!));
    print("LAST GEENRATED HERW!!!!!: $lastGeneratedQuery");

    // Add a method to compare the last generated query with the new input query
    void compareAndConfirmQuery(
        String lastQuery, String newQuery, void Function() submit) {
      print("LAST QUERY: $lastQuery");
      print("NEW QUERY: $newQuery");
      ref.invalidate(historyProvider);
      if (lastQuery == newQuery) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                'You just generated a similar playlist',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              content: Text(
                'Are you sure you want to regenerate the same playlist? You can check your history for previously created playlists',
                style: subtitleTextStyle,
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Get.back();
                    globalKey.currentState!.openDrawer();
                  },
                  child: const Text(
                    'Go to history',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    submit(); // Correctly call the submit function
                  },
                  child: const Text(
                    'Regenerate',
                  ),
                ),
              ],
            );
          },
        );
      } else {
        submit(); // Correctly call the submit function
      }
    }

    return WillPopScope(
      onWillPop: () async {
        return true;
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
                if (data == null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Discover Playlists',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Animate(
                          effects: const [
                            MoveEffect(
                              begin: Offset(0, -5), // Move down from 10px above
                              end: Offset(0, 0),
                              duration: Duration(
                                  milliseconds:
                                      500), // Duration of the animation
                              curve: Curves.easeOut, // Smooth transition
                            ),
                            FadeEffect(
                              begin: 0.0,
                              end: 1.0,
                              duration: Duration(milliseconds: 500),
                              curve: Curves.easeOut,
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
                              begin: Offset(0, -5), // Move down from 10px above
                              end: Offset(0, 0),
                              duration: Duration(
                                  milliseconds:
                                      500), // Duration of the animation
                              delay: Duration(
                                  milliseconds:
                                      500), // Delay for the second animation
                              curve: Curves.easeOut, // Smooth transition
                            ),
                            FadeEffect(
                              begin: 0.0,
                              end: 1.0,
                              duration: Duration(milliseconds: 500),
                              delay: Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                            ),
                          ],
                          child: Text(
                            ' ${data.user["user_metadata"]["full_name"].split(" ")[0]}',
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
                              begin: Offset(0, -5), // Move down from 10px above
                              end: Offset(0, 0),
                              duration: Duration(
                                  milliseconds:
                                      500), // Duration of the animation
                              delay: Duration(
                                  milliseconds:
                                      1000), // Delay for the third animation
                              curve: Curves.easeOut, // Smooth transition
                            ),
                            FadeEffect(
                              begin: 0.0,
                              end: 1.0,
                              duration: Duration(milliseconds: 500),
                              delay: Duration(milliseconds: 1000),
                              curve: Curves.easeOut,
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
                              begin: Offset(0, -5), // Move down from 10px above
                              end: Offset(0, 0),
                              duration: Duration(
                                  milliseconds:
                                      500), // Duration of the animation
                              delay: Duration(
                                  milliseconds:
                                      1500), // Delay for the fourth animation
                              curve: Curves.easeOut, // Smooth transition
                            ),
                            FadeEffect(
                              begin: 0.0,
                              end: 1.0,
                              duration: Duration(milliseconds: 500),
                              delay: Duration(milliseconds: 1500),
                              curve: Curves.easeOut,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: sessionState.when(
                  data: (data) {
                    if (data == null) {
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
                                Colors.orange,
                                Color.fromARGB(255, 255, 222, 59),
                                Color.fromARGB(255, 225, 153, 47),
                                Colors.red,
                              ],
                            ),
                            color: Colors.orange,
                          ),
                        ),
                        onTap: () {
                          globalKey.currentState!.openDrawer();
                          // sessionData.logout();
                        },
                      );
                    }
                    return CupertinoButton(
                      padding: const EdgeInsets.all(0),
                      onPressed: () {
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
                        imageUrl:
                            data.user["user_metadata"]["avatar_url"] ?? "",
                        placeholder: (context, url) => const Center(
                          child: CupertinoActivityIndicator(
                              color: AppTheme.textColor),
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
                            // sessionData.logout();
                          },
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child:
                        CupertinoActivityIndicator(color: AppTheme.textColor),
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
                      // sessionData.logout();
                    },
                  ),
                ),
              ),
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
                      // backgroundColor: Colors.transparent,
                      onRefresh: onRefresh,
                      // indicatorBuilder: (context, controller) {
                      //   return CheckMarkIndicator(
                      //     child: Container(
                      //       height: 40,
                      //       width: 40,
                      //       decoration: const BoxDecoration(
                      //         color: Colors.transparent,
                      //         shape: BoxShape.circle,
                      //       ),
                      //       // color: Colors.white,
                      //       alignment: Alignment.center,
                      //       child: Image.asset(
                      //         "assets/whitelogo.png",
                      //         color: Colors.white,
                      //       ),
                      //     ),
                      //   );
                      // },
                      // triggerMode: RefreshIndicatorTriggerMode.anywhere,
                      // displacement: 100,
                      // color: Colors.white,

                      // enablePullDown: true,
                      // onRefresh: onRefresh,
                      // controller: _refreshController,

                      child: RawScrollbar(
                        fadeDuration: 500.ms,
                        radius: const Radius.circular(20),
                        timeToFade: 500.ms,
                        trackBorderColor: Colors.grey,
                        controller: _scrollController,
                        thumbVisibility: true,
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
                                    Get.to(RecommendationsResultScreen(
                                      sessionState: sessionState,
                                      searchTitle: recommendation['name'],
                                      playlistId: recommendation['id'],
                                    ));
                                  },
                                ).marginOnly(bottom: 25);
                              } else {
                                return GeneratePlaylistCard(
                                  prompt: recommendation['text'],
                                  image: recommendation['image'],
                                  onClick: () {
                                    _generatedRecQuery.text =
                                        recommendation['text'];
                                    compareAndConfirmQuery(
                                      lastGeneratedQuery ?? "",
                                      _generatedRecQuery.text,
                                      submitGeneratedQuery,
                                    );
                                  },
                                ).marginOnly(bottom: 25);
                              }
                            }
                            // return null;
                            else {
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
                      // loading: () => ListView.builder(
                      //   padding: const EdgeInsets.only(top: 24),
                      //   itemCount: 30,
                      //   itemBuilder: (context, index) {
                      //     return SizedBox(
                      //       child: Shimmer.fromColors(
                      //         baseColor: const Color.fromARGB(51, 255, 255, 255),
                      //         highlightColor:
                      //             const Color.fromARGB(65, 255, 255, 255),
                      //         child: Container(
                      //           margin:
                      //               const EdgeInsets.symmetric(horizontal: 20),
                      //           height: 190,
                      //           decoration: BoxDecoration(
                      //             color: Colors.grey,
                      //             borderRadius: BorderRadius.circular(25),
                      //           ),
                      //         ).marginOnly(bottom: 25),
                      //       ),
                      //     );
                      //   },
                      // ),
                      // error: (error, stackTrace) => Center(
                      //   child: Text(
                      //     'Error loading playlists',
                      //     style: subtitleTextStyle.copyWith(
                      //       color: Colors.white,
                      //     ),
                      //   ),
                      // ),
                      // ,
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
                                  submitTagQuery();
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
                              compareAndConfirmQuery(
                                lastGeneratedQuery ?? "",
                                _controller.text,
                                submit, // Pass the submit function reference
                              );
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
                        compareAndConfirmQuery(
                          lastGeneratedQuery ?? "",
                          _controller.text,
                          submit, // Pass the submit function reference
                        );
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
