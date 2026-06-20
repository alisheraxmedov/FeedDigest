import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/core/utils/formatters.dart';

void main() {
  test('compactScore formats thousands and millions', () {
    expect(Formatters.compactScore(999), '999');
    expect(Formatters.compactScore(1500), '1.5k');
    expect(Formatters.compactScore(2000000), '2.0M');
  });

  test('timeAgo uses injected now', () {
    final now = DateTime.utc(2024, 1, 1, 12, 0, 0);
    final created =
        now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch / 1000;
    expect(Formatters.timeAgo(created, now: now), '3h');
  });
}
