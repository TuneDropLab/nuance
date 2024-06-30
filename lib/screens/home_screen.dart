import 'dart:math';
import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:nuance/providers/home_recommedations_provider.dart';
import 'package:nuance/providers/recommendation_tags_provider.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/screens/recommendations_result_screen.dart';
import 'package:nuance/theme.dart';
import 'package:nuance/widgets/custom_divider.dart';
import 'package:nuance/widgets/custom_drawer.dart';
import 'package:nuance/widgets/general_button.dart';
import 'package:nuance/widgets/generate_playlist_card.dart';
import 'package:nuance/widgets/spotify_playlist_card.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:shimmer/shimmer.dart';

// import 'constants.dart'; // Import the constants file

class HomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _controller = TextEditingController(
    text: '',
  );
  final _tagQuery = TextEditingController();
  final _generatedRecQuery = TextEditingController();

  final GlobalKey<ScaffoldState> _key = GlobalKey();

  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);
    final sessionData = ref.read(sessionProvider.notifier);
    final homeRecommendations = ref.watch(spotifyHomeRecommendationsProvider);
    final tagsRecommendations = ref.watch(recommendationTagsProvider);
    final focusNode = FocusNode();

    void onRefresh() async {
      // monitor network fetch
      // await Future.delayed(const Duration(milliseconds: 1000));
      // if failed,use refreshFailed()
      _refreshController.refreshCompleted();
    }

    void onLoading() async {
      // monitor network fetch
      ref.invalidate(spotifyHomeRecommendationsProvider);
      // ref.invalidate(recommendationTagsProvider);

      // await Future.delayed(const Duration(milliseconds: 1000));
      // if (homeRecommendations.value) {
      //   _refreshController.loadNoData();
      //   return;
      // }

      if (mounted) {
        setState(() {});
      }
      _refreshController.loadComplete();
    }

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

    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          key: _key,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          drawerEnableOpenDragGesture: true,
          drawer: const MyCustomDrawer(),
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
                    Text(
                      'Welcome ${data.user["user_metadata"]["full_name"].split(" ")[0]}',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                    ),
                    Text(
                      'Discover Playlists',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                    ),
                  ],
                );
              },
              loading: () => Text(
                'Loading...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              error: (error, stack) => Text(
                'Error loading user data',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            automaticallyImplyLeading: false,
            centerTitle: false,
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: sessionState.when(
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
                        imageUrl:
                            data.user["user_metadata"]["avatar_url"] ?? "",
                        placeholder: (context, url) => const Center(
                          child: CupertinoActivityIndicator(
                            color: AppTheme.textColor,
                          ),
                        ),
                        errorWidget: (context, url, error) => CupertinoButton(
                          child: const CircleAvatar(
                            radius: 40,
                          ),
                          onPressed: () {
                            sessionData.logout();
                          },
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CupertinoActivityIndicator(
                      color: AppTheme.textColor,
                    ),
                  ),
                  error: (error, stack) => CupertinoButton(
                    padding: const EdgeInsets.all(0),
                    onPressed: () {
                      sessionData.logout();
                    },
                    child: const CircleAvatar(
                      radius: 40,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Container(
                // padding: const EdgeInsets.only(bottom: 10),
                child: SmartRefresher(
                  enablePullDown: true,
                  enablePullUp: true,
                  onRefresh: onRefresh,
                  onLoading: onLoading,
                  header: const ClassicHeader(),
                  controller: _refreshController,
                  child: homeRecommendations.when(
                    data: (recommendations) {
                      return ListView.builder(
                        itemCount: recommendations.length,
                        itemBuilder: (context, index) {
                          // log("message");
                          print("RECOMMENDS: ${recommendations.first}");
                          final recommendation = recommendations[index];

                          if (recommendation['type'] == 'playlist') {
                            // Spotify Playlist Card
                            return SpotifyPlaylistCard(
                              trackListHref: recommendation['tracks']['href'],
                              playlistName: recommendation['name'],
                              artistNames: recommendation['description'],
                              onClick: () {
                                // Handle click
                              },
                            ).marginOnly(bottom: 25);
                          } else {
                            // Generate Playlist Card
                            return GeneratePlaylistCard(
                              prompt: recommendation['text'],
                              image: recommendation['image'],
                              onClick: () {
                                // Handle click
                                _generatedRecQuery.text =
                                    recommendation['text'];
                                submitGeneratedQuery();
                              },
                            ).marginOnly(bottom: 25);
                          }
                        },
                        padding: const EdgeInsets.only(
                          bottom: 200,
                          left: 20,
                          right: 20,
                          top: 20,
                        ),
                      );
                    },
                    loading: () => ListView.builder(
                      padding: const EdgeInsets.only(top: 24),
                      itemCount: 30,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          // width: 200.0,
                          // height: 100.0,
                          child: Shimmer.fromColors(
                              baseColor:
                                  const Color.fromARGB(51, 255, 255, 255),
                              highlightColor:
                                  const Color.fromARGB(65, 255, 255, 255),
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                height: 190,
                                // width: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ).marginOnly(bottom: 25)
                              // child: const Text(
                              //   // 'Shimmer',
                              //   textAlign: TextAlign.center,
                              //   style: TextStyle(
                              //     fontSize: 40.0,
                              //     fontWeight: FontWeight.bold,
                              //   ),
                              // ),
                              ),
                        );
                      },
                    ),
                    error: (error, stackTrace) =>
                        Center(child: Text('Error: $error')),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: Colors.black,
                  height: 150,
                  // padding: const EdgeInsets.all(16),
                  // decoration: BoxDecoration(
                  //   // color: Colors.grey[900],
                  //   borderRadius: const BorderRadius.vertical(
                  //     top: Radius.circular(16),
                  //   ),
                  // ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                          // height: 300,
                          // height: 300,
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
                                  colors[Random().nextInt(colors.length)];

                              return InkWell(
                                onTap: () {
                                  _tagQuery.text = data[index];
                                  submitTagQuery();
                                },
                                child: Chip(
                                  side: BorderSide.none,
                                  avatar: SvgPicture.asset(
                                    "assets/icon4star.svg",
                                    color: randomColor,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  label: Text(data[index]),
                                  backgroundColor: Colors.grey[900],
                                  labelStyle:
                                      const TextStyle(color: Colors.white),
                                ),
                              );
                              // return ElevatedButton(
                              //   onPressed: () {},
                              //   style: ElevatedButton.styleFrom(
                              //     backgroundColor: Colors.grey[900],
                              //   ),
                              //   child: Row(
                              //     children: [
                              //       SvgPicture.asset(
                              //         "assets/icon4star.svg",
                              //         color: randomColor,
                              //       ),
                              //       Text(
                              //         data[index],
                              //         style:   const TextStyle(color: Colors.white),
                              //       ),
                              //     ],
                              //   ),
                              // );
                            },
                            separatorBuilder: (context, index) {
                              return const SizedBox(width: 5);
                            },
                            itemCount: 7,
                          );
                        },
                        error: (error, stackTrace) {
                          return Text("error: $error");
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
                                  // avatar: SvgPicture.asset(
                                  //   "assets/icon4star.svg",
                                  //   // color: randomColor,
                                  // ),
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
                      )),
                      const CustomDivider(),
                      const SizedBox(
                        height: 5,
                      ),
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
                                submit();
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
                          // 'Chill Lo-Fi Beats to Help Me Study',
                          'What do you like to listen to?',
                          'Songs like Owl City Fireflies',
                          '1970\'s RnB For Long Drives',
                          'Songs to Help Me Sleep',
                        ],
                        onSubmitted: (value) {
                          submit();
                        },
                      ),
                      // const SizedBox(height: 16),
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
}
