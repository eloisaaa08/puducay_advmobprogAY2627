import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/user_service.dart';

// Splash screen that restores a saved DummyJSON or Firebase session before opening Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();

  // Fade and slide-up animation shown while the session check runs.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeIn,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.15),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _checkAuthentication();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Checks for a saved session and refreshes its token before skipping sign-in.
  Future<void> _checkAuthentication() async {
    // Short delay so the splash branding and animation are visible.
    await Future.delayed(const Duration(milliseconds: 1500));

    final bool loggedIn = await _userService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      // Enhancement 2: refreshes the Firebase ID token or DummyJSON access token, ignoring offline errors.
      try {
        if (await _userService.getLoginType() == LoginType.firebase) {
          await _userService.refreshFirebaseToken();
        } else {
          await _userService.refreshDummyToken();
        }
      } catch (_) {}

      final User user = await _userService.getUser();

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/home', arguments: user);
    } else {
      // No saved session, so the user must sign in.
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Soft branded gradient background.
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.08),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo badge that falls back to an icon if the asset is missing.
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.18),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        'assets/images/nubdexchange_logo.png',
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.shopping_bag_rounded,
                            size: 56,
                            color: colorScheme.primary,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      'NUBD Exchange',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Checking your session…',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
