import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../database/database_helper.dart';

import '../providers/settings_provider.dart';
import '../providers/study_provider.dart';
import '../services/fsrs_service.dart';
import '../services/study_service.dart';
import '../services/tts_service.dart';

String formatInterval(int days) {
  if (days < 1) return '< 1天';
  if (days == 1) return '1天';
  if (days < 30) return '$days天';
  if (days < 365) return '${(days / 30).round()}个月';
  return '${(days / 365).toStringAsFixed(1)}年';
}

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key});

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  bool loading = true;
  bool showMeaning = false;
  bool ratingDisabled = false;
  List<ButtonPreview> previews = [];
  final tts = TtsService();

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    final settings = ref.read(settingsProvider);
    final db = await DatabaseHelper.database;

    try {
      final session = await getTodayStudyQueue(
          db, settings.selectedBookId, settings.newWordsPerDay);
      final allWords = [
        ...session.newWords.map((w) => StudyWord(word: w.word, card: w.card)),
        ...session.reviewWords.map((w) => StudyWord(word: w.word, card: w.card)),
      ];

      if (allWords.isEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text(AppStrings.hint),
              content: const Text(AppStrings.noStudyWords),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: const Text('确定')),
              ],
            ),
          );
        }
        setState(() => loading = false);
        return;
      }

      ref.read(studyProvider.notifier).setQueue(allWords);
      _updatePreviews();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(AppStrings.error),
            content: const Text(AppStrings.loadFailed),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('确定')),
            ],
          ),
        );
      }
    }

    if (mounted) setState(() => loading = false);
  }

  void _updatePreviews() {
    final studyState = ref.read(studyProvider);
    if (studyState.currentWord != null) {
      previews = getButtonPreviews(studyState.currentWord!.card);
    }
  }

  void _handleShowMeaning() {
    if (showMeaning) return;
    Haptics.vibrate(HapticsType.light);
    setState(() => showMeaning = true);
  }

  void _handleSpeak(String text) {
    tts.speak(text);
  }

  Future<void> _handleRate(AppRating rating) async {
    final studyState = ref.read(studyProvider);
    if (studyState.currentWord == null || ratingDisabled) return;

    setState(() => ratingDisabled = true);
    Haptics.vibrate(HapticsType.medium);

    final db = await DatabaseHelper.database;
    final current = studyState.currentWord!;

    try {
      final updatedCard = await processRating(db, current.card, rating);
      ref.read(studyProvider.notifier).updateCurrentCard(updatedCard);

      final isNew = current.card.reps == 0;
      final studyTime =
          ((DateTime.now().millisecondsSinceEpoch - studyState.sessionStartTime) / 1000)
              .round();
      await recordStudy(db, isNew, studyTime > 0 ? studyTime : 1);

      if (isNew) {
        ref.read(studyProvider.notifier).incrementNewCount();
      } else {
        ref.read(studyProvider.notifier).incrementReviewCount();
      }

      final hasNext = ref.read(studyProvider.notifier).moveToNext();
      if (!hasNext) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('完成'),
              content: const Text(AppStrings.studyComplete),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: const Text('确定')),
              ],
            ),
          );
        }
      } else {
        _updatePreviews();
        setState(() => showMeaning = false);
      }
    } catch (e) {
      debugPrint('Failed to process rating: $e');
    }

    if (mounted) setState(() => ratingDisabled = false);
  }

  @override
  Widget build(BuildContext context) {
    final studyState = ref.watch(studyProvider);

    if (loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: Text(AppStrings.preparing,
                style: TextStyle(fontSize: 16, color: AppColors.outline))),
      );
    }

    final currentWord = studyState.currentWord;
    if (currentWord == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: Text(AppStrings.noWord,
                style: TextStyle(fontSize: 16, color: AppColors.outline))),
      );
    }

    final progress = studyState.progress;
    final word = currentWord.word;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top Bar
          Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 24,
                right: 24,
                bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.close, size: 24, color: AppColors.onSurfaceVariant),
                  ),
                ),
                Text('${progress.current} / ${progress.total}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.outline,
                        letterSpacing: 0.05)),
                const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.more_horiz,
                        size: 24, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          // Progress Bar
          LinearProgressIndicator(
            value: progress.total > 0 ? progress.current / progress.total : 0,
            backgroundColor: AppColors.surfaceContainerHigh,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 4,
          ),

          // Word Area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              children: [
                // Word Section
                Center(
                  child: Text(word.word,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          letterSpacing: -0.02)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (word.phonetic.isNotEmpty)
                      Text(word.phonetic,
                          style: const TextStyle(
                              fontSize: 16, color: AppColors.outline)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _handleSpeak(word.word),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.volume_up,
                            color: AppColors.primary, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Meaning Cover / Display
                if (!showMeaning)
                  GestureDetector(
                    onTap: _handleShowMeaning,
                    child: Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_off,
                              size: 32, color: AppColors.outlineVariant),
                          const SizedBox(height: 16),
                          const Text(AppStrings.recallHint,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.outline)),
                          const SizedBox(height: 8),
                          const Text(AppStrings.tapToShow,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.outlineVariant)),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Center(
                    child: Container(
                      width: 40,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(word.meaning,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurface,
                          height: 1.5)),
                  if (word.example.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(AppStrings.exampleLabel,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                          const SizedBox(height: 8),
                          Text(word.example,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.onSurfaceVariant,
                                  height: 1.6)),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),

          // Rating Buttons
          if (showMeaning)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Row(
                children: previews.map((btn) {
                  Color bgColor;
                  Color textColor;
                  switch (btn.rating) {
                    case AppRating.again:
                      bgColor = AppColors.againBg;
                      textColor = AppColors.againRed;
                    case AppRating.hard:
                      bgColor = AppColors.hardBg;
                      textColor = AppColors.hardYellow;
                    case AppRating.good:
                      bgColor = AppColors.goodBg;
                      textColor = AppColors.goodGreen;
                  }
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: GestureDetector(
                        onTap: () => _handleRate(btn.rating),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(btn.label,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textColor)),
                              const SizedBox(height: 2),
                              Text(formatInterval(btn.interval),
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: textColor.withValues(alpha: 0.7))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
