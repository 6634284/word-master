import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../database/database_helper.dart';
import '../providers/settings_provider.dart';
import '../services/study_service.dart';
import '../widgets/header.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  StudyStats? stats;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final settings = ref.read(settingsProvider);
    final db = await DatabaseHelper.database;
    final data = await getStudyStats(db, settings.selectedBookId);
    if (mounted) {
      setState(() {
        stats = data;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading || stats == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Header(title: AppStrings.studyStats),
            Expanded(
              child: Center(
                child: Text('加载中...',
                    style: TextStyle(fontSize: 16, color: AppColors.outline)),
              ),
            ),
          ],
        ),
      );
    }

    final s = stats!;
    final totalWords = s.newCount + s.learningCount + s.reviewCount + s.relearningCount;
    final currentStreak =
        s.checkIns.isNotEmpty ? s.checkIns[0].streakCount as int : 0;

    final last7Days = List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      final dateStr = date.toIso8601String().split('T')[0];
      final log = s.studyLogs.cast().firstWhere(
            (l) => l.date == dateStr,
            orElse: () => null,
          );
      return (
        date: '${date.month}/${date.day}',
        count: log != null
            ? (log.newWordsLearned as int) + (log.wordsReviewed as int)
            : 0,
      );
    });

    final maxCount =
        last7Days.map((d) => d.count).reduce((a, b) => a > b ? a : b).clamp(1, 999999);

    final totalNew = s.studyLogs.fold<int>(0, (sum, l) => sum + (l.newWordsLearned as int));
    final totalReview =
        s.studyLogs.fold<int>(0, (sum, l) => sum + (l.wordsReviewed as int));
    final totalMinutes = (s.studyLogs.fold<int>(0, (sum, l) => sum + (l.totalStudyTime as int)) / 60)
        .round();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const Header(title: AppStrings.studyStats),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              children: [
                // Streak Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.streakBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x33C1C7D2)),
                  ),
                  child: Column(
                    children: [
                      const Text(AppStrings.streakLabel,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4E472B),
                              letterSpacing: 0.05)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$currentStreak',
                              style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.streakText)),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text('天',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.streakText)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Word Distribution
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x1AC1C7D2)),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(AppStrings.mastered,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDistItem(AppColors.surfaceContainerHighest,
                              AppStrings.notLearned, s.newCount),
                          _buildDistItem(AppColors.streakText,
                              AppStrings.learning, s.learningCount + s.relearningCount),
                          _buildDistItem(
                              AppColors.primary, AppStrings.learned, s.reviewCount),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 8,
                          child: Row(
                            children: [
                              if (totalWords > 0)
                                Expanded(
                                  flex: s.learningCount + s.relearningCount,
                                  child: Container(color: AppColors.streakText),
                                ),
                              if (totalWords > 0)
                                Expanded(
                                  flex: s.reviewCount,
                                  child: Container(color: AppColors.primary),
                                ),
                              if (totalWords > 0)
                                Expanded(
                                  flex: s.newCount,
                                  child: Container(color: AppColors.surfaceContainerHigh),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 7-Day Chart
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x1AC1C7D2)),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(AppStrings.recent7Days,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface)),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 120,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: last7Days.map((day) {
                            final heightPct = day.count / maxCount;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 90 * heightPct,
                                      decoration: BoxDecoration(
                                        color: day.count > 0
                                            ? AppColors.primary
                                            : AppColors.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      constraints:
                                          const BoxConstraints(minHeight: 4),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(day.date,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.outline)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Summary Cards
                Row(
                  children: [
                    Expanded(
                        child: _buildSummaryCard('$totalNew', AppStrings.totalNewWords)),
                    const SizedBox(width: 10),
                    Expanded(
                        child:
                            _buildSummaryCard('$totalReview', AppStrings.totalReviewWords)),
                    const SizedBox(width: 10),
                    Expanded(
                        child:
                            _buildSummaryCard('$totalMinutes', AppStrings.studyMinutes)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistItem(Color color, String label, int count) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text('$count',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface)),
      ],
    );
  }

  Widget _buildSummaryCard(String number, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1AC1C7D2)),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(number,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
