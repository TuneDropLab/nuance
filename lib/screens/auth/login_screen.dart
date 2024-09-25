import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:get/get.dart';
import 'package:nuance/models/history_model.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/screens/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/services/all_services.dart';
import 'package:nuance/utils/constants.dart';
// import 'package:flutter_animate/flutter_animate.dart';
import 'package:nuance/widgets/general_button.dart'; // Import flutter_animate

// import 'package:flutter_riverpod/flutter_riverpod.dart';

// final providerTypeProvider = StateProvider<String?>((ref) => null);

class LoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/';
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false; // Loading state
  late AnimationController _controller; // Animation controller

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller when the widget is disposed
    super.dispose();
  }

  Future<void> _authenticate(String provider) async {
    final authUrl = provider == 'apple'
        ? null // We don't need to use the first Apple login URL since it's handled by MusicKit
        : '$baseURL/auth/login'; // Only use this for Spotify or other providers

    const callbackUrlScheme = "nuance"; // Custom URL scheme

    try {
      debugPrint("Starting authentication with provider: $provider");

      if (provider == 'apple') {
        // For Apple, directly call the Apple MusicKit authentication (which handles both Apple login and MusicKit login)
        await _handleAppleAuthentication();
      } else {
        // For Spotify or other providers, use the original flow
        final result = await FlutterWebAuth.authenticate(
          url: authUrl!, // The Spotify auth URL
          callbackUrlScheme: callbackUrlScheme,
        );

        final uri = Uri.parse(result); // Parse the result from Spotify
        final sessionData = uri.queryParameters['session'];
        final sessionMap = jsonDecode(sessionData!);
        final accessToken = sessionMap['access_token'];
        final providerType = sessionMap['user']['app_metadata']['provider']; // Get provider type
        log("Provider Type: $providerType");
        // ProviderType.setType(providerType); // Store the provider type

        // Update the provider type in Riverpod
        // ref.read(providerTypeProvider.notifier).state = providerType;

        setState(() {
          _isLoading = true;
        });

        try {
          final profile = await AllServices().getUserProfile(accessToken);
          final name = profile['user']['name'];
          final email = profile['user']['email'];

          // Save session data for Spotify
          await ref.read(sessionProvider.notifier).storeSessionAndSaveToState(
                sessionData: sessionData,
                name: name,
                email: email,
              );

          await Future.delayed(const Duration(seconds: 2));

          await Get.to(
            () => const HomeScreen(),
            transition: Transition.fade,
            curve: Curves.easeInOut,
          );
        } catch (error) {
          debugPrint("Error during authentication process: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Authentication failed: ${error.toString()}"),
            ),
          );
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } on PlatformException catch (e) {
      debugPrint("Error during web authentication: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Authentication failed: ${e.message}")),
      );
    }
  }

  Future<void> _handleAppleAuthentication() async {
    const musicKitAuthUrl =
        'http://localhost:3000/apple-music-auth'; // Your actual hosted MusicKit URL

    log('APPLEMUSICFN: Starting Apple Music Authentication...');

    try {
      log('APPLEMUSICFN: MusicKit Auth URL: $musicKitAuthUrl');

      // Launch the MusicKit HTML authentication page
      final result = await FlutterWebAuth.authenticate(
        url: musicKitAuthUrl, // URL to the MusicKit HTML page
        callbackUrlScheme:
            "nuanceapp", // Custom URL scheme to capture the redirect
      );

      log('APPLEMUSICFN: Apple Music Auth Result: $result');

      // Parse the result URL to extract query parameters
      final uri = Uri.parse(result);
      final musicUserToken = uri.queryParameters['musicUserToken'];
      final developerToken = uri.queryParameters['developerToken'];
      final countryCode = uri.queryParameters['countryCode'];
      final sessionData = uri.queryParameters['session'];
      debugPrint("Session data received: $sessionData");

      // if (sessionData != null) {
      final sessionMap = jsonDecode(sessionData!);
      final accessToken = sessionMap['access_token'];
      debugPrint("Access token: $accessToken");

      log('APPLEMUSICFN: Music User Token: $musicUserToken');
      log('APPLEMUSICFN: Developer Token: $developerToken');
      log('APPLEMUSICFN: Country Code: $countryCode');

      // Check if tokens are missing
      if (musicUserToken == null ||
          developerToken == null ||
          countryCode == null) {
        log('APPLEMUSICFN: ERROR - Missing tokens');
        throw Exception("Failed to obtain Apple Music tokens");
      }

      // Fetch user profile from AllServices using the musicUserToken
      final profile = await AllServices()
          .getUserProfile(accessToken); // Pass musicUserToken as accessToken
      final name = profile['user']['name'];
      final email = profile['user']['email'];

      // Store the tokens and user profile
      final musicKitData = {
        'musicKitUserToken': musicUserToken,
        'developerToken': developerToken,
        'countryCode': countryCode,
      };

      log('APPLEMUSICFN: Storing MusicKit data and user profile: $musicKitData');

      await ref.read(sessionProvider.notifier).storeSessionAndSaveToState(
            sessionData: sessionData,
            name: name, // Store actual user name from profile
            email: email, // Store actual user email from profile
            musicKitData: musicKitData,
          );

      log('APPLEMUSICFN: Session stored successfully');

      // Navigate to the home screen after successful authentication
      await Get.to(
        () => const HomeScreen(),
        transition: Transition.fade,
        curve: Curves.easeInOut,
      );
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') {
        log('APPLEMUSICFN: User canceled the login process');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Apple Music authentication canceled.")),
          );
        }
      } else {
        log('APPLEMUSICFN: ERROR - $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Authentication failed: ${e.message}")),
          );
        }
      }
    } catch (e) {
      log('APPLEMUSICFN: ERROR - $e');
      throw Exception("Apple Music authentication failed: $e");
    }
  }

  static const String developerToken = '';
  static const String userToken = '';
  static const String countryCode0 = '';

  @override
  Widget build(BuildContext context) {
    // log dev token
    // log("Developer Token: $_developerToken");
    // log("User Token: $_userToken");
    // log("Country Code: $_countryCode");
    return SafeArea(
      child: ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: CupertinoColors.black,
          body: Stack(
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
                      // const Text('DeveloperToken: $developerToken\n',
                      //     style: TextStyle(color: Colors.white60)),
                      // const Text('UserToken: $userToken\n',
                      //     style: TextStyle(color: Colors.white60)),
                      // const Text('CountryCode: $countryCode0\n',
                      //     style: TextStyle(color: Colors.white60)),
                      // const SizedBox(height: 8),
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
                          bottom: 10,
                          left: 20,
                          right: 20,
                        ),
                        child: GeneralButton(
                          text: 'Sign in with Apple Music',
                          icon: SvgPicture.asset(
                            'assets/icon4star.svg',
                            width: 10,
                            height: 10,
                          ),
                          backgroundColor: const Color.fromARGB(
                              255, 255, 88, 88), // Apple Music theme
                          onPressed:
                              _isLoading ? () {} : () => _authenticate("apple"),
                          hasPadding: true,
                        ),
                      ),
                      Container(
                        width: Get.width,
                        padding: const EdgeInsets.only(
                          bottom: 50,
                          left: 20,
                          right: 20,
                        ),
                        child: GeneralButton(
                          text: 'Sign in with Spotify',
                          icon: SvgPicture.asset(
                            'assets/icon4star.svg',
                            width: 10,
                            height: 10,
                          ),
                          backgroundColor:
                              const Color.fromARGB(255, 79, 162, 114),
                          onPressed: _isLoading
                              ? () {}
                              : () => _authenticate('spotify'),
                          hasPadding: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
