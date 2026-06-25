import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final String selectedBookId;
  final int newWordsPerDay;
  final bool darkMode;
  final bool followSystem;

  SettingsState({
    this.selectedBookId = 'hongbaoshu_kaoyan',
    this.newWordsPerDay = 30,
    this.darkMode = false,
    this.followSystem = true,
  });

  SettingsState copyWith({
    String? selectedBookId,
    int? newWordsPerDay,
    bool? darkMode,
    bool? followSystem,
  }) =>
      SettingsState(
        selectedBookId: selectedBookId ?? this.selectedBookId,
        newWordsPerDay: newWordsPerDay ?? this.newWordsPerDay,
        darkMode: darkMode ?? this.darkMode,
        followSystem: followSystem ?? this.followSystem,
      );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(SettingsState initial) : super(initial);

  Future<void> setSelectedBookId(String id) async {
    state = state.copyWith(selectedBookId: id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedBookId', id);
  }

  Future<void> setNewWordsPerDay(int count) async {
    state = state.copyWith(newWordsPerDay: count);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('newWordsPerDay', count);
  }

  Future<void> setDarkMode(bool value) async {
    state = state.copyWith(darkMode: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }

  Future<void> setFollowSystem(bool value) async {
    state = state.copyWith(followSystem: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('followSystem', value);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  // Initial state is passed from main.dart via the ProviderScope
  // This is a fallback in case it's not provided
  return SettingsNotifier(SettingsState());
});
