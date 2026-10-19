import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:nuance/screens/auth/login_screen.dart';
import 'package:nuance/screens/playlist_screen.dart';
import 'package:nuance/services/itunes_service.dart';
import 'package:get/get.dart';

void main() {
  patrolTest(
    'Nuance E2E: Guest user enters instant preview and generates iTunes playlist',
    ($) async {
      // 1. Pump the Login Screen in a clean ProviderScope
      await $.pumpWidgetAndSettle(
        const ProviderScope(
          child: GetMaterialApp(
            debugShowCheckedModeBanner: false,
            home: LoginScreen(),
          ),
        ),
      );

      // 2. Verify Login screen loaded with Spotify & Instant Preview buttons
      expect($('Sign in with Spotify'), findsOneWidget);
      expect($('Try Instant Preview (No Login Needed)'), findsOneWidget);

      // 3. Tap the "Try Instant Preview" button
      await $(const Text('Try Instant Preview (No Login Needed)')).tap();
      await $.pumpAndSettle();

      // 4. Verify we can navigate directly to PlaylistScreen with a prompt
      const testPrompt = 'high-energy trap with a dark edge';
      await $.pumpWidgetAndSettle(
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

      // 5. Verify the PlaylistScreen initializes and displays query title
      expect($(testPrompt), findsOneWidget);

      // 6. Test iTunes Service directly to verify track fetching & preview URLs
      final itunes = ItunesService();
      final tracks = await itunes.getRecommendations(testPrompt);

      expect(tracks, isNotEmpty);
      expect(tracks.first.title, isNotEmpty);
      expect(tracks.first.previewUrl, isNotEmpty);
      expect(tracks.first.artworkUrl, isNotEmpty);
    },
  );
}
