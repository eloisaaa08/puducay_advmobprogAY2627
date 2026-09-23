import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'signin_screen.dart';

// ============================================================================
// HomeScreen reads the persisted session with UserService.getUser() and
// passes the resulting User object straight into this screen, so
// ProfileScreen itself only has to worry about rendering — it never talks
// to SharedPreferences or the API directly. The same User.id is what
// HomeScreen also feeds into CartScreen(userId: user.id) so the Cart tab
// is scoped to whichever account is currently signed in.
// ============================================================================
class ProfileScreen extends StatelessWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  /// Enhancement 3: logs the current user out via UserService (clears
  /// SharedPreferences) and returns to the Sign-In screen, removing every
  /// previous route so "back" cannot return to an authenticated screen.
  Future<void> _logout(BuildContext context) async {
    await UserService().logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  String get _fullName {
    final name = '${user.firstName} ${user.lastName}'.trim();
    return name.isEmpty ? user.username : name;
  }

  String get _initials {
    final first = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final last = user.lastName.isNotEmpty ? user.lastName[0] : '';
    final combined = '$first$last';
    return combined.isEmpty
        ? (user.username.isNotEmpty ? user.username[0].toUpperCase() : '?')
        : combined.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            // ----------------------------------------------------------
            // Enhancement 3: avatar + name card, rendered from User.
            // ----------------------------------------------------------
            Padding(
              padding: EdgeInsets.symmetric(vertical: 28.h),
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
                            text: _initials,
                            fontSize: 26.sp,
                            fontWeight: FontWeight.bold,
                          )
                        : null,
                  ),

                  SizedBox(height: 14.h),

                  CustomText(
                    text: _fullName,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),

                  SizedBox(height: 4.h),

                  CustomText(
                    text: '@${user.username}',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // ----------------------------------------------------------
            // Enhancement 3: account-detail card, one row per User field.
            // ----------------------------------------------------------
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                child: Column(
                  children: [
                    _ProfileInfoRow(
                      icon: Icons.mail_outline,
                      label: 'Email',
                      value: user.email,
                    ),
                    const Divider(height: 1),
                    _ProfileInfoRow(
                      icon: Icons.wc_outlined,
                      label: 'Gender',
                      value: user.gender,
                    ),
                    const Divider(height: 1),
                    _ProfileInfoRow(
                      // Enhancement 3: the same user.id shown here is used
                      // by HomeScreen to load this user's cart.
                      icon: Icons.badge_outlined,
                      label: 'User ID',
                      value: '#${user.id}',
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // ----------------------------------------------------------
            // Enhancement 3: Log Out clears the persisted session so the
            // next app launch lands back on the sign-in screen.
            // ----------------------------------------------------------
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
                onPressed: () => _logout(context),
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
    );
  }
}

/// Small reusable row used to render a single User field with a leading
/// icon, matching the activity's sample profile layout.
class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

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
          const Spacer(),
          Flexible(
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
