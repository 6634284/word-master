import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../database/database_helper.dart';
import '../database/queries.dart' as queries;
import '../models/book.dart';
import '../models/word.dart';
import '../providers/settings_provider.dart';
import '../widgets/header.dart';

class BookListScreen extends ConsumerStatefulWidget {
  const BookListScreen({super.key});

  @override
  ConsumerState<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends ConsumerState<BookListScreen> {
  List<Book> books = [];
  List<Word> words = [];
  bool loading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final settings = ref.read(settingsProvider);
    final db = await DatabaseHelper.database;

    final bookData = await queries.getAllBooks(db);
    List<Word> wordData = [];
    if (settings.selectedBookId.isNotEmpty) {
      wordData = await queries.getWordsByBook(db, settings.selectedBookId, limit: 10);
    }

    if (mounted) {
      setState(() {
        books = bookData;
        words = wordData;
        loading = false;
      });
    }
  }

  Future<void> _handleSelectBook(Book book) async {
    ref.read(settingsProvider.notifier).setSelectedBookId(book.id);
    final db = await DatabaseHelper.database;
    final wordData = await queries.getWordsByBook(db, book.id, limit: 10);
    if (mounted) setState(() => words = wordData);
  }

  @override
  Widget build(BuildContext context) {
    final selectedBookId = ref.watch(settingsProvider).selectedBookId;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: loading
          ? Center(
              child: Text('加载中...',
                  style: TextStyle(fontSize: 16, color: AppColors.outline)))
          : Column(
              children: [
                const Header(title: AppStrings.bookList, showBack: true),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      // Search Bar
                      Container(
                        margin: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 16, right: 8),
                              child: Icon(Icons.search,
                                  size: 20, color: AppColors.outline),
                            ),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: AppStrings.searchWords,
                                  hintStyle: TextStyle(color: AppColors.outlineVariant),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                                ),
                                style: TextStyle(
                                    fontSize: 17, color: AppColors.onSurface),
                                onChanged: (q) => setState(() => searchQuery = q),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Book Cards - Horizontal Scroll
                      SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: books.length,
                          separatorBuilder: (_, __) => SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final book = books[index];
                            final isActive = selectedBookId == book.id;
                            return GestureDetector(
                              onTap: () => _handleSelectBook(book),
                              child: Container(
                                width: 260,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.bookSelectedBg
                                      : AppColors.surfaceLowest,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.primary
                                        : AppColors.outlineVariant,
                                  ),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                              color: AppColors.primary.withValues(alpha: 0.05),
                                              blurRadius: 20,
                                              offset: const Offset(0, 4))
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isActive)
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: Icon(Icons.check_circle,
                                            size: 24, color: AppColors.primary),
                                      ),
                                    Text(book.name,
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: isActive
                                                ? AppColors.bookSelectedTitle
                                                : AppColors.onSurface)),
                                    SizedBox(height: 4),
                                    Text('${book.wordCount} 词',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isActive
                                                ? FontWeight.w500
                                                : FontWeight.w400,
                                            color: isActive
                                                ? AppColors.primaryContainer
                                                : AppColors.onSurfaceVariant)),
                                    SizedBox(height: 8),
                                    Expanded(
                                      child: Text(
                                          book.description.isNotEmpty
                                              ? book.description
                                              : '涵盖核心词汇，适合冲刺阶段强化记忆。',
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w400,
                                              color: isActive
                                                  ? AppColors.onSurfaceVariant
                                                  : AppColors.outline,
                                              height: 1.5)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Word List
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLowest,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 10,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: AppColors.surfaceContainer)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(AppStrings.todayReviewTask,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.onSurfaceVariant)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.bookSelectedBg,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                        '${AppStrings.remainingWords} ${words.length} 词',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.primary)),
                                  ),
                                ],
                              ),
                            ),
                            ...words.map((word) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            color: AppColors.surfaceContainer)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(word.word,
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.onSurface)),
                                            SizedBox(height: 2),
                                            if (word.phonetic.isNotEmpty)
                                              Text(word.phonetic,
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: AppColors.outline)),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.4,
                                        child: Text(word.meaning,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.end,
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w400,
                                                color: AppColors.onSurfaceVariant)),
                                      ),
                                    ],
                                  ),
                                )),
                            if (words.isNotEmpty)
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context, '/book/$selectedBookId'),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Text(AppStrings.viewAllWords,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.primary)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
