import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeData {
  final int newCount;
  final int reviewCount;
  final int streak;
  final int todayNew;
  final int todayReview;

  HomeData({
    required this.newCount,
    required this.reviewCount,
    required this.streak,
    required this.todayNew,
    required this.todayReview,
  });
}

/// Pre-loaded home data from main.dart, available immediately on first frame
final homeDataSeedProvider = Provider<HomeData?>((ref) => null);
