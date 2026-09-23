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
  // Enhancement 2 (Lab Activity 3):
  // The central bottom-navigation destination is now Cart.
  // Chat is opened through the FloatingActionButton instead.
  int _selectedIndex = 0;

  final PageController _pageController = PageController();

  // ==========================================================================
  // LAB ACTIVITY 4 — ENHANCEMENT 3
  // HomeScreen is the single place that reads the persisted session (via
  // UserService -> User model) and hands it down to the screens that need
  // it: ProfileScreen renders the User directly, and CartScreen receives
  // user.id so the Cart tab always requests THIS user's cart from the API
  // (GET /carts/user/{id}) instead of a hard-coded ID.
  // ==========================================================================
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

          // Enhancement 3: if no valid session is found while Home is
          // already on screen (e.g. token cleared elsewhere), fall back to
          // Sign-In instead of rendering a broken profile/cart.
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

                // Enhancement 3: cart scoped to the signed-in user's ID.
                CartScreen(userId: user.id),

                // Enhancement 3: profile rendered straight from the
                // saved User model.
                ProfileScreen(user: user),
              ],
              onPageChanged: (page) {
                setState(() {
                  _selectedIndex = page;
                });
              },
            ),

            // ============================================================
            // Enhancement 2 (Lab Activity 3):
            // Chat was removed from the BottomNavigationBar and converted
            // into a FloatingActionButton. It is hidden on Cart, matching
            // the required enhancement behavior.
            // ============================================================
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
