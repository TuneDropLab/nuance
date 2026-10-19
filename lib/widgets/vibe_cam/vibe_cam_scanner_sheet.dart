import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/screens/playlist_screen.dart';
import 'package:nuance/services/vibe_cam_service.dart';
import 'package:nuance/widgets/custom_snackbar.dart';

class VibeCamScannerSheet extends ConsumerStatefulWidget {
  final Uint8List imageBytes;
  final VibeCamAtmosphere atmosphere;

  const VibeCamScannerSheet({
    super.key,
    required this.imageBytes,
    required this.atmosphere,
  });

  static Future<void> show(
    BuildContext context, {
    required Uint8List imageBytes,
  }) async {
    final atmosphere = await VibeCamService().extractAtmosphere(imageBytes);
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VibeCamScannerSheet(
        imageBytes: imageBytes,
        atmosphere: atmosphere,
      ),
    );
  }

  @override
  ConsumerState<VibeCamScannerSheet> createState() =>
      _VibeCamScannerSheetState();
}

class _VibeCamScannerSheetState extends ConsumerState<VibeCamScannerSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;
  final TextEditingController _promptController = TextEditingController();
  bool _isGenerating = false;
  late VibeCamAtmosphere _currentAtmosphere;

  @override
  void initState() {
    super.initState();
    _currentAtmosphere = widget.atmosphere;
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateSoundscape() async {
    setState(() {
      _isGenerating = true;
    });

    final session = ref.read(sessionProvider);
    final accessToken = session.value?.accessToken;
    final provider = session.value?.provider ?? "guest";

    try {
      final result = await VibeCamService().generateSoundscape(
        imageBytes: widget.imageBytes,
        userPrompt: _promptController.text.trim().isNotEmpty
            ? _promptController.text.trim()
            : null,
        accessToken: accessToken,
        provider: provider,
      );

      if (mounted) {
        Navigator.of(context).pop(); // dismiss sheet
        Get.to(
          () => PlaylistScreen(
            searchTitle: result.title,
            searchQuery: result.title,
            songs: result.songs,
            sessionState: session.asData,
            imageBytes: widget.imageBytes,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        CustomSnackbar().show("Failed to create soundscape: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final primary = _currentAtmosphere.primaryColor;
    final secondary = _currentAtmosphere.secondaryColor;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F14).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.4),
            blurRadius: 36,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
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
                const SizedBox(height: 16),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primary.withValues(alpha: 0.6),
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.camera_viewfinder,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "VIBE CAM SCANNER",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            "Atmosphere ➜ Curated Soundscape",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12,
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

                // Image scanner container
                Center(
                  child: Stack(
                    children: [
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.memory(
                            widget.imageBytes,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      // Scanning laser beam
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _scanController,
                          builder: (context, child) {
                            return Align(
                              alignment: Alignment(
                                0.0,
                                (_scanController.value * 2.0) - 1.0,
                              ),
                              child: Container(
                                height: 3,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      primary,
                                      Colors.white,
                                      primary,
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary,
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Ambient HUD corner markers
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _HudCorner(color: primary),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Transform.flip(
                          flipX: true,
                          child: _HudCorner(color: primary),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Transform.flip(
                          flipY: true,
                          child: _HudCorner(color: primary),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Transform.flip(
                          flipX: true,
                          flipY: true,
                          child: _HudCorner(color: primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Extracted Palette Chips
                Row(
                  children: [
                    const Text(
                      "Extracted Palette",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _currentAtmosphere.mood,
                      style: TextStyle(
                        color: primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _currentAtmosphere.paletteColors.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final c = _currentAtmosphere.paletteColors[idx];
                      final hex = '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: c.withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: c.withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hex,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Tags row
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _currentAtmosphere.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: secondary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: secondary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Optional Atmosphere Context Input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: _promptController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Add atmosphere notes (e.g. rainy cafe, night drive)",
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                      icon: Icon(
                        CupertinoIcons.sparkles,
                        color: primary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Generate Soundscape Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _generateSoundscape,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 8,
                      shadowColor: primary.withValues(alpha: 0.5),
                    ),
                    child: _isGenerating
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CupertinoActivityIndicator(color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                "Synthesizing Soundscape...",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.waveform_path_badge_plus, size: 20),
                              SizedBox(width: 10),
                              Text(
                                "Generate Soundscape",
                                style: TextStyle(
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

class _HudCorner extends StatelessWidget {
  final Color color;
  const _HudCorner({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: _HudCornerPainter(color: color),
      ),
    );
  }
}

class _HudCornerPainter extends CustomPainter {
  final Color color;
  _HudCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
