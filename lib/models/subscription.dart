import 'package:flutter/foundation.dart';

@immutable
class Subscription {
  const Subscription({
    required this.id,
    required this.label,
    required this.subreddit,
    required this.createdAt,
  });

  factory Subscription.create(
    String subreddit, {
    String? label,
    DateTime? createdAt,
  }) =>
      Subscription(
        id: subreddit.toLowerCase(),
        label: (label == null || label.isEmpty) ? subreddit : label,
        subreddit: subreddit,
        createdAt: createdAt ?? DateTime.now(),
      );

  final String id;
  final String label;
  final String subreddit;
  final DateTime createdAt;

  String get displayName => 'r/$subreddit';

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        subreddit: json['subreddit'] as String? ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (json['createdAt'] as num?)?.toInt() ?? 0),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'subreddit': subreddit,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  @override
  bool operator ==(Object other) => other is Subscription && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
