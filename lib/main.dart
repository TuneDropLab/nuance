import 'dart:convert';
import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import Firebase Messaging
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/routes.dart';
import 'package:nuance/screens/auth/login_screen.dart';
import 'package:nuance/screens/home_screen.dart';
import 'package:nuance/screens/initial_screen.dart';
import 'package:nuance/screens/recommendations_result_screen.dart';
import 'package:nuance/services/recomedation_service.dart';
import 'package:nuance/theme.dart';
import 'package:nuance/widgets/custom_snackbar.dart';
import 'package:uni_links/uni_links.dart';
// import http package as http
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform,
      );

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

  @override
  void initState() {
    super.initState();
    _initUniLinks();
    _initFirebaseMessaging(); // Initialize Firebase Messaging
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
      // Handle exception by logging or displaying an error message
      print(e.toString());
    }
  }

  void _initFirebaseMessaging() async {
    FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.instance.getToken().then((String? token) {
      print("Device Token: $token");
      // if (token != null) {
      //   _sendTokenToServer(token);
      // }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground Message received: ${message.notification?.title}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Message opened app: ${message.notification?.title}");
    });
  }

  // void _sendTokenToServer(String token) async {
  //   final response = await http.post(
  //     Uri.parse('https://your-server.com/api/save-token'),
  //     headers: <String, String>{
  //       'Content-Type': 'application/json; charset=UTF-8',
  //     },
  //     body: jsonEncode(<String, String>{
  //       'token': token,
  //     }),
  //   );

  //   if (response.statusCode == 200) {
  //     print('Token successfully sent to the server');
  //   } else {
  //     print('Failed to send token to the server');
  //   }
  // }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _handleDeepLink(Uri uri) async {
    if (uri.pathSegments.contains('share')) {
      final shareId = uri.pathSegments[1];
      final jsonData =
          await RecommendationsService().getSharedRecommendation(shareId);

      final searchTitle = jsonData['searchQuery'] as String?;
      final songsData = jsonData['songs'] as List<dynamic>?;
      final image = jsonData['image'] as String?;
      log('Shared Recommendation: $jsonData');
      if (songsData != null) {
        final songs =
            songsData.map((song) => SongModel.fromJson(song)).toList();

        // Get the session state from the provider

        final container = ProviderContainer();
        final sessionData = container.read(sessionProvider);
        
        Get.to(() => RecommendationsResultScreen(
              searchTitle: searchTitle,
              songs: songs,
              imageUrl: image,
              sessionState: sessionData.asData,
            ));
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
      initialRoute: widget.sessionData == null
          ? InitialScreen.routeName
          : HomeScreen.routeName,
      theme: AppTheme.lightTheme,
      routes: routes,
    );
  }
}
