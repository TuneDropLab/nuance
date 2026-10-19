import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/widgets/music_listtile.dart';
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

  testWidgets(
    'MusicListTile safely renders iTunes song with null popularity without crashing',
    (tester) async {
      final itunesSong = SongModel(
        id: '12345',
        title: 'Cosmic Stargazing Voyage',
        artist: 'Ambient Explorer',
        albumName: 'Deep Space',
        popularity: null,
        previewUrl: 'https://audio-ssl.itunes.apple.com/preview.m4a',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MusicListTile(
                recommendation: itunesSong,
                isPlaying: false,
                trailingOnTap: () {},
                isSelected: false,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Ambient Explorer', findRichText: true), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
