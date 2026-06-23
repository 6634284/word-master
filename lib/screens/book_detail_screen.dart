import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../database/database_helper.dart';
import '../database/queries.dart' as queries;
import '../models/word.dart';

class BookDetailScreen extends StatefulWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  List<Word> words = [];
  bool loading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final db = await DatabaseHelper.database;
    final data = await queries.getWordsByBook(db, widget.bookId);
    if (mounted) setState(() { words = data; loading = false; });
  }

  Future<void> _handleSearch(String query) async {
    setState(() => searchQuery = query);
    final db = await DatabaseHelper.database;
    if (query.trim().isEmpty) {
      _loadWords();
      return;
    }
    final results = await queries.searchWords(db, widget.bookId, query);
    if (mounted) setState(() => words = results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('词书详情'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: loading
          ? const Center(
              child: Text('加载中...',
                  style: TextStyle(fontSize: 16, color: AppColors.outline)))
          : Column(
              children: [
                // Search
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: AppStrings.searchWords,
                      filled: true,
                      fillColor: AppColors.surfaceLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.surfaceContainerHigh),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.surfaceContainerHigh),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 16, color: AppColors.onSurface),
                    onChanged: _handleSearch,
                  ),
                ),
                // Word List
                Expanded(
                  child: words.isEmpty
                      ? Center(
                          child: Text(
                            searchQuery.isNotEmpty
                                ? AppStrings.noMatchFound
                                : AppStrings.noWords,
                            style: const TextStyle(
                                fontSize: 16, color: AppColors.outline),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: words.length,
                          itemBuilder: (context, index) {
                            final word = words[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLowest,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(word.word,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.onSurface)),
                                      if (word.phonetic.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(word.phonetic,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: AppColors.outline)),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(word.meaning,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          color: AppColors.onSurfaceVariant,
                                          height: 1.5)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
