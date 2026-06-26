/*
Subscription — a topic the user follows.
fromJson also reads the legacy "subreddit" key: a migration fallback so that
subscriptions saved by an older version don't end up with an empty topic and
break the feed.
*/
import 'package:flutter/foundation.dart';

@immutable
class Subscription {
  const Subscription({
    required this.id,
    required this.label,
    required this.topic,
    required this.createdAt,
  });

  factory Subscription.create(
    String topic, {
    String? label,
    DateTime? createdAt,
  }) => Subscription(
    id: topic.toLowerCase(),
    label: (label == null || label.isEmpty) ? topic : label,
    topic: topic,
    createdAt: createdAt ?? DateTime.now(),
  );

  final String id;
  final String label;
  final String topic;
  final DateTime createdAt;

  String get displayName => '#$topic';

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    id: json['id'] as String? ?? '',
    label: json['label'] as String? ?? '',
    topic: json['topic'] as String? ?? json['subreddit'] as String? ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (json['createdAt'] as num?)?.toInt() ?? 0,
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'topic': topic,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  @override
  bool operator ==(Object other) => other is Subscription && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
