import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/core/constants/interests.dart';
import 'package:feeddigest/features/interests/viewmodel/interests_viewmodel.dart';

void main() {
  group('InterestCatalog', () {
    final all = InterestCatalog.groups.expand((g) => g.interests).toList();

    test('has groups and a reasonable number of interests', () {
      expect(InterestCatalog.groups, isNotEmpty);
      expect(all.length, greaterThan(10));
    });

    test('topics are unique, lowercase, non-empty; labels non-empty', () {
      final topics = all.map((i) => i.topic).toList();
      expect(topics.toSet().length, topics.length, reason: 'duplicate topic');
      for (final interest in all) {
        expect(interest.topic, isNotEmpty);
        expect(interest.topic, interest.topic.toLowerCase());
        expect(interest.label.trim(), isNotEmpty);
      }
    });
  });

  group('InterestsSelectionController', () {
    test('toggle adds then removes a topic', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(interestsSelectionProvider.notifier);

      expect(container.read(interestsSelectionProvider), isEmpty);
      notifier.toggle('flutter');
      expect(container.read(interestsSelectionProvider), {'flutter'});
      notifier.toggle('rust');
      expect(container.read(interestsSelectionProvider), {'flutter', 'rust'});
      notifier.toggle('flutter');
      expect(container.read(interestsSelectionProvider), {'rust'});
    });
  });
}
