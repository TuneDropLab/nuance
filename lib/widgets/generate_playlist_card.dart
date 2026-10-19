import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nuance/utils/constants.dart';
import 'package:nuance/widgets/general_button.dart';

class GeneratePlaylistCard extends StatefulWidget {
  final String? prompt;
  final String? image;
  final String? category;
  final int initialBpm;
  final String? initialEnergy;
  final LinearGradient gradient;
  final Function(int bpm, String energy)? onGenerate;
  final VoidCallback? onClick;

  const GeneratePlaylistCard({
    required this.prompt,
    this.image,
    this.category,
    this.initialBpm = 95,
    this.initialEnergy,
    required this.gradient,
    this.onGenerate,
    this.onClick,
    super.key,
  });

  @override
  State<GeneratePlaylistCard> createState() => _GeneratePlaylistCardState();
}

class _GeneratePlaylistCardState extends State<GeneratePlaylistCard> {
  late int _bpm;

  @override
  void initState() {
    super.initState();
    _bpm = widget.initialBpm;
  }

  String get _energyLabel {
    if (_bpm < 80) return 'Chill Ambient';
    if (_bpm < 100) return 'Smooth Groove';
    if (_bpm < 120) return 'Midtempo Drive';
    if (_bpm < 135) return 'Upbeat Bounce';
    return 'Peak Hype';
  }

  Color get _energyColor {
    if (_bpm < 85) return const Color(0xFF64B5F6);
    if (_bpm < 115) return kUiGreen;
    if (_bpm < 135) return const Color(0xFFFFB74D);
    return const Color(0xFFFF5252);
  }

  String get _categoryDisplayName {
    switch (widget.category?.toLowerCase()) {
      case 'temporal':
        return '🌙 TEMPORAL';
      case 'activity':
        return '⚡ ACTIVITY';
      case 'mood':
        return '🎭 MOOD';
      case 'genre_fusion':
        return '📻 FUSION';
      case 'cinematic':
        return '🎬 CINEMATIC';
      case 'regional':
        return '📍 REGIONAL';
      default:
        return '✨ CURATED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.image != null && widget.image!.trim().isNotEmpty;

    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          width: 1.5,
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            // Background Image or Gradient Fallback
            Positioned.fill(
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: widget.image!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: BoxDecoration(gradient: widget.gradient),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(gradient: widget.gradient),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(gradient: widget.gradient),
                    ),
            ),

            // Subtle dark overlay to ensure text contrast and premium feel
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      hasImage
                          ? Colors.black.withOpacity(0.4)
                          : widget.gradient.colors.first.withOpacity(0.4),
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
            ),

            // Foreground Text & Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Text(
                      _categoryDisplayName,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Tooltip(
                    message: widget.prompt ?? "",
                    child: Text(
                      widget.prompt ?? "",
                      maxLines: 2,
                      style: const TextStyle(
                        height: 1.2,
                        overflow: TextOverflow.ellipsis,
                        fontSize: 21,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Inline editable BPM & Energy stepper badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _energyColor.withOpacity(0.35), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Decrease BPM
                        InkWell(
                          onTap: () {
                            if (_bpm > 65) {
                              setState(() => _bpm -= 5);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.remove, size: 14, color: Colors.white70),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '⚡ $_bpm BPM · $_energyLabel',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _energyColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Increase BPM
                        InkWell(
                          onTap: () {
                            if (_bpm < 155) {
                              setState(() => _bpm += 5);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, size: 14, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    child: GeneralButton(
                      hasPadding: true,
                      text: "Generate",
                      backgroundColor: Colors.white.withOpacity(0.25),
                      color: Colors.white,
                      icon: SvgPicture.asset(
                        'assets/icon4star.svg',
                        width: 10,
                        height: 10,
                      ),
                      onPressed: () {
                        if (widget.onGenerate != null) {
                          widget.onGenerate!(_bpm, _energyLabel);
                        } else if (widget.onClick != null) {
                          widget.onClick!();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
