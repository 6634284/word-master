class Card {
  final int id;
  final int wordId;
  final int due;
  final double stability;
  final double difficulty;
  final int elapsedDays;
  final int scheduledDays;
  final int reps;
  final int lapses;
  final int state;
  final int lastReview;

  Card({
    required this.id,
    required this.wordId,
    required this.due,
    required this.stability,
    required this.difficulty,
    required this.elapsedDays,
    required this.scheduledDays,
    required this.reps,
    required this.lapses,
    required this.state,
    required this.lastReview,
  });

  factory Card.fromMap(Map<String, dynamic> map) => Card(
        id: map['id'] as int,
        wordId: map['wordId'] as int,
        due: map['due'] as int,
        stability: (map['stability'] as num).toDouble(),
        difficulty: (map['difficulty'] as num).toDouble(),
        elapsedDays: map['elapsedDays'] as int,
        scheduledDays: map['scheduledDays'] as int,
        reps: map['reps'] as int,
        lapses: map['lapses'] as int,
        state: map['state'] as int,
        lastReview: map['lastReview'] as int,
      );

  Card copyWith({
    int? id,
    int? wordId,
    int? due,
    double? stability,
    double? difficulty,
    int? elapsedDays,
    int? scheduledDays,
    int? reps,
    int? lapses,
    int? state,
    int? lastReview,
  }) =>
      Card(
        id: id ?? this.id,
        wordId: wordId ?? this.wordId,
        due: due ?? this.due,
        stability: stability ?? this.stability,
        difficulty: difficulty ?? this.difficulty,
        elapsedDays: elapsedDays ?? this.elapsedDays,
        scheduledDays: scheduledDays ?? this.scheduledDays,
        reps: reps ?? this.reps,
        lapses: lapses ?? this.lapses,
        state: state ?? this.state,
        lastReview: lastReview ?? this.lastReview,
      );
}
