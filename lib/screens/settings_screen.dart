import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../providers/settings_provider.dart';
import '../widgets/header.dart';
import '../widgets/number_picker.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _newWordsOptions = [10, 20, 30, 50, 100, 200];

  void _showNewWordsPicker() {
    final settings = ref.read(settingsProvider);
    showDialog(
      context: context,
      builder: (_) => NumberPicker(
        title: AppStrings.setDailyNewWords,
        subtitle: AppStrings.planProgress,
        options: _newWordsOptions,
        currentValue: settings.newWordsPerDay,
        onSelect: (value) =>
            ref.read(settingsProvider.notifier).setNewWordsPerDay(value),
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const Header(title: AppStrings.settings),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                _sectionTitle(AppStrings.bookSection),
                _card([
                  _row(
                    label: AppStrings.currentBook,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('考研核心词汇',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: AppColors.onSurfaceVariant)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right,
                            size: 20, color: AppColors.outlineVariant),
                      ],
                    ),
                    onTap: () => Navigator.pushNamed(context, '/book'),
                  ),
                ]),

                _sectionTitle(AppStrings.dailyLearning),
                _card([
                  _row(
                    label: AppStrings.dailyNewWords,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('${settings.newWordsPerDay}个',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary)),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right,
                            size: 20, color: AppColors.outlineVariant),
                      ],
                    ),
                    onTap: _showNewWordsPicker,
                  ),
                ]),

                _sectionTitle(AppStrings.appearance),
                _card([
                  _row(
                    label: AppStrings.darkMode,
                    trailing: Switch(
                      value: settings.darkMode,
                      onChanged: (_) =>
                          ref.read(settingsProvider.notifier).toggleDarkMode(),
                      activeThumbColor: AppColors.primary,
                      inactiveTrackColor: AppColors.surfaceContainerHighest,
                    ),
                  ),
                ]),

                _sectionTitle(AppStrings.about),
                _card([
                  _row(
                    label: AppStrings.version,
                    trailing: const Text('1.0.0',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColors.onSurfaceVariant)),
                  ),
                  const Divider(
                      height: 1,
                      color: AppColors.surfaceContainerHigh,
                      indent: 16),
                  _row(
                    label: AppStrings.algorithm,
                    trailing: const Text(AppStrings.fsrsVersion,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColors.onSurfaceVariant)),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.outline,
              letterSpacing: 0.05)),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x26C1C7D2)),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _row({
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: AppColors.onSurface)),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
