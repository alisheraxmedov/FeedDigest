import 'package:flutter/foundation.dart';

@immutable
class RedditPost {
  const RedditPost({
    required this.id,
    required this.title,
    required this.selftext,
    required this.url,
    required this.permalink,
    required this.author,
    required this.subreddit,
    required this.subredditNamePrefixed,
    required this.score,
    required this.numComments,
    required this.createdUtc,
    required this.thumbnail,
    required this.isSelf,
    required this.over18,
    required this.domain,
    required this.upvoteRatio,
    required this.linkFlairText,
  });

  final String id;
  final String title;
  final String selftext;
  final String url;
  final String permalink;
  final String author;
  final String subreddit;
  final String subredditNamePrefixed;
  final int score;
  final int numComments;
  final double createdUtc;
  final String thumbnail;
  final bool isSelf;
  final bool over18;
  final String domain;
  final double upvoteRatio;
  final String linkFlairText;

  String get fullPermalink => 'https://www.reddit.com$permalink';

  bool get hasThumbnail =>
      thumbnail.startsWith('http') &&
      thumbnail != 'self' &&
      thumbnail != 'default' &&
      thumbnail != 'nsfw';

  String get contentText => isSelf && selftext.isNotEmpty ? selftext : url;

  factory RedditPost.fromJson(Map<String, dynamic> json) => RedditPost(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        selftext: json['selftext'] as String? ?? '',
        url: json['url'] as String? ?? '',
        permalink: json['permalink'] as String? ?? '',
        author: json['author'] as String? ?? '',
        subreddit: json['subreddit'] as String? ?? '',
        subredditNamePrefixed: json['subreddit_name_prefixed'] as String? ?? '',
        score: (json['score'] as num?)?.toInt() ?? 0,
        numComments: (json['num_comments'] as num?)?.toInt() ?? 0,
        createdUtc: (json['created_utc'] as num?)?.toDouble() ?? 0,
        thumbnail: json['thumbnail'] as String? ?? '',
        isSelf: json['is_self'] as bool? ?? false,
        over18: json['over_18'] as bool? ?? false,
        domain: json['domain'] as String? ?? '',
        upvoteRatio: (json['upvote_ratio'] as num?)?.toDouble() ?? 0,
        linkFlairText: json['link_flair_text'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'selftext': selftext,
        'url': url,
        'permalink': permalink,
        'author': author,
        'subreddit': subreddit,
        'subreddit_name_prefixed': subredditNamePrefixed,
        'score': score,
        'num_comments': numComments,
        'created_utc': createdUtc,
        'thumbnail': thumbnail,
        'is_self': isSelf,
        'over_18': over18,
        'domain': domain,
        'upvote_ratio': upvoteRatio,
        'link_flair_text': linkFlairText,
      };

  @override
  bool operator ==(Object other) => other is RedditPost && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
