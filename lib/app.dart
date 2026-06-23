import 'package:flutter/material.dart';

import 'constants/colors.dart';
import 'screens/home_screen.dart';
import 'screens/study_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/book_list_screen.dart';
import 'screens/book_detail_screen.dart';

class WordMasterApp extends StatelessWidget {
  const WordMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '词达人',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: const MainShell(),
      onGenerateRoute: (settings) {
        if (settings.name == '/study') {
          return MaterialPageRoute(
            builder: (_) => const StudyScreen(),
            settings: settings,
          );
        }
        if (settings.name == '/book') {
          return MaterialPageRoute(
            builder: (_) => const BookListScreen(),
            settings: settings,
          );
        }
        if (settings.name != null && settings.name!.startsWith('/book/')) {
          final bookId = settings.name!.replaceFirst('/book/', '');
          return MaterialPageRoute(
            builder: (_) => BookDetailScreen(bookId: bookId),
            settings: settings,
          );
        }
        return null;
      },
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

  static const _screens = [
    HomeScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _buildNavItem(0, Icons.home, '首页'),
                _buildNavItem(1, Icons.bar_chart, '统计'),
                _buildNavItem(2, Icons.settings, '设置'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 24,
                color: isActive ? AppColors.primary : AppColors.outline),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? AppColors.primary : AppColors.outline)),
          ],
        ),
      ),
    );
  }
}
