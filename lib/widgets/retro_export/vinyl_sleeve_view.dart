import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nuance/widgets/retro_export/nuance_wavecode.dart';

class VinylSleeveView extends StatefulWidget {
  final String playlistTitle;
  final int trackCount;
  final int totalDurationMs;
  final String? artworkUrl;
  final Uint8List? imageBytes;
  final bool isPlaying;
  final VoidCallback? onTogglePlay;
  final Color? accentColor;

  const VinylSleeveView({
    super.key,
    required this.playlistTitle,
    required this.trackCount,
    required this.totalDurationMs,
    this.artworkUrl,
    this.imageBytes,
    this.isPlaying = false,
    this.onTogglePlay,
    this.accentColor,
  });

  @override
  State<VinylSleeveView> createState() => _VinylSleeveViewState();
}

class _VinylSleeveViewState extends State<VinylSleeveView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    if (widget.isPlaying) {
      _spinController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant VinylSleeveView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _spinController.repeat();
      } else {
        _spinController.stop();
      }
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  String _formatDuration(int ms) {
    final dur = Duration(milliseconds: ms);
    final m = dur.inMinutes;
    final s = dur.inSeconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.accentColor ?? const Color(0xFFFFB300);
    final durString = _formatDuration(widget.totalDurationMs);

    return AspectRatio(
      aspectRatio: 1.45,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Vinyl Record (sliding out to the right)
          Positioned(
            right: 0,
            top: 10,
            bottom: 10,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: GestureDetector(
                onTap: widget.onTogglePlay,
                child: AnimatedBuilder(
                  animation: _spinController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _spinController.value * 2 * math.pi,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [
                              Color(0xFF0A0A0C),
                              Color(0xFF1E1E24),
                              Color(0xFF0F0F13),
                              Color(0xFF22222A),
                              Color(0xFF101014),
                            ],
                            stops: [0.0, 0.35, 0.65, 0.85, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.8),
                              blurRadius: 18,
                              offset: const Offset(4, 4),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: _VinylGroovesPainter(),
                          child: Center(
                            // Center Vinyl Label
                            child: Container(
                              width: 78,
                              height: 78,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primary,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          "33⅓ RPM",
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          widget.playlistTitle.toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        const Text(
                                          "NUANCE LP",
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 6,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Center Spindle Hole
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF0F0F12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 12" Vinyl Cardboard Sleeve (Cover Jacket)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.9),
                      blurRadius: 20,
                      offset: const Offset(4, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      // Album Cover Art Background
                      Positioned.fill(
                        child: widget.imageBytes != null
                            ? Image.memory(
                                widget.imageBytes!,
                                fit: BoxFit.cover,
                              )
                            : widget.artworkUrl != null &&
                                    widget.artworkUrl!.isNotEmpty
                                ? Image.network(
                                    widget.artworkUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _defaultCover(primary),
                                  )
                                : _defaultCover(primary),
                      ),

                      // Cardboard ring-wear patina overlay
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _RingWearPainter(),
                        ),
                      ),

                      // Dark gradient for text readability
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Top Spine / Header Bar
                      Positioned(
                        top: 10,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: primary.withValues(alpha: 0.8),
                                    width: 0.8,
                                  ),
                                ),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "ORIGINAL MASTER RECORDING",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.play_circle,
                                color: Colors.white70,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Jacket Details & Nuance Wavecode
                      Positioned(
                        bottom: 10,
                        left: 12,
                        right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.playlistTitle.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${widget.trackCount} TRACKS • $durString • HIGH FIDELITY VINYL",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            NuanceWavecode(
                              playlistTitle: widget.playlistTitle,
                              trackCount: widget.trackCount,
                              totalDurationMs: widget.totalDurationMs,
                              height: 18,
                              barColor: Colors.white,
                              showLabel: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultCover(Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent,
            const Color(0xFF1E1E24),
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.music_albums,
          color: Colors.white.withValues(alpha: 0.4),
          size: 64,
        ),
      ),
    );
  }
}

class _VinylGroovesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw concentric groove rings
    for (double r = 42; r < (size.width / 2) - 4; r += 5) {
      canvas.drawCircle(center, r, paint);
    }

    // Specular light reflection arc sheen
    final shinePaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, size.width / 2 - 2, shinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RingWearPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0;

    canvas.drawCircle(center, size.width * 0.40, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
