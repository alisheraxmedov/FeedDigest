import 'package:flutter/foundation.dart';

import '../../../../core/utils/formatters.dart';

/// A single Reddit comment (a `t1` thing), top-level only.
@immutable
class RedditComment {
  const RedditComment({
    required this.id,
    required this.author,
    required this.body,
    required this.score,
    required this.createdUtc,
    required this.isSubmitter,
  });

  final String id;
  final String author;
  final String body;
  final int score;
  final int createdUtc;

  /// True when the comment is by the post's author (OP).
  final bool isSubmitter;

  String get timeAgo => Formatters.timeAgo(createdUtc);
  String get compactScore => Formatters.compactNumber(score);

  factory RedditComment.fromJson(Map<String, dynamic> data) {
    return RedditComment(
      id: (data['id'] ?? '').toString(),
      author: (data['author'] ?? '[deleted]').toString(),
      body: Formatters.unescapeHtml((data['body'] ?? '').toString()),
      score: _int(data['score'] ?? data['ups']),
      createdUtc: _int(data['created_utc']),
      isSubmitter: data['is_submitter'] == true,
    );
  }

  /// Extracts top-level comments from a comments-thread response.
  ///
  /// The endpoint returns `[postListing, commentsListing]`; we read the second
  /// listing's children, keep real `t1` comments (skipping "more" stubs and
  /// removed bodies), sort by score and cap at [limit].
  static List<RedditComment> fromThread(dynamic json, {int limit = 12}) {
    if (json is! List || json.length < 2) return const [];
    final commentsListing = json[1];
    if (commentsListing is! Map) return const [];
    final data = commentsListing['data'];
    if (data is! Map || data['children'] is! List) return const [];

    final comments = <RedditComment>[];
    for (final child in data['children'] as List) {
      if (child is! Map || child['kind'] != 't1') continue;
      final cdata = child['data'];
      if (cdata is! Map) continue;
      final body = (cdata['body'] ?? '').toString().trim();
      if (body.isEmpty || body == '[removed]' || body == '[deleted]') continue;
      comments.add(RedditComment.fromJson(Map<String, dynamic>.from(cdata)));
    }

    comments.sort((a, b) => b.score.compareTo(a.score));
    return comments.take(limit).toList();
  }

  static int _int(Object? v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
