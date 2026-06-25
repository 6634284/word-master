import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'constants/colors.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/study_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/book_list_screen.dart';
import 'screens/book_detail_screen.dart';

class WordMasterApp extends ConsumerWidget {
  const WordMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final systemDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = settings.followSystem ? systemDark : settings.darkMode;
    AppColors.setDarkMode(isDark);

    return ValueListenableBuilder<bool>(
      valueListenable: AppColors.darkModeNotifier,
      builder: (context, darkMode, _) {
        AppColors.setDarkMode(darkMode);
        return MaterialApp(
          title: '词达人',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF005EA1),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: AppColors.background,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6CB4EE),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: AppColors.background,
            useMaterial3: true,
          ),
          themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
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

  void _switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  List<Widget> get _screens => [
    HomeScreen(onStatsTap: () => _switchToTab(1)),
    const StatsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: AppColors.darkModeNotifier,
        builder: (context, _, __) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.bottomNavBg,
              boxShadow: [
                BoxShadow(
                  color: AppColors.bottomNavShadow,
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
          );
        },
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
            SizedBox(height: 4),
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
