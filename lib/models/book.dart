class Book {
  final String id;
  final String name;
  final int wordCount;
  final String description;

  Book({
    required this.id,
    required this.name,
    required this.wordCount,
    required this.description,
  });

  factory Book.fromMap(Map<String, dynamic> map) => Book(
        id: map['id'] as String,
        name: map['name'] as String,
        wordCount: map['wordCount'] as int,
        description: (map['description'] as String?) ?? '',
      );
}
