/*
filterArticlesByTopic — keeps only articles whose title or body contains a topic
token. Used by sources that must filter client-side (Lobsters non-tag topics,
VC.ru). An empty topic keeps everything; a non-empty topic with no matches
returns an empty list — never unrelated items dressed up as topic results.
*/
import '../../models/article.dart';

List<Article> filterArticlesByTopic(List<Article> items, String topic) {
  final tokens = topic
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((token) => token.length > 1)
      .toList();
  if (tokens.isEmpty) return items;
  return items.where((article) {
    final haystack = '${article.title} ${article.body}'.toLowerCase();
    return tokens.any(haystack.contains);
  }).toList();
}
