import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/screens/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class LoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/';
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final success =
          await ref.read(sessionProvider.notifier).signInWithGoogle();
      if (success && mounted) {
        Get.offAll(() => const HomeScreen());
      }
    } catch (e) {
      if (mounted) {
        final errText = e.toString().toLowerCase();
        if (!errText.contains('cancel')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Google sign-in failed: $e")),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEmailSignInModal() {
    final emailController = TextEditingController();
    String? errorMessage;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: bottomInset + 24,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF181818),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sign in with Email',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter your email to sync and save your playlists to your Nuance account.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: emailController,
                      autofocus: true,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) {
                        if (errorMessage != null) {
                          setModalState(() => errorMessage = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'name@example.com',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        prefixIcon: const Icon(CupertinoIcons.mail, color: Colors.white70, size: 18),
                        filled: true,
                        fillColor: const Color(0xFF262626),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFFF5252),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: GeneralButton(
                        text: 'Continue with Email',
                        color: Colors.white,
                        backgroundColor: kUiGreen,
                        hasPadding: true,
                        onPressed: () async {
                          final email = emailController.text.trim();
                          if (email.isEmpty) {
                            setModalState(() {
                              errorMessage = 'Please enter your email address.';
                            });
                            return;
                          }
                          if (!GetUtils.isEmail(email)) {
                            setModalState(() {
                              errorMessage = 'Please enter a valid email address.';
                            });
                            return;
                          }
                          Get.back();
                          setState(() => _isLoading = true);
                          try {
                            await ref
                                .read(sessionProvider.notifier)
                                .signInWithEmail(email);
                            Get.offAll(() => const HomeScreen());
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Email sign-in failed: $e")),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: CupertinoColors.black,
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 600,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/3dbg.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Center(
                      child: _isLoading
                          ? RotationTransition(
                              turns: _controller,
                              child: Image.asset(
                                'assets/whitelogo.png',
                                width: 40,
                                height: 40,
                              ),
                            )
                          : Image.asset(
                              'assets/whitelogo.png',
                              width: 40,
                              height: 40,
                            ),
                    ),
                  ),
                  Column(
                    children: [
                      const Text(
                        'Nuance',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Get.width * 0.2,
                          vertical: 6,
                        ),
                        child: const Text(
                          'Generate any kind of playlist you can think of in seconds',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white60,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: Get.width,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: GeneralButton(
                          text: 'Start Exploring Music',
                          color: Colors.white,
                          icon: SvgPicture.asset(
                            'assets/icon4star.svg',
                            width: 14,
                            height: 14,
                            color: Colors.white,
                          ),
                          backgroundColor: kUiGreen,
                          onPressed: _isLoading
                              ? () {}
                              : () async {
                                  setState(() => _isLoading = true);
                                  await ref
                                      .read(sessionProvider.notifier)
                                      .startGuestSession();
                                  Get.offAll(() => const HomeScreen());
                                },
                          hasPadding: true,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.white.withOpacity(0.2),
                                thickness: 0.8,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'or sign in to sync history',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.white.withOpacity(0.2),
                                thickness: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: Get.width,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: GeneralButton(
                          text: 'Continue with Google',
                          color: Colors.black87,
                          icon: SvgPicture.string(
                            _googleLogoSvg,
                            width: 18,
                            height: 18,
                          ),
                          backgroundColor: Colors.white,
                          onPressed: _isLoading ? () {} : _handleGoogleSignIn,
                          hasPadding: true,
                        ),
                      ),
                      Container(
                        width: Get.width,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: GeneralButton(
                          text: 'Sign in with Email',
                          color: Colors.white,
                          icon: const Icon(
                            CupertinoIcons.mail,
                            size: 18,
                            color: Colors.white,
                          ),
                          backgroundColor: const Color(0xFF222222),
                          onPressed: _isLoading ? () {} : _showEmailSignInModal,
                          hasPadding: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Guest mode allows immediate listening with zero sign-in.\nSign in with your Nuance account to preserve your playlists in history.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.35),
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
