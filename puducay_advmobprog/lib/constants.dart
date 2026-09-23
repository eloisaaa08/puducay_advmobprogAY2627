import 'package:flutter_dotenv/flutter_dotenv.dart';

var host = dotenv.env['HOST'];

/// LAB ACTIVITY 4 — ENHANCEMENT 3
/// This demo user ID is no longer used to drive the Cart or Add-to-Cart
/// flows now that authentication is connected: HomeScreen loads the real
/// signed-in user via UserService.getUser() and passes user.id to
/// CartScreen, and ProductDetailScreen reads UserService.getUser().id when
/// adding an item to the cart. Left here only as a reference constant.
const int currentUserId = 2;
