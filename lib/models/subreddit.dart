import 'package:flutter/foundation.dart';

@immutable
class Subreddit {
  const Subreddit({
    required this.name,
    required this.namePrefixed,
    required this.title,
    required this.subscribers,
    required this.icon,
    required this.publicDescription,
  });

  final String name;
  final String namePrefixed;
  final String title;
  final int subscribers;
  final String icon;
  final String publicDescription;

  bool get hasIcon => icon.startsWith('http');

  factory Subreddit.fromJson(Map<String, dynamic> json) {
    final communityIcon = json['community_icon'] as String? ?? '';
    final iconImg = json['icon_img'] as String? ?? '';
    final raw = communityIcon.isNotEmpty ? communityIcon : iconImg;
    return Subreddit(
      name: json['display_name'] as String? ?? '',
      namePrefixed: json['display_name_prefixed'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subscribers: (json['subscribers'] as num?)?.toInt() ?? 0,
      icon: raw.split('?').first,
      publicDescription: json['public_description'] as String? ?? '',
    );
  }
}
