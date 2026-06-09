import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/core/utils/formatters.dart';

void main() {
  group('Formatters.compactNumber', () {
    test('formats thousands and millions', () {
      expect(Formatters.compactNumber(999), '999');
      expect(Formatters.compactNumber(1000), '1k');
      expect(Formatters.compactNumber(1234), '1.2k');
      expect(Formatters.compactNumber(1500000), '1.5m');
    });
  });

  group('Formatters.timeAgo', () {
    test('returns "hozir" for a very recent time', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      expect(Formatters.timeAgo(now), 'hozir');
    });

    test('returns hours for an older time', () {
      final threeHoursAgo = DateTime.now()
              .subtract(const Duration(hours: 3))
              .millisecondsSinceEpoch ~/
          1000;
      expect(Formatters.timeAgo(threeHoursAgo), '3 soat');
    });
  });

  group('Formatters.unescapeHtml', () {
    test('decodes common entities', () {
      expect(Formatters.unescapeHtml('a &amp; b'), 'a & b');
      expect(Formatters.unescapeHtml('&lt;tag&gt;'), '<tag>');
    });
  });
}
