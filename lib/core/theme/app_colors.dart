import 'package:flutter/material.dart';

/// Design tokens and palette for the Job Hunter Stitch Dark Theme.
abstract final class AppColors {
  // --- Background & Surfaces ---
  /// Deep dark background (Slate 900).
  static const Color slate900 = Color(0xFF0F172A);

  /// Card / Surface primary background (Slate 800).
  static const Color slate800 = Color(0xFF1E293B);

  /// Darker card variant / nested surfaces (Slate 850).
  static const Color slate850 = Color(0xFF0F1E2E);

  /// Divider, borders and subtle outline (Slate 700).
  static const Color slate700 = Color(0xFF334155);

  /// Muted container surface (Slate 600).
  static const Color slate600 = Color(0xFF475569);

  // --- Highlights & Accents ---
  /// Primary action / brand highlight (Indigo).
  static const Color primaryIndigo = Color(0xFF6366F1);

  /// Secondary terminal / code highlight (Cyan).
  static const Color terminalCyan = Color(0xFF38BDF8);

  // --- Text & Foreground ---
  /// Pure white text for headings and high emphasis.
  static const Color textWhite = Color(0xFFFFFFFF);

  /// Primary body text (Slate 300).
  static const Color textSlate300 = Color(0xFFCBD5E1);

  /// Secondary / muted labels (Slate 400).
  static const Color textSlate400 = Color(0xFF94A3B8);

  /// Tertiary placeholder / hint text (Slate 500).
  static const Color textSlate500 = Color(0xFF64748B);

  // --- Semantic Kanban Status Palette ---
  /// New job status badge / border (Cyan terminal).
  static const Color kanbanNew = Color(0xFF38BDF8);

  /// Applied status (Violet).
  static const Color kanbanApplied = Color(0xFF8B5CF6);

  /// Interview stage (Amber).
  static const Color kanbanInterview = Color(0xFFF59E0B);

  /// Offer stage (Emerald).
  static const Color kanbanOffer = Color(0xFF10B981);

  /// Rejected status (Rose).
  static const Color kanbanRejected = Color(0xFFF43F5E);
}
