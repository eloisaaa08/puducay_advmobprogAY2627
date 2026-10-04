import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';

import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// Sign-in screen that logs in through either DummyJSON or Firebase depending on the selected LoginType.

// Navy/gold brand palette kept local to the auth screens.
class _Brand {
  static const Color navy = Color(0xFF232A6B);
  static const Color gold = Color(0xFFF2B705);
  static const Color background = Color(0xFFF6F5FB);
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

  // Same UserService used by the splash screen so both read the same session.
  final UserService _userService = UserService();

  // Enhancement 2: selected backend for this login attempt.
  LoginType _loginType = LoginType.firebase;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  bool get _isFirebase => _loginType == LoginType.firebase;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Enhancement 2: validates the form then signs in with DummyJSON or Firebase.
  Future<void> _login() async {
    if (_isLoading) return;

    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isFirebase) {
        await _userService.signIn(
          email: _usernameController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _userService.loginUser(
          _usernameController.text.trim(),
          _passwordController.text,
        );
      }

      if (!mounted) return;

      setState(() => _isLoading = false);

      Navigator.pushReplacementNamed(context, '/home');
    } on fb.FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Firebase sign-in failed.');
    } catch (e) {
      _showError('Incorrect username or password. Please try again.');
    }
  }

  // Shows the error message inside the form and as a SnackBar.
  void _showError(String message) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Login failed: $message')));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _Brand.background,
      body: Stack(
        children: [
          // Soft decorative brand blobs behind the form.
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
                    // Brand mark and heading.
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
                    ),

                    const SizedBox(height: 24),

                    // Enhancement 2: toggle between Firebase Auth and the DummyJSON API.
                    SegmentedButton<LoginType>(
                      segments: const [
                        ButtonSegment(
                          value: LoginType.firebase,
                          icon: Icon(Icons.local_fire_department_outlined),
                          label: Text('Firebase'),
                        ),
                        ButtonSegment(
                          value: LoginType.dummyjson,
                          icon: Icon(Icons.cloud_outlined),
                          label: Text('DummyJSON'),
                        ),
                      ],
                      selected: {_loginType},
                      onSelectionChanged: (value) {
                        setState(() {
                          _loginType = value.first;
                          _errorMessage = null;
                          _usernameController.clear();
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // Form fields grouped on an elevated white card.
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

                            // Firebase signs in with email while DummyJSON uses a username.
                            _FieldLabel(_isFirebase ? 'Email Address' : 'Username'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _usernameController,
                              keyboardType: _isFirebase
                                  ? TextInputType.emailAddress
                                  : TextInputType.text,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                              decoration: _fieldDecoration(
                                hint: _isFirebase
                                    ? 'Enter your email'
                                    : 'Enter your username',
                                icon: _isFirebase
                                    ? Icons.mail_outline
                                    : Icons.person_outline,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return _isFirebase
                                      ? 'Please enter your email'
                                      : 'Please enter your username';
                                }
                                if (_isFirebase &&
                                    !RegExp(
                                      r'^[\w.+-]+@[\w-]+\.[\w.]+$',
                                    ).hasMatch(value.trim())) {
                                  return 'Please enter a valid email';
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

                            // Full-width branded button that runs the login logic.
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

                    const SizedBox(height: 20),

                    // Enhancement 2: link to the Firebase signup screen.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CustomText(
                          text: "Don't have an account?",
                          fontSize: 13,
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/signup'),
                          child: const CustomText(
                            text: 'Sign Up',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

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

// Small label placed above each form field.
class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return CustomText(text: text, fontSize: 12.5, fontWeight: FontWeight.w600);
  }
}

// Decorative soft circle used for background depth.
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
