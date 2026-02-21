import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/memory_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const AniMindApp(),
    ),
  );
}

class AniMindApp extends StatelessWidget {
  const AniMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AniMind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C4DFF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF3E0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF7C4DFF),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    MemoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFFFFF8E7),
        indicatorColor: const Color(0xFF7C4DFF).withAlpha(30),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFF7C4DFF)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology, color: Color(0xFF7C4DFF)),
            label: 'Memories',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Color(0xFF7C4DFF)),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
