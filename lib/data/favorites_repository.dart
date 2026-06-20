import 'package:hive_ce/hive.dart';
import '../models/reddit_post.dart';

class FavoritesRepository {
  FavoritesRepository(this._box);

  final Box<dynamic> _box;

  List<RedditPost> all() => _box.values
      .map((v) => RedditPost.fromJson(Map<String, dynamic>.from(v as Map)))
      .toList();

  bool contains(String id) => _box.containsKey(id);

  Future<void> add(RedditPost post) => _box.put(post.id, post.toJson());

  Future<void> remove(String id) => _box.delete(id);

  Future<void> toggle(RedditPost post) =>
      contains(post.id) ? remove(post.id) : add(post);
}
