import 'dart:math';
import '../models/card.dart' as app;

// FSRS v4 parameters
const _requestRetention = 0.9;
const _maximumInterval = 365.0;

// FSRS v4 default parameters (w)
const _w = [
  0.4, 0.6, 2.4, 5.8, 4.93, 0.94, 0.86, 0.01,
  1.49, 0.14, 0.94, 2.18, 0.05, 0.34, 1.26, 0.29,
  2.61, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
];

// State: 0=New, 1=Learning, 2=Review, 3=Relearning
// Rating: 1=Again, 2=Hard, 3=Good

double _meanReversion(double param, double value) {
  return _w[7] * param + (1 - _w[7]) * value;
}

double _stabilityAfterSuccess(
    double stability, double difficulty, int elapsedDays, int rating) {
  if (stability <= 0) return _w[0] + _w[1] * difficulty;
  double hardPenalty = rating == 2 ? _w[15] : 1.0;
  double easyBonus = rating == 4 ? _w[16] : 1.0;
  return stability *
      (1 +
          exp(_w[8]) *
              (11 - difficulty) *
              pow(stability, -_w[9]) *
              (exp((1 - _w[10]) * elapsedDays) - 1) *
              hardPenalty *
              easyBonus);
}

double _stabilityAfterFailure(double stability, double difficulty) {
  return min(_w[11], pow(difficulty, -_w[12]).toDouble()) *
      pow(stability + 1.0, -_w[13]).toDouble() *
      (exp(_w[14] * (1 - difficulty)) - 1) *
      max(0.0, 1.0) +
      1.0;
}

int _nextInterval(double stability) {
  if (stability.isNaN || stability.isInfinite || stability <= 0) return 1;
  final interval =
      (stability / 1.0) * (pow(_requestRetention, 1.0 / _w[17]) - 1);
  if (interval.isNaN || interval.isInfinite) return 1;
  return max(1, min(interval.round(), _maximumInterval.round()));
}

double _nextDifficulty(int rating, double difficulty) {
  double nextD;
  if (rating == 1) {
    nextD = _meanReversion(_w[2], difficulty);
  } else {
    double delta = -_w[6] * (rating - 3);
    nextD = difficulty + delta * (10 - difficulty) / 9;
  }
  return max(1.0, min(nextD, 10.0));
}

_FSRSCard _scheduleNext(_FSRSCard card, int rating, DateTime now) {
  int elapsedDays =
      card.lastReview != null ? now.difference(card.lastReview!).inDays : 0;

  if (card.state == 0) {
    // New card
    double difficulty = _nextDifficulty(rating, _w[2]);
    double stability;
    if (rating == 1) {
      stability = _stabilityAfterFailure(0, difficulty);
    } else {
      stability = _stabilityAfterSuccess(0, difficulty, 0, rating);
    }
    int interval = rating == 1 ? 0 : _nextInterval(stability);
    return _FSRSCard(
      due: now.add(Duration(days: interval)),
      stability: stability,
      difficulty: difficulty,
      elapsedDays: 0,
      scheduledDays: interval,
      reps: 1,
      lapses: rating == 1 ? 1 : 0,
      state: rating == 1 ? 1 : 2,
      lastReview: now,
    );
  }

  if (rating == 1) {
    // Again
    double newDifficulty = _nextDifficulty(1, card.difficulty);
    double newStability = _stabilityAfterFailure(card.stability, card.difficulty);
    return _FSRSCard(
      due: now.add(const Duration(minutes: 5)),
      stability: newStability,
      difficulty: newDifficulty,
      elapsedDays: elapsedDays,
      scheduledDays: 0,
      reps: card.reps + 1,
      lapses: card.lapses + 1,
      state: 3,
      lastReview: now,
    );
  }

  double newDifficulty = _nextDifficulty(rating, card.difficulty);
  double newStability =
      _stabilityAfterSuccess(card.stability, card.difficulty, elapsedDays, rating);
  int newInterval = _nextInterval(newStability);

  return _FSRSCard(
    due: now.add(Duration(days: newInterval)),
    stability: newStability,
    difficulty: newDifficulty,
    elapsedDays: elapsedDays,
    scheduledDays: newInterval,
    reps: card.reps + 1,
    lapses: card.lapses,
    state: 2,
    lastReview: now,
  );
}

class _FSRSCard {
  final DateTime due;
  final double stability;
  final double difficulty;
  final int elapsedDays;
  final int scheduledDays;
  final int reps;
  final int lapses;
  final int state;
  final DateTime? lastReview;

  _FSRSCard({
    required this.due,
    required this.stability,
    required this.difficulty,
    required this.elapsedDays,
    required this.scheduledDays,
    required this.reps,
    required this.lapses,
    required this.state,
    this.lastReview,
  });
}

_FSRSCard _dbCardToFSRSCard(app.Card card) {
  return _FSRSCard(
    due: DateTime.fromMillisecondsSinceEpoch(card.due),
    stability: card.stability,
    difficulty: card.difficulty,
    elapsedDays: card.elapsedDays,
    scheduledDays: card.scheduledDays,
    reps: card.reps,
    lapses: card.lapses,
    state: card.state,
    lastReview: card.lastReview > 0
        ? DateTime.fromMillisecondsSinceEpoch(card.lastReview)
        : null,
  );
}

app.Card _fsrsCardToDbCard(int wordId, _FSRSCard card) {
  return app.Card(
    id: 0,
    wordId: wordId,
    due: card.due.millisecondsSinceEpoch,
    stability: card.stability,
    difficulty: card.difficulty,
    elapsedDays: card.elapsedDays,
    scheduledDays: card.scheduledDays,
    reps: card.reps,
    lapses: card.lapses,
    state: card.state,
    lastReview: card.lastReview?.millisecondsSinceEpoch ?? 0,
  );
}

enum AppRating { again, hard, good }

int _appRatingToFSRS(AppRating rating) {
  switch (rating) {
    case AppRating.again:
      return 1;
    case AppRating.hard:
      return 2;
    case AppRating.good:
      return 3;
  }
}

class ButtonPreview {
  final AppRating rating;
  final String label;
  final String color;
  final String bgColor;
  final int interval;

  ButtonPreview({
    required this.rating,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.interval,
  });
}

app.Card scheduleNext(app.Card card, AppRating rating) {
  final fsrsCard = _dbCardToFSRSCard(card);
  final now = DateTime.now();
  final result = _scheduleNext(fsrsCard, _appRatingToFSRS(rating), now);
  return _fsrsCardToDbCard(card.wordId, result);
}

List<ButtonPreview> getButtonPreviews(app.Card card) {
  final fsrsCard = _dbCardToFSRSCard(card);
  final now = DateTime.now();

  final ratings = [
    (AppRating.again, 1, '不认识', '#DC3545', 'rgba(220,53,69,0.1)'),
    (AppRating.hard, 2, '不确定', '#FFC107', 'rgba(255,193,7,0.1)'),
    (AppRating.good, 3, '认识', '#28A745', 'rgba(40,167,69,0.1)'),
  ];

  return ratings.map((r) {
    final result = _scheduleNext(fsrsCard, r.$2, now);
    final dueTime = result.due.millisecondsSinceEpoch;
    final nowTime = now.millisecondsSinceEpoch;
    final intervalMs = dueTime - nowTime;
    final intervalDays = intervalMs > 0
        ? max(1, (intervalMs / (1000 * 60 * 60 * 24)).ceil())
        : 1;
    return ButtonPreview(
      rating: r.$1,
      label: r.$3,
      color: r.$4,
      bgColor: r.$5,
      interval: intervalDays,
    );
  }).toList();
}
