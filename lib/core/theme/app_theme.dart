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
}
