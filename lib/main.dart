import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/routes.dart';
import 'package:nuance/screens/auth/login_screen.dart';
import 'package:nuance/screens/home_screen.dart';
import 'package:nuance/screens/initial_screen.dart';
import 'package:nuance/theme.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

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

class MyApp extends StatelessWidget {
  final Map<String, dynamic>? sessionData;

  const MyApp({super.key, this.sessionData});

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: RefreshConfiguration(
        headerBuilder: () =>
            const ClassicHeader(), // Configure the default header indicator. If you have the same header indicator for each page, you need to set this
        footerBuilder: () =>
            const ClassicFooter(), // Configure default bottom indicator
        headerTriggerDistance: 160.0, // header trigger refresh trigger distance
        springDescription: const SpringDescription(
            stiffness: 170,
            damping: 16,
            mass:
                1.9), // custom spring back animate,the props meaning see the flutter api
        maxOverScrollExtent:
            100, //The maximum dragging range of the head. Set this property if a rush out of the view area occurs
        maxUnderScrollExtent: 0, // Maximum dragging range at the bottom
        enableScrollWhenRefreshCompleted:
            true, //This property is incompatible with PageView and TabBarView. If you need TabBarView to slide left and right, you need to set it to true.
        enableLoadingWhenFailed:
            true, //In the case of load failure, users can still trigger more loads by gesture pull-up.
        hideFooterWhenNotFull:
            false, // Disable pull-up to load more functionality when Viewport is less than one screen
        enableBallisticLoad: true, //
        child: GetCupertinoApp(
          localizationsDelegates: const [
            DefaultCupertinoLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          title: 'Nuance',
          initialRoute: sessionData == null
              ? InitialScreen.routeName
              : HomeScreen.routeName,
          theme: AppTheme.lightTheme,
          routes: routes,
        ),
      ),
    );
  }
}
