import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/features/feed/viewmodel/streak_viewmodel.dart';

void main() {
  group('streak day index', () {
    test(
      'consecutive calendar days always differ by exactly 1 (EU DST fall-back)',
      () {
        // 25 Oct 2026 is the European DST→standard transition; a local-midnight
        // epoch division breaks the +1 invariant here, a UTC-anchored one holds.
        final a = dayIndexForDate(2026, 10, 25);
        final b = dayIndexForDate(2026, 10, 26);
        expect(b - a, 1);
      },
    );

    test('consecutive calendar days differ by 1 across spring-forward', () {
      final a = dayIndexForDate(2026, 3, 29); // EU spring-forward
      final b = dayIndexForDate(2026, 3, 30);
      expect(b - a, 1);
    });

    test(
      'localDayIndex depends only on the calendar date, not wall-clock time',
      () {
        final justAfterMidnight = localDayIndex(DateTime(2026, 6, 1, 0, 5));
        final lateNight = localDayIndex(DateTime(2026, 6, 1, 23, 55));
        expect(justAfterMidnight, lateNight);
      },
    );
  });
}
