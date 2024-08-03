import 'dart:convert';
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import Firebase Messaging
import 'package:nuance/models/song_model.dart';
import 'package:nuance/providers/auth_provider.dart';

import 'package:nuance/screens/home_screen.dart';
import 'package:nuance/screens/initial_screen.dart';
import 'package:nuance/screens/onboarding_screen.dart';
import 'package:nuance/screens/recommendations_result_screen.dart';
import 'package:nuance/utils/theme.dart';
import 'package:nuance/widgets/custom_snackbar.dart';
import 'package:uni_links/uni_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final container = ProviderContainer();
  final authService = container.read(authServiceProvider);
  final sessionData = await authService.getSessionData();

  runApp(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(authService),
      ],
      child: MyApp(sessionData: sessionData),
    ),
  );
}

// Firebase Messaging Background Handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class MyApp extends StatefulWidget {
  final Map<String, dynamic>? sessionData;

  const MyApp({super.key, this.sessionData});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;
  bool? _isFirstRun;

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
    _initUniLinks();
    _initFirebaseMessaging();
  }

  Future<void> _checkFirstRun() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _isFirstRun = prefs.getBool('isFirstRun') ?? true;
      });
    } catch (e) {
      // Default to true if there's an error
      setState(() {
        _isFirstRun = true;
      });
    }
  }

  Future<void> _initUniLinks() async {
    try {
      _sub = uriLinkStream.listen((Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri);
        }
      }, onError: (err) {
        // Handle error
      });
    } on Exception catch (e) {
      print(e.toString());
    }
  }

  void _initFirebaseMessaging() async {
    FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.instance.getToken().then((String? token) {
      print("Device Token: $token");
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground Message received: ${message.notification?.title}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Message opened app: ${message.notification?.title}");
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _handleDeepLink(Uri uri) {
    if (uri.pathSegments.contains('share')) {
      final jsonData = uri.queryParameters['data'];
      if (jsonData != null) {
        final recommendationData = jsonDecode(jsonData) as Map<String, dynamic>;
        final searchTitle = recommendationData['searchQuery'] as String?;
        final songsData = recommendationData['songs'] as List<dynamic>?;

        if (songsData != null) {
          final songs =
              songsData.map((song) => SongModel.fromJson(song)).toList();
          Get.to(() => RecommendationsResultScreen(
                searchTitle: searchTitle,
                songs: songs,
              ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetCupertinoApp(
      navigatorKey: CustomSnackbar().navigatorKey,
      localizationsDelegates: const [
        DefaultCupertinoLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      title: 'Nuance',
      home: _isFirstRun == null
          ? OnboardingScreen(onComplete: _onboardingComplete)
          : _isFirstRun!
              ? OnboardingScreen(onComplete: _onboardingComplete)
              : !_isFirstRun! && widget.sessionData == null
                  ? const InitialScreen()
                  : const HomeScreen(),
      theme: AppTheme.lightTheme,
    );
  }

  void _onboardingComplete() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstRun', false);
    setState(() {
      _isFirstRun = false;
    });
    Get.offAll(() => widget.sessionData == null
        ? const InitialScreen()
        : const HomeScreen());
  }
}
