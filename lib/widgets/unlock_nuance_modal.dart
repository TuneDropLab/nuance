import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/screens/auth/login_screen.dart';
import 'package:nuance/screens/home_screen.dart';
import 'package:nuance/utils/constants.dart';
import 'package:nuance/widgets/general_button.dart';

const String _googleLogoSvg = '''
<svg viewBox="0 0 24 24" width="24" height="24">
  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"/>
  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"/>
</svg>
''';

class UnlockNuanceModal extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;

  const UnlockNuanceModal({
    super.key,
    this.title = 'Unlock Unlimited Nuance',
    this.subtitle = 'You have used your 3 free guest test soundscapes.',
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Unlock Unlimited Nuance',
    String subtitle = 'You have used your 3 free guest test soundscapes.',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UnlockNuanceModal(title: title, subtitle: subtitle),
    );
  }

  @override
  ConsumerState<UnlockNuanceModal> createState() => _UnlockNuanceModalState();
}

class _UnlockNuanceModalState extends ConsumerState<UnlockNuanceModal> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final success = await ref.read(sessionProvider.notifier).signInWithGoogle();
      if (success && mounted) {
        Navigator.of(context).pop();
        Get.offAll(() => const HomeScreen());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset + 32,
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
            children: [
              // Pull bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kUiGreen.withOpacity(0.15),
                  border: Border.all(color: kUiGreen.withOpacity(0.3)),
                ),
                child: const Icon(CupertinoIcons.sparkles, color: kUiGreen, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              // Value pillars
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    _buildFeatureRow(
                      CupertinoIcons.infinite,
                      'Unlimited AI Generations',
                      'Never run out of vibe prompts or song recommendations',
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    _buildFeatureRow(
                      CupertinoIcons.arrow_up_right_circle_fill,
                      '1-Tap Export to Spotify & Apple',
                      'Transfer your playlists directly to your streaming accounts',
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    _buildFeatureRow(
                      CupertinoIcons.cloud_fill,
                      'Persistent Cloud History',
                      'Access all your past soundscapes across web and mobile',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Sign-in buttons
              SizedBox(
                width: double.infinity,
                child: GeneralButton(
                  text: 'Continue with Google',
                  color: Colors.black87,
                  icon: SvgPicture.string(_googleLogoSvg, width: 18, height: 18),
                  backgroundColor: Colors.white,
                  onPressed: _isLoading ? () {} : _handleGoogleSignIn,
                  hasPadding: true,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: GeneralButton(
                  text: 'Sign in with Email',
                  color: Colors.white,
                  icon: const Icon(CupertinoIcons.mail, size: 18, color: Colors.white),
                  backgroundColor: const Color(0xFF262626),
                  onPressed: _isLoading
                      ? () {}
                      : () {
                          Navigator.of(context).pop();
                          Get.to(() => const LoginScreen());
                        },
                  hasPadding: true,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '100% Free · Your current generated playlists are preserved',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: kUiGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: kUiGreen, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.55),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
