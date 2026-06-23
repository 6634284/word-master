class CheckIn {
  final int id;
  final String date;
  final int streakCount;

  CheckIn({
    required this.id,
    required this.date,
    required this.streakCount,
  });

  factory CheckIn.fromMap(Map<String, dynamic> map) => CheckIn(
        id: map['id'] as int,
        date: map['date'] as String,
        streakCount: map['streakCount'] as int,
      );
}
