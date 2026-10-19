import 'dart:math' as math;
import 'package:flutter/material.dart';

class NuanceWavecode extends StatelessWidget {
  final String playlistTitle;
  final int trackCount;
  final int totalDurationMs;
  final double height;
  final Color? barColor;
  final Gradient? barGradient;
  final Color? textColor;
  final bool showLabel;

  const NuanceWavecode({
    super.key,
    required this.playlistTitle,
    required this.trackCount,
    required this.totalDurationMs,
    this.height = 36,
    this.barColor,
    this.barGradient,
    this.textColor,
    this.showLabel = true,
  });

  /// Computes a unique hash code string for display (e.g. "NU-7842-WAVE")
  String get wavecodeText {
    int hash = 0;
    for (int i = 0; i < playlistTitle.length; i++) {
      hash = (31 * hash + playlistTitle.codeUnitAt(i)) & 0xFFFFFFF;
    }
    hash = (hash + trackCount * 1000 + (totalDurationMs ~/ 1000)) & 0xFFFFFFF;
    final hex = hash.toRadixString(16).padLeft(6, '0').toUpperCase();
    return "NUE-$hex";
  }

  /// Deterministically derives a list of 32 bar heights (between 0.15 and 1.0)
  List<double> generateBarHeights() {
    final List<double> heights = [];
    int seed = 42;
    for (int i = 0; i < playlistTitle.length; i++) {
      seed = (seed * 37 + playlistTitle.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    seed = (seed + trackCount * 7919) & 0x7FFFFFFF;

    final random = math.Random(seed);
    const int barCount = 34;

    for (int i = 0; i < barCount; i++) {
      // Create organic waveform contour with natural audio frequency curve
      final double normalizedX = i / (barCount - 1);
      final double envelope = math.sin(normalizedX * math.pi) * 0.5 + 0.35;
      final double noise = (random.nextDouble() * 0.45) - 0.1;
      final double h = (envelope + noise).clamp(0.18, 1.0);
      heights.add(h);
    }
    return heights;
  }

  @override
  Widget build(BuildContext context) {
    final bars = generateBarHeights();
    final defaultGradient = barGradient ??
        const LinearGradient(
          colors: [
            Color(0xFFFF7043),
            Color(0xFFFFCA28),
            Color(0xFF26C6DA),
          ],
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lead glyph
              Container(
                width: 6,
                height: height * 0.9,
                decoration: BoxDecoration(
                  color: barColor ?? Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),

              // Wave bars
              Expanded(
                child: CustomPaint(
                  size: Size(double.infinity, height),
                  painter: _WavecodePainter(
                    bars: bars,
                    barColor: barColor,
                    gradient: defaultGradient,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Tail glyph
              Container(
                width: 6,
                height: height * 0.9,
                decoration: BoxDecoration(
                  color: barColor ?? Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 3),
          Builder(
            builder: (context) {
              final effectiveTextColor = textColor ??
                  (barColor != null ? barColor! : Colors.white);
              final subtitleColor = effectiveTextColor.withValues(alpha: 0.65);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "20Hz",
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "| NUANCE WAVECODE • $wavecodeText |",
                        style: TextStyle(
                          color: effectiveTextColor,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  Text(
                    "20kHz",
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _WavecodePainter extends CustomPainter {
  final List<double> bars;
  final Color? barColor;
  final Gradient gradient;

  _WavecodePainter({
    required this.bars,
    this.barColor,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (barColor != null) {
      paint.color = barColor!;
    } else {
      paint.shader = gradient.createShader(rect);
    }

    final double totalWidth = size.width;
    final int count = bars.length;
    final double barWidth = (totalWidth / count) * 0.55;
    final double spacing = (totalWidth - (barWidth * count)) / (count - 1);

    for (int i = 0; i < count; i++) {
      final double h = bars[i] * size.height;
      final double x = i * (barWidth + spacing);
      final double y = (size.height - h) / 2;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, h),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavecodePainter oldDelegate) {
    return oldDelegate.bars != bars ||
        oldDelegate.barColor != barColor ||
        oldDelegate.gradient != gradient;
  }
}
