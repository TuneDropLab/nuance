import 'dart:developer';
import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/screens/recommendations_result_screen.dart';
import 'package:nuance/theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _controller = TextEditingController(
    text: '',
    // text: 'drake songs',
  );
  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);
    final sessionData = ref.read(sessionProvider.notifier);

    // log("HOME SCREEN: ${sessionState.data}");
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
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
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
                      radius: 30,
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
                      width: 50.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: imageProvider,
                        ),
                      ),
                    ),
                    fit: BoxFit.fill,
                    height: 150,
                    imageUrl: data.user["user_metadata"]["avatar_url"] ?? '',
                    placeholder: (context, url) => const Center(
                      child: CupertinoActivityIndicator(
                        color: AppTheme.textColor,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 50.0,
                      height: 100.0,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Colors.black12
                          // image: DecorationImage(
                          //   // image: imageProvider,
                          // ),
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
        decoration: const BoxDecoration(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: AnimatedTextField(
              animationDuration: const Duration(milliseconds: 98000),
              animationType: Animationtype.slide,
              focusNode: focusNode,
              onTapOutside: (event) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              controller: _controller,
              decoration: InputDecoration(
                filled: false,
                suffixIcon: CupertinoButton(
                  onPressed: () {
                    submit();
                  },
                  child: Icon(
                    Icons.add_circle,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
                // focusedBorder: OutlineInputBorder(
                //   borderSide: BorderSide(
                //       color: Theme.of(context).primaryColor, width: 2),
                // ),
                contentPadding: const EdgeInsets.all(12),
              ),
              hintTextStyle: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 14,
              ),
              hintTexts: const [
                'Chill Lo-Fi Beats to Help Me Study',
                '21 Savage Songs From 2016',
                'Songs like Owl City Fireflies',
                '1970\'s RnB For Long Drives',
                'Songs to Help Me Sleep',
              ],
              onSubmitted: (value) {
                submit();
              },
            ),
          ),
        ),
      ),
    );
  }
}
