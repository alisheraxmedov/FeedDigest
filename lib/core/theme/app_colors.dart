/*
Raw color tokens for the FeedDigest redesign (icon-matched).
`dark*` = "Neon Professional" (primary); `light*` = "Lumina Tech".
Values are pulled straight from the design handoff so the app matches its
app icon (deep navy-teal surfaces + a teal→cyan brand gradient). Semantic
mapping lives in app_theme.dart.
*/
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Neon Professional (dark, primary) ──────────────────────────────────
  static const Color darkBackground = Color(0xFF0A1013); // --bg / scaffold
  static const Color darkCard = Color(0xFF111B20); // --card
  static const Color darkInputFill = Color(0xFF0D1519); // --card2 / inputs
  static const Color darkContainerLowest = Color(0xFF070C0E);
  static const Color darkContainer = Color(0xFF16242A);
  static const Color darkContainerHigh = Color(0xFF1B2C33);
  static const Color darkContainerHighest = Color(0xFF22343B);
  static const Color darkMutedBorder = Color(0xFF1E2E34); // --border
  static const Color darkOutline = Color(0xFF5E7276);
  static const Color darkOutlineVariant = Color(0xFF2A3A40);
  static const Color darkOnSurface = Color(0xFFEAF2F3); // text
  static const Color darkOnSurfaceVariant = Color(0xFFB4C6C9); // text2
  static const Color darkTextDim = Color(0xFF7E9498);
  static const Color darkError = Color(0xFFFFB4AB);

  static const Color electricCyan = Color(0xFF16C0D4); // accent (solid)
  static const Color cyanHover = Color(0xFF34D6EA);
  static const Color onCyan = Color(0xFF03242A); // accent-ink
  static const Color darkAccentSoft = Color(0x1F00E5FF); // rgba(0,229,255,.12)
  static const Color darkAccentText = Color(0xFF43E1F0);

  // ── Lumina Tech (light) ─────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFEEF4F5); // --bg
  static const Color lightCard = Color(0xFFFFFFFF); // --card
  static const Color lightInputFill = Color(0xFFF1F7F8); // --card2
  static const Color lightContainer = Color(0xFFE3EFF1);
  static const Color lightContainerHighest = Color(0xFFD6E6E9);
  static const Color lightBorder = Color(0xFFDCE8EA); // --border
  static const Color lightOnSurface = Color(0xFF082A30); // text
  static const Color lightOnSurfaceVariant = Color(0xFF3D585C); // text2
  static const Color lightTextDim = Color(0xFF6A7F83);
  static const Color lightError = Color(0xFFBA1A1A);

  static const Color lightCyan = Color(0xFF0A97AB); // accent (solid)
  static const Color lightCyanHover = Color(0xFF098A9C);
  static const Color lightCyanText = Color(0xFF07899C); // accentText
  static const Color lightCyanSoft = Color(0xFFDBF3F6); // accentSoft
  static const Color onLightCyan = Color(0xFFFFFFFF);

  // ── Brand gradient (the signature teal→cyan sweep from the icon) ────────
  static const Color brandStartDark = Color(0xFF13B3C7);
  static const Color brandEndDark = Color(0xFF00E5FF);
  static const Color brandStartLight = Color(0xFF0FA6BB);
  static const Color brandEndLight = Color(0xFF00C4D9);

  // ── Ambient / chrome tokens (per theme) ─────────────────────────────────
  static const Color bgGlowDark = Color(0x381396A8); // rgba(19,150,168,.22)
  static const Color bgGlowLight = Color(0x291096AA); // rgba(16,150,170,.16)
  static const Color navBarDark = Color(0xBD090F12); // rgba(9,15,18,.74)
  static const Color navBarLight = Color(0xD1FFFFFF); // rgba(255,255,255,.82)
  static const Color scrimDark = Color(0xB303080A); // rgba(3,8,10,.70)
  static const Color scrimLight = Color(0x6B081E22); // rgba(8,30,34,.42)

  // ── Source accent dots (constant across both themes) ────────────────────
  static const Color hackerNewsOrange = Color(0xFFFF6600);
  static const Color devtoAvatarStart = Color(0xFF5B3DF0);
  static const Color devtoAvatarEnd = Color(0xFF8F6DFF);
}
