import 'package:hive_ce/hive.dart';
import '../models/article.dart';

class FavoritesRepository {
  FavoritesRepository(this._box);

  final Box<dynamic> _box;

  List<Article> all() => _box.values
      .map((v) => Article.fromJson(Map<String, dynamic>.from(v as Map)))
      .toList();

  bool contains(String id) => _box.containsKey(id);

  Future<void> add(Article article) => _box.put(article.id, article.toJson());

  Future<void> remove(String id) => _box.delete(id);

  Future<void> toggle(Article article) =>
      contains(article.id) ? remove(article.id) : add(article);
}
