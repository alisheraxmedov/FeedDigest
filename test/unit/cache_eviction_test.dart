import 'dart:io';
import 'package:hive_ce/hive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/data/article_body_cache_repository.dart';
import 'package:feeddigest/data/summary_cache_repository.dart';
import 'package:feeddigest/models/ai_summary.dart';

late Directory dir;

void main() {
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('feeddigest_cache');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  group('SummaryCacheRepository eviction', () {
    test(
      'evicts the oldest entry, never the just-written one, on overflow',
      () async {
        final box = await Hive.openBox<dynamic>('summaries');
        var clock = DateTime(2026, 1, 1);
        final repo = SummaryCacheRepository(
          box,
          maxEntries: 3,
          now: () => clock,
        );

        // Insertion order h1,h2,h3 with increasing timestamps; keys sort HIGH.
        for (final id in ['h1', 'h2', 'h3']) {
          clock = clock.add(const Duration(seconds: 1));
          await repo.put(AiSummary(postId: id, summary: id));
        }
        // 'd1' sorts lexicographically FIRST ('d' < 'h') but is the NEWEST.
        // Buggy FIFO (keys.take) would evict 'd1' itself; correct FIFO evicts h1.
        clock = clock.add(const Duration(seconds: 1));
        await repo.put(const AiSummary(postId: 'd1', summary: 'd1'));

        expect(box.length, 3);
        expect(
          repo.get('d1')?.summary,
          'd1',
          reason: 'newest entry must survive eviction',
        );
        expect(repo.get('h1'), isNull, reason: 'oldest entry must be evicted');
        expect(repo.get('h2'), isNotNull);
        expect(repo.get('h3'), isNotNull);
      },
    );
  });

  group('ArticleBodyCacheRepository eviction + migration', () {
    test(
      'evicts the oldest body, never the just-written one, on overflow',
      () async {
        final box = await Hive.openBox<dynamic>('bodies');
        var clock = DateTime(2026, 1, 1);
        final repo = ArticleBodyCacheRepository(
          box,
          maxEntries: 3,
          now: () => clock,
        );

        for (final id in ['h1', 'h2', 'h3']) {
          clock = clock.add(const Duration(seconds: 1));
          await repo.put(id, 'body-$id');
        }
        clock = clock.add(const Duration(seconds: 1));
        await repo.put('d1', 'body-d1');

        expect(box.length, 3);
        expect(
          repo.get('d1'),
          'body-d1',
          reason: 'newest body must survive eviction',
        );
        expect(repo.get('h1'), isNull, reason: 'oldest body must be evicted');
      },
    );

    test(
      'reads legacy plain-string values written before the envelope change',
      () async {
        final box = await Hive.openBox<dynamic>('bodies');
        await box.put('hn-legacy', 'old body'); // pre-migration shape
        final repo = ArticleBodyCacheRepository(box);
        expect(repo.get('hn-legacy'), 'old body');
      },
    );
  });
}
