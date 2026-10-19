import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/services/vibe_cam_service.dart';
import 'package:nuance/widgets/retro_export/cassette_mixtape_card.dart';
import 'package:nuance/widgets/retro_export/nuance_wavecode.dart';
import 'package:nuance/widgets/retro_export/retro_export_dialog.dart';
import 'package:nuance/widgets/retro_export/vinyl_sleeve_view.dart';

void main() {
  group('Vibe Cam Multimodal Atmosphere & Vision Tests', () {
    test('Atmosphere classification maps golden/warm hues correctly', () async {
      // 1x1 orange pixel PNG
      final Uint8List orangePng = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
        0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
        0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D, 0xB0, 0x00, 0x00, 0x00,
        0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

      final atmosphere = await VibeCamService().extractAtmosphere(orangePng);
      expect(atmosphere.paletteColors, isNotEmpty);
      expect(atmosphere.mood, isNotEmpty);
      expect(atmosphere.title, isNotEmpty);
      expect(atmosphere.searchPrompt, isNotEmpty);
      expect(atmosphere.tags, isNotEmpty);
    });

    test('User prompt overrides default atmospheric search title', () async {
      final Uint8List mockPng = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
        0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
        0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D, 0xB0, 0x00, 0x00, 0x00,
        0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

      final atmosphere = await VibeCamService().extractAtmosphere(
        mockPng,
        userPrompt: "Late night rainy neon coffee shop",
      );
      expect(atmosphere.title, contains("Late night rainy neon coffee shop"));
      expect(atmosphere.searchPrompt, equals("Late night rainy neon coffee shop"));
    });

    test('generateSoundscape returns rich playlist with songs', () async {
      final Uint8List mockPng = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
        0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
        0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D, 0xB0, 0x00, 0x00, 0x00,
        0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

      final result = await VibeCamService().generateSoundscape(
        imageBytes: mockPng,
        userPrompt: "afrobeats sunset chill",
      );

      expect(result.songs, isNotEmpty);
      expect(result.paletteColors, isNotEmpty);
      expect(result.title, isNotEmpty);
      expect(result.imageBytes, equals(mockPng));
    });
  });

  group('Nuance Wavecode Generation Tests', () {
    test('Computes deterministic hash code and waveform bar counts', () {
      const wavecode = NuanceWavecode(
        playlistTitle: "Golden Hour Drive",
        trackCount: 16,
        totalDurationMs: 2400000,
      );

      final hash = wavecode.wavecodeText;
      expect(hash, startsWith("NUE-"));
      expect(hash.length, greaterThanOrEqualTo(8));

      final bars = wavecode.generateBarHeights();
      expect(bars.length, equals(34));
      for (final h in bars) {
        expect(h, greaterThanOrEqualTo(0.15));
        expect(h, lessThanOrEqualTo(1.0));
      }

      // Exact repeatability
      final bars2 = wavecode.generateBarHeights();
      expect(bars, equals(bars2));
    });
  });

  group('Retro Interactive Cassette & Vinyl Widget Tests', () {
    final testSongs = [
      SongModel(
        title: "Midnight City",
        artist: "M83",
        albumName: "Hurry Up",
        previewUrl: "https://example.com/audio1.mp3",
        artworkUrl: "https://example.com/art1.jpg",
        durationMs: 240000,
      ),
      SongModel(
        title: "Resonance",
        artist: "HOME",
        albumName: "Odyssey",
        previewUrl: "https://example.com/audio2.mp3",
        artworkUrl: "https://example.com/art2.jpg",
        durationMs: 210000,
      ),
    ];

    testWidgets('CassetteMixtapeCard renders spools, label, title, and wavecode',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 380,
                child: CassetteMixtapeCard(
                  playlistTitle: "Tokyo Night Drive",
                  trackCount: 12,
                  totalDurationMs: 2500000,
                  isPlaying: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Check vintage typography
      expect(find.text("TOKYO NIGHT DRIVE"), findsOneWidget);
      expect(find.text("SIDE A"), findsOneWidget);
      expect(find.text("STEREO"), findsOneWidget);

      // Check track count & format badge
      expect(find.textContaining("12 TRACKS"), findsOneWidget);
      expect(find.textContaining("TYPE II CrO2"), findsOneWidget);

      // Check Nuance Wavecode label
      expect(find.textContaining("NUANCE WAVECODE"), findsOneWidget);

      // Tap SIDE A to toggle SIDE B
      await tester.tap(find.text("SIDE A"));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text("SIDE B"), findsOneWidget);
    });

    testWidgets('VinylSleeveView renders 12" jacket, 33⅓ RPM label, and vinyl disc',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 380,
                child: VinylSleeveView(
                  playlistTitle: "Cosmic Odyssey",
                  trackCount: 10,
                  totalDurationMs: 2200000,
                  isPlaying: false,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Check vinyl metadata
      expect(find.text("33⅓ RPM"), findsOneWidget);
      expect(find.text("COSMIC ODYSSEY"), findsNWidgets(2)); // On label & on jacket
      expect(find.text("ORIGINAL MASTER RECORDING"), findsOneWidget);
      expect(find.textContaining("HIGH FIDELITY VINYL"), findsOneWidget);
    });

    testWidgets('RetroExportDialog toggles between Cassette Tape and Vinyl Sleeve',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RetroExportDialog(
              playlistTitle: "Chillwave 2026",
              songs: testSongs,
              isPlaying: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially in Cassette mode
      expect(find.text("Cassette Tape"), findsOneWidget);
      expect(find.text("Vinyl Sleeve"), findsOneWidget);
      expect(find.byType(CassetteMixtapeCard), findsOneWidget);
      expect(find.text("Export Cassette Mixtape (PNG)"), findsOneWidget);

      // Switch to Vinyl Sleeve mode
      await tester.tap(find.text("Vinyl Sleeve"));
      await tester.pumpAndSettle();

      expect(find.byType(VinylSleeveView), findsOneWidget);
      expect(find.text("Export Vinyl Sleeve (PNG)"), findsOneWidget);
    });

    testWidgets('CassetteMixtapeCard displays custom date prop on label',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 380,
                child: CassetteMixtapeCard(
                  playlistTitle: "Summer Memories",
                  trackCount: 8,
                  totalDurationMs: 1800000,
                  date: "JUL '24",
                  isPlaying: false,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.textContaining("JUL '24"), findsOneWidget);
      expect(find.textContaining("8 TRACKS"), findsOneWidget);
    });

    testWidgets('NuanceWavecode applies custom textColor for high contrast on light surfaces',
        (tester) async {
      const darkInk = Color(0xFF26262D);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NuanceWavecode(
              playlistTitle: "Vintage Lo-Fi Beats",
              trackCount: 14,
              totalDurationMs: 2800000,
              textColor: darkInk,
              barColor: darkInk,
              showLabel: true,
            ),
          ),
        ),
      );

      await tester.pump();
      final textFinder = find.text("20Hz");
      expect(textFinder, findsOneWidget);
      final Text textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.color, equals(darkInk.withValues(alpha: 0.65)));
    });

    testWidgets('NuanceWavecode safely handles edge cases (empty title, 0 tracks, 0 duration)',
        (tester) async {
      const emptyWavecode = NuanceWavecode(
        playlistTitle: "",
        trackCount: 0,
        totalDurationMs: 0,
      );

      expect(emptyWavecode.wavecodeText, startsWith("NUE-"));
      final bars = emptyWavecode.generateBarHeights();
      expect(bars.length, equals(34));
      for (final bar in bars) {
        expect(bar.isFinite, isTrue);
        expect(bar, greaterThanOrEqualTo(0.15));
      }
    });

    testWidgets('RetroExportDialog dynamically reacts to audio player stream state',
        (tester) async {
      final controller = StreamController<PlayerState>.broadcast();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RetroExportDialog(
              playlistTitle: "Synthwave Nights",
              songs: testSongs,
              isPlaying: false,
              playerStateStream: controller.stream,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially paused
      expect(find.byIcon(CupertinoIcons.play_circle_fill), findsOneWidget);
      expect(find.text("Paused • Tap to spin"), findsOneWidget);

      // Simulate audio player starting playback
      controller.add(PlayerState.playing);
      await tester.pump(const Duration(milliseconds: 50));

      // UI should update to show playing state
      expect(find.byIcon(CupertinoIcons.pause_circle_fill), findsOneWidget);
      expect(find.text("Playing preview • Spools spinning"), findsOneWidget);

      // Simulate song completing
      controller.add(PlayerState.completed);
      await tester.pump(const Duration(milliseconds: 50));

      // UI should revert to paused state
      expect(find.byIcon(CupertinoIcons.play_circle_fill), findsOneWidget);
      expect(find.text("Paused • Tap to spin"), findsOneWidget);

      await controller.close();
    });
  });
}
