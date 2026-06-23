import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

Future<void> seedSampleData(Database db) async {
  final count = Sqflite.firstIntValue(
    await db.rawQuery('SELECT COUNT(*) FROM words WHERE book_id = ?', ['hongbaoshu_kaoyan']),
  );

  if (count == 5047) return;

  // Delete existing data
  await db.delete('cards');
  await db.delete('words');
  await db.delete('books');

  // Load JSON from assets
  final jsonStr = await rootBundle.loadString('assets/data/words.json');
  final List<dynamic> words = jsonDecode(jsonStr);

  // Insert book
  await db.insert('books', {
    'id': 'hongbaoshu_kaoyan',
    'name': '红宝书考研英语词汇（乱序版）',
    'word_count': words.length,
    'description': '涵盖核心词汇，适合冲刺阶段强化记忆。',
  });

  // Insert words in batches
  final batch = db.batch();
  for (final w in words) {
    batch.insert('words', {
      'id': w['wordIndex'],
      'word': w['word'],
      'phonetic': w['phonetic'] ?? '',
      'meaning': w['meaning'],
      'example': w['example'] ?? '',
      'book_id': w['bookId'],
      'word_index': w['wordIndex'],
    });
  }
  await batch.commit(noResult: true);
}
