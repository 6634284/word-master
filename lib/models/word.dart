class Word {
  final int id;
  final String word;
  final String phonetic;
  final String meaning;
  final String example;
  final String bookId;
  final int wordIndex;

  Word({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.meaning,
    required this.example,
    required this.bookId,
    required this.wordIndex,
  });

  factory Word.fromMap(Map<String, dynamic> map) => Word(
        id: map['id'] as int,
        word: map['word'] as String,
        phonetic: (map['phonetic'] as String?) ?? '',
        meaning: map['meaning'] as String,
        example: (map['example'] as String?) ?? '',
        bookId: map['bookId'] as String,
        wordIndex: map['wordIndex'] as int,
      );
}
