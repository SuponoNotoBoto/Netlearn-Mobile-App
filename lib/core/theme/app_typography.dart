import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Typography scale mapped directly to `design.md` §2
/// ("Typography Tokens — Sans-Serif Plus Jakarta Sans").
class AppTypography {
  AppTypography._();

  /// `--font-size-title-lg`: `22px`, Bold (`700`), Line-Height `130%` (`1.3`)
  /// Usage: Greeting headline ("Ready to Learn?")
  static TextStyle titleLg(BuildContext context) {
    final base = Theme.of(context).textTheme.headlineMedium;
    return (base ?? const TextStyle()).copyWith(
      fontFamily: AppTheme.displayFontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.3,
      color: context.onSurface,
    );
  }

  /// `--font-size-title-md`: `16px`, Semi-Bold (`600`), Line-Height `140%` (`1.4`)
  /// Usage: Section headers ("Quick Access", "Academic Overview")
  static TextStyle titleMd(BuildContext context) {
    final base = Theme.of(context).textTheme.titleMedium;
    return (base ?? const TextStyle()).copyWith(
      fontFamily: AppTheme.displayFontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: context.onSurface,
    );
  }

  /// `--font-size-body-lg`: `14px`, Medium (`500`), Line-Height `140%` (`1.4`)
  /// Usage: Menu labels, progress titles
  static TextStyle bodyLg(BuildContext context) {
    final base = Theme.of(context).textTheme.titleSmall;
    return (base ?? const TextStyle()).copyWith(
      fontFamily: AppTheme.fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: context.onSurface,
    );
  }

  /// `--font-size-body-md`: `13px`, Regular (`400`), Line-Height `150%` (`1.5`)
  /// Usage: Sub-text, banner description
  static TextStyle bodyMd(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium;
    return (base ?? const TextStyle()).copyWith(
      fontFamily: AppTheme.fontFamily,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: context.mutedText,
    );
  }

  /// `--font-size-caption`: `11px`, Medium (`500`), Line-Height `120%` (`1.2`)
  /// Usage: Bottom navbar labels, "See all"
  static TextStyle caption(BuildContext context) {
    final base = Theme.of(context).textTheme.bodySmall;
    return (base ?? const TextStyle()).copyWith(
      fontFamily: AppTheme.fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.2,
      color: context.mutedText,
    );
  }

  // Semantic aliases used across feature screens
  static TextStyle sectionTitle(BuildContext context) => titleMd(context);

  static TextStyle cardTitle(BuildContext context) =>
      bodyLg(context).copyWith(fontWeight: FontWeight.w600);

  static TextStyle body(BuildContext context) => bodyMd(context);

  static TextStyle badge(BuildContext context) =>
      caption(context).copyWith(fontWeight: FontWeight.w600);

  static TextStyle displayTitle(BuildContext context) => titleLg(context);
}
