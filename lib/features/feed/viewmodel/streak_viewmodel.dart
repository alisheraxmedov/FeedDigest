/*
Local reading streak: consecutive calendar days on which the reader opened at
least one article. Purely on-device (meta box), no account. Recorded from the
detail screen when an article opens; shown as a flame chip in the feed app bar.
*/
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

@immutable
class StreakState {
  const StreakState({this.current = 0, this.best = 0, this.lastDay = -1});

  final int current;
  final int best;

  /// Days since the Unix epoch (local midnight) of the last active day.
  final int lastDay;
}

final streakProvider =
    NotifierProvider<StreakController, StreakState>(StreakController.new);

class StreakController extends Notifier<StreakState> {
  static const String _kCurrent = 'streak_current';
  static const String _kBest = 'streak_best';
  static const String _kLastDay = 'streak_last_day';

  @override
  StreakState build() {
    final box = ref.read(metaBoxProvider);
    return StreakState(
      current: box.get(_kCurrent) as int? ?? 0,
      best: box.get(_kBest) as int? ?? 0,
      lastDay: box.get(_kLastDay) as int? ?? -1,
    );
  }

  /// Records activity for [dayIndex] (local days since epoch). Same day → no-op;
  /// consecutive day → streak grows; a gap → streak resets to 1.
  Future<void> recordActivity(int dayIndex) async {
    if (state.lastDay == dayIndex) return;
    final current = state.lastDay == dayIndex - 1 ? state.current + 1 : 1;
    final best = current > state.best ? current : state.best;
    state = StreakState(current: current, best: best, lastDay: dayIndex);
    final box = ref.read(metaBoxProvider);
    await box.putAll({
      _kCurrent: current,
      _kBest: best,
      _kLastDay: dayIndex,
    });
    await box.flush();
  }
}
