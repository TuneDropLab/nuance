import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/services/itunes_service.dart';
import 'package:nuance/utils/constants.dart';

class VibeCamAtmosphere {
  final String mood;
  final String title;
  final String searchPrompt;
  final List<String> tags;
  final List<Color> paletteColors;
  final Color primaryColor;
  final Color secondaryColor;

  const VibeCamAtmosphere({
    required this.mood,
    required this.title,
    required this.searchPrompt,
    required this.tags,
    required this.paletteColors,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

class VibeCamResult {
  final String title;
  final String mood;
  final String scene;
  final List<Color> paletteColors;
  final List<SongModel> songs;
  final Uint8List imageBytes;

  const VibeCamResult({
    required this.title,
    required this.mood,
    required this.scene,
    required this.paletteColors,
    required this.songs,
    required this.imageBytes,
  });
}

class VibeCamService {
  static final VibeCamService _instance = VibeCamService._internal();
  factory VibeCamService() => _instance;
  VibeCamService._internal();

  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      return file;
    } catch (e) {
      dev.log("VibeCam: Error picking image: $e");
      return null;
    }
  }

  Future<VibeCamAtmosphere> extractAtmosphere(
    Uint8List imageBytes, {
    String? userPrompt,
  }) async {
    Color dominant = const Color(0xFF6200EE);
    Color darkVibrant = const Color(0xFF1E1E2C);
    Color lightVibrant = const Color(0xFFBB86FC);
    List<Color> paletteColors = [];

    try {
      final provider = MemoryImage(imageBytes);
      final palette = await PaletteGenerator.fromImageProvider(
        provider,
        size: const Size(200, 200),
        maximumColorCount: 16,
      );

      dominant = palette.dominantColor?.color ?? dominant;
      darkVibrant = palette.darkVibrantColor?.color ??
          palette.darkMutedColor?.color ??
          dominant;
      lightVibrant = palette.lightVibrantColor?.color ??
          palette.lightMutedColor?.color ??
          dominant;

      paletteColors = palette.colors.take(6).toList();
      if (paletteColors.isEmpty) {
        paletteColors = [dominant, darkVibrant, lightVibrant];
      }
    } catch (e) {
      dev.log("VibeCam: Palette extraction fallback: $e");
      paletteColors = [dominant, darkVibrant, lightVibrant];
    }

    final hsl = HSLColor.fromColor(dominant);
    final hue = hsl.hue;
    final saturation = hsl.saturation;
    final lightness = hsl.lightness;

    String mood;
    String title;
    String searchPrompt;
    List<String> tags;

    if (userPrompt != null && userPrompt.trim().isNotEmpty) {
      final p = userPrompt.trim();
      mood = "Tailored to: $p";
      title = "Vibe Cam: $p";
      searchPrompt = p;
      tags = ["Atmospheric", "Tailored", "Nuance Vision"];
    } else if (lightness < 0.30) {
      // Midnight / Nocturnal / Low-light
      mood = "Late Night, Introspective & Hypnotic";
      title = "Midnight Echoes";
      searchPrompt = "midnight dark synthwave ambient electronic chill";
      tags = ["Late Night", "Ambient", "Deep Synth", "Nocturnal"];
    } else if (hue >= 15 && hue <= 55 && saturation > 0.35) {
      // Sunset / Golden Hour / Warm Glow
      mood = "Golden Hour, Warm & Nostalgic";
      title = "Golden Hour Drift";
      searchPrompt = "sunset golden hour neo soul lofi r&b indie";
      tags = ["Golden Hour", "Warm Glow", "Neo-Soul", "Nostalgic"];
    } else if (hue >= 70 && hue <= 165) {
      // Nature / Lush Green / Earth
      mood = "Organic, Earthy & Peaceful";
      title = "Organic Solitude";
      searchPrompt = "indie folk acoustic organic peaceful wilderness";
      tags = ["Organic", "Folk", "Acoustic", "Nature"];
    } else if ((hue > 280 || hue < 15) && saturation > 0.5) {
      // Neon / Magenta / Purple / Electric
      mood = "Cyberpunk, Electric & Euphoric";
      title = "Neon Glow Soundscape";
      searchPrompt = "neon electronic hyperpop synthpop dance groove";
      tags = ["Neon", "Electric", "Synthpop", "Future"];
    } else if (hue >= 170 && hue <= 260 && saturation > 0.35) {
      // Blue / Ocean / Twilight
      mood = "Chillwave, Deep Water & Serene";
      title = "Azure Horizons";
      searchPrompt = "chillwave downtempo dream pop indie rock";
      tags = ["Chillwave", "Oceanic", "Dream Pop", "Serene"];
    } else if (saturation < 0.25) {
      // Muted / Monochromatic / Rainy
      mood = "Rainy Day, Contemplative Lo-Fi";
      title = "Monochrome Melancholy";
      searchPrompt = "lo-fi study beats rainy day jazz piano melancholic";
      tags = ["Lo-Fi", "Rainy Day", "Coffee Shop", "Muted"];
    } else {
      // Vibrant daylight
      mood = "Sunlit, Uplifting & Vibrant";
      title = "Sunlit Frequency";
      searchPrompt = "uplifting indie pop afrobeat feel good sunshine";
      tags = ["Sunlit", "Vibrant", "Upbeat", "Warm"];
    }

    return VibeCamAtmosphere(
      mood: mood,
      title: title,
      searchPrompt: searchPrompt,
      tags: tags,
      paletteColors: paletteColors,
      primaryColor: dominant,
      secondaryColor: darkVibrant,
    );
  }

  Future<VibeCamResult> generateSoundscape({
    required Uint8List imageBytes,
    String? userPrompt,
    String? accessToken,
    String? provider,
  }) async {
    final atmosphere = await extractAtmosphere(imageBytes, userPrompt: userPrompt);
    final itunes = ItunesService();
    List<SongModel> songs = [];
    String finalTitle = atmosphere.title;
    String finalMood = atmosphere.mood;
    String finalScene = "Visual scene captured via Vibe Cam";

    // 1. Try sending base64 image to backend Vibe Cam multimodal endpoint
    try {
      final base64Image = base64Encode(imageBytes);
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (accessToken != null && accessToken.isNotEmpty && !accessToken.startsWith('guest_')) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      final uri = Uri.parse('$baseURL/gemini/vibe-cam');
      dev.log("VibeCam: Sending multimodal request to $uri");

      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'image': base64Image,
              'promptMessage': userPrompt ?? atmosphere.searchPrompt,
            }),
          )
          .timeout(const Duration(seconds: 14));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recs = data['recommendations'];
        if (recs != null) {
          if (recs['search_query'] != null) {
            finalTitle = "Vibe Cam: ${recs['search_query']}";
          }
          if (recs['mood'] != null) {
            finalMood = recs['mood'];
          }
          if (recs['scene'] != null) {
            finalScene = recs['scene'];
          }

          final songsJson = recs['songs'] as List<dynamic>? ?? [];
          if (songsJson.isNotEmpty) {
            songs = await itunes.resolveRecommendations(songsJson);
          }
        }
      } else {
        dev.log("VibeCam: Backend responded with ${response.statusCode}");
      }
    } catch (e) {
      dev.log("VibeCam: Multimodal backend fallback: $e");
    }

    // 2. If songs are still empty, use atmospheric vision prompt with iTunes
    if (songs.isEmpty) {
      dev.log("VibeCam: Querying iTunes with prompt: ${atmosphere.searchPrompt}");
      try {
        songs = await itunes.getRecommendations(atmosphere.searchPrompt);
      } catch (e) {
        dev.log("VibeCam: iTunes search error: $e");
      }
    }

    // 3. Fallback to rich curated playlist if offline
    if (songs.isEmpty) {
      songs = [
        SongModel(
          title: "Midnight City",
          artist: "M83",
          albumName: "Hurry Up, We're Dreaming",
          previewUrl: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/24/09/79/2409794c-3d5d-af26-580e-7dc00ee4f207/mzaf_369629549966021675.plus.aac.p.m4a",
          artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/cb/7b/a9/cb7ba903-b5f1-cc21-90db-7a81b7aa0997/724596951057.jpg/600x600bb.jpg",
          durationMs: 241440,
        ),
        SongModel(
          title: "Resonance",
          artist: "Home",
          albumName: "Odyssey",
          previewUrl: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/33/bb/1a/33bb1a1a-1448-3118-6891-639e61784145/mzaf_3810752549913623044.plus.aac.p.m4a",
          artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/4f/13/65/4f1365b0-e97c-c469-c438-2f7d8f204355/872133025584_cover.jpg/600x600bb.jpg",
          durationMs: 212939,
        ),
        SongModel(
          title: "Sunset Lover",
          artist: "Petit Biscuit",
          albumName: "Petit Biscuit - EP",
          previewUrl: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/6e/7f/e8/6e7fe823-dc62-3c03-5b18-358ba31f7d2e/mzaf_7798102817870742981.plus.aac.p.m4a",
          artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/78/1c/93/781c934a-c233-cfce-39db-31f7284969b4/cover.jpg/600x600bb.jpg",
          durationMs: 237678,
        ),
      ];
    }

    return VibeCamResult(
      title: finalTitle,
      mood: finalMood,
      scene: finalScene,
      paletteColors: atmosphere.paletteColors,
      songs: songs,
      imageBytes: imageBytes,
    );
  }
}
