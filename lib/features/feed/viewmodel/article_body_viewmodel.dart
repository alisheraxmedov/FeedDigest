import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/sources/devto_source.dart';
import '../../../models/article.dart';

/// Resolves the readable full-text body for an article.
///
/// The feed only carries a short description, so dev.to articles are re-fetched
/// from the single-article endpoint to obtain the complete `body_markdown`.
/// Other sources (Hacker News links have no full text in the API) fall back to
/// whatever body the feed already provided.
final articleBodyProvider =
    FutureProvider.family<String, Article>((ref, article) async {
  if (!article.id.startsWith('devto-')) return article.body;
  final source = ref.read(devtoSourceProvider);
  if (source is! DevtoSource) return article.body;
  final full = await source.fetchFullBody(article.id);
  return full.isNotEmpty ? full : article.body;
});
