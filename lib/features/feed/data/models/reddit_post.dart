import 'package:flutter/foundation.dart';

import '../../../../core/utils/formatters.dart';

/// A single Reddit submission (a `t3` "thing").
///
/// Mapped defensively from the Reddit JSON API: every field has a safe default
/// because the API omits keys depending on post type (self vs link vs media).
@immutable
class RedditPost {
  const RedditPost({
    required this.id,
    required this.title,
    required this.selftext,
    required this.author,
    required this.subreddit,
    required this.permalink,
    required this.url,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.score,
    required this.numComments,
    required this.createdUtc,
    required this.domain,
    required this.isSelf,
    required this.isVideo,
    required this.over18,
    this.likes,
  });

  final String id;
  final String title;
  final String selftext;
  final String author;
  final String subreddit;
  final String permalink;
  final String url;

  /// Best available preview image (high-res), or empty when none.
  final String imageUrl;

  /// Small thumbnail, or empty when not a real URL.
  final String thumbnailUrl;

  final int score;
  final int numComments;
  final int createdUtc;
  final String domain;
  final bool isSelf;
  final bool isVideo;
  final bool over18;

  /// Current vote from the logged-in user: true = upvoted, false = downvoted,
  /// null = no vote. Only populated on authenticated requests.
  final bool? likes;

  // --- Derived helpers ------------------------------------------------------

  String get fullPermalink => 'https://www.reddit.com$permalink';

  /// Reddit "fullname" used by the vote API (`t3_<id>`).
  String get fullname => 't3_$id';

  /// Vote direction derived from [likes]: 1 up, -1 down, 0 none.
  int get voteDirection => likes == true
      ? 1
      : likes == false
          ? -1
          : 0;

  bool get hasImage => imageUrl.isNotEmpty;

  String get timeAgo => Formatters.timeAgo(createdUtc);

  String get compactScore => Formatters.compactNumber(score);

  String get compactComments => Formatters.compactNumber(numComments);

  /// Text handed to the AI for summarisation. Link posts carry no body, so the
  /// title (plus domain) is the best available signal.
  String get summarizableText {
    final body = selftext.trim();
    if (body.isNotEmpty) return body;
    return isSelf ? title : 'Havola: $url ($domain)';
  }

  factory RedditPost.fromJson(Map<String, dynamic> data) {
    return RedditPost(
      id: _str(data['id']),
      title: _unescape(_str(data['title'])),
      selftext: _unescape(_str(data['selftext'])),
      author: _str(data['author'], fallback: '[deleted]'),
      subreddit: _str(data['subreddit']),
      permalink: _str(data['permalink']),
      url: _unescape(_str(data['url_overridden_by_dest'] ?? data['url'])),
      imageUrl: _extractImage(data),
      thumbnailUrl: _extractThumbnail(data),
      score: _int(data['score']),
      numComments: _int(data['num_comments']),
      createdUtc: _int(data['created_utc']),
      domain: _str(data['domain']),
      isSelf: data['is_self'] == true,
      isVideo: data['is_video'] == true,
      over18: data['over_18'] == true,
      likes: data['likes'] is bool ? data['likes'] as bool : null,
    );
  }

  // --- Parsing utilities ----------------------------------------------------

  static String _str(Object? v, {String fallback = ''}) =>
      v == null ? fallback : v.toString();

  static String _unescape(String v) => Formatters.unescapeHtml(v);

  static int _int(Object? v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  /// Pulls the highest-quality preview image Reddit offers, falling back to
  /// the destination URL when it points directly at an image file.
  static String _extractImage(Map<String, dynamic> data) {
    // 1) Rich preview (preferred).
    final preview = data['preview'];
    if (preview is Map && preview['images'] is List) {
      final images = preview['images'] as List;
      if (images.isNotEmpty && images.first is Map) {
        final source = (images.first as Map)['source'];
        if (source is Map && source['url'] is String) {
          return _unescape(source['url'] as String);
        }
      }
    }

    // 2) Gallery / direct image link.
    final url = _str(data['url_overridden_by_dest'] ?? data['url']);
    if (_looksLikeImage(url)) return _unescape(url);

    return '';
  }

  static String _extractThumbnail(Map<String, dynamic> data) {
    final thumb = _str(data['thumbnail']);
    const placeholders = {'self', 'default', 'nsfw', 'spoiler', 'image', ''};
    if (placeholders.contains(thumb)) return '';
    return _unescape(thumb);
  }

  static bool _looksLikeImage(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.contains('i.redd.it') ||
        lower.contains('i.imgur.com');
  }

  /// Identity is the Reddit post id, so the summary provider family caches one
  /// result per post.
  @override
  bool operator ==(Object other) => other is RedditPost && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
