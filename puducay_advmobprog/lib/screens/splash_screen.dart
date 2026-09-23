import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/user_service.dart';

// ============================================================================
// LAB ACTIVITY 4 — ENHANCEMENT 1
// Custom UI for the Splash Screen implementing PERSISTENT AUTHENTICATION.
//
// How the persistent authentication works:
//   1. On app start, this screen asks UserService.isLoggedIn() whether a
//      valid access token is already stored in SharedPreferences (saved
//      earlier by UserService.saveUserData() during a previous sign-in).
//   2. If a token exists, the previously saved user data is read back with
//      UserService.getUser() (which returns a strongly-typed User model,
//      not a raw Map) and the user is sent straight to '/home' — they never
//      have to log in again as long as their session is still on the
//      device. This is what makes the authentication "persistent".
//   3. If no token exists, the user is redirected to '/signin' instead.
//
// The custom UI below (branded background, animated logo/text fade-in,
// and a themed progress indicator) replaces the plain placeholder splash
// that shipped with the starter code.
// ============================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();

  // Enhancement 1: simple fade + slide-up animation so the splash screen
  // does not feel like a static placeholder while the auth check runs.
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

  /// Enhancement 1: Persistent-authentication check.
  ///
  /// Reads the login flag + saved profile straight from SharedPreferences
  /// (via UserService) instead of forcing the user through the sign-in
  /// form every time the app is opened.
  Future<void> _checkAuthentication() async {
    // Small delay so the splash branding is actually visible, and so the
    // fade-in animation above has time to finish.
    await Future.delayed(const Duration(milliseconds: 1500));

    final bool loggedIn = await _userService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      // Session token found -> restore the saved User model and skip
      // straight to Home without asking for credentials again.
      final User user = await _userService.getUser();

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/home', arguments: user);
    } else {
      // No stored session -> the user must sign in.
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Enhancement 1: soft branded gradient background instead of a
      // plain white/placeholder scaffold.
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
                    // Branded logo badge. Falls back to an icon so the
                    // screen still looks intentional if the asset is
                    // missing from a given build.
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
