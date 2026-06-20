import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/models/reddit_post.dart';

Map<String, dynamic> _firstPostData(dynamic decoded) {
  final listing = decoded is List ? decoded.first : decoded;
  final children = listing['data']['children'] as List;
  final first = children.firstWhere((c) => c['kind'] == 't3');
  return Map<String, dynamic>.from(first['data'] as Map);
}

void main() {
  test('parses a post from the top fixture', () {
    final raw = File('test/fixtures/top_example.json').readAsStringSync();
    final post = RedditPost.fromJson(_firstPostData(jsonDecode(raw)));
    expect(post.id, isNotEmpty);
    expect(post.title, isNotEmpty);
  });

  test('parses a post from the search fixture', () {
    final raw = File('test/fixtures/search_example.json').readAsStringSync();
    final post = RedditPost.fromJson(_firstPostData(jsonDecode(raw)));
    expect(post.id, isNotEmpty);
  });

  test('tolerates missing fields', () {
    final post = RedditPost.fromJson(const {});
    expect(post.id, '');
    expect(post.score, 0);
    expect(post.isSelf, false);
  });

  test('hasThumbnail rejects placeholder values', () {
    expect(RedditPost.fromJson(const {'thumbnail': 'self'}).hasThumbnail, false);
    expect(
        RedditPost.fromJson(const {'thumbnail': 'https://x/y.jpg'}).hasThumbnail,
        true);
  });

  test('round-trips through json', () {
    final post = RedditPost.fromJson(const {
      'id': 'abc',
      'title': 'T',
      'score': 5,
      'created_utc': 1700000000,
    });
    final back = RedditPost.fromJson(post.toJson());
    expect(back.id, 'abc');
    expect(back.score, 5);
  });
}
