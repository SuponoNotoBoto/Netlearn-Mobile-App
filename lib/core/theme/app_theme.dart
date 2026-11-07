import 'package:flutter/material.dart';

class NetLearnColors {
  NetLearnColors._();

  static const Color primary = Color(0xFF8C52FF);
  static const Color primaryDeep = Color(0xFF1E126B);
  static const Color primaryMid = Color(0xFF4E33C8);
  static const Color primarySoft = Color(0xFF8A70EA);
  static const Color primaryTint = Color(0xFFECE6FF);

  static const Color heroAvatarBg = Color(0xFFE6DCFF);
  static const Color heroAvatarFg = Color(0xFF6040AD);

  static const Color purple500 = Color(0xFF8C52FF);
  static const Color purple100 = Color(0xFFECE6FF);
  static const Color purple50 = Color(0xFFF6F4FD);

  static const Color appBg = Color(0xFFF6F4FD);
  static const Color cardBannerBg = Color(0xFFECE6FF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFECEEF2);

  static const Color neutral900 = Color(0xFF1D1C21);
  static const Color neutral700 = Color(0xFF3A3845);
  static const Color neutral500 = Color(0xFF75747E);
  static const Color neutral400 = Color(0xFFA19FA8);
  static const Color neutral200 = Color(0xFFF2EFFE);
  static const Color white = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF35C779);
  static const Color warning = Color(0xFFFFB800);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF00C2FF);
  static const Color orange = Color(0xFFFF7A00);
  static const Color pink = Color(0xFFFF5C8A);
  static const Color indigo = Color(0xFF5B61F4);
  static const Color forest = Color(0xFF1E824C);
  static const Color sectionIcon = Color(0xFF9D92CB);

  static const Color tabsBg = Color(0xFFEAEAF3);
  static const Color tabsSelectedDark = Color(0xFF34304E);
  static const Color primaryDarkSoft = Color(0xFFD0C2FF);
  static const Color primaryDarkTint = Color(0xFF242035);
  static const Color darkRaised = Color(0xFF262936);
  static const Color darkCoralText = Color(0xFFFF8577);
  static const Color darkCoralBorder = Color(0xFF5E2A2A);

  static const Color themeSwitchOff = Color(0xFFD8D4EC);

  static const List<Color> gridAccents = [
    Color(0xFF8C52FF), // Purple
    Color(0xFFFF7A00), // Orange
    Color(0xFF00C2FF), // Cyan
    Color(0xFFFFB800), // Amber
    Color(0xFF35C779), // Green
    Color(0xFFFF5C8A), // Pink
    Color(0xFF5B61F4), // Indigo
  ];
}

class NetLearnGradients {
  NetLearnGradients._();

  static const LinearGradient hero = LinearGradient(
    colors: [NetLearnColors.primaryDeep, NetLearnColors.primaryMid],
    begin: Alignment(-0.747, -0.664),
    end: Alignment(0.747, 0.664),
  );
}

class NetLearnAccents {
  NetLearnAccents._();

  static const Color purple = Color(0xFF8C52FF);
  static const Color pink = Color(0xFFFF5C8A);
  static const Color blue = Color(0xFF00B4D8);

  static const tintBackgrounds = <Color>[
    Color(0xFFEBF3FE), // 0: blue-tint
    Color(0xFFEAE8FC), // 1: indigo-tint
    Color(0xFFE8F8F2), // 2: green-tint
    Color(0xFFF0EEFC), // 3: purple-tint
    Color(0xFFFFF3EB), // 4: orange-tint
  ];

  static const tintForegrounds = <Color>[
    Color(0xFF4F85C4),
    NetLearnColors.primary,
    Color(0xFF309778),
    Color(0xFF7E65C4),
    Color(0xFFC78046),
  ];
}

class NetLearnSpace {
  NetLearnSpace._();

  static const double s4 = 4;
  static const double s5 = 5;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s13 = 13;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s17 = 17;
  static const double s19 = 19;
  static const double s20 = 20;
  static const double s22 = 22;
  static const double s24 = 24;
  static const double s32 = 32;
}

class NetLearnRadius {
  NetLearnRadius._();

  static const double sm = 10;
  static const double card = 16;
  static const double cardLg = 20;
  static const double radiusLg = 24;
  static const double pill = 100;
  static const double radiusPill = 100;
  static const double radiusSm = 12;
  static const double button = 12;
  static const double badge = 6;
  static const double moduleNumber = 11;
  static const double field = 10;
}

class NetLearnShadows {
  NetLearnShadows._();

  static const List<BoxShadow> softSm = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> banner = [
    BoxShadow(
      color: Color(0x148C52FF),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> tabsSelected = [
    BoxShadow(
      color: Color(0x0B292052),
      blurRadius: 5,
      offset: Offset(0, 2),
    ),
  ];
}

class NetLearnFeedbackColors {
  final Color successBg, successFg, successBorder;
  final Color errorBg, errorFg, errorBorder;
  final Color warningBg, warningFg, warningBorder;
  final Color infoBg, infoFg, infoBorder;

  const NetLearnFeedbackColors({
    required this.successBg,
    required this.successFg,
    required this.successBorder,
    required this.errorBg,
    required this.errorFg,
    required this.errorBorder,
    required this.warningBg,
    required this.warningFg,
    required this.warningBorder,
    required this.infoBg,
    required this.infoFg,
    required this.infoBorder,
  });

  static const light = NetLearnFeedbackColors(
    successBg: Color(0xFFE8F6EF),
    successFg: Color(0xFF1E824C),
    successBorder: Color(0xFFBCE3CD),
    errorBg: Color(0xFFFDF0F0),
    errorFg: Color(0xFFD63031),
    errorBorder: Color(0xFFF5C2C2),
    warningBg: Color(0xFFFEF7E7),
    warningFg: Color(0xFFB87800),
    warningBorder: Color(0xFFFCE1A8),
    infoBg: Color(0xFFEEF3FE),
    infoFg: Color(0xFF2962FF),
    infoBorder: Color(0xFFBED4FD),
  );
}

extension NetLearnContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get scheme => theme.colorScheme;
  Color get background => NetLearnColors.appBg;
  Color get surface => Colors.white;
  Color get onSurface => NetLearnColors.neutral900;
  Color get border => NetLearnColors.border;
  Color get mutedText => NetLearnColors.neutral500;
  Color get raisedSurface => const Color(0xFFF3F1FA);
  Color get accent => NetLearnColors.primary;
  Color get accentTint => NetLearnColors.primaryTint;
  NetLearnFeedbackColors get feedback => NetLearnFeedbackColors.light;

  TextStyle? get sectionHeadingStyle => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: NetLearnColors.neutral900,
      );

  TextStyle? get linkSmallStyle => const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: NetLearnColors.primary,
      );
}
