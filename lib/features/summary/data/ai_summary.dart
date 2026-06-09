import 'dart:convert';

import 'package:flutter/foundation.dart';

/// The two-part AI result: a summary of the post and, separately, a summary of
/// the discussion (top comments).
@immutable
class AiSummary {
  const AiSummary({required this.postSummary, required this.commentsSummary});

  final String postSummary;
  final String commentsSummary;

  bool get hasComments => commentsSummary.trim().isNotEmpty;

  /// Parses Gemini's JSON response defensively.
  ///
  /// Expects `{"post_summary": "...", "comments_summary": "..."}`. Tolerates
  /// markdown code fences and, if JSON parsing fails entirely, falls back to
  /// using the raw text as the post summary so the user still sees something.
  factory AiSummary.fromGeminiText(String raw) {
    final cleaned = _stripCodeFence(raw).trim();
    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map) {
        final post = (decoded['post_summary'] ?? '').toString().trim();
        final comments = (decoded['comments_summary'] ?? '').toString().trim();
        if (post.isNotEmpty || comments.isNotEmpty) {
          return AiSummary(
            postSummary: post.isEmpty ? raw.trim() : post,
            commentsSummary: comments,
          );
        }
      }
    } catch (_) {
      // Not valid JSON — fall through to the raw-text fallback.
    }
    return AiSummary(postSummary: raw.trim(), commentsSummary: '');
  }

  static String _stripCodeFence(String input) {
    var s = input.trim();
    if (s.startsWith('```')) {
      // Remove an opening ```json / ``` line and a trailing ```.
      final firstNewline = s.indexOf('\n');
      if (firstNewline != -1) s = s.substring(firstNewline + 1);
      if (s.endsWith('```')) s = s.substring(0, s.length - 3);
    }
    return s;
  }
}
