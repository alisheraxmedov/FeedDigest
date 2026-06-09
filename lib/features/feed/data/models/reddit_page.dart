import 'package:flutter/foundation.dart';

import 'reddit_post.dart';

/// One page of a Reddit listing plus the pagination cursor.
@immutable
class RedditPage {
  const RedditPage({required this.posts, this.after});

  final List<RedditPost> posts;

  /// Opaque cursor for the next page; `null` means there are no more posts.
  final String? after;

  bool get hasMore => after != null && after!.isNotEmpty;

  /// Parses a standard Reddit `Listing` (`{ kind: "Listing", data: {...} }`).
  factory RedditPage.fromListing(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) return const RedditPage(posts: []);

    final children = data['children'];
    final posts = <RedditPost>[];
    if (children is List) {
      for (final child in children) {
        if (child is Map && child['data'] is Map) {
          final postData = Map<String, dynamic>.from(child['data'] as Map);
          // Skip stickied announcements and ads to keep the feed clean.
          if (postData['stickied'] == true) continue;
          posts.add(RedditPost.fromJson(postData));
        }
      }
    }

    final after = data['after'];
    return RedditPage(
      posts: posts,
      after: after is String ? after : null,
    );
  }
}
