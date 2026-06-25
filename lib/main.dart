import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'constants/colors.dart';
import 'database/database_helper.dart';
import 'database/queries.dart' as queries;
import 'database/seed_data.dart';
import 'providers/home_data_provider.dart';
import 'providers/settings_provider.dart';
import 'services/study_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-read all settings before app starts
  final prefs = await SharedPreferences.getInstance();
  final followSystem = prefs.getBool('followSystem') ?? true;
  final darkMode = prefs.getBool('darkMode') ?? false;
  final selectedBookId = prefs.getString('selectedBookId') ?? 'hongbaoshu_kaoyan';
  final newWordsPerDay = prefs.getInt('newWordsPerDay') ?? 30;

  // Detect system brightness
  final systemDark = PlatformDispatcher.instance.platformBrightness == Brightness.dark;
  final isDark = followSystem ? systemDark : darkMode;
  AppColors.setDarkMode(isDark);

  // Create initial settings state (no async reload needed)
  final initialSettings = SettingsState(
    selectedBookId: selectedBookId,
    newWordsPerDay: newWordsPerDay,
    darkMode: darkMode,
    followSystem: followSystem,
  );

  // Initialize database and seed data
  final db = await DatabaseHelper.database;
  await seedSampleData(db);

  // Pre-load home screen data
  await queries.initCardsForBook(db, selectedBookId);
  final queue = await getTodayStudyQueue(db, selectedBookId, newWordsPerDay);
  final currentStreak = await checkIn(db);
  final today = DateTime.now().toIso8601String().split('T')[0];
  final todayLog = await queries.getTodayStudyLog(db, today);

  final homeData = HomeData(
    newCount: queue.newWords.length,
    reviewCount: queue.reviewWords.length,
    streak: currentStreak,
    todayNew: todayLog?.newWordsLearned ?? 0,
    todayReview: todayLog?.wordsReviewed ?? 0,
  );

  runApp(ProviderScope(
    overrides: [
      settingsProvider.overrideWith((ref) => SettingsNotifier(initialSettings)),
      homeDataSeedProvider.overrideWithValue(homeData),
    ],
    child: const WordMasterApp(),
  ));
}
