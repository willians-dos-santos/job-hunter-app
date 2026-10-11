import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'kanban_status_colors.dart';

/// Central theme provider configured for the Stitch Dark Mode terminal aesthetic.
abstract final class AppTheme {
  /// Dark Theme incorporating Slate 900 background, Slate 800 surfaces,
  /// Slate 700 borders, Indigo & Terminal Cyan accents, and Kanban status colors.
  static ThemeData get darkTheme {
    final colorScheme = const ColorScheme.dark().copyWith(
      primary: AppColors.primaryIndigo,
      onPrimary: AppColors.textWhite,
      secondary: AppColors.terminalCyan,
      onSecondary: AppColors.slate900,
      surface: AppColors.slate800,
      onSurface: AppColors.textWhite,
      outline: AppColors.slate700,
      outlineVariant: AppColors.slate700,
      error: AppColors.kanbanRejected,
      onError: AppColors.textWhite,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.slate900,
      colorScheme: colorScheme,
      cardColor: AppColors.slate800,
      canvasColor: AppColors.slate900,
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.slate800,
      ),
      dividerColor: AppColors.slate700,
      textTheme: AppTypography.textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.slate900,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.slate800,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.slate700),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.slate700,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryIndigo,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.terminalCyan,
          side: const BorderSide(color: AppColors.slate700),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.terminalCyan,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slate850,
        hintStyle: const TextStyle(color: AppColors.textSlate500),
        labelStyle: const TextStyle(color: AppColors.textSlate400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.slate700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.slate700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.terminalCyan, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.kanbanRejected),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.slate850,
        labelStyle: const TextStyle(color: AppColors.textSlate300, fontSize: 12),
        side: const BorderSide(color: AppColors.slate700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        KanbanStatusColors.dark,
      ],
    );
  }
}
