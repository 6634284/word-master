import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vocab.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        word_count INTEGER NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE words (
        id INTEGER PRIMARY KEY NOT NULL,
        word TEXT NOT NULL,
        phonetic TEXT,
        meaning TEXT NOT NULL,
        example TEXT,
        book_id TEXT NOT NULL,
        word_index INTEGER NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id INTEGER NOT NULL UNIQUE,
        due INTEGER NOT NULL,
        stability REAL NOT NULL DEFAULT 0,
        difficulty REAL NOT NULL DEFAULT 0,
        elapsed_days INTEGER NOT NULL DEFAULT 0,
        scheduled_days INTEGER NOT NULL DEFAULT 0,
        reps INTEGER NOT NULL DEFAULT 0,
        lapses INTEGER NOT NULL DEFAULT 0,
        state INTEGER NOT NULL DEFAULT 0,
        last_review INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (word_id) REFERENCES words(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE study_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        new_words_learned INTEGER NOT NULL DEFAULT 0,
        words_reviewed INTEGER NOT NULL DEFAULT 0,
        total_study_time INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE check_ins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        streak_count INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('CREATE INDEX idx_cards_due ON cards(due)');
    await db.execute('CREATE INDEX idx_cards_state ON cards(state)');
    await db.execute('CREATE INDEX idx_words_book ON words(book_id)');
    await db.execute('CREATE INDEX idx_study_logs_date ON study_logs(date)');
    await db.execute('CREATE INDEX idx_check_ins_date ON check_ins(date)');
  }
}
