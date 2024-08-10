import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:get/get.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/screens/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/services/all_services.dart';
import 'package:nuance/utils/constants.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import flutter_animate

class LoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/';
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin {
  bool _isLoading = false; // Loading state
  late AnimationController _controller; // Animation controller

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(); // Repeat the animation indefinitely
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller when the widget is disposed
    super.dispose();
  }

  Future<void> _authenticate() async {
    final authUrl = '$baseURL/auth/login';
    const callbackUrlScheme = "nuance";

    try {
      final result = await FlutterWebAuth.authenticate(
        url: authUrl,
        callbackUrlScheme: callbackUrlScheme,
      );

      final uri = Uri.parse(result);
      final sessionData = uri.queryParameters['session'];
      if (sessionData != null) {
        final sessionMap = jsonDecode(sessionData);
        final accessToken = sessionMap['access_token'];

        // Trigger loading state
        setState(() {
          _isLoading = true;
        });

        // Fetch user profile details
        try {
          final profile = await AllServices().getUserProfile(accessToken);
          final name = profile['user']['name'];
          final email = profile['user']['email'];
          await ref
              .read(sessionProvider.notifier)
              .storeSessionAndSaveToState(sessionData, name, email);

          // Simulate loading delay
          await Future.delayed(const Duration(seconds: 2));

          await Get.to(
            () => const HomeScreen(),
            transition: Transition.fade,
            curve: Curves.easeInOut,
          );
        } catch (error) {
          debugPrint("Error fetching user profile: $error");
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } on PlatformException catch (e) {
      debugPrint("Error during authentication: $e");
    }
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
                height: 600,
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
                        Colors.black.withOpacity(0.7),
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
                    child: _isLoading
                        ? RotationTransition(
                            turns: _controller,
                            child: Image.asset(
                              'assets/whitelogo.png',
                              width: 40,
                              height: 40,
                            ),
                          )
                        : Image.asset(
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
