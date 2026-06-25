import 'package:flutter/material.dart';

class AppColors {
  static bool _isDark = false;
  static final ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);

  static void setDarkMode(bool dark) {
    _isDark = dark;
    darkModeNotifier.value = dark;
  }

  // Primary
  static Color get primary => _isDark ? const Color(0xFF6CB4EE) : const Color(0xFF005EA1);
  static Color get primaryContainer => _isDark ? const Color(0xFF1A3A5C) : const Color(0xFF2B78BF);
  static Color get onPrimary => _isDark ? const Color(0xFF003166) : const Color(0xFFFFFFFF);
  static Color get ctaButton => _isDark ? const Color(0xFF6CB4EE) : const Color(0xFF4A90D9);

  // Background & Surface
  static Color get background => _isDark ? const Color(0xFF121218) : const Color(0xFFF7F9FC);
  static Color get surfaceLowest => _isDark ? const Color(0xFF1C1C26) : const Color(0xFFFFFFFF);
  static Color get surfaceContainerLow => _isDark ? const Color(0xFF222230) : const Color(0xFFF2F4F7);
  static Color get surfaceContainer => _isDark ? const Color(0xFF2A2A38) : const Color(0xFFECEEF1);
  static Color get surfaceContainerHigh => _isDark ? const Color(0xFF323242) : const Color(0xFFE6E8EB);
  static Color get surfaceContainerHighest => _isDark ? const Color(0xFF3A3A48) : const Color(0xFFE0E3E6);

  // Text
  static Color get onSurface => _isDark ? const Color(0xFFE2E2E8) : const Color(0xFF191C1E);
  static Color get onSurfaceVariant => _isDark ? const Color(0xFFC4C4D0) : const Color(0xFF414751);
  static Color get outline => _isDark ? const Color(0xFF8E8E9A) : const Color(0xFF717782);
  static Color get outlineVariant => _isDark ? const Color(0xFF3A3A48) : const Color(0xFFC1C7D2);

  // Streak (warm tones, adapted for dark)
  static Color get streakBg => _isDark ? const Color(0xFF3D3520) : const Color(0xFFFFF3CD);
  static Color get streakText => _isDark ? const Color(0xFFF0B840) : const Color(0xFFD97706);

  // Error
  static Color get error => _isDark ? const Color(0xFFFF6B6B) : const Color(0xFFBA1A1A);

  // Tertiary
  static Color get tertiary => _isDark ? const Color(0xFF6CB4D4) : const Color(0xFF18618C);
  static Color get tertiaryContainer => _isDark ? const Color(0xFF1A3A5C) : const Color(0xFF3A7AA6);

  // Rating buttons (semantic colors - same in both modes)
  static Color get againRed => const Color(0xFFDC3545);
  static Color get againBg => const Color(0x1ADC3545);
  static Color get hardYellow => const Color(0xFFFFC107);
  static Color get hardBg => const Color(0x1AFFC107);
  static Color get goodGreen => const Color(0xFF28A745);
  static Color get goodBg => const Color(0x1A28A745);

  // Border (adapts to mode)
  static Color get cardBorder => _isDark ? const Color(0xFF2A2A38) : const Color(0x1AC1C7D2);
  static Color get cardBorderStrong => _isDark ? const Color(0xFF3A3A48) : const Color(0x33C1C7D2);

  // Shadow
  static Color get shadow => _isDark ? const Color(0x40000000) : const Color(0x0D000000);

  // Streak icon backgrounds
  static Color get streakIconBg => _isDark ? const Color(0xFF4A3D1A) : const Color(0xFFEBDFBA);
  static Color get streakLabelText => _isDark ? const Color(0xFFD4C88A) : const Color(0xFF4E472B);

  // Queue icon backgrounds
  static Color get queueIconBg => _isDark ? const Color(0xFF1A3050) : const Color(0x262B78BF);
  static Color get queueIconBgAlt => _isDark ? const Color(0xFF1A2A3A) : const Color(0xFFE6F4F9);

  // Book selected
  static Color get bookSelectedBg => _isDark ? const Color(0xFF1A2A4A) : const Color(0xFFD2E4FF);
  static Color get bookSelectedTitle => _isDark ? const Color(0xFFB0D4FF) : const Color(0xFF001C37);

  // Bottom nav
  static Color get bottomNavBg => _isDark ? const Color(0xFF1C1C26) : Colors.white;
  static Color get bottomNavShadow => _isDark ? const Color(0x40000000) : const Color(0x0D000000);

  // Dialog
  static Color get dialogOverlay => _isDark ? const Color(0x80000000) : const Color(0x66191C1E);
}
