import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/models/subscription.dart';

void main() {
  test('create lowercases id and defaults label to topic', () {
    final s = Subscription.create('Flutter', createdAt: DateTime.utc(2024));
    expect(s.id, 'flutter');
    expect(s.label, 'Flutter');
    expect(s.topic, 'Flutter');
  });

  test('create keeps a given label', () {
    final s = Subscription.create(
      'rust',
      label: 'Rust lang',
      createdAt: DateTime.utc(2024),
    );
    expect(s.label, 'Rust lang');
  });

  test('round-trips through json', () {
    final s = Subscription.create(
      'rust',
      label: 'Rust',
      createdAt: DateTime.utc(2024, 1, 1),
    );
    final back = Subscription.fromJson(s.toJson());
    expect(back.id, 'rust');
    expect(back.label, 'Rust');
    expect(back.topic, 'rust');
    expect(
      back.createdAt.millisecondsSinceEpoch,
      DateTime.utc(2024, 1, 1).millisecondsSinceEpoch,
    );
  });

  test('equality keyed on id (case-insensitive topic)', () {
    final a = Subscription.create('Rust', createdAt: DateTime.utc(2024));
    final b = Subscription.create('rust', createdAt: DateTime.utc(2025));
    expect(a, b);
  });
}
