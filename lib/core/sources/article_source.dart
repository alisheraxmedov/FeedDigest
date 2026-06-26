/*
ArticleSource — the common interface for article sources (Hacker News, dev.to).
To add a new source: add an entry to FeedSource and write a class implementing
this interface; the rest of the app stays unchanged.
FeedSource.id is the stable key persisted in Hive; label is shown in the UI.
*/
import '../config/app_config.dart';
import '../../models/article.dart';

enum FeedSource {
  hackerNews('hacker_news', 'Hacker News'),
  devto('dev_to', 'dev.to');

  const FeedSource(this.id, this.label);

  final String id;
  final String label;

  static FeedSource fromId(String? id) => FeedSource.values.firstWhere(
        (source) => source.id == id,
        orElse: () => FeedSource.hackerNews,
      );
}

enum FeedSort {
  newest('newest'),
  popular('popular');

  const FeedSort(this.id);

  final String id;

  static FeedSort fromId(String? id) => FeedSort.values.firstWhere(
        (sort) => sort.id == id,
        orElse: () => FeedSort.newest,
      );
}

abstract class ArticleSource {
  FeedSource get kind;

  Future<List<Article>> topPosts(
    String topic, {
    int limit = AppConfig.feedLimit,
    int page = 1,
    FeedSort sort = FeedSort.newest,
  });

  Future<List<Article>> search(String query, {int limit = AppConfig.searchLimit});
}
