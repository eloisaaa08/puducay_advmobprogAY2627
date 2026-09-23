import 'package:flutter/material.dart';

import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// ============================================================================
// LAB ACTIVITY 4 — ENHANCEMENT 2
// Custom UI for the Sign-In Screen implementing UserService + the
// authentication logic from the reference source code.
//
// Flow:
//   1. The user fills in the username/password form below.
//   2. _login() calls UserService.loginUser(), which POSTs the credentials
//      to '<host>/auth/login'.
//   3. UserService.loginUser() already calls saveUserData() internally on a
//      successful response, so the returned profile + tokens are persisted
//      to SharedPreferences right here at login time — this is the write
//      side of the persistent authentication used by SplashScreen.
//   4. On success the user is routed to '/home'; on failure a SnackBar
//      reports the error and the form stays on screen.
// ============================================================================

// Enhancement 2: small NUBD Exchange brand palette (navy/gold, echoing the
// crest used on the splash screen) kept local to this screen instead of
// relying on the generic Material "blue swatch" theme color.
class _Brand {
  static const Color navy = Color(0xFF232A6B);
  static const Color navyDark = Color(0xFF171C4A);
  static const Color gold = Color(0xFFF2B705);
  static const Color background = Color(0xFFF6F5FB);
  static const Color textDark = Color(0xFF1F2233);
  static const Color textMuted = Color(0xFF6B7080);
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Enhancement 2: same UserService used by the splash screen, so both
  // screens read/write the exact same persisted session.
  final UserService _userService = UserService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Enhancement 2: authentication logic — validates the form, calls
  /// UserService.loginUser() (which also persists the session via
  /// saveUserData()), then navigates to Home or shows the error.
  Future<void> _login() async {
    if (_isLoading) return;

    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _userService.loginUser(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      // Session is already saved inside loginUser() -> saveUserData().
      if (!mounted) return;

      setState(() => _isLoading = false);

      Navigator.pushReplacementNamed(context, '/home', arguments: response);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Incorrect username or password. Please try again.';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _Brand.background,
      body: Stack(
        children: [
          // ------------------------------------------------------------
          // Enhancement 2: soft decorative brand blobs behind everything,
          // instead of a flat single-color background.
          // ------------------------------------------------------------
          Positioned(
            top: -size.width * 0.35,
            right: -size.width * 0.30,
            child: _Blob(
              diameter: size.width * 0.9,
              color: _Brand.navy.withValues(alpha: 0.06),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.4,
            left: -size.width * 0.35,
            child: _Blob(
              diameter: size.width * 0.85,
              color: _Brand.gold.withValues(alpha: 0.10),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height * 0.86),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --------------------------------------------------
                    // Enhancement 2: brand mark + heading, matching the
                    // activity's sample output layout.
                    // --------------------------------------------------
                    Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _Brand.navy.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          'assets/images/nubdexchange_logo.png',
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.storefront_rounded,
                              size: 36,
                              color: _Brand.navy,
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const CustomText(
                      text: 'Welcome back',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 6),

                    const CustomText(
                      text: 'Sign in to continue to NU Bulldogs Exchange',
                      fontSize: 14,
                      textAlign: TextAlign.center,
                      fontStyle: FontStyle.normal,
                    ),

                    const SizedBox(height: 32),

                    // --------------------------------------------------
                    // Enhancement 2: form fields sit on an elevated white
                    // card so they read as one clear input group instead
                    // of floating on the page background.
                    // --------------------------------------------------
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _Brand.navy.withValues(alpha: 0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      size: 18,
                                      color: Colors.redAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: CustomText(
                                        text: _errorMessage!,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            _FieldLabel('Username'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _usernameController,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                              decoration: _fieldDecoration(
                                hint: 'Enter your username',
                                icon: Icons.person_outline,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your username';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            _FieldLabel('Password'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                              onFieldSubmitted: (_) => _login(),
                              decoration: _fieldDecoration(
                                hint: 'Enter your password',
                                icon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                    color: _Brand.textMuted,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 26),

                            // ------------------------------------------
                            // Enhancement 2: full-width branded "Log In"
                            // button that triggers the authentication
                            // logic above.
                            // ------------------------------------------
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _Brand.navy,
                                  disabledBackgroundColor: _Brand.navy
                                      .withValues(alpha: 0.6),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _isLoading ? null : _login,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const CustomText(
                                        text: 'Log In',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        color: _Brand.textMuted,
      ),
      prefixIcon: Icon(icon, size: 20, color: _Brand.textMuted),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _Brand.background,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: border(Colors.transparent, 0),
      enabledBorder: border(Colors.transparent, 0),
      focusedBorder: border(_Brand.navy, 1.6),
      errorBorder: border(Colors.redAccent, 1.2),
      focusedErrorBorder: border(Colors.redAccent, 1.6),
    );
  }
}

/// Small label placed above each field so the form reads clearly without
/// relying on Material's floating-label animation, matching the rest of
/// the app's `CustomText`-based typography.
class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return CustomText(text: text, fontSize: 12.5, fontWeight: FontWeight.w600);
  }
}

/// Purely decorative soft-edged circle used to give the background some
/// depth without competing with the form content.
class _Blob extends StatelessWidget {
  final double diameter;
  final Color color;

  const _Blob({required this.diameter, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
