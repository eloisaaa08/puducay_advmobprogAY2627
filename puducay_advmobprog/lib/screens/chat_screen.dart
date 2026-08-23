import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/custom_text.dart';

/// Enhancement 2:
/// The Chat destination is now opened from the FloatingActionButton
/// instead of occupying a BottomNavigationBar slot.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Chat',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: CustomText(
            text: 'Chat support will appear here.',
            fontSize: 15.sp,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
