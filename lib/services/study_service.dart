import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/word.dart';
import '../models/card.dart' as app;
import '../database/queries.dart' as queries;
import 'fsrs_service.dart';

class StudySession {
  final List<({Word word, app.Card card})> newWords;
  final List<({Word word, app.Card card})> reviewWords;

  StudySession({required this.newWords, required this.reviewWords});
}

Future<StudySession> getTodayStudyQueue(
    Database db, String bookId, int newWordsPerDay) async {
  final now = DateTime.now().millisecondsSinceEpoch;

  debugPrint('getTodayStudyQueue: bookId=$bookId, newWordsPerDay=$newWordsPerDay, now=$now');

  final dueCards = await queries.getDueCards(db, now, 10000);
  final newCards = await queries.getNewCards(db, bookId, newWordsPerDay);

  debugPrint('getTodayStudyQueue: dueCards=${dueCards.length}, newCards=${newCards.length}');

  final reviewWords = <({Word word, app.Card card})>[];
  for (final card in dueCards) {
    final word = await queries.getWordById(db, card.wordId);
    if (word != null) {
      reviewWords.add((word: word, card: card));
    }
  }

  final newWords = <({Word word, app.Card card})>[];
  for (final card in newCards) {
    final word = await queries.getWordById(db, card.wordId);
    if (word != null) {
      newWords.add((word: word, card: card));
    }
  }

  debugPrint('getTodayStudyQueue: reviewWords=${reviewWords.length}, newWords=${newWords.length}');
  return StudySession(newWords: newWords, reviewWords: reviewWords);
}

Future<app.Card> processRating(
    Database db, app.Card card, AppRating rating) async {
  final updatedCard = scheduleNext(card, rating);
  await queries.upsertCard(db, updatedCard);
  return updatedCard;
}

Future<void> recordStudy(
    Database db, bool isNewWord, int studyTimeSeconds) async {
  final today = DateTime.now().toIso8601String().split('T')[0];
  await queries.upsertStudyLog(
    db,
    date: today,
    newWordsLearned: isNewWord ? 1 : 0,
    wordsReviewed: isNewWord ? 0 : 1,
    totalStudyTime: studyTimeSeconds,
  );
}

Future<int> checkIn(Database db) async {
  final today = DateTime.now().toIso8601String().split('T')[0];
  final existing = await queries.getCheckIn(db, today);

  if (existing != null) {
    return existing.streakCount;
  }

  final yesterday =
      DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
  final yesterdayCheckIn = await queries.getCheckIn(db, yesterday);
  final streakCount = yesterdayCheckIn != null ? yesterdayCheckIn.streakCount + 1 : 1;

  await queries.createCheckIn(db, today, streakCount);
  return streakCount;
}

Future<StudyStats> getStudyStats(Database db, String bookId) async {
  final stateCounts = await queries.getCardCountByState(db, bookId);
  final studyLogs = await queries.getStudyLogs(db, 30);
  final checkIns = await queries.getCheckIns(db, 365);

  final stateMap = <int, int>{};
  for (final row in stateCounts) {
    stateMap[row['state'] as int] = row['count'] as int;
  }

  return StudyStats(
    newCount: stateMap[0] ?? 0,
    learningCount: stateMap[1] ?? 0,
    reviewCount: stateMap[2] ?? 0,
    relearningCount: stateMap[3] ?? 0,
    studyLogs: studyLogs,
    checkIns: checkIns,
  );
}

class StudyStats {
  final int newCount;
  final int learningCount;
  final int reviewCount;
  final int relearningCount;
  final List studyLogs;
  final List checkIns;

  StudyStats({
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
    required this.relearningCount,
    required this.studyLogs,
    required this.checkIns,
  });
}
