import 'dart:convert';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/routes.dart';
import 'package:nuance/screens/auth/login_screen.dart';
import 'package:nuance/screens/home_screen.dart';
import 'package:nuance/screens/initial_screen.dart';
import 'package:nuance/screens/recommendations_result_screen.dart';
import 'package:nuance/theme.dart';
import 'package:nuance/widgets/custom_snackbar.dart';
import 'package:uni_links/uni_links.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      initialRoute: widget.sessionData == null
          ? InitialScreen.routeName
          : HomeScreen.routeName,
      theme: AppTheme.lightTheme,
      routes: routes,
    );
  }
}
