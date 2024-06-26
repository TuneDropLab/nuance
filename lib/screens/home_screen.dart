import 'dart:developer';
import 'dart:math';
import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/screens/recommendations_result_screen.dart';
import 'package:nuance/theme.dart';
import 'package:nuance/widgets/custom_drawer.dart';
import 'package:nuance/widgets/general_button.dart';
import 'package:nuance/widgets/playlist_widget.dart';
// import 'constants.dart'; // Import the constants file

class HomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _controller = TextEditingController(
    text: 'drake songs',
  );

  final GlobalKey<ScaffoldState> _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);
    final sessionData = ref.read(sessionProvider.notifier);
    final focusNode = FocusNode();

    void submit() {
      focusNode.unfocus();
      final userMessage = _controller.text;

      Navigator.pushNamed(
        context,
        RecommendationsResultScreen.routeName,
        arguments: {
          'search_term': userMessage,
          'sessionState': sessionState,
        },
      ).then((value) => setState(() {}));
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
                            color: Colors.grey.shade100,
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
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ListView(
                  children: [
                    SpotifyPlaylistCard(
                      artistImages: artistImages,
                      playlistName: playlistName,
                      artistNames: artistNames,
                      onClick: () {},
                    ),
                    SpotifyPlaylistCard(
                      artistImages: artistImages,
                      playlistName: playlistName,
                      artistNames: artistNames,
                      onClick: () {},
                    ),
                  ],
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
                        child: ListView.separated(
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

                            return Chip(
                              side: BorderSide.none,
                              avatar: SvgPicture.asset(
                                "assets/icon4star.svg",
                                color: randomColor,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              label: Text('Artist ${index + 1}'),
                              backgroundColor: Colors.grey[800],
                              labelStyle: const TextStyle(color: Colors.white),
                            );
                          },
                          separatorBuilder: (context, index) {
                            return const SizedBox(width: 5);
                          },
                          itemCount: artistImages.length,
                        ),
                      ),
                      const Divider(
                        height: 0.3,
                        color: Color.fromARGB(30, 255, 255, 255),
                      ),
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

// constants.dart
const List<String> artistImages = [
  'https://i.redd.it/s3jlsf41eqh81.jpg',
  'https://i.redd.it/s3jlsf41eqh81.jpg',
  'https://i.redd.it/s3jlsf41eqh81.jpg',
  'https://i.redd.it/s3jlsf41eqh81.jpg',
  'https://i.pinimg.com/564x/68/28/0b/68280b6753541cb03a89f7cdaa63a44a.jpg',
  'https://i.pinimg.com/564x/68/28/0b/68280b6753541cb03a89f7cdaa63a44a.jpg',
  'https://i.redd.it/s3jlsf41eqh81.jpg',
];

const String playlistName = 'Best of the decade';
const String artistNames =
    'Drake, J. Cole, Kanye West, Travis Scott, ASAP Rocky, Future';
