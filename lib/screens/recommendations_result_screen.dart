import 'dart:developer';
import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/providers/recommendation_provider.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/theme.dart';

class RecommendationsResult extends ConsumerStatefulWidget {
  static const routeName = '/rec_results';

  const RecommendationsResult({super.key});

  @override
  ConsumerState<RecommendationsResult> createState() => _RecommendationsResultState();
}

class _RecommendationsResultState extends ConsumerState<RecommendationsResult> {
  final TextEditingController _controller = TextEditingController();
  String _userMessage = '';

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);
    // final recommendationsState =
    //     ref.watch(recommendationsProvider(_userMessage));
    final sessionData = ref.read(sessionProvider.notifier);

    log("HOME SCREEN: $sessionState");
    final focusNode = FocusNode();

    void submit() {
      focusNode.unfocus();
      setState(() {
        _userMessage = _controller.text;
      });
      ref.read(recommendationsProvider(_userMessage));
      _controller.clear();
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
                    imageUrl: data.user["user_metadata"]["avatar_url"],
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.textColor,
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
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
              focusNode: focusNode,
              onTapOutside: (event) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              controller: _controller,
              decoration: InputDecoration(
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
                hintMaxLines: 1,
                helperMaxLines: 1,
                fillColor: Colors.white,

                // filled: false,
                border: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white,
                    width: 0.3,
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              animationDuration: const Duration(milliseconds: 98000),
              animationType: Animationtype.slide,
              hintTextStyle: TextStyle(
                color: Theme.of(context).inputDecorationTheme.iconColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              hintTexts: const [
                'Chill Lo-Fi Beats to Help Me Study',
                // '21 Savage Songs From 2016',
                'Classical Music for Kids',
                '1970\'s RnB For Long Drives',
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
