import 'dart:developer';
import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/providers/recommendation_provider.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final String _userMessage = '';

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);
    final recommendationsState =
        ref.watch(recommendationsProvider(_userMessage));
    final sessionData = ref.read(sessionProvider.notifier);

    log("HOME SCREEN: $sessionState");

    return Scaffold(
      appBar: AppBar(
        // backgroundColor: AppTheme.primaryColor,
        actionsIconTheme: const IconThemeData(size: 40),
        title: const Text('Home Screen'),
        automaticallyImplyLeading: false,
        centerTitle: false,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.logout),
          //   tooltip: 'Logout',
          //   onPressed: () {
          //     sessionData.logout();
          //   },
          // ),
          sessionState.when(
            data: (data) {
              return CupertinoButton(
                // color: Colors.amber,
                onPressed: () {
                  sessionData.logout();
                },
                child: CachedNetworkImage(
                  imageBuilder: (context, imageProvider) => Container(
                    width: 30.0,
                    height: 100.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: imageProvider,
                        // fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  fit: BoxFit.fill,
                  height: 150,
                  imageUrl: data?.user["user_metadata"]["avatar_url"],
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: AppTheme.textColor,
              ),
            ),
            error: (error, stack) => const CircleAvatar(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: AnimatedTextField(
              animationType: Animationtype.slide,
              controller: _controller,
              decoration: InputDecoration(
                // filled: false,
                // prefixIcon: const Icon(Icons.sea),
                suffixIcon: Icon(
                  Icons.add_circle,
                  color: Theme.of(context).iconTheme.color,
                ),
                // border: OutlineInputBorder(
                //   // borderSide: const BorderSide(color: Colors.white, width: 1),
                //   borderRadius: BorderRadius.circular(24),
                // ),
                focusedBorder: const OutlineInputBorder(
                    // borderSide: const BorderSide(color: Colors.black, width: 2),
                    // borderRadius: BorderRadius.circular(4),
                    ),
                contentPadding: const EdgeInsets.all(12),
              ),
              hintTexts: const [
                'Chill Lo-Fi beats to help me study',
                '21 Savage Songs from 2016',
                'Classical Music for Kids',
                '1990\'s RnB',
              ],
              onSubmitted: (value) {
                setState(() {
                  // _userMessage = value;
                });
              },
            ),
          ),
          // Column(
          //   children: [
          //     // Center(
          //     //   child:
          //     // ),
          //     // Expanded(
          //     //   child: recommendationsState.when(
          //     //     data: (recommendations) {
          //     //       return ListView.builder(
          //     //         itemCount: recommendations.length,
          //     //         itemBuilder: (context, index) {
          //     //           final recommendation = recommendations[index];
          //     //           return ListTile(
          //     //             title: Text(recommendation.title),
          //     //             subtitle: Text(recommendation.artist),
          //     //             onTap: () {
          //     //               // Navigator.push(
          //     //               //   context,
          //     //               //   MaterialPageRoute(
          //     //               //     // builder: (context) => TrackInfoScreen(songs: [recommendation.id]),
          //     //               //   ),
          //     //               // );
          //     //             },
          //     //           );
          //     //         },
          //     //       );
          //     //     },
          //     //     loading: () => const CircularProgressIndicator(),
          //     //     error: (error, stack) => Text('Error: $error'),
          //     //   ),
          //     // ),
          //   ],
          // ),
        ),
      ),
    );
  }
}
