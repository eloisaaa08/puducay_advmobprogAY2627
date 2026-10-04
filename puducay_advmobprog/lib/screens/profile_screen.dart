import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// Enhancement 3: profile screen that loads its own data through UserService().getUserData().
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late Future<Map<String, dynamic>> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.getUserData();
  }

  // Reloads the user data after an update.
  void _refresh() {
    setState(() => _userFuture = _userService.getUserData());
  }

  // Clears the session and sends the user back to the sign-in screen.
  Future<void> _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Turns Firebase and API errors into a readable message.
  String _errorText(Object e) {
    if (e is fb.FirebaseAuthException) return e.message ?? e.code;
    return e.toString().replaceFirst('Exception: ', '');
  }

  // Enhancement 3: asks for a new username then updates it for the current LoginType.
  Future<void> _updateUsername(User user) async {
    final controller = TextEditingController(text: user.username);
    final formKey = GlobalKey<FormState>();

    final newUsername = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Username'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'New username',
              prefixIcon: Icon(Icons.alternate_email),
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (!RegExp(r'^[a-zA-Z0-9_.]{3,20}$').hasMatch(value)) {
                return '3–20 letters, numbers, _ or .';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newUsername == null || newUsername == user.username) return;

    try {
      await _userService.updateUsername(username: newUsername);
      _toast('Username updated.');
      _refresh();
    } catch (e) {
      _toast('Update failed: ${_errorText(e)}');
    }
  }

  // Enhancement 3: asks for the current and new password then changes it.
  Future<void> _changePassword(User user) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  prefixIcon: Icon(Icons.lock_reset),
                  errorMaxLines: 2,
                ),
                validator: (v) {
                  final p = v ?? '';
                  final strong =
                      p.length >= 8 &&
                      p.contains(RegExp(r'[A-Z]')) &&
                      p.contains(RegExp(r'[a-z]')) &&
                      p.contains(RegExp(r'[0-9]')) &&
                      p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));
                  return strong
                      ? null
                      : '8+ chars with upper, lower, number and symbol';
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _userService.resetPasswordFromCurrentPassword(
        currentPassword: currentController.text,
        newPassword: newController.text,
        email: user.email,
      );
      _toast('Password changed.');
    } catch (e) {
      _toast('Change failed: ${_errorText(e)}');
    }
  }

  // Enhancement 3: confirms with the password then deletes the account.
  Future<void> _deleteAccount(User user) async {
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently removes your account and cannot be undone.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Enter your password to confirm',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _userService.deleteAccount(
        email: user.email,
        password: passwordController.text,
      );
      _toast('Account deleted.');
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } catch (e) {
      _toast('Delete failed: ${_errorText(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: CustomText(text: 'Unable to load profile.', fontSize: 14.sp),
          );
        }
        return _buildProfile(context, User.fromJson(snapshot.data!));
      },
    );
  }

  Widget _buildProfile(BuildContext context, User user) {
    final colorScheme = Theme.of(context).colorScheme;
    final fullName = '${user.firstName} ${user.lastName}'.trim();
    final initials =
        '${user.firstName.isNotEmpty ? user.firstName[0] : ''}'
                '${user.lastName.isNotEmpty ? user.lastName[0] : ''}'
            .toUpperCase();

    // Enhancement 3: rows shown depend on the LoginType of the session.
    final rows = user.isFirebase
        ? [
            _ProfileInfoRow(Icons.mail_outline, 'Email', user.email),
            _ProfileInfoRow(Icons.cake_outlined, 'Age', user.age),
            _ProfileInfoRow(Icons.phone_outlined, 'Contact No.', user.phone),
            _ProfileInfoRow(Icons.fingerprint, 'Firebase UID', user.uid),
          ]
        : [
            _ProfileInfoRow(Icons.mail_outline, 'Email', user.email),
            _ProfileInfoRow(Icons.wc_outlined, 'Gender', user.gender),
            _ProfileInfoRow(Icons.cake_outlined, 'Age', user.age),
            _ProfileInfoRow(Icons.phone_outlined, 'Contact No.', user.phone),
            _ProfileInfoRow(Icons.badge_outlined, 'User ID', '#${user.id}'),
          ];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.r),
          child: Column(
            children: [
              // Avatar, name, username, and login type badge.
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44.r,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      backgroundImage: user.image.isNotEmpty
                          ? NetworkImage(user.image)
                          : null,
                      child: user.image.isEmpty
                          ? CustomText(
                              text: initials.isNotEmpty
                                  ? initials
                                  : (user.username.isNotEmpty
                                        ? user.username[0].toUpperCase()
                                        : '?'),
                              fontSize: 26.sp,
                              fontWeight: FontWeight.bold,
                            )
                          : null,
                    ),
                    SizedBox(height: 14.h),
                    CustomText(
                      text: fullName.isEmpty ? user.username : fullName,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      text: '@${user.username}',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    SizedBox(height: 10.h),
                    Chip(
                      avatar: Icon(
                        user.isFirebase
                            ? Icons.local_fire_department
                            : Icons.cloud_outlined,
                        size: 16.sp,
                        color: user.isFirebase
                            ? Colors.orange
                            : colorScheme.primary,
                      ),
                      label: CustomText(
                        text: user.isFirebase
                            ? 'Signed in with Firebase'
                            : 'Signed in with DummyJSON',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Account details card.
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 4.h,
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < rows.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        rows[i],
                      ],
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Enhancement 3: account actions are only shown for Firebase since DummyJSON cannot save changes.
              if (user.isFirebase) ...[
                Card(
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: CustomText(
                          text: 'Update Username',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _updateUsername(user),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_reset),
                        title: CustomText(
                          text: 'Change Password',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _changePassword(user),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: colorScheme.error,
                        ),
                        title: Text(
                          'Delete Account',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.error,
                          ),
                        ),
                        onTap: () => _deleteAccount(user),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
              ],

              SizedBox(height: 24.h),

              // Enhancement 1: logout button that clears the session/token and returns to login.
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: CustomText(
                    text: 'Log Out',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

// Single profile detail row with a leading icon.
class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: colorScheme.primary),
          SizedBox(width: 12.w),
          CustomText(text: label, fontSize: 14.sp, fontWeight: FontWeight.w600),
          SizedBox(width: 12.w),
          Expanded(
            child: CustomText(
              text: value.isEmpty ? 'N/A' : value,
              fontSize: 13.sp,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
