import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nuance/widgets/retro_export/nuance_wavecode.dart';

class CassetteMixtapeCard extends StatefulWidget {
  final String playlistTitle;
  final int trackCount;
  final int totalDurationMs;
  final bool isPlaying;
  final VoidCallback? onTogglePlay;
  final List<String>? trackNames;
  final Color? accentColor;
  final String? date;

  const CassetteMixtapeCard({
    super.key,
    required this.playlistTitle,
    required this.trackCount,
    required this.totalDurationMs,
    this.isPlaying = false,
    this.onTogglePlay,
    this.trackNames,
    this.accentColor,
    this.date,
  });

  @override
  State<CassetteMixtapeCard> createState() => _CassetteMixtapeCardState();
}

class _CassetteMixtapeCardState extends State<CassetteMixtapeCard>
    with TickerProviderStateMixin {
  late final AnimationController _spoolController;
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;
  bool _isSideA = true;

  @override
  void initState() {
    super.initState();
    _spoolController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.isPlaying) {
      _spoolController.repeat();
    }

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutBack,
    );
  }

  void _toggleSide() {
    setState(() {
      _isSideA = !_isSideA;
    });
    if (_flipController.status == AnimationStatus.completed ||
        _flipController.value > 0.5) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant CassetteMixtapeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _spoolController.repeat();
      } else {
        _spoolController.stop();
      }
    }
  }

  @override
  void dispose() {
    _spoolController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  String _formatDate() {
    if (widget.date != null && widget.date!.isNotEmpty) {
      return widget.date!;
    }
    final now = DateTime.now();
    const months = [
      "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
    ];
    return "${months[now.month - 1]} '${now.year.toString().substring(2)}";
  }

  String _formatDuration(int ms) {
    final dur = Duration(milliseconds: ms);
    final m = dur.inMinutes;
    final s = dur.inSeconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final primaryAccent = widget.accentColor ?? const Color(0xFFFF7043);
    final durString = _formatDuration(widget.totalDurationMs);
    final formattedDate = _formatDate();

    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value * math.pi;
        final isFlipped = _flipAnimation.value >= 0.5;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: Transform(
            // When rotated past 90 degrees, mirror back so text reads correctly on Side B
            transform: Matrix4.identity()
              ..rotateY(isFlipped ? math.pi : 0),
            alignment: Alignment.center,
            child: AspectRatio(
              aspectRatio: 1.58, // Standard compact cassette aspect ratio
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF282830),
                      Color(0xFF16161A),
                      Color(0xFF0F0F12),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF3E3E48),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.7),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: primaryAccent.withValues(alpha: 0.18),
                      blurRadius: 30,
                      spreadRadius: 1,
                    ),
                  ],
                ),
        child: Stack(
          children: [
            // Realistic corner screws
            const Positioned(top: 8, left: 8, child: _ScrewWidget()),
            const Positioned(top: 8, right: 8, child: _ScrewWidget()),
            const Positioned(bottom: 8, left: 8, child: _ScrewWidget()),
            const Positioned(bottom: 8, right: 8, child: _ScrewWidget()),

            // Top grip textured notches
            Positioned(
              top: 4,
              left: 50,
              right: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  14,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 3,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),

            // Main Paper / Vinyl Sticker Label
            Positioned(
              top: 20,
              bottom: 24,
              left: 18,
              right: 18,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4EB), // Warm vintage off-white
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      // Vintage racing stripes across top
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Container(
                              height: 6,
                              color: primaryAccent,
                            ),
                            Container(
                              height: 3,
                              color: const Color(0xFFFFB300),
                            ),
                            Container(
                              height: 2,
                              color: const Color(0xFF1E88E5),
                            ),
                          ],
                        ),
                      ),

                      // Label header: SIDE, Playlist Title, Format
                      Positioned(
                        top: 14,
                        left: 12,
                        right: 12,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SIDE A/B Badge (tap to toggle with 3D flip)
                            GestureDetector(
                              onTap: _toggleSide,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _isSideA ? "SIDE A" : "SIDE B",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Playlist Title
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.playlistTitle.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF1E1E24),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  Text(
                                    "${widget.trackCount} TRACKS • $durString • $formattedDate • TYPE II CrO2",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Vintage Hi-Fi / Stereo Logo
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  "STEREO",
                                  style: TextStyle(
                                    color: Color(0xFF1E1E24),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  "NR [B•C]",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Center Tape Window with Dual Spools
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          margin: const EdgeInsets.only(top: 24, bottom: 36),
                          height: 72,
                          width: 210,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C22),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF383842),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Magnetic tape strip background
                              Container(
                                height: 28,
                                margin: const EdgeInsets.symmetric(horizontal: 22),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF3A2418), // Brown magnetic tape
                                      Color(0xFF5A3622),
                                      Color(0xFF3A2418),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),

                              // Central measurement gauge markers
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _GaugeMarker(label: "100"),
                                  SizedBox(width: 8),
                                  _GaugeMarker(label: "50"),
                                  SizedBox(width: 8),
                                  _GaugeMarker(label: "0"),
                                ],
                              ),

                              // Dual Spools (Left & Right)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Left supply spool
                                    GestureDetector(
                                      onTap: widget.onTogglePlay,
                                      child: _RotatingSpool(
                                        controller: _spoolController,
                                        tapePackRadius: _isSideA ? 28 : 22,
                                        accentColor: primaryAccent,
                                      ),
                                    ),

                                    // Center Play / Pause Indicator
                                    GestureDetector(
                                      onTap: widget.onTogglePlay,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.4),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          widget.isPlaying
                                              ? CupertinoIcons.pause_fill
                                              : CupertinoIcons.play_fill,
                                          color: Colors.white70,
                                          size: 14,
                                        ),
                                      ),
                                    ),

                                    // Right take-up spool
                                    GestureDetector(
                                      onTap: widget.onTogglePlay,
                                      child: _RotatingSpool(
                                        controller: _spoolController,
                                        tapePackRadius: _isSideA ? 22 : 28,
                                        accentColor: primaryAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Label: Nuance Wavecode integrated directly!
                      Positioned(
                        bottom: 4,
                        left: 12,
                        right: 12,
                        child: NuanceWavecode(
                          playlistTitle: widget.playlistTitle,
                          trackCount: widget.trackCount,
                          totalDurationMs: widget.totalDurationMs,
                          height: 24,
                          barColor: const Color(0xFF26262D),
                          textColor: const Color(0xFF26262D),
                          showLabel: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Head Opening Trapezoid Bevel
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 140,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFF141418),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                  border: Border(
                    top: BorderSide(color: Color(0xFF383842), width: 1.5),
                    left: BorderSide(color: Color(0xFF383842), width: 1.5),
                    right: BorderSide(color: Color(0xFF383842), width: 1.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(width: 8, height: 4, color: const Color(0xFF2A2A32)),
                    Container(width: 8, height: 4, color: const Color(0xFF2A2A32)),
                    Container(width: 8, height: 4, color: const Color(0xFF2A2A32)),
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
      },
    );
  }
}

class _RotatingSpool extends StatelessWidget {
  final AnimationController controller;
  final double tapePackRadius;
  final Color accentColor;

  const _RotatingSpool({
    required this.controller,
    required this.tapePackRadius,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: controller.value * 2 * math.pi,
          child: SizedBox(
            width: 44,
            height: 44,
            child: CustomPaint(
              painter: _SpoolPainter(
                tapePackRadius: tapePackRadius,
                teethColor: Colors.white,
                coreColor: const Color(0xFFE5E5EB),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpoolPainter extends CustomPainter {
  final double tapePackRadius;
  final Color teethColor;
  final Color coreColor;

  _SpoolPainter({
    required this.tapePackRadius,
    required this.teethColor,
    required this.coreColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Wound tape pack ring
    final tapePaint = Paint()
      ..color = const Color(0xFF482B1B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    canvas.drawCircle(center, 18, tapePaint);

    // White spool plastic core
    final corePaint = Paint()
      ..color = coreColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 15, corePaint);

    // Center hole
    final holePaint = Paint()
      ..color = const Color(0xFF14141A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6.5, holePaint);

    // 6 spool driving teeth / spokes
    final toothPaint = Paint()
      ..color = teethColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi) / 3;
      final x = center.dx + 9.5 * math.cos(angle);
      final y = center.dy + 9.5 * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 2.2, toothPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScrewWidget extends StatelessWidget {
  const _ScrewWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF444450),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF6E6E7E), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 5,
          height: 1,
          color: const Color(0xFF1A1A22),
        ),
      ),
    );
  }
}

class _GaugeMarker extends StatelessWidget {
  final String label;
  const _GaugeMarker({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 1.5,
          height: 6,
          color: Colors.white38,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 7,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
