import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/utils/file_saver.dart';
import 'package:nuance/widgets/custom_snackbar.dart';
import 'package:nuance/widgets/retro_export/cassette_mixtape_card.dart';
import 'package:nuance/widgets/retro_export/vinyl_sleeve_view.dart';

enum RetroExportMode { cassette, vinyl }

class RetroExportDialog extends StatefulWidget {
  final String playlistTitle;
  final List<SongModel> songs;
  final String? artworkUrl;
  final Uint8List? imageBytes;
  final bool isPlaying;
  final VoidCallback? onTogglePlay;
  final Color? accentColor;
  final AudioPlayer? audioPlayer;
  final Stream<PlayerState>? playerStateStream;

  const RetroExportDialog({
    super.key,
    required this.playlistTitle,
    required this.songs,
    this.artworkUrl,
    this.imageBytes,
    this.isPlaying = false,
    this.onTogglePlay,
    this.accentColor,
    this.audioPlayer,
    this.playerStateStream,
  });

  static Future<void> show(
    BuildContext context, {
    required String playlistTitle,
    required List<SongModel> songs,
    String? artworkUrl,
    Uint8List? imageBytes,
    bool isPlaying = false,
    VoidCallback? onTogglePlay,
    Color? accentColor,
    AudioPlayer? audioPlayer,
    Stream<PlayerState>? playerStateStream,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RetroExportDialog(
        playlistTitle: playlistTitle,
        songs: songs,
        artworkUrl: artworkUrl,
        imageBytes: imageBytes,
        isPlaying: isPlaying,
        onTogglePlay: onTogglePlay,
        accentColor: accentColor,
        audioPlayer: audioPlayer,
        playerStateStream: playerStateStream,
      ),
    );
  }

  @override
  State<RetroExportDialog> createState() => _RetroExportDialogState();
}

class _RetroExportDialogState extends State<RetroExportDialog> {
  final GlobalKey _repaintKey = GlobalKey();
  RetroExportMode _mode = RetroExportMode.cassette;
  bool _isExporting = false;
  late bool _isPlaying;
  StreamSubscription<PlayerState>? _playerSub;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.isPlaying;
    final stream = widget.playerStateStream ?? widget.audioPlayer?.onPlayerStateChanged;
    if (stream != null) {
      _playerSub = stream.listen((state) {
        if (!mounted) return;
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      });
    }
  }

  @override
  void didUpdateWidget(covariant RetroExportDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      setState(() {
        _isPlaying = widget.isPlaying;
      });
    }
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    super.dispose();
  }

  void _handleTogglePlay() {
    if (widget.onTogglePlay != null) {
      widget.onTogglePlay!();
      if (_playerSub == null) {
        setState(() {
          _isPlaying = !_isPlaying;
        });
      }
    }
  }

  int get _totalDurationMs {
    return widget.songs.fold(0, (sum, song) => sum + (song.durationMs ?? 0));
  }

  Future<void> _exportArtifact() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Small pause to allow frame to settle
      await Future.delayed(const Duration(milliseconds: 60));

      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception("Render boundary unavailable");
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to encode PNG");
      }

      final pngBytes = byteData.buffer.asUint8List();
      final suffix = _mode == RetroExportMode.cassette ? "cassette_mixtape" : "vinyl_sleeve";
      final cleanTitle = widget.playlistTitle.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final fileName = "nuance_${cleanTitle}_$suffix.png";

      await saveOrShareImageBytes(
        pngBytes,
        fileName,
        title: "Nuance ${widget.playlistTitle} (${_mode == RetroExportMode.cassette ? 'Cassette Mixtape' : 'Vinyl Sleeve'})",
      );

      if (mounted) {
        CustomSnackbar().show("Artifact exported successfully!");
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar().show("Export error: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.accentColor ?? const Color(0xFFFF7043);
    final trackNames = widget.songs.map((s) => s.title ?? "Track").toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF111116).withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 36,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.sparkles,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "RETRO ARTIFACT EXPORT",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            "Animated Cassette & Vinyl with Nuance Wavecode",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Mode Selector Switcher (Cassette Tape vs Vinyl Sleeve)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _mode = RetroExportMode.cassette;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _mode == RetroExportMode.cassette
                                  ? primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.waveform_circle,
                                  size: 16,
                                  color: _mode == RetroExportMode.cassette
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Cassette Tape",
                                  style: TextStyle(
                                    color: _mode == RetroExportMode.cassette
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _mode = RetroExportMode.vinyl;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _mode == RetroExportMode.vinyl
                                  ? primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.music_albums,
                                  size: 16,
                                  color: _mode == RetroExportMode.vinyl
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Vinyl Sleeve",
                                  style: TextStyle(
                                    color: _mode == RetroExportMode.vinyl
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // RepaintBoundary wrapping the target export card
                Center(
                  child: RepaintBoundary(
                    key: _repaintKey,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.25),
                            blurRadius: 28,
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) {
                          final rotateAnim = Tween<double>(begin: math.pi / 2, end: 0.0).animate(
                            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                          );
                          return AnimatedBuilder(
                            animation: rotateAnim,
                            builder: (context, _) {
                              return Transform(
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.0012)
                                  ..rotateY(rotateAnim.value),
                                alignment: Alignment.center,
                                child: child,
                              );
                            },
                          );
                        },
                        child: _mode == RetroExportMode.cassette
                            ? CassetteMixtapeCard(
                                key: const ValueKey("cassette"),
                                playlistTitle: widget.playlistTitle,
                                trackCount: widget.songs.length,
                                totalDurationMs: _totalDurationMs,
                                isPlaying: _isPlaying,
                                onTogglePlay: _handleTogglePlay,
                                trackNames: trackNames,
                                accentColor: primary,
                              )
                            : VinylSleeveView(
                                key: const ValueKey("vinyl"),
                                playlistTitle: widget.playlistTitle,
                                trackCount: widget.songs.length,
                                totalDurationMs: _totalDurationMs,
                                artworkUrl: widget.artworkUrl,
                                imageBytes: widget.imageBytes,
                                isPlaying: _isPlaying,
                                onTogglePlay: _handleTogglePlay,
                                accentColor: primary,
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Controls row (Audio playback toggle & info)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isPlaying
                            ? CupertinoIcons.pause_circle_fill
                            : CupertinoIcons.play_circle_fill,
                        color: primary,
                        size: 34,
                      ),
                      onPressed: _handleTogglePlay,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isPlaying ? "Playing preview • Spools spinning" : "Paused • Tap to spin",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // One-tap Export Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isExporting ? null : _exportArtifact,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 8,
                      shadowColor: primary.withValues(alpha: 0.5),
                    ),
                    child: _isExporting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CupertinoActivityIndicator(color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                "Rendering High-Res Artifact...",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(CupertinoIcons.arrow_down_doc_fill, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                _mode == RetroExportMode.cassette
                                    ? "Export Cassette Mixtape (PNG)"
                                    : "Export Vinyl Sleeve (PNG)",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
