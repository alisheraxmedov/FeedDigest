import 'package:flutter/material.dart';

/// Brand colours and gradients used across the app.
class AppColors {
  const AppColors._();

  /// Primary brand seed — a modern indigo/violet.
  static const Color seed = Color(0xFF6366F1);

  /// Accent used for the AI summary call-to-action.
  static const Color aiStart = Color(0xFF7C3AED);
  static const Color aiEnd = Color(0xFFEC4899);

  /// Upvote / engagement accent (Reddit-ish warm orange).
  static const Color upvote = Color(0xFFF97316);

  /// Downvote accent (cool periwinkle).
  static const Color downvote = Color(0xFF5B6CFF);

  static const LinearGradient aiGradient = LinearGradient(
    colors: [aiStart, aiEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
