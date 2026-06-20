/*
Raw color tokens taken verbatim from the Stitch design exports.
`dark*` belongs to the "Neon Professional" theme (primary); `light*` belongs to
the "Lumina Tech" theme. Semantic mapping lives in app_theme.dart.
*/
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Neon Professional (dark, primary).
  static const Color darkBackground = Color(0xFF111319);
  static const Color darkInputFill = Color(0xFF0F1117);
  static const Color darkContainerLowest = Color(0xFF0C0E14);
  static const Color darkCard = Color(0xFF191B22);
  static const Color darkContainer = Color(0xFF1E1F26);
  static const Color darkContainerHigh = Color(0xFF282A30);
  static const Color darkContainerHighest = Color(0xFF33343B);
  static const Color darkMutedBorder = Color(0xFF2D313D);
  static const Color darkOutline = Color(0xFF849495);
  static const Color darkOutlineVariant = Color(0xFF3B494B);
  static const Color darkOnSurface = Color(0xFFE2E2EB);
  static const Color darkOnSurfaceVariant = Color(0xFFB9CACB);
  static const Color darkTextDim = Color(0xFFA0A7B5);
  static const Color darkError = Color(0xFFFFB4AB);

  static const Color electricCyan = Color(0xFF00F0FF);
  static const Color cyanHover = Color(0xFF7DF4FF);
  static const Color onCyan = Color(0xFF00363A);

  // Lumina Tech (light).
  static const Color lightBackground = Color(0xFFF8F9FF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightInputFill = Color(0xFFEFF4FF);
  static const Color lightContainer = Color(0xFFE5EEFF);
  static const Color lightContainerHighest = Color(0xFFD3E4FE);
  static const Color lightBorder = Color(0xFFBBC9CB);
  static const Color lightOnSurface = Color(0xFF0B1C30);
  static const Color lightOnSurfaceVariant = Color(0xFF3C494B);
  static const Color lightTextDim = Color(0xFF5A6573);
  static const Color lightError = Color(0xFFBA1A1A);

  static const Color lightCyan = Color(0xFF00BDCC);
  static const Color lightCyanHover = Color(0xFF00A3B0);
  static const Color lightCyanText = Color(0xFF008A94);
  static const Color lightCyanSoft = Color(0xFFE0F7F9);
  static const Color onLightCyan = Color(0xFFFFFFFF);
}
