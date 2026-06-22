/*
Article — the source-agnostic model every source (Hacker News, dev.to) maps into.
Each source converts its own JSON response into this shape; the UI only knows Article.
The id is namespaced by source (e.g. "hn-123", "devto-456") so articles from
different sources never collide in favorites or when aggregating feeds.
*/
import 'package:flutter/foundation.dart';

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

  String get faviconUrl {
    final host = Uri.tryParse(link)?.host ?? '';
    return host.isEmpty
        ? ''
        : 'https://www.google.com/s2/favicons?sz=128&domain=$host';
  }

  String get contentText => body.isNotEmpty ? body : url;

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        url: json['url'] as String? ?? '',
        commentsUrl: json['commentsUrl'] as String? ?? '',
        author: json['author'] as String? ?? '',
        topic: json['topic'] as String? ?? '',
        source: json['source'] as String? ?? '',
        score: (json['score'] as num?)?.toInt() ?? 0,
        commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
        publishedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['publishedAt'] as num?)?.toInt() ?? 0,
          isUtc: true,
        ),
        imageUrl: json['imageUrl'] as String? ?? '',
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
