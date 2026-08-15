import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../widgets/custom_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        // Enhancement 3:
        // Added a Settings page to move the dark/light mode switch
        // away from the Home screen.
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
                    // Enhancement 3:
                    // The icon changes depending on the selected theme.
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

                    // Enhancement 3:
                    // Dark/light mode switch is now located on the
                    // Settings page.
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
          ],
        ),
      ),
    );
  }
}
