import 'dart:io';
import 'package:hive_ce/hive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/data/favorites_repository.dart';
import 'package:feeddigest/data/subscription_repository.dart';
import 'package:feeddigest/data/summary_cache_repository.dart';
import 'package:feeddigest/models/ai_summary.dart';
import 'package:feeddigest/models/reddit_post.dart';

late Directory dir;

RedditPost _post(String id) => RedditPost.fromJson({'id': id, 'title': 't$id'});

void main() {
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('feeddigest_hive');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('favorites add/contains/remove/toggle', () async {
    final box = await Hive.openBox<dynamic>('favorites');
    final repo = FavoritesRepository(box);
    await repo.add(_post('a'));
    expect(repo.contains('a'), true);
    expect(repo.all().length, 1);
    await repo.toggle(_post('a'));
    expect(repo.contains('a'), false);
  });

  test('summary cache get/put dedup', () async {
    final box = await Hive.openBox<dynamic>('summaries');
    final repo = SummaryCacheRepository(box);
    expect(repo.get('a'), isNull);
    await repo.put(const AiSummary(postId: 'a', summary: 'salom'));
    expect(repo.get('a')!.summary, 'salom');
  });

  test('subscription subscribe/unsubscribe/toggle by lowercase id', () async {
    final box = await Hive.openBox<dynamic>('subscriptions');
    final meta = await Hive.openBox<dynamic>('meta');
    final repo = SubscriptionRepository(box, meta);
    await repo.subscribe('FlutterDev');
    expect(repo.isSubscribed('flutterdev'), true);
    expect(repo.all().length, 1);
    await repo.toggle('flutterdev');
    expect(repo.isSubscribed('flutterdev'), false);
  });

  test('seedDefaultsIfNeeded is idempotent across unsubscribe', () async {
    final box = await Hive.openBox<dynamic>('subscriptions');
    final meta = await Hive.openBox<dynamic>('meta');
    final repo = SubscriptionRepository(box, meta);
    repo.seedDefaultsIfNeeded();
    expect(repo.all(), isNotEmpty);
    repo.seedDefaultsIfNeeded();
    final afterSecond = repo.all().length;
    expect(afterSecond, repo.all().length);
    for (final s in repo.all()) {
      await repo.unsubscribe(s.id);
    }
    repo.seedDefaultsIfNeeded();
    expect(repo.all(), isEmpty);
  });
}
