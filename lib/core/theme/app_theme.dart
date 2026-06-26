/*
AppTheme builds the two themes from the Stitch tokens: a primary "Neon
Professional" dark theme and an adaptive "Lumina Tech" light theme. Tokens that
Material's ColorScheme cannot express (accent glow, muted border, dim text, card
and input fills) are exposed through the AppPalette theme extension so widgets
read the exact same values in both themes.
*/
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.accent,
    required this.accentHover,
    required this.onAccent,
    required this.accentSoft,
    required this.accentText,
    required this.mutedBorder,
    required this.cardColor,
    required this.inputFill,
    required this.iconCircle,
    required this.textDim,
  });

  final Color accent;
  final Color accentHover;
  final Color onAccent;
  final Color accentSoft;
  final Color accentText;
  final Color mutedBorder;
  final Color cardColor;
  final Color inputFill;
  final Color iconCircle;
  final Color textDim;

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!;

  @override
  AppPalette copyWith({
    Color? accent,
    Color? accentHover,
    Color? onAccent,
    Color? accentSoft,
    Color? accentText,
    Color? mutedBorder,
    Color? cardColor,
    Color? inputFill,
    Color? iconCircle,
    Color? textDim,
  }) {
    return AppPalette(
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      onAccent: onAccent ?? this.onAccent,
      accentSoft: accentSoft ?? this.accentSoft,
      accentText: accentText ?? this.accentText,
      mutedBorder: mutedBorder ?? this.mutedBorder,
      cardColor: cardColor ?? this.cardColor,
      inputFill: inputFill ?? this.inputFill,
      iconCircle: iconCircle ?? this.iconCircle,
      textDim: textDim ?? this.textDim,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      accent: Color.lerp(accent, other.accent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      mutedBorder: Color.lerp(mutedBorder, other.mutedBorder, t)!,
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      iconCircle: Color.lerp(iconCircle, other.iconCircle, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
    );
  }
}

class AppTheme {
  AppTheme._();

  static const AppPalette _darkPalette = AppPalette(
    accent: AppColors.electricCyan,
    accentHover: AppColors.cyanHover,
    onAccent: AppColors.onCyan,
    accentSoft: Color(0x1A00F0FF),
    accentText: AppColors.electricCyan,
    mutedBorder: AppColors.darkMutedBorder,
    cardColor: AppColors.darkCard,
    inputFill: AppColors.darkInputFill,
    iconCircle: AppColors.darkContainerHighest,
    textDim: AppColors.darkTextDim,
  );

  static const AppPalette _lightPalette = AppPalette(
    accent: AppColors.lightCyan,
    accentHover: AppColors.lightCyanHover,
    onAccent: AppColors.onLightCyan,
    accentSoft: AppColors.lightCyanSoft,
    accentText: AppColors.lightCyanText,
    mutedBorder: AppColors.lightBorder,
    cardColor: AppColors.lightCard,
    inputFill: AppColors.lightInputFill,
    iconCircle: AppColors.lightContainerHighest,
    textDim: AppColors.lightTextDim,
  );

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.electricCyan,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.electricCyan,
          onPrimary: AppColors.onCyan,
          surface: AppColors.darkBackground,
          onSurface: AppColors.darkOnSurface,
          onSurfaceVariant: AppColors.darkOnSurfaceVariant,
          surfaceContainerLowest: AppColors.darkContainerLowest,
          surfaceContainerLow: AppColors.darkCard,
          surfaceContainer: AppColors.darkContainer,
          surfaceContainerHigh: AppColors.darkContainerHigh,
          surfaceContainerHighest: AppColors.darkContainerHighest,
          outline: AppColors.darkOutline,
          outlineVariant: AppColors.darkOutlineVariant,
          error: AppColors.darkError,
          onError: const Color(0xFF690005),
        );
    return _build(Brightness.dark, scheme, _darkPalette);
  }

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.lightCyan,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.lightCyan,
          onPrimary: AppColors.onLightCyan,
          surface: AppColors.lightBackground,
          onSurface: AppColors.lightOnSurface,
          onSurfaceVariant: AppColors.lightOnSurfaceVariant,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: AppColors.lightInputFill,
          surfaceContainer: AppColors.lightContainer,
          surfaceContainerHighest: AppColors.lightContainerHighest,
          outline: const Color(0xFF6C7A7B),
          outlineVariant: AppColors.lightBorder,
          error: AppColors.lightError,
        );
    return _build(Brightness.light, scheme, _lightPalette);
  }

  static ThemeData _build(
    Brightness brightness,
    ColorScheme scheme,
    AppPalette palette,
  ) {
    final base = ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      useMaterial3: true,
    );
    final inter = GoogleFonts.interTextTheme(base.textTheme);
    final outfit = GoogleFonts.outfitTextTheme(base.textTheme);
    // Body keeps Inter; display/headline switch to Outfit for the elegant,
    // geometric title rhythm (mirrors the ente design language).
    final text = inter.copyWith(
      displayLarge: outfit.displayLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      displayMedium: outfit.displayMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      displaySmall: outfit.displaySmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      headlineLarge: outfit.headlineLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      headlineMedium: outfit.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: outfit.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: outfit.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: outfit.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleSmall: outfit.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      extensions: <ThemeExtension<dynamic>>[palette],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: -0.3,
          color: scheme.onSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.cardColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.mutedBorder,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.accent),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.cardColor,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: palette.mutedBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.inputFill,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.mutedBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.mutedBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
      ),
    );
  }
}
