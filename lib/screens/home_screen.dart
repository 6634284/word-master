import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../database/database_helper.dart';
import '../database/queries.dart' as queries;
import '../providers/settings_provider.dart';
import '../services/study_service.dart';
import '../widgets/header.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int newCount = 0;
  int reviewCount = 0;
  int streak = 0;
  int todayNew = 0;
  int todayReview = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final settings = ref.read(settingsProvider);
    final db = await DatabaseHelper.database;

    await queries.initCardsForBook(db, settings.selectedBookId);
    final queue =
        await getTodayStudyQueue(db, settings.selectedBookId, settings.newWordsPerDay);
    final currentStreak = await checkIn(db);
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayLog = await queries.getTodayStudyLog(db, today);

    if (mounted) {
      setState(() {
        newCount = queue.newWords.length;
        reviewCount = queue.reviewWords.length;
        streak = currentStreak;
        todayNew = todayLog?.newWordsLearned ?? 0;
        todayReview = todayLog?.wordsReviewed ?? 0;
      });
    }
  }

  void _handleStartStudy() {
    if (newCount == 0 && reviewCount == 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(AppStrings.hint),
          content: const Text(AppStrings.noWordsToday),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('确定')),
          ],
        ),
      );
      return;
    }
    Navigator.pushNamed(context, '/study').then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const Header(title: AppStrings.appName),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              children: [
                // Streak Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.streakBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x33C1C7D2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEBDFBA),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.local_fire_department,
                                color: AppColors.streakText, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(AppStrings.streakLabel,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF4E472B),
                                      letterSpacing: 0.05)),
                              Text('$streak天',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.streakText,
                                      height: 1.3)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0x4DD97706), width: 2),
                        ),
                        child: const Icon(Icons.flag,
                            color: AppColors.streakText, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Stats Card
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text(AppStrings.newWords,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.onSurfaceVariant,
                                    letterSpacing: 0.05)),
                            const SizedBox(height: 4),
                            Text('$todayNew',
                                style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    height: 1.2,
                                    letterSpacing: -0.02)),
                          ],
                        ),
                      ),
                      Container(
                          width: 1,
                          height: 48,
                          color: const Color(0x33C1C7D2)),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(AppStrings.review,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.onSurfaceVariant,
                                    letterSpacing: 0.05)),
                            const SizedBox(height: 4),
                            Text('$todayReview',
                                style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    height: 1.2,
                                    letterSpacing: -0.02)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Queue Card
                Container(
                  padding: const EdgeInsets.all(20),
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
                    children: [
                      _buildQueueRow(
                        icon: Icons.menu_book,
                        iconBg: const Color(0x262B78BF),
                        title: '${AppStrings.newWordQueue} $newCount 个',
                        count: '0/$newCount',
                        progress: 0,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      _buildQueueRow(
                        icon: Icons.history,
                        iconBg: const Color(0xFFE6F4F9),
                        title: '${AppStrings.reviewQueue} $reviewCount 个',
                        count: '0/$reviewCount',
                        progress: 0,
                        color: AppColors.tertiary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Start Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _handleStartStudy,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ctaButton,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      shadowColor: AppColors.ctaButton.withValues(alpha: 0.2),
                    ),
                    child: const Text(AppStrings.startStudy,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),

                // Bottom Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildGridItem(
                        icon: Icons.auto_stories,
                        label: AppStrings.bookList,
                        onTap: () => Navigator.pushNamed(context, '/book'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGridItem(
                        icon: Icons.bar_chart,
                        label: AppStrings.stats,
                        iconBg: const Color(0xFFE6F4F9),
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueRow({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String count,
    required double progress,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.onSurface)),
                  Text(count,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required String label,
    Color iconBg = const Color(0x262B78BF),
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1AC1C7D2)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface)),
          ],
        ),
      ),
    );
  }
}
