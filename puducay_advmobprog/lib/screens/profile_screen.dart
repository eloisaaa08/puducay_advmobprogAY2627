import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/custom_text.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 38.r,
                child: Icon(Icons.person, size: 40.sp),
              ),
              SizedBox(height: 12.h),
              CustomText(
                text: 'Profile',
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 6.h),
              CustomText(
                text: 'Your account information will appear here.',
                fontSize: 14.sp,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
