import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Enhancement 3: confirms, clears the session/token, and goes back to login.
  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await UserService().logout();

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        // Settings page that holds the dark/light mode switch.
        title: CustomText(
          text: 'Settings',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),

      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: 'Appearance',
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),

            SizedBox(height: 16.h),

            Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    // Icon changes depending on the selected theme.
                    Icon(
                      themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
                      size: 28.sp,
                    ),

                    SizedBox(width: 16.w),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            text: 'Dark Mode',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),

                          SizedBox(height: 4.h),

                          CustomText(
                            text: themeProvider.isDark
                                ? 'Dark mode is enabled'
                                : 'Light mode is enabled',
                            fontSize: 13.sp,
                          ),
                        ],
                      ),
                    ),

                    // Dark/light mode switch.
                    Switch(
                      value: themeProvider.isDark,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24.h),

            CustomText(
              text: 'Account',
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),

            SizedBox(height: 16.h),

            // Enhancement 3: logout option inside Settings.
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 4.h,
                ),
                leading: Icon(
                  Icons.logout,
                  color: colorScheme.error,
                  size: 28.sp,
                ),
                title: Text(
                  'Log Out',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.error,
                  ),
                ),
                subtitle: CustomText(
                  text: 'Sign out and return to the login screen',
                  fontSize: 13.sp,
                ),
                onTap: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
