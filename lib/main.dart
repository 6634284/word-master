import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/database_helper.dart';
import 'database/seed_data.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database and seed data
  final db = await DatabaseHelper.database;
  await seedSampleData(db);

  runApp(const ProviderScope(child: WordMasterApp()));
}
