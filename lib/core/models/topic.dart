import 'package:flutter/foundation.dart';

/// A user-configurable category that maps a friendly [label] to a Reddit
/// [subreddit]. Topics are editable from the Settings screen and persisted.
@immutable
class Topic {
  const Topic({
    required this.label,
    required this.subreddit,
  });

  /// Display name, e.g. "Flutter".
  final String label;

  /// Subreddit without the `r/` prefix, e.g. "FlutterDev".
  final String subreddit;

  String get displayName => 'r/$subreddit';

  Topic copyWith({String? label, String? subreddit}) {
    return Topic(
      label: label ?? this.label,
      subreddit: subreddit ?? this.subreddit,
    );
  }

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      label: json['label'] as String? ?? '',
      subreddit: json['subreddit'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'subreddit': subreddit,
      };

  /// Equality keyed on the subreddit (case-insensitive) so a topic uniquely
  /// identifies a feed regardless of its label.
  @override
  bool operator ==(Object other) =>
      other is Topic &&
      other.subreddit.toLowerCase() == subreddit.toLowerCase();

  @override
  int get hashCode => subreddit.toLowerCase().hashCode;

  @override
  String toString() => 'Topic($label · r/$subreddit)';
}
