import 'package:flutter/foundation.dart';

import '../../../../core/utils/formatters.dart';

/// A subreddit (`t5` thing), as returned by `/subreddits/mine/subscriber`.
@immutable
class Subreddit {
  const Subreddit({
    required this.name,
    required this.title,
    required this.subscribers,
    required this.iconUrl,
  });

  /// Display name without `r/`, e.g. "FlutterDev".
  final String name;
  final String title;
  final int subscribers;
  final String iconUrl;

  String get displayName => 'r/$name';
  String get compactSubscribers => Formatters.compactNumber(subscribers);

  factory Subreddit.fromJson(Map<String, dynamic> data) {
    return Subreddit(
      name: (data['display_name'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      subscribers: _int(data['subscribers']),
      iconUrl: _icon(data),
    );
  }

  /// Parses a `Listing` of `t5` things into subreddits, skipping empties.
  static List<Subreddit> fromListing(dynamic json) {
    if (json is! Map) return const [];
    final data = json['data'];
    if (data is! Map || data['children'] is! List) return const [];
    final result = <Subreddit>[];
    for (final child in data['children'] as List) {
      if (child is! Map || child['kind'] != 't5') continue;
      final cdata = child['data'];
      if (cdata is! Map) continue;
      final sub = Subreddit.fromJson(Map<String, dynamic>.from(cdata));
      if (sub.name.isNotEmpty) result.add(sub);
    }
    return result;
  }

  static String _icon(Map data) {
    for (final key in ['community_icon', 'icon_img']) {
      final raw = (data[key] ?? '').toString();
      if (raw.isNotEmpty) {
        // Strip the query string (size params) and unescape entities.
        final clean = Formatters.unescapeHtml(raw);
        final q = clean.indexOf('?');
        return q == -1 ? clean : clean.substring(0, q);
      }
    }
    return '';
  }

  static int _int(Object? v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  bool operator ==(Object other) =>
      other is Subreddit && other.name.toLowerCase() == name.toLowerCase();

  @override
  int get hashCode => name.toLowerCase().hashCode;
}
