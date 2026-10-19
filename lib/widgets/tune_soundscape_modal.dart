import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nuance/utils/constants.dart';
import 'package:nuance/widgets/general_button.dart';

class SoundscapeTuningParams {
  final int bpm;
  final String energyLabel;
  final String vocalStyle; // 'Instrumental', 'Balanced', 'Vocal Heavy'
  final String discoveryLevel; // 'Familiar Hits', 'Balanced', 'Deep Cuts'

  const SoundscapeTuningParams({
    required this.bpm,
    required this.energyLabel,
    required this.vocalStyle,
    required this.discoveryLevel,
  });

  String buildEnrichedQuery(String basePrompt) {
    final buffer = StringBuffer(basePrompt.trim());
    buffer.write(' (~$bpm BPM $energyLabel');
    if (vocalStyle == 'Instrumental') {
      buffer.write(', purely instrumental beats no vocals');
    } else if (vocalStyle == 'Vocal Heavy') {
      buffer.write(', vocal driven melodies');
    }
    if (discoveryLevel == 'Deep Cuts') {
      buffer.write(', underground hidden gems');
    } else if (discoveryLevel == 'Familiar Hits') {
      buffer.write(', popular mainstream anthems');
    }
    buffer.write(')');
    return buffer.toString();
  }
}

class TuneSoundscapeModal extends StatefulWidget {
  final String prompt;
  final Function(SoundscapeTuningParams params) onConfirm;

  const TuneSoundscapeModal({
    super.key,
    required this.prompt,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required String prompt,
    required Function(SoundscapeTuningParams params) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TuneSoundscapeModal(prompt: prompt, onConfirm: onConfirm),
    );
  }

  @override
  State<TuneSoundscapeModal> createState() => _TuneSoundscapeModalState();
}

class _TuneSoundscapeModalState extends State<TuneSoundscapeModal> {
  double _bpm = 100;
  String _vocalStyle = 'Balanced';
  String _discoveryLevel = 'Balanced';

  String get _energyLabel {
    if (_bpm < 80) return 'Chill Ambient';
    if (_bpm < 100) return 'Slow Groove';
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 28,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 40, spreadRadius: 10),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header pull tab
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _energyColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(CupertinoIcons.tuningfork, color: _energyColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TUNE SOUND PROFILE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '"${widget.prompt}"',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 1. Energy & BPM Slider
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Energy & Tempo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _energyColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _energyColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            '${_bpm.round()} BPM · $_energyLabel',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _energyColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _energyColor,
                        inactiveTrackColor: Colors.white12,
                        thumbColor: _energyColor,
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                      ),
                      child: Slider(
                        value: _bpm,
                        min: 65,
                        max: 155,
                        divisions: 18,
                        onChanged: (val) => setState(() => _bpm = val),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Chill (65)', style: TextStyle(fontSize: 11, color: Colors.white38)),
                          Text('Midtempo (110)', style: TextStyle(fontSize: 11, color: Colors.white38)),
                          Text('Hype (155)', style: TextStyle(fontSize: 11, color: Colors.white38)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Vocal Texture Chips
              const Text(
                'Vocal Texture',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildOptionChip(
                    label: 'Instrumental',
                    icon: CupertinoIcons.music_note,
                    isSelected: _vocalStyle == 'Instrumental',
                    onTap: () => setState(() => _vocalStyle = 'Instrumental'),
                  ),
                  const SizedBox(width: 8),
                  _buildOptionChip(
                    label: 'Balanced',
                    icon: CupertinoIcons.waveform,
                    isSelected: _vocalStyle == 'Balanced',
                    onTap: () => setState(() => _vocalStyle = 'Balanced'),
                  ),
                  const SizedBox(width: 8),
                  _buildOptionChip(
                    label: 'Vocal Heavy',
                    icon: CupertinoIcons.mic,
                    isSelected: _vocalStyle == 'Vocal Heavy',
                    onTap: () => setState(() => _vocalStyle = 'Vocal Heavy'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Discovery Depth
              const Text(
                'Artist Discovery',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildOptionChip(
                    label: 'Familiar Hits',
                    icon: CupertinoIcons.star_fill,
                    isSelected: _discoveryLevel == 'Familiar Hits',
                    onTap: () => setState(() => _discoveryLevel = 'Familiar Hits'),
                  ),
                  const SizedBox(width: 8),
                  _buildOptionChip(
                    label: 'Balanced',
                    icon: CupertinoIcons.layers,
                    isSelected: _discoveryLevel == 'Balanced',
                    onTap: () => setState(() => _discoveryLevel = 'Balanced'),
                  ),
                  const SizedBox(width: 8),
                  _buildOptionChip(
                    label: 'Hidden Gems ★',
                    icon: CupertinoIcons.sparkles,
                    isSelected: _discoveryLevel == 'Deep Cuts',
                    onTap: () => setState(() => _discoveryLevel = 'Deep Cuts'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Craft Button
              SizedBox(
                width: double.infinity,
                child: GeneralButton(
                  text: 'Craft Soundscape (${_bpm.round()} BPM)',
                  color: Colors.black87,
                  icon: const Icon(CupertinoIcons.bolt_fill, size: 16, color: Colors.black87),
                  backgroundColor: kUiGreen,
                  onPressed: () {
                    final params = SoundscapeTuningParams(
                      bpm: _bpm.round(),
                      energyLabel: _energyLabel,
                      vocalStyle: _vocalStyle,
                      discoveryLevel: _discoveryLevel,
                    );
                    Navigator.of(context).pop();
                    widget.onConfirm(params);
                  },
                  hasPadding: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? kUiGreen.withOpacity(0.18) : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? kUiGreen : Colors.white.withOpacity(0.08),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? kUiGreen : Colors.white60,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
