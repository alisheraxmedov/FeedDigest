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
final articleBodyProvider = FutureProvider.autoDispose.family<String, Article>((
  ref,
  article,
) async {
  final source = article.id.startsWith('devto-')
      ? ref.read(devtoSourceProvider)
      : ref.read(hackerNewsSourceProvider);
  final full = await source.fullBody(article);
  return full.isNotEmpty ? full : article.body;
});
