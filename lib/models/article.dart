/*
Article — the source-agnostic model every source (Hacker News, dev.to) maps into.
Each source converts its own JSON response into this shape; the UI only knows Article.
The id is namespaced by source (e.g. "hn-123", "devto-456") so articles from
different sources never collide in favorites or when aggregating feeds.
*/
import 'package:flutter/foundation.dart';

/// Defensive cast: a present-but-non-String JSON field decodes to '' instead of
/// throwing a ClassCastException.
String _str(dynamic value) => value is String ? value : '';

@immutable
class Article {
  const Article({
    required this.id,
    required this.title,
    required this.body,
    required this.url,
    required this.commentsUrl,
    required this.author,
    required this.topic,
    required this.source,
    required this.score,
    required this.commentCount,
    required this.publishedAt,
    required this.imageUrl,
  });

  final String id;
  final String title;
  final String body;
  final String url;
  final String commentsUrl;
  final String author;
  final String topic;
  final String source;
  final int score;
  final int commentCount;
  final DateTime publishedAt;
  final String imageUrl;

  bool get hasImage => imageUrl.startsWith('http');

  String get link => url.isNotEmpty ? url : commentsUrl;

  /// Bare host of the link (no scheme, no `www.`) — used as a light snippet
  /// fallback so link posts with no body still show where they point.
  String get linkHost {
    final host = Uri.tryParse(link)?.host ?? '';
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  String get faviconUrl {
    final host = Uri.tryParse(link)?.host ?? '';
    return host.isEmpty
        ? ''
        : 'https://www.google.com/s2/favicons?sz=128&domain=$host';
  }

  String get contentText => body.isNotEmpty ? body : url;

  factory Article.fromJson(Map<String, dynamic> json) => Article(
    id: _str(json['id']),
    title: _str(json['title']),
    body: _str(json['body']),
    url: _str(json['url']),
    commentsUrl: _str(json['commentsUrl']),
    author: _str(json['author']),
    topic: _str(json['topic']),
    source: _str(json['source']),
    score: (json['score'] as num?)?.toInt() ?? 0,
    commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
    publishedAt: DateTime.fromMillisecondsSinceEpoch(
      (json['publishedAt'] as num?)?.toInt() ?? 0,
      isUtc: true,
    ),
    imageUrl: _str(json['imageUrl']),
  );

  Article copyWith({String? body}) => Article(
    id: id,
    title: title,
    body: body ?? this.body,
    url: url,
    commentsUrl: commentsUrl,
    author: author,
    topic: topic,
    source: source,
    score: score,
    commentCount: commentCount,
    publishedAt: publishedAt,
    imageUrl: imageUrl,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'url': url,
    'commentsUrl': commentsUrl,
    'author': author,
    'topic': topic,
    'source': source,
    'score': score,
    'commentCount': commentCount,
    'publishedAt': publishedAt.millisecondsSinceEpoch,
    'imageUrl': imageUrl,
  };

  @override
  bool operator ==(Object other) => other is Article && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
