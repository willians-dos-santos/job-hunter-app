import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography configuration using Inter for UI and JetBrains Mono for terminal tokens.
abstract final class AppTypography {
  /// When true, bypasses network/asset resolution in GoogleFonts and uses standard
  /// [TextStyle] with the requested fontFamily (ideal for hermetic unit & widget tests).
  static bool useSystemFonts = false;

  /// Returns an Inter text style, using [GoogleFonts.inter] or system fallback when in tests.
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    if (useSystemFonts) {
      return TextStyle(
        fontFamily: 'Inter',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Monospace typography for terminal logs, tags, metrics, and code snippets.
  static TextStyle mono({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.terminalCyan,
    double? letterSpacing,
  }) {
    if (useSystemFonts) {
      return TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
    }
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Compact tag / badge typography.
  static TextStyle monoTag({
    Color color = AppColors.terminalCyan,
  }) {
    return mono(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 0.5,
    );
  }

  /// Base text theme configured with Inter font family.
  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textWhite,
        letterSpacing: -0.5,
      ),
      displayMedium: inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textWhite,
        letterSpacing: -0.5,
      ),
      displaySmall: inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textWhite,
      ),
      headlineMedium: inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textWhite,
      ),
      headlineSmall: inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textWhite,
      ),
      titleLarge: inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textWhite,
      ),
      titleMedium: inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSlate300,
      ),
      titleSmall: inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSlate400,
      ),
      bodyLarge: inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textSlate300,
        height: 1.5,
      ),
      bodyMedium: inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSlate300,
        height: 1.4,
      ),
      bodySmall: inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSlate400,
      ),
      labelLarge: inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textWhite,
      ),
      labelMedium: inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSlate300,
      ),
      labelSmall: inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSlate400,
      ),
    );
  }
}
