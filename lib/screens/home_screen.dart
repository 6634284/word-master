import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../database/database_helper.dart';
import '../database/queries.dart' as queries;
import '../providers/home_data_provider.dart';
import '../providers/settings_provider.dart';
import '../services/study_service.dart';
import '../widgets/header.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onStatsTap;
  const HomeScreen({super.key, this.onStatsTap});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int newCount;
  late int reviewCount;
  late int streak;
  late int todayNew;
  late int todayReview;

  @override
  void initState() {
    super.initState();
    // Use pre-loaded data from main.dart (available immediately)
    final seed = ref.read(homeDataSeedProvider);
    newCount = seed?.newCount ?? 0;
    reviewCount = seed?.reviewCount ?? 0;
    streak = seed?.streak ?? 0;
    todayNew = seed?.todayNew ?? 0;
    todayReview = seed?.todayReview ?? 0;
    // Refresh in background for latest data
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

    debugPrint('=== HOME _loadData: newWordsPerDay=${settings.newWordsPerDay}, newCount=${queue.newWords.length}, reviewCount=${queue.reviewWords.length} ===');

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
          title: Text(AppStrings.hint),
          content: Text(AppStrings.noWordsToday),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('确定')),
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
                    border: Border.all(color: AppColors.cardBorderStrong),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.streakIconBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.local_fire_department,
                                color: AppColors.streakText, size: 26),
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppStrings.streakLabel,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.streakLabelText,
                                      letterSpacing: 0.05)),
                              Text('$streak天',
                                  style: TextStyle(
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
                              color: AppColors.streakText.withValues(alpha: 0.3), width: 2),
                        ),
                        child: Icon(Icons.flag,
                            color: AppColors.streakText, size: 18),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),

                // Stats Card
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
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
                            Text(AppStrings.newWords,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.onSurfaceVariant,
                                    letterSpacing: 0.05)),
                            SizedBox(height: 4),
                            Text('$todayNew',
                                style: TextStyle(
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
                          color: AppColors.cardBorderStrong),
                      Expanded(
                        child: Column(
                          children: [
                            Text(AppStrings.review,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.onSurfaceVariant,
                                    letterSpacing: 0.05)),
                            SizedBox(height: 4),
                            Text('$todayReview',
                                style: TextStyle(
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
                SizedBox(height: 12),

                // Queue Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
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
                        iconBg: AppColors.queueIconBg,
                        title: '${AppStrings.newWordQueue} $newCount 个',
                        count: '$todayNew/$newCount',
                        progress: newCount > 0 ? todayNew / newCount : 0,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 16),
                      _buildQueueRow(
                        icon: Icons.history,
                        iconBg: AppColors.queueIconBgAlt,
                        title: '${AppStrings.reviewQueue} $reviewCount 个',
                        count: '$todayReview/$reviewCount',
                        progress: reviewCount > 0 ? todayReview / reviewCount : 0,
                        color: AppColors.tertiary,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),

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
                    child: Text(AppStrings.startStudy,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onPrimary)),
                  ),
                ),
                SizedBox(height: 12),

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
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildGridItem(
                        icon: Icons.bar_chart,
                        label: AppStrings.stats,
                        iconBg: AppColors.queueIconBgAlt,
                        onTap: widget.onStatsTap ?? () {},
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
        SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.onSurface)),
                  Text(count,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant)),
                ],
              ),
              SizedBox(height: 8),
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
    Color? iconBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadow,
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
            SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface)),
          ],
        ),
      ),
    );
  }
}
