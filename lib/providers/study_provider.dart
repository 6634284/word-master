import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/word.dart';
import '../models/card.dart' as app;

class StudyWord {
  final Word word;
  final app.Card card;

  StudyWord({required this.word, required this.card});
}

class StudyState {
  final List<StudyWord> queue;
  final int currentIndex;
  final bool isFlipped;
  final int sessionStartTime;
  final int sessionNewCount;
  final int sessionReviewCount;

  StudyState({
    this.queue = const [],
    this.currentIndex = 0,
    this.isFlipped = false,
    this.sessionStartTime = 0,
    this.sessionNewCount = 0,
    this.sessionReviewCount = 0,
  });

  StudyState copyWith({
    List<StudyWord>? queue,
    int? currentIndex,
    bool? isFlipped,
    int? sessionStartTime,
    int? sessionNewCount,
    int? sessionReviewCount,
  }) =>
      StudyState(
        queue: queue ?? this.queue,
        currentIndex: currentIndex ?? this.currentIndex,
        isFlipped: isFlipped ?? this.isFlipped,
        sessionStartTime: sessionStartTime ?? this.sessionStartTime,
        sessionNewCount: sessionNewCount ?? this.sessionNewCount,
        sessionReviewCount: sessionReviewCount ?? this.sessionReviewCount,
      );

  StudyWord? get currentWord =>
      queue.isNotEmpty && currentIndex < queue.length ? queue[currentIndex] : null;

  ({int current, int total}) get progress =>
      (current: currentIndex + 1, total: queue.length);
}

class StudyNotifier extends StateNotifier<StudyState> {
  StudyNotifier() : super(StudyState());

  void setQueue(List<StudyWord> words) {
    state = StudyState(
      queue: words,
      currentIndex: 0,
      isFlipped: false,
      sessionStartTime: DateTime.now().millisecondsSinceEpoch,
      sessionNewCount: 0,
      sessionReviewCount: 0,
    );
  }

  void updateCurrentCard(app.Card card) {
    final current = state.currentWord;
    if (current == null) return;
    final newQueue = List<StudyWord>.from(state.queue);
    newQueue[state.currentIndex] = StudyWord(word: current.word, card: card);
    state = state.copyWith(queue: newQueue);
  }

  void flipCard() => state = state.copyWith(isFlipped: true);
  void resetFlip() => state = state.copyWith(isFlipped: false);

  bool moveToNext() {
    if (state.currentIndex + 1 >= state.queue.length) return false;
    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      isFlipped: false,
    );
    return true;
  }

  void incrementNewCount() =>
      state = state.copyWith(sessionNewCount: state.sessionNewCount + 1);

  void incrementReviewCount() =>
      state = state.copyWith(sessionReviewCount: state.sessionReviewCount + 1);

  void resetSession() => state = StudyState();
}

final studyProvider =
    StateNotifierProvider<StudyNotifier, StudyState>((ref) {
  return StudyNotifier();
});
