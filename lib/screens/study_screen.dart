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
      debugPrint('=== _loadQueue: START ===');
      final session = await getTodayStudyQueue(
          db, settings.selectedBookId, settings.newWordsPerDay);
      debugPrint('=== _loadQueue: got session, new=${session.newWords.length}, review=${session.reviewWords.length} ===');

      final allWords = [
        ...session.newWords.map((w) => StudyWord(word: w.word, card: w.card)),
        ...session.reviewWords.map((w) => StudyWord(word: w.word, card: w.card)),
      ];
      debugPrint('=== _loadQueue: allWords.length=${allWords.length} ===');

      if (allWords.isEmpty) {
        debugPrint('=== _loadQueue: EMPTY queue ===');
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(AppStrings.hint),
              content: Text(AppStrings.noStudyWords),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: Text('确定')),
              ],
            ),
          );
        }
        setState(() => loading = false);
        return;
      }

      debugPrint('=== _loadQueue: calling setQueue ===');
      ref.read(studyProvider.notifier).setQueue(allWords);
      debugPrint('=== _loadQueue: setQueue done, calling _updatePreviews ===');
      _updatePreviews();
      debugPrint('=== _loadQueue: _updatePreviews done ===');
    } catch (e, stackTrace) {
      debugPrint('Study queue error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppStrings.error),
            content: Text(AppStrings.loadFailed),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: Text('确定')),
            ],
          ),
        );
      }
    }

    if (mounted) setState(() => loading = false);
  }

  void _updatePreviews() {
    try {
      final studyState = ref.read(studyProvider);
      if (studyState.currentWord != null) {
        previews = getButtonPreviews(studyState.currentWord!.card);
      }
    } catch (e) {
      debugPrint('=== _updatePreviews error: $e ===');
    }
  }

  void _handleShowMeaning() {
    if (showMeaning) return;
    try {
      Haptics.vibrate(HapticsType.light);
    } catch (e) {
      debugPrint('=== Haptics.vibrate light error: $e ===');
    }
    setState(() => showMeaning = true);
  }

  void _handleSpeak(String text) {
    tts.speak(text);
  }

  Future<void> _handleRate(AppRating rating) async {
    final studyState = ref.read(studyProvider);
    if (studyState.currentWord == null || ratingDisabled) return;

    setState(() => ratingDisabled = true);
    try {
      Haptics.vibrate(HapticsType.medium);
    } catch (e) {
      debugPrint('=== Haptics.vibrate medium error: $e ===');
    }

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
              title: Text('完成'),
              content: Text(AppStrings.studyComplete),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: Text('确定')),
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
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: Text(AppStrings.preparing,
                style: TextStyle(fontSize: 16, color: AppColors.outline))),
      );
    }

    final currentWord = studyState.currentWord;
    if (currentWord == null) {
      return Scaffold(
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
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 24, right: 24, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(Icons.close, size: 24, color: AppColors.onSurfaceVariant),
                    ),
                  ),
                  Text('${progress.current} / ${progress.total}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.outline,
                          letterSpacing: 0.05)),
                  SizedBox(
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
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 4,
            ),

            // Word Area
            Expanded(
              child: Column(
                children: [
                  // Word
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                    child: Column(
                      children: [
                        Center(
                          child: Text(word.word,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                  letterSpacing: -0.02)),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (word.phonetic.isNotEmpty)
                              Text(word.phonetic,
                                  style: TextStyle(
                                      fontSize: 16, color: AppColors.outline)),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _handleSpeak(word.word),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.volume_up,
                                    color: AppColors.primary, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Cover or Meaning
                  Expanded(
                    child: !showMeaning
                        ? GestureDetector(
                            onTap: _handleShowMeaning,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: double.infinity,
                              alignment: Alignment.center,
                              color: Colors.transparent,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility_off,
                                      size: 32, color: AppColors.outlineVariant),
                                  SizedBox(height: 16),
                                  Text(AppStrings.recallHint,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.outline)),
                                  SizedBox(height: 8),
                                  Text(AppStrings.tapToShow,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.outlineVariant)),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              children: [
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
                                SizedBox(height: 20),
                                Text(word.meaning,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.onSurface,
                                        height: 1.5)),
                                if (word.example.isNotEmpty) ...[
                                  SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(AppStrings.exampleLabel,
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary)),
                                        SizedBox(height: 8),
                                        Text(word.example,
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.onSurfaceVariant,
                                                height: 1.6)),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // Rating Buttons (fixed at bottom)
            if (showMeaning)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
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
                                SizedBox(height: 2),
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
      ),
    );
  }
}
