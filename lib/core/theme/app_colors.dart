import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Semantic color tokens mapped directly to `design.md`
/// ("Design System Token Specs (Dashboard-Siswa iOS)").
class AppColors {
  AppColors._();

  // Primary & Accent Colors (design.md §1)
  /// `--color-purple-50` (`--bg-app`: `#F6F4FD`) — Outer canvas / main dashboard background.
  static const Color bgApp = NetLearnColors.purple50;

  /// `--color-purple-100` (`--bg-card-banner`: `#ECE6FF`) — Banner card background ("Ready to Learn?").
  static const Color bgCardBanner = NetLearnColors.purple100;

  /// `--color-purple-500` (`--primary-action`: `#8C52FF`) — Brand primary (CTA buttons, active states, active icons).
  static const Color primaryAction = NetLearnColors.purple500;

  /// `--color-lavender-300` (`--status-attendance`: `#A6B1E1`) — Secondary progress indicator (attendance/reading).
  static const Color statusAttendance = NetLearnColors.lavender300;

  /// `--color-pink-300` (`--status-pending`: `#FFB6C1`) — Pending assignments progress indicator.
  static const Color statusPending = NetLearnColors.pink300;

  // Neutral & Surface Colors (design.md §1)
  /// `--color-neutral-900` (`--text-primary`: `#1D1C21`) — Main text, headings, icons.
  static const Color textPrimary = NetLearnColors.neutral900;

  /// `--color-neutral-500` (`--text-secondary`: `#75747E`) — Secondary text, descriptions, inactive states.
  static const Color textSecondary = NetLearnColors.neutral500;

  /// `--color-neutral-200` (`#F2EFFE`) — Empty progress bar background, dropdown container.
  static const Color neutral200 = NetLearnColors.neutral200;

  /// `--color-white` (`--bg-card-container`: `#FFFFFF`) — Cards, modules, menus, bottom nav, secondary buttons.
  static const Color bgCardContainer = NetLearnColors.white;

  // Backward-compatible aliases used across v7 class screens
  static const Color primaryBlue = primaryAction;
  static const Color surfaceBlue = bgCardBanner;
  static const Color successGreen = Color(0xFF28856A);
  static const Color warningAmber = Color(0xFFD97706);
  static const Color dangerRed = Color(0xFFEB5757);
  static const Color textMuted = NetLearnColors.neutralText;

  static Color surfaceMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? NetLearnColors.darkRaised
          : neutral200;

  static Color borderSubtle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? NetLearnColors.darkLine
          : neutral200;

  static Color surfaceCard(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? NetLearnColors.darkRaised
          : bgCardContainer;

  static Color surfaceElevated(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? NetLearnColors.darkRaised
          : bgApp;
}
