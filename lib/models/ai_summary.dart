import 'package:flutter/foundation.dart';

@immutable
class AiSummary {
  const AiSummary({required this.postId, required this.summary});

  final String postId;
  final String summary;

  factory AiSummary.fromJson(Map<String, dynamic> json) => AiSummary(
        postId: json['postId'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'postId': postId, 'summary': summary};
}
