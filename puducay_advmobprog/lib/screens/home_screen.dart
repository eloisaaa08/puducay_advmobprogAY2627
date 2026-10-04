import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'cart_screen.dart';
import 'chat_screen.dart';
import 'product_screen.dart';
import 'profile_screen.dart';
import 'signin_screen.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Cart is the middle tab while Chat opens from the FloatingActionButton.
  int _selectedIndex = 0;

  final PageController _pageController = PageController();

  // Loads the signed-in user so the Cart tab uses that user's ID.
  final UserService _userService = UserService();
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.getUser();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Falls back to Sign-In when no valid session is found.
          final user = snapshot.data;
          if (snapshot.hasError || user == null || user.id == 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                (route) => false,
              );
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              elevation: 2,
              title: _selectedIndex == 0
                  ? Image.asset(
                      'assets/images/nubdexchange_logo.png',
                      scale: 11.sp,
                    )
                  : CustomText(
                      text: _selectedIndex == 1 ? 'My Cart' : 'Profile',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                    ),
              actions: [
                IconButton(
                  icon: Icon(Icons.settings, size: 24.sp),
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            ),
            body: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              children: [
                const ProductScreen(),

                // Cart scoped to the signed-in user's ID.
                CartScreen(userId: user.id),

                // Enhancement 3: profile now fetches its own data through UserService().getUserData().
                const ProfileScreen(),
              ],
              onPageChanged: (page) {
                setState(() {
                  _selectedIndex = page;
                });
              },
            ),

            // Chat FloatingActionButton that is hidden on the Cart tab.
            floatingActionButton: _selectedIndex == 1
                ? null
                : FloatingActionButton(
                    tooltip: 'Chat',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatScreen()),
                      );
                    },
                    child: const Icon(Icons.chat),
                  ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

            bottomNavigationBar: BottomNavigationBar(
              showSelectedLabels: false,
              showUnselectedLabels: false,
              onTap: _onTappedBar,
              currentIndex: _selectedIndex,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.shop_2),
                  label: 'Shop',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart),
                  label: 'Cart',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
    _pageController.jumpToPage(value);
  }
}
