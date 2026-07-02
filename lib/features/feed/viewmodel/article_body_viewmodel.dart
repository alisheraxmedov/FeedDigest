import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../models/article.dart';

/// Resolves the readable full-text body for an article.
///
/// dev.to articles only carry a short description in the feed, so their source
/// re-fetches the complete `body_markdown`; other sources fall back to the body
/// the feed already provided (both handled via [ArticleSource.fullBody]). The
/// owning source is picked by the article's namespaced id. autoDispose so a
/// popped detail screen does not retain the full body forever.
///
/// Offline (§9): a successfully resolved body is cached; if the fetch later
/// fails (no network), the cached body is served so a previously opened article
/// still reads offline.
final articleBodyProvider = FutureProvider.autoDispose.family<String, Article>((
  ref,
  article,
) async {
  final cache = ref.read(articleBodyCacheRepositoryProvider);
  final source = article.id.startsWith('devto-')
      ? ref.read(devtoSourceProvider)
      : ref.read(hackerNewsSourceProvider);
  try {
    final full = await source.fullBody(article);
    final body = full.isNotEmpty ? full : article.body;
    await cache.put(article.id, body);
    return body;
  } catch (_) {
    final cached = cache.get(article.id);
    if (cached != null && cached.isNotEmpty) return cached;
    rethrow;
  }
});
