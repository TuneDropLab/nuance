import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:get/get.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/screens/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/services/recomedation_service.dart';
import 'package:nuance/utils/constants.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/';
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late String _status;

  Future<void> _authenticate() async {
    const authUrl = '$baseURL/auth/login';
    const callbackUrlScheme = "nuance";

    try {
      final result = await FlutterWebAuth.authenticate(
        url: authUrl,
        callbackUrlScheme: callbackUrlScheme,
      );
      _status = "Alright";

      final uri = Uri.parse(result);
      final sessionData = uri.queryParameters['session'];

      log("Session data: $sessionData");

      if (sessionData != null) {
        final sessionMap = jsonDecode(sessionData);
        final accessToken = sessionMap['access_token'];

        // Fetch user profile details
        try {
          final profile =
              await RecommendationsService().getUserProfile(accessToken);
          final name = profile['user']['name'];
          final email = profile['user']['email'];

          // Update session data
          await ref
              .read(sessionProvider.notifier)
              .storeSessionAndSaveToState(sessionData, name, email);

          // Navigate to HomeScreen
          await Get.to(
            () => const HomeScreen(),
            transition: Transition.fade,
            curve: Curves.easeInOut,
          );
        } catch (error) {
          debugPrint("Error fetching user profile: $error");
          // setState(() {
          //   _status = 'Error fetching user profile';
          // });
        }
      }
    } on PlatformException catch (e) {
      // setState(() {
      //   debugPrint("ERROR MESSAGE: ${e.message}");
      //   _status = 'Error: ${e.message}';
      // });
    }
  }

  @override
  void initState() {
    super.initState();
    _status = "Untouched";
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.black,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 600, // Adjust the height as needed
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/3dbg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7), // Darken the top part
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Center(
                    child: Image.asset(
                      'assets/whitelogo.png',
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),
                Column(
                  children: [
                    const Text(
                      'Nuance',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Get.width * 0.2,
                        vertical: 6,
                      ),
                      child: const Text(
                        'Generate any kind of playlist you can think of in seconds',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white60,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: Get.width,
                      padding: const EdgeInsets.only(
                        bottom: 50,
                        left: 20,
                        right: 20,
                      ),
                      child: SizedBox(
                        child: CupertinoButton.filled(
                          pressedOpacity: 0.3,
                          onPressed: _authenticate,
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
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
