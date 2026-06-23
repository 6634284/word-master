import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final String selectedBookId;
  final int newWordsPerDay;
  final bool darkMode;

  SettingsState({
    this.selectedBookId = 'hongbaoshu_kaoyan',
    this.newWordsPerDay = 30,
    this.darkMode = false,
  });

  SettingsState copyWith({
    String? selectedBookId,
    int? newWordsPerDay,
    bool? darkMode,
  }) =>
      SettingsState(
        selectedBookId: selectedBookId ?? this.selectedBookId,
        newWordsPerDay: newWordsPerDay ?? this.newWordsPerDay,
        darkMode: darkMode ?? this.darkMode,
      );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      selectedBookId: prefs.getString('selectedBookId') ?? 'hongbaoshu_kaoyan',
      newWordsPerDay: prefs.getInt('newWordsPerDay') ?? 30,
      darkMode: prefs.getBool('darkMode') ?? false,
    );
  }

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

  Future<void> toggleDarkMode() async {
    state = state.copyWith(darkMode: !state.darkMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', state.darkMode);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
