import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Starts the application and provides the theme state to all widgets.
void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => ThemeModel(), child: const MyApp()),
  );
}

/// Manages the application's light and dark theme.
class ThemeModel with ChangeNotifier {
  bool _isDark = false;

  /// Returns the current theme mode.
  bool get isDark => _isDark;

  /// Changes the theme and updates all listening widgets.
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

/// Builds the root widget and applies the selected theme.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeModel.isDark ? ThemeData.dark() : ThemeData.light(),
      home: const CounterScreen(),
    );
  }
}

/// Displays the counter screen using setState().
class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

/// Manages the state of the counter screen.
class _CounterScreenState extends State<CounterScreen> {
  int _counter = 0;

  /// Increases the counter by one.
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ephemeral State Example"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ThemeScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("You have pressed the button this many times:"),
            Text(
              "$_counter",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Displays the theme screen using Provider.
class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Theme Screen"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Switch(
              value: themeModel.isDark,
              onChanged: (value) {
                themeModel.toggleTheme();
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              themeModel.isDark ? Icons.dark_mode : Icons.light_mode,
              size: 60,
            ),
            const SizedBox(height: 20),
            Text(
              themeModel.isDark ? "Dark Mode" : "Light Mode",
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              themeModel.isDark ? "Dark theme enabled" : "Light theme enabled",
            ),
          ],
        ),
      ),
    );
  }
}
