// packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// screens
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';

// providers
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await dotenv.load(fileName: 'assets/.env');

  // Initializes Firebase before runApp so FirebaseAuth is ready on every screen.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const PuducayAdvMobProg());
}

class PuducayAdvMobProg extends StatelessWidget {
  const PuducayAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ScreenUtilInit(
        designSize: const Size(412, 715),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          final themeModel = context.watch<ThemeProvider>();

          return MaterialApp(
            debugShowCheckedModeBanner: false,

            title: 'E-Commerce App',

            theme: themeModel.lightTheme,
            darkTheme: themeModel.darkTheme,
            themeMode: themeModel.isDark ? ThemeMode.dark : ThemeMode.light,

            initialRoute: '/splash',

            routes: {
              '/splash': (context) => const SplashScreen(),

              '/signin': (context) => const SignInScreen(),

              // Enhancement 2: route for the new Firebase signup screen.
              '/signup': (context) => const SignUpScreen(),

              '/home': (context) => const HomeScreen(),

              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
