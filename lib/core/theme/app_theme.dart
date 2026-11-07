import 'package:flutter/material.dart';

class NetLearnColors {
  NetLearnColors._();

  static const Color primary = Color(0xFF8C52FF);
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

class NetLearnSpace {
  NetLearnSpace._();

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

class NetLearnRadius {
  NetLearnRadius._();

  static const double card = 16;
  static const double radiusLg = 24;
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

