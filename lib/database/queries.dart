import 'package:sqflite/sqflite.dart';
import '../models/word.dart';
import '../models/card.dart';
import '../models/book.dart';
import '../models/study_log.dart';
import '../models/check_in.dart';

// Books
Future<List<Book>> getAllBooks(Database db) async {
  final maps = await db.rawQuery(
    'SELECT id, name, word_count as wordCount, description FROM books',
  );
  return maps.map(Book.fromMap).toList();
}

Future<Book?> getBookById(Database db, String id) async {
  final maps = await db.rawQuery(
    'SELECT id, name, word_count as wordCount, description FROM books WHERE id = ?',
    [id],
  );
  return maps.isEmpty ? null : Book.fromMap(maps.first);
}

// Words
Future<List<Word>> getWordsByBook(Database db, String bookId,
    {int? limit, int? offset}) async {
  if (limit != null) {
    final maps = await db.rawQuery(
      'SELECT id, word, phonetic, meaning, example, book_id as bookId, word_index as wordIndex FROM words WHERE book_id = ? LIMIT ? OFFSET ?',
      [bookId, limit, offset ?? 0],
    );
    return maps.map(Word.fromMap).toList();
  }
  final maps = await db.rawQuery(
    'SELECT id, word, phonetic, meaning, example, book_id as bookId, word_index as wordIndex FROM words WHERE book_id = ?',
    [bookId],
  );
  return maps.map(Word.fromMap).toList();
}

Future<Word?> getWordById(Database db, int id) async {
  final maps = await db.rawQuery(
    'SELECT id, word, phonetic, meaning, example, book_id as bookId, word_index as wordIndex FROM words WHERE id = ?',
    [id],
  );
  return maps.isEmpty ? null : Word.fromMap(maps.first);
}

Future<List<Word>> searchWords(Database db, String bookId, String keyword) async {
  final maps = await db.rawQuery(
    'SELECT id, word, phonetic, meaning, example, book_id as bookId, word_index as wordIndex FROM words WHERE book_id = ? AND (word LIKE ? OR meaning LIKE ?)',
    [bookId, '%$keyword%', '%$keyword%'],
  );
  return maps.map(Word.fromMap).toList();
}

// Cards
Future<Card?> getCardByWordId(Database db, int wordId) async {
  final maps = await db.rawQuery(
    '''SELECT id, word_id as wordId, due, stability, difficulty,
       elapsed_days as elapsedDays, scheduled_days as scheduledDays,
       reps, lapses, state, last_review as lastReview
       FROM cards WHERE word_id = ?''',
    [wordId],
  );
  return maps.isEmpty ? null : Card.fromMap(maps.first);
}

Future<List<Card>> getDueCards(Database db, int now, int limit) async {
  final maps = await db.rawQuery(
    '''SELECT id, word_id as wordId, due, stability, difficulty,
       elapsed_days as elapsedDays, scheduled_days as scheduledDays,
       reps, lapses, state, last_review as lastReview
       FROM cards WHERE due <= ? AND state != 0
       ORDER BY due ASC LIMIT ?''',
    [now, limit],
  );
  return maps.map(Card.fromMap).toList();
}

Future<List<Card>> getNewCards(Database db, String bookId, int limit) async {
  final maps = await db.rawQuery(
    '''SELECT c.id, c.word_id as wordId, c.due, c.stability, c.difficulty,
       c.elapsed_days as elapsedDays, c.scheduled_days as scheduledDays,
       c.reps, c.lapses, c.state, c.last_review as lastReview
       FROM cards c
       JOIN words w ON c.word_id = w.id
       WHERE w.book_id = ? AND c.state = 0
       ORDER BY w.word_index ASC LIMIT ?''',
    [bookId, limit],
  );
  return maps.map(Card.fromMap).toList();
}

Future<void> upsertCard(Database db, Card card) async {
  await db.rawInsert(
    '''INSERT INTO cards (word_id, due, stability, difficulty, elapsed_days, scheduled_days, reps, lapses, state, last_review)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(word_id) DO UPDATE SET
         due = excluded.due,
         stability = excluded.stability,
         difficulty = excluded.difficulty,
         elapsed_days = excluded.elapsed_days,
         scheduled_days = excluded.scheduled_days,
         reps = excluded.reps,
         lapses = excluded.lapses,
         state = excluded.state,
         last_review = excluded.last_review''',
    [
      card.wordId, card.due, card.stability, card.difficulty,
      card.elapsedDays, card.scheduledDays, card.reps, card.lapses,
      card.state, card.lastReview,
    ],
  );
}

Future<List<Map<String, dynamic>>> getCardCountByState(
    Database db, String bookId) async {
  return db.rawQuery(
    '''SELECT c.state, COUNT(*) as count
       FROM cards c JOIN words w ON c.word_id = w.id
       WHERE w.book_id = ?
       GROUP BY c.state''',
    [bookId],
  );
}

Future<void> initCardsForBook(Database db, String bookId) async {
  await db.rawInsert(
    '''INSERT OR IGNORE INTO cards (word_id, due, stability, difficulty, elapsed_days, scheduled_days, reps, lapses, state, last_review)
       SELECT id, 0, 0, 0, 0, 0, 0, 0, 0, 0 FROM words WHERE book_id = ?''',
    [bookId],
  );
}

// Study Logs
Future<StudyLog?> getTodayStudyLog(Database db, String date) async {
  final maps = await db.rawQuery(
    '''SELECT id, date, new_words_learned as newWordsLearned,
       words_reviewed as wordsReviewed, total_study_time as totalStudyTime
       FROM study_logs WHERE date = ?''',
    [date],
  );
  return maps.isEmpty ? null : StudyLog.fromMap(maps.first);
}

Future<void> upsertStudyLog(Database db,
    {required String date,
    required int newWordsLearned,
    required int wordsReviewed,
    required int totalStudyTime}) async {
  await db.rawInsert(
    '''INSERT INTO study_logs (date, new_words_learned, words_reviewed, total_study_time)
       VALUES (?, ?, ?, ?)
       ON CONFLICT(date) DO UPDATE SET
         new_words_learned = new_words_learned + excluded.new_words_learned,
         words_reviewed = words_reviewed + excluded.words_reviewed,
         total_study_time = total_study_time + excluded.total_study_time''',
    [date, newWordsLearned, wordsReviewed, totalStudyTime],
  );
}

Future<List<StudyLog>> getStudyLogs(Database db, int days) async {
  final maps = await db.rawQuery(
    '''SELECT id, date, new_words_learned as newWordsLearned,
       words_reviewed as wordsReviewed, total_study_time as totalStudyTime
       FROM study_logs ORDER BY date DESC LIMIT ?''',
    [days],
  );
  return maps.map(StudyLog.fromMap).toList();
}

// Check-ins
Future<CheckIn?> getCheckIn(Database db, String date) async {
  final maps = await db.rawQuery(
    'SELECT id, date, streak_count as streakCount FROM check_ins WHERE date = ?',
    [date],
  );
  return maps.isEmpty ? null : CheckIn.fromMap(maps.first);
}

Future<void> createCheckIn(Database db, String date, int streakCount) async {
  await db.rawInsert(
    'INSERT OR IGNORE INTO check_ins (date, streak_count) VALUES (?, ?)',
    [date, streakCount],
  );
}

Future<List<CheckIn>> getCheckIns(Database db, int days) async {
  final maps = await db.rawQuery(
    'SELECT id, date, streak_count as streakCount FROM check_ins ORDER BY date DESC LIMIT ?',
    [days],
  );
  return maps.map(CheckIn.fromMap).toList();
}
