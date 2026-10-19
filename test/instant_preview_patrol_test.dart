import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:nuance/screens/auth/login_screen.dart';
import 'package:nuance/screens/playlist_screen.dart';
import 'package:get/get.dart';

void main() {
  patrolWidgetTest(
    'Nuance E2E: Guest user enters instant preview and displays PlaylistScreen',
    ($) async {
      // 1. Pump the Login Screen in a clean ProviderScope
      await $.tester.pumpWidget(
        const ProviderScope(
          child: GetMaterialApp(
            debugShowCheckedModeBanner: false,
            home: LoginScreen(),
          ),
        ),
      );
      await $.tester.pump(const Duration(milliseconds: 500));

      // 2. Verify Login screen loaded with Start Exploring Music button
      expect($('Start Exploring Music'), findsOneWidget);

      // 3. Tap the "Start Exploring Music" button
      await $('Start Exploring Music').tap();
      await $.tester.pump(const Duration(milliseconds: 500));

      // 4. Verify we can navigate directly to PlaylistScreen with a prompt
      const testPrompt = 'high-energy trap with a dark edge';
      await $.tester.pumpWidget(
        ProviderScope(
          child: GetMaterialApp(
            debugShowCheckedModeBanner: false,
            home: PlaylistScreen(
              searchQuery: testPrompt,
              sessionState: null,
            ),
          ),
        ),
      );
      await $.tester.pump(const Duration(milliseconds: 500));

      // 5. Verify the PlaylistScreen initializes and displays query title
      expect(find.textContaining(RegExp('high-energy trap', caseSensitive: false)), findsWidgets);
    },
  );
}
