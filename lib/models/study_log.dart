class StudyLog {
  final int id;
  final String date;
  final int newWordsLearned;
  final int wordsReviewed;
  final int totalStudyTime;

  StudyLog({
    required this.id,
    required this.date,
    required this.newWordsLearned,
    required this.wordsReviewed,
    required this.totalStudyTime,
  });

  factory StudyLog.fromMap(Map<String, dynamic> map) => StudyLog(
        id: map['id'] as int,
        date: map['date'] as String,
        newWordsLearned: map['newWordsLearned'] as int,
        wordsReviewed: map['wordsReviewed'] as int,
        totalStudyTime: map['totalStudyTime'] as int,
      );
}
