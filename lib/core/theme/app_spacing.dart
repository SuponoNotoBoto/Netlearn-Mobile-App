/// Layout, Spacing (8pt Rhythm), and Border Radius tokens mapped directly
/// to `design.md` ("Design System Token Specs (Dashboard-Siswa iOS)").
class AppSpacing {
  AppSpacing._();

  // 8pt Rhythm (design.md §4)
  /// `--spacing-xs`: `4px`
  static const double xs = 4;

  /// `--spacing-sm`: `8px` (Gap between internal elements inside small cards)
  static const double sm = 8;

  /// `--spacing-md`: `12px` (Gap between Quick Access cards)
  static const double md = 12;

  /// `--spacing-lg`: `16px` (Card internal padding, spacing between sections)
  static const double lg = 16;

  /// `--spacing-xl`: `24px` (Left/right screen edge padding)
  static const double xl = 24;

  // Numeric scale aliases
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
}

class AppRadius {
  AppRadius._();

  // Border Radius Tokens (design.md §3)
  /// `--radius-pill`: `100px` (CTA buttons, tab indicators, pill dropdowns)
  static const double pill = 100;

  /// `--radius-lg`: `24px` (Main banner & Academic Overview card)
  static const double lg = 24;

  /// `--radius-md`: `16px` (Quick Access grid buttons, sub-modules)
  static const double md = 16;

  /// `--radius-sm`: `12px` (Input elements, small badges)
  static const double sm = 12;

  // Numeric scale aliases
  static const double r8 = 8;
  static const double r10 = 10;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r24 = 24;
  static const double rPill = 100;
}
