import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// Enhancement 2: signup screen that creates a Firebase account using the DummyJSON user fields.

// Navy/gold brand palette matching the sign-in screen.
class _Brand {
  static const Color navy = Color(0xFF232A6B);
  static const Color gold = Color(0xFFF2B705);
  static const Color background = Color(0xFFF6F5FB);
  static const Color textMuted = Color(0xFF6B7080);
  static const Color success = Color(0xFF2E7D32);
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    // Rebuilds the password checklist while the user types.
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _ageController.dispose();
    _contactNoController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Password rules shown as a live checklist and enforced by the validator.
  Map<String, bool> get _passwordRules {
    final p = _passwordController.text;
    return {
      'At least 8 characters': p.length >= 8,
      'One uppercase letter': p.contains(RegExp(r'[A-Z]')),
      'One lowercase letter': p.contains(RegExp(r'[a-z]')),
      'One number': p.contains(RegExp(r'[0-9]')),
      'One special character': p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]')),
    };
  }

  // Creates the Firebase account, saves the profile fields, and opens Home.
  Future<void> _signUp() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _userService.signUp(
        firstName: _fNameController.text.trim(),
        lastName: _lNameController.text.trim(),
        age: _ageController.text.trim(),
        contactNo: _contactNoController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } on fb.FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Sign up failed.');
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Sign up failed: $message')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Brand.background,
      appBar: AppBar(
        backgroundColor: _Brand.background,
        elevation: 0,
        foregroundColor: _Brand.navy,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CustomText(
                text: 'Create account',
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 6),
              const CustomText(
                text: 'Join NU Bulldogs Exchange with your Firebase account',
                fontSize: 14,
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
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
                      const _SectionLabel('Personal Information'),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'First Name',
                              controller: _fNameController,
                              hint: 'Juan',
                              icon: Icons.person_outline,
                              validator: (v) => _required(v, 'First name'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              label: 'Last Name',
                              controller: _lNameController,
                              hint: 'Dela Cruz',
                              icon: Icons.person_outline,
                              validator: (v) => _required(v, 'Last name'),
                            ),
                          ),
                        ],
                      ),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: _buildField(
                              label: 'Age',
                              controller: _ageController,
                              hint: '20',
                              icon: Icons.cake_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              validator: (v) {
                                final age = int.tryParse(v ?? '');
                                if (age == null) return 'Required';
                                if (age < 13 || age > 120) return '13–120';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              label: 'Contact No.',
                              controller: _contactNoController,
                              hint: '+63 912 345 6789',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9+\- ]'),
                                ),
                              ],
                              validator: (v) {
                                final digits = (v ?? '').replaceAll(
                                  RegExp(r'\D'),
                                  '',
                                );
                                if (digits.isEmpty) return 'Required';
                                if (digits.length < 10 || digits.length > 13) {
                                  return 'Enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),
                      const _SectionLabel('Account Details'),

                      _buildField(
                        label: 'Username',
                        controller: _usernameController,
                        hint: 'juandelacruz',
                        icon: Icons.alternate_email,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Username is required';
                          if (!RegExp(r'^[a-zA-Z0-9_.]{3,20}$').hasMatch(value)) {
                            return '3–20 letters, numbers, _ or .';
                          }
                          return null;
                        },
                      ),

                      _buildField(
                        label: 'Email Address',
                        controller: _emailController,
                        hint: 'juan@email.com',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Email is required';
                          if (!RegExp(
                            r'^[\w.+-]+@[\w-]+\.[\w.]+$',
                          ).hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      _buildField(
                        label: 'Password',
                        controller: _passwordController,
                        hint: 'Create a password',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: _visibilityToggle(
                          _obscurePassword,
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          if (_passwordRules.containsValue(false)) {
                            return 'Password does not meet all requirements';
                          }
                          return null;
                        },
                      ),

                      // Live checklist of the password requirements.
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _passwordRules.entries.map((rule) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    rule.value
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    size: 14,
                                    color: rule.value
                                        ? _Brand.success
                                        : _Brand.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  CustomText(text: rule.key, fontSize: 11.5),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      _buildField(
                        label: 'Confirm Password',
                        controller: _confirmPasswordController,
                        hint: 'Re-enter your password',
                        icon: Icons.lock_outline,
                        obscureText: _obscureConfirm,
                        suffixIcon: _visibilityToggle(
                          _obscureConfirm,
                          () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                        validator: (v) {
                          if (v != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 8),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Brand.navy,
                            disabledBackgroundColor: _Brand.navy.withValues(
                              alpha: 0.6,
                            ),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isLoading ? null : _signUp,
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
                                  text: 'Sign Up',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CustomText(
                    text: 'Already have an account?',
                    fontSize: 13,
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const CustomText(
                      text: 'Log In',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value, String name) {
    return (value == null || value.trim().isEmpty) ? '$name is required' : null;
  }

  Widget _visibilityToggle(bool obscured, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: _Brand.textMuted,
      ),
      onPressed: onPressed,
    );
  }

  // Builds one labeled text field with the shared brand styling.
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(text: label, fontSize: 12.5, fontWeight: FontWeight.w600),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            obscureText: obscureText,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
            validator: validator,
            decoration: InputDecoration(
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
              errorMaxLines: 2,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: border(Colors.transparent, 0),
              enabledBorder: border(Colors.transparent, 0),
              focusedBorder: border(_Brand.navy, 1.6),
              errorBorder: border(Colors.redAccent, 1.2),
              focusedErrorBorder: border(Colors.redAccent, 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

// Small gold-accented heading that groups related fields.
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: _Brand.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          CustomText(text: text, fontSize: 14, fontWeight: FontWeight.w700),
        ],
      ),
    );
  }
}
