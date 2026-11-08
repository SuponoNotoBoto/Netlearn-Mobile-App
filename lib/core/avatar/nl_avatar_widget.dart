import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'nl_avatar_models.dart';

/// Renders a cute, unified chibi cartoon avatar at any [size].
///
/// Every character (`cat`, `dog`, `bear`, `rabbit`, `fox`, `panda`, `owl`,
/// `koala`, `penguin`, `robot`) uses identical head proportions, line weights,
/// glossy eye highlights, blush cheeks, and accessory anchor coordinates so
/// mixing any character + color + hat + eyewear + accessory always looks like
/// one cohesive sticker pack.
class NlAvatarWidget extends StatelessWidget {
  final AvatarConfig config;
  final double size;
  final double borderWidth;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Widget? badgeOverlay;

  const NlAvatarWidget({
    super.key,
    required this.config,
    this.size = 48,
    this.borderWidth = 2.0,
    this.borderColor,
    this.onTap,
    this.badgeOverlay,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = borderColor ?? Colors.white;

    Widget circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: config.bgColor,
        border: borderWidth > 0
            ? Border.all(color: ringColor, width: borderWidth)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: size * 0.14,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: ClipOval(
        child: CustomPaint(
          size: Size(size, size),
          painter: _ChibiCartoonAvatarPainter(config: config),
        ),
      ),
    );

    if (onTap != null) {
      circle = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: circle,
        ),
      );
    }

    if (badgeOverlay == null) {
      return circle;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          circle,
          Positioned(
            right: -2,
            bottom: -2,
            child: badgeOverlay!,
          ),
        ],
      ),
    );
  }
}

class _ChibiCartoonAvatarPainter extends CustomPainter {
  final AvatarConfig config;

  const _ChibiCartoonAvatarPainter({required this.config});

  static const Color _ink = Color(0xFF2B253A);
  static const Color _blush = Color(0xFFFF8BA0);
  static const Color _cream = Color(0xFFFFF8F0);
  static const Color _darkPatch = Color(0xFF333042);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final strokeW = (s * 0.036).clamp(1.2, 4.8);

    final stroke = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final primary = config.primaryColor;
    final darkerPrimary = Color.lerp(primary, Colors.black, 0.16)!;
    final lighterPrimary = Color.lerp(primary, Colors.white, 0.52)!;

    // Subtle soft glow highlight at top of background circle
    final bgGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.9,
        colors: [
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, s, s));
    canvas.drawRect(Rect.fromLTWH(0, 0, s, s), bgGlow);

    // 1. Headphone headband back arc (if worn, sits neatly around head)
    if (config.accessory == 'headphone') {
      _drawHeadphoneBand(canvas, s, strokeW);
    }

    // 2. Cute rounded chibi shoulders / body at bottom
    _drawBody(canvas, s, primary, lighterPrimary, stroke);

    // 3. Back ears (for species whose ears sit behind the head contour)
    _drawEars(canvas, s, primary, darkerPrimary, lighterPrimary, stroke);

    // 4. Unified Chibi Head Contour
    final headRect = Rect.fromCenter(
      center: Offset(s * 0.50, s * 0.55),
      width: s * 0.58,
      height: s * 0.49,
    );
    final headRRect = RRect.fromRectAndRadius(
      headRect,
      Radius.circular(s * 0.24),
    );

    final isDefaultWhite =
        primary == const Color(0xFFECEFF1) || primary.computeLuminance() > 0.88;

    final headFillColor = switch (config.base) {
      'panda' => const Color(0xFFFAFAFC),
      'penguin' => isDefaultWhite ? _darkPatch : primary,
      'robot' => Color.lerp(primary, const Color(0xFFCFD8DC), 0.35)!,
      _ => primary,
    };

    canvas.drawRRect(headRRect, Paint()..color = headFillColor);

    // Species face markings (inside head before outline & eyes)
    _drawSpeciesFaceMarkings(canvas, s, headRect, primary, lighterPrimary);

    // Crisp cartoon head outline
    canvas.drawRRect(headRRect, stroke);

    // Floppy ears that overlap the side of the head (dog)
    if (config.base == 'dog') {
      _drawDogFloppyEars(canvas, s, darkerPrimary, stroke);
    }

    // 5. Eyes, Blush, Snout & Smile
    _drawFacialFeatures(canvas, s, stroke, strokeW);

    // 6. Neck / Ear Accessories (bowtie, scarf, headphone earcups)
    _drawExtraAccessory(canvas, s, stroke, strokeW);

    // 7. Eyewear (round, nerd, cool shades, monocle)
    _drawEyewear(canvas, s, stroke, strokeW);

    // 8. Headwear (sprout, bow, cap, beanie, grad cap, wizard hat, crown)
    _drawHeadwear(canvas, s, stroke, strokeW);
  }

  void _drawBody(
    Canvas canvas,
    double s,
    Color primary,
    Color lighter,
    Paint stroke,
  ) {
    final isDefaultWhite =
        primary == const Color(0xFFECEFF1) || primary.computeLuminance() > 0.88;
    final bodyColor = switch (config.base) {
      'panda' => isDefaultWhite ? _darkPatch : primary,
      'penguin' => isDefaultWhite ? _darkPatch : primary,
      _ => primary,
    };
    final bodyRect = Rect.fromCenter(
      center: Offset(s * 0.50, s * 0.93),
      width: s * 0.50,
      height: s * 0.34,
    );
    final bodyRRect = RRect.fromRectAndRadius(
      bodyRect,
      Radius.circular(s * 0.18),
    );
    canvas.drawRRect(bodyRRect, Paint()..color = bodyColor);

    // Cute tummy patch
    final tummyColor = switch (config.base) {
      'panda' => const Color(0xFFFAFAFC),
      'penguin' => _cream,
      _ => lighter,
    };
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.50, s * 0.95),
        width: s * 0.28,
        height: s * 0.22,
      ),
      Paint()..color = tummyColor,
    );
    canvas.drawRRect(bodyRRect, stroke);
  }

  void _drawEars(
    Canvas canvas,
    double s,
    Color primary,
    Color darker,
    Color lighter,
    Paint stroke,
  ) {
    final pinkInner = Paint()..color = const Color(0xFFFFABBA);

    switch (config.base) {
      case 'cat':
      case 'fox':
        final earColor = config.base == 'fox' ? primary : primary;
        for (final dir in [-1.0, 1.0]) {
          final cx = s * 0.50 + dir * s * 0.20;
          final path = Path()
            ..moveTo(cx - dir * s * 0.09, s * 0.39)
            ..quadraticBezierTo(
              cx + dir * s * 0.03,
              s * 0.17,
              cx + dir * s * 0.07,
              s * 0.20,
            )
            ..quadraticBezierTo(
              cx + dir * s * 0.11,
              s * 0.28,
              cx + dir * s * 0.08,
              s * 0.43,
            )
            ..close();
          canvas.drawPath(path, Paint()..color = earColor);

          final inner = Path()
            ..moveTo(cx - dir * s * 0.04, s * 0.37)
            ..lineTo(cx + dir * s * 0.045, s * 0.24)
            ..lineTo(cx + dir * s * 0.055, s * 0.39)
            ..close();
          canvas.drawPath(
            inner,
            config.base == 'fox' ? (Paint()..color = _darkPatch) : pinkInner,
          );
          canvas.drawPath(path, stroke);
        }
        break;

      case 'bear':
      case 'panda':
        final isDefaultWhite =
            primary == const Color(0xFFECEFF1) || primary.computeLuminance() > 0.88;
        final earColor = config.base == 'panda'
            ? (isDefaultWhite ? _darkPatch : primary)
            : primary;
        final earFill = Paint()..color = earColor;
        for (final dir in [-1.0, 1.0]) {
          final center = Offset(s * 0.50 + dir * s * 0.22, s * 0.34);
          canvas.drawCircle(center, s * 0.105, earFill);
          if (config.base == 'bear') {
            canvas.drawCircle(center, s * 0.055, pinkInner);
          }
          canvas.drawCircle(center, s * 0.105, stroke);
        }
        break;

      case 'rabbit':
        for (final dir in [-1.0, 1.0]) {
          canvas.save();
          final pivot = Offset(s * 0.50 + dir * s * 0.13, s * 0.34);
          canvas.translate(pivot.dx, pivot.dy);
          canvas.rotate(dir * 0.12);
          final earRect = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(0, -s * 0.09),
              width: s * 0.13,
              height: s * 0.28,
            ),
            Radius.circular(s * 0.07),
          );
          canvas.drawRRect(earRect, Paint()..color = primary);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(0, -s * 0.08),
                width: s * 0.065,
                height: s * 0.18,
              ),
              Radius.circular(s * 0.04),
            ),
            pinkInner,
          );
          canvas.drawRRect(earRect, stroke);
          canvas.restore();
        }
        break;

      case 'koala':
        for (final dir in [-1.0, 1.0]) {
          final center = Offset(s * 0.50 + dir * s * 0.28, s * 0.46);
          canvas.drawCircle(center, s * 0.13, Paint()..color = primary);
          canvas.drawCircle(center, s * 0.075, Paint()..color = _cream);
          canvas.drawCircle(center, s * 0.13, stroke);
        }
        break;

      case 'owl':
        // Cute feather ear tufts
        for (final dir in [-1.0, 1.0]) {
          final path = Path()
            ..moveTo(s * 0.50 + dir * s * 0.16, s * 0.35)
            ..lineTo(s * 0.50 + dir * s * 0.28, s * 0.24)
            ..lineTo(s * 0.50 + dir * s * 0.25, s * 0.41)
            ..close();
          canvas.drawPath(path, Paint()..color = darker);
          canvas.drawPath(path, stroke);
        }
        break;

      case 'robot':
        // Cute cyber antenna + side bolts
        final stemTop = Offset(s * 0.50, s * 0.18);
        canvas.drawLine(Offset(s * 0.50, s * 0.31), stemTop, stroke);
        canvas.drawCircle(
          stemTop,
          s * 0.045,
          Paint()..color = const Color(0xFF00E5FF),
        );
        canvas.drawCircle(stemTop, s * 0.045, stroke);
        for (final dir in [-1.0, 1.0]) {
          final boltRect = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(s * 0.50 + dir * s * 0.31, s * 0.55),
              width: s * 0.07,
              height: s * 0.12,
            ),
            Radius.circular(s * 0.025),
          );
          canvas.drawRRect(boltRect, Paint()..color = darker);
          canvas.drawRRect(boltRect, stroke);
        }
        break;

      default:
        break;
    }
  }

  void _drawDogFloppyEars(
    Canvas canvas,
    double s,
    Color darker,
    Paint stroke,
  ) {
    for (final dir in [-1.0, 1.0]) {
      canvas.save();
      final pivot = Offset(s * 0.50 + dir * s * 0.26, s * 0.45);
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(dir * 0.22);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, s * 0.08),
          width: s * 0.13,
          height: s * 0.24,
        ),
        Radius.circular(s * 0.065),
      );
      canvas.drawRRect(rrect, Paint()..color = darker);
      canvas.drawRRect(rrect, stroke);
      canvas.restore();
    }
  }

  void _drawSpeciesFaceMarkings(
    Canvas canvas,
    double s,
    Rect headRect,
    Color primary,
    Color lighter,
  ) {
    switch (config.base) {
      case 'fox':
        // Cream lower cheek masks
        final mask = Path()
          ..moveTo(s * 0.21, s * 0.58)
          ..quadraticBezierTo(s * 0.36, s * 0.52, s * 0.50, s * 0.63)
          ..quadraticBezierTo(s * 0.64, s * 0.52, s * 0.79, s * 0.58)
          ..quadraticBezierTo(s * 0.78, s * 0.79, s * 0.50, s * 0.795)
          ..quadraticBezierTo(s * 0.22, s * 0.79, s * 0.21, s * 0.58)
          ..close();
        canvas.drawPath(mask, Paint()..color = _cream);
        break;

      case 'penguin':
        // Heart-shaped cream face mask + colored forehead accent
        for (final dir in [-1.0, 1.0]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(s * 0.50 + dir * s * 0.11, s * 0.58),
              width: s * 0.24,
              height: s * 0.31,
            ),
            Paint()..color = _cream,
          );
        }
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(s * 0.50, s * 0.65),
            width: s * 0.42,
            height: s * 0.24,
          ),
          Paint()..color = _cream,
        );
        break;

      case 'owl':
        for (final dir in [-1.0, 1.0]) {
          canvas.drawCircle(
            Offset(s * 0.50 + dir * s * 0.125, s * 0.55),
            s * 0.115,
            Paint()..color = _cream,
          );
        }
        break;

      case 'panda':
        final isDefaultWhite =
            primary == const Color(0xFFECEFF1) || primary.computeLuminance() > 0.88;
        final patchColor = isDefaultWhite
            ? _darkPatch
            : Color.lerp(primary, _darkPatch, 0.22)!;
        for (final dir in [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(s * 0.50 + dir * s * 0.13, s * 0.555);
          canvas.rotate(-dir * 0.22);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: s * 0.135,
              height: s * 0.165,
            ),
            Paint()..color = patchColor,
          );
          canvas.restore();
        }
        break;

      case 'cat':
        // Cute forehead tabby stripes
        final stripePaint = Paint()
          ..color = Color.lerp(primary, Colors.black, 0.20)!
          ..strokeWidth = (s * 0.028).clamp(1.0, 4.0)
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(s * 0.50, s * 0.33),
          Offset(s * 0.50, s * 0.41),
          stripePaint,
        );
        canvas.drawLine(
          Offset(s * 0.44, s * 0.34),
          Offset(s * 0.45, s * 0.40),
          stripePaint,
        );
        canvas.drawLine(
          Offset(s * 0.56, s * 0.34),
          Offset(s * 0.55, s * 0.40),
          stripePaint,
        );
        break;

      case 'robot':
        // Inner dark visor screen
        final screenRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(s * 0.50, s * 0.56),
            width: s * 0.44,
            height: s * 0.31,
          ),
          Radius.circular(s * 0.11),
        );
        canvas.drawRRect(screenRect, Paint()..color = const Color(0xFF1E2233));
        break;

      default:
        break;
    }
  }

  void _drawFacialFeatures(
    Canvas canvas,
    double s,
    Paint stroke,
    double strokeW,
  ) {
    final eyeY = s * 0.55;
    final leftEye = Offset(s * 0.375, eyeY);
    final rightEye = Offset(s * 0.625, eyeY);

    // Rosy Blush Cheeks
    final blushPaint = Paint()..color = _blush.withValues(alpha: 0.58);
    for (final cx in [s * 0.305, s * 0.695]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, s * 0.62),
          width: s * 0.095,
          height: s * 0.055,
        ),
        blushPaint,
      );
    }

    if (config.base == 'robot') {
      // Glowing cyan happy LED eyes + smile
      final cyan = Paint()..color = const Color(0xFF26E6FF);
      for (final eye in [leftEye, rightEye]) {
        canvas.drawCircle(eye, s * 0.042, cyan);
        canvas.drawCircle(
          eye.translate(-s * 0.012, -s * 0.012),
          s * 0.014,
          Paint()..color = Colors.white,
        );
      }
      final smilePaint = Paint()
        ..color = const Color(0xFF26E6FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW * 0.85
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(s * 0.50, s * 0.615),
          width: s * 0.11,
          height: s * 0.075,
        ),
        0.15,
        math.pi - 0.3,
        false,
        smilePaint,
      );
      return;
    }

    // Glossy Cartoon Eyes
    final eyeRadius = s * 0.044;
    final eyePaint = Paint()
      ..color = config.base == 'panda' ? const Color(0xFF15131E) : _ink;
    final whitePaint = Paint()..color = Colors.white;

    for (final eye in [leftEye, rightEye]) {
      canvas.drawCircle(eye, eyeRadius, eyePaint);
      // Big sparkle
      canvas.drawCircle(
        eye.translate(-eyeRadius * 0.30, -eyeRadius * 0.32),
        eyeRadius * 0.36,
        whitePaint,
      );
      // Tiny lower catchlight
      canvas.drawCircle(
        eye.translate(eyeRadius * 0.30, eyeRadius * 0.30),
        eyeRadius * 0.16,
        whitePaint,
      );
    }

    // Snout / Beak / Mouth per species
    final mouthStroke = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = (strokeW * 0.80).clamp(1.0, 3.8)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (config.base == 'owl' || config.base == 'penguin') {
      final beak = Path()
        ..moveTo(s * 0.46, s * 0.59)
        ..lineTo(s * 0.54, s * 0.59)
        ..lineTo(s * 0.50, s * 0.655)
        ..close();
      canvas.drawPath(beak, Paint()..color = const Color(0xFFFFA726));
      canvas.drawPath(beak, mouthStroke);
      return;
    }

    if (config.base == 'koala') {
      // Cute oval button nose
      final noseRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s * 0.50, s * 0.595),
          width: s * 0.075,
          height: s * 0.095,
        ),
        Radius.circular(s * 0.04),
      );
      canvas.drawRRect(noseRect, Paint()..color = _darkPatch);
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(s * 0.50, s * 0.655),
          width: s * 0.08,
          height: s * 0.05,
        ),
        0.15,
        math.pi - 0.3,
        false,
        mouthStroke,
      );
      return;
    }

    if (config.base == 'bear' || config.base == 'dog' || config.base == 'panda') {
      if (config.base != 'panda') {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(s * 0.50, s * 0.625),
            width: s * 0.17,
            height: s * 0.12,
          ),
          Paint()..color = _cream,
        );
      }
    }

    // Cute tiny triangle/oval nose
    final noseColor = (config.base == 'cat' || config.base == 'rabbit')
        ? const Color(0xFFFF7A93)
        : _ink;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.50, s * 0.595),
        width: s * 0.055,
        height: s * 0.038,
      ),
      Paint()..color = noseColor,
    );

    // Classic cute ':3' / 'w' cat-smile
    final wSmile = Path()
      ..moveTo(s * 0.445, s * 0.635)
      ..quadraticBezierTo(s * 0.472, s * 0.668, s * 0.50, s * 0.632)
      ..quadraticBezierTo(s * 0.528, s * 0.668, s * 0.555, s * 0.635);
    canvas.drawPath(wSmile, mouthStroke);

    // Cat whiskers
    if (config.base == 'cat') {
      final whisker = Paint()
        ..color = _ink.withValues(alpha: 0.75)
        ..strokeWidth = (strokeW * 0.6).clamp(0.9, 2.5)
        ..strokeCap = StrokeCap.round;
      for (final dir in [-1.0, 1.0]) {
        canvas.drawLine(
          Offset(s * 0.50 + dir * s * 0.22, s * 0.58),
          Offset(s * 0.50 + dir * s * 0.31, s * 0.565),
          whisker,
        );
        canvas.drawLine(
          Offset(s * 0.50 + dir * s * 0.22, s * 0.62),
          Offset(s * 0.50 + dir * s * 0.31, s * 0.63),
          whisker,
        );
      }
    }
  }

  void _drawHeadphoneBand(Canvas canvas, double s, double strokeW) {
    final bandPaint = Paint()
      ..color = const Color(0xFF5E35B1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.055
      ..strokeCap = StrokeCap.round;
    final outlinePaint = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.055 + strokeW * 1.4
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCenter(
      center: Offset(s * 0.50, s * 0.55),
      width: s * 0.66,
      height: s * 0.58,
    );
    canvas.drawArc(rect, math.pi * 1.05, math.pi * 0.90, false, outlinePaint);
    canvas.drawArc(rect, math.pi * 1.05, math.pi * 0.90, false, bandPaint);
  }

  void _drawExtraAccessory(
    Canvas canvas,
    double s,
    Paint stroke,
    double strokeW,
  ) {
    switch (config.accessory) {
      case 'bowtie':
        final bowY = s * 0.805;
        final red = Paint()..color = const Color(0xFFFF5252);
        final leftWing = Path()
          ..moveTo(s * 0.50, bowY)
          ..lineTo(s * 0.39, bowY - s * 0.05)
          ..lineTo(s * 0.39, bowY + s * 0.05)
          ..close();
        final rightWing = Path()
          ..moveTo(s * 0.50, bowY)
          ..lineTo(s * 0.61, bowY - s * 0.05)
          ..lineTo(s * 0.61, bowY + s * 0.05)
          ..close();
        canvas.drawPath(leftWing, red);
        canvas.drawPath(rightWing, red);
        canvas.drawPath(leftWing, stroke);
        canvas.drawPath(rightWing, stroke);
        canvas.drawCircle(Offset(s * 0.50, bowY), s * 0.028, red);
        canvas.drawCircle(Offset(s * 0.50, bowY), s * 0.028, stroke);
        break;

      case 'scarf':
        final scarfRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(s * 0.50, s * 0.795),
            width: s * 0.44,
            height: s * 0.095,
          ),
          Radius.circular(s * 0.045),
        );
        final tailRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.54, s * 0.80, s * 0.10, s * 0.15),
          Radius.circular(s * 0.03),
        );
        final scarfFill = Paint()..color = const Color(0xFFEF5350);
        canvas.drawRRect(tailRect, scarfFill);
        canvas.drawRRect(tailRect, stroke);
        canvas.drawRRect(scarfRect, scarfFill);
        // Cute yellow stripe
        canvas.drawLine(
          Offset(s * 0.34, s * 0.795),
          Offset(s * 0.66, s * 0.795),
          Paint()
            ..color = const Color(0xFFFFD54F)
            ..strokeWidth = strokeW * 0.9
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawRRect(scarfRect, stroke);
        break;

      case 'headphone':
        for (final dir in [-1.0, 1.0]) {
          final cupRect = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(s * 0.50 + dir * s * 0.315, s * 0.56),
              width: s * 0.105,
              height: s * 0.19,
            ),
            Radius.circular(s * 0.05),
          );
          canvas.drawRRect(cupRect, Paint()..color = const Color(0xFF7E57C2));
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(s * 0.50 + dir * s * 0.315, s * 0.56),
              width: s * 0.04,
              height: s * 0.09,
            ),
            Paint()..color = const Color(0xFF00E5FF),
          );
          canvas.drawRRect(cupRect, stroke);
        }
        break;

      default:
        break;
    }
  }

  void _drawEyewear(
    Canvas canvas,
    double s,
    Paint stroke,
    double strokeW,
  ) {
    final eyeY = s * 0.55;
    final leftC = Offset(s * 0.375, eyeY);
    final rightC = Offset(s * 0.625, eyeY);
    final frameStroke = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = (strokeW * 0.85).clamp(1.1, 4.0)
      ..strokeCap = StrokeCap.round;

    switch (config.eyewear) {
      case 'glasses_round':
        final lensFill = Paint()..color = Colors.white.withValues(alpha: 0.25);
        canvas.drawCircle(leftC, s * 0.085, lensFill);
        canvas.drawCircle(rightC, s * 0.085, lensFill);
        canvas.drawCircle(leftC, s * 0.085, frameStroke);
        canvas.drawCircle(rightC, s * 0.085, frameStroke);
        canvas.drawLine(
          Offset(s * 0.46, eyeY),
          Offset(s * 0.54, eyeY),
          frameStroke,
        );
        break;

      case 'glasses_nerd':
        final thickStroke = Paint()
          ..color = const Color(0xFF1A1726)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (strokeW * 1.15).clamp(1.4, 5.0);
        for (final c in [leftC, rightC]) {
          final r = RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: s * 0.18, height: s * 0.135),
            Radius.circular(s * 0.035),
          );
          canvas.drawRRect(
            r,
            Paint()..color = const Color(0xFFB3E5FC).withValues(alpha: 0.28),
          );
          canvas.drawRRect(r, thickStroke);
        }
        canvas.drawLine(
          Offset(s * 0.465, eyeY - s * 0.01),
          Offset(s * 0.535, eyeY - s * 0.01),
          thickStroke,
        );
        break;

      case 'glasses_cool':
        final shadeFill = Paint()..color = const Color(0xFF1E1B2E);
        for (final c in [leftC, rightC]) {
          final r = RRect.fromRectAndCorners(
            Rect.fromCenter(center: c, width: s * 0.19, height: s * 0.125),
            topLeft: Radius.circular(s * 0.025),
            topRight: Radius.circular(s * 0.025),
            bottomLeft: Radius.circular(s * 0.06),
            bottomRight: Radius.circular(s * 0.06),
          );
          canvas.drawRRect(r, shadeFill);
          // Cool diagonal shine
          canvas.drawLine(
            Offset(c.dx - s * 0.05, c.dy - s * 0.03),
            Offset(c.dx - s * 0.01, c.dy + s * 0.03),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.55)
              ..strokeWidth = strokeW * 0.75
              ..strokeCap = StrokeCap.round,
          );
          canvas.drawRRect(r, frameStroke);
        }
        canvas.drawLine(
          Offset(s * 0.21, eyeY - s * 0.025),
          Offset(s * 0.79, eyeY - s * 0.025),
          frameStroke,
        );
        break;

      case 'monocle':
        final goldStroke = Paint()
          ..color = const Color(0xFFFFB300)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (strokeW * 0.95).clamp(1.2, 4.2);
        canvas.drawCircle(
          rightC,
          s * 0.088,
          Paint()..color = const Color(0xFFFFF8E1).withValues(alpha: 0.30),
        );
        canvas.drawCircle(rightC, s * 0.088, goldStroke);
        // Cute hanging gold chain
        final chain = Path()
          ..moveTo(rightC.dx + s * 0.075, rightC.dy + s * 0.04)
          ..quadraticBezierTo(
            rightC.dx + s * 0.10,
            rightC.dy + s * 0.16,
            rightC.dx + s * 0.04,
            rightC.dy + s * 0.21,
          );
        canvas.drawPath(
          chain,
          goldStroke..strokeWidth = (strokeW * 0.6).clamp(1.0, 2.5),
        );
        break;

      default:
        break;
    }
  }

  void _drawHeadwear(
    Canvas canvas,
    double s,
    Paint stroke,
    double strokeW,
  ) {
    switch (config.headwear) {
      case 'sprout':
        final stem = Path()
          ..moveTo(s * 0.50, s * 0.31)
          ..quadraticBezierTo(s * 0.49, s * 0.21, s * 0.51, s * 0.17);
        canvas.drawPath(stem, stroke);
        final leafPaint = Paint()..color = const Color(0xFF66BB6A);
        final leftLeaf = Path()
          ..moveTo(s * 0.505, s * 0.185)
          ..quadraticBezierTo(s * 0.38, s * 0.12, s * 0.39, s * 0.21)
          ..quadraticBezierTo(s * 0.44, s * 0.24, s * 0.505, s * 0.185);
        final rightLeaf = Path()
          ..moveTo(s * 0.505, s * 0.185)
          ..quadraticBezierTo(s * 0.62, s * 0.11, s * 0.62, s * 0.20)
          ..quadraticBezierTo(s * 0.56, s * 0.23, s * 0.505, s * 0.185);
        canvas.drawPath(leftLeaf, leafPaint);
        canvas.drawPath(rightLeaf, leafPaint);
        canvas.drawPath(leftLeaf, stroke);
        canvas.drawPath(rightLeaf, stroke);
        break;

      case 'bow':
        final bx = s * 0.62;
        final by = s * 0.30;
        final bowPaint = Paint()..color = const Color(0xFFFF6090);
        for (final dir in [-1.0, 1.0]) {
          final loop = Path()
            ..moveTo(bx, by)
            ..quadraticBezierTo(
              bx + dir * s * 0.12,
              by - s * 0.08,
              bx + dir * s * 0.11,
              by + s * 0.01,
            )
            ..quadraticBezierTo(
              bx + dir * s * 0.10,
              by + s * 0.08,
              bx,
              by,
            );
          canvas.drawPath(loop, bowPaint);
          canvas.drawPath(loop, stroke);
        }
        canvas.drawCircle(Offset(bx, by), s * 0.032, bowPaint);
        canvas.drawCircle(Offset(bx, by), s * 0.032, stroke);
        break;

      case 'hat_cap':
        final capPaint = Paint()..color = const Color(0xFF42A5F5);
        final dome = Path()
          ..moveTo(s * 0.25, s * 0.36)
          ..quadraticBezierTo(s * 0.50, s * 0.13, s * 0.74, s * 0.35)
          ..close();
        canvas.drawPath(dome, capPaint);
        canvas.drawPath(dome, stroke);
        final visor = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.44, s * 0.32, s * 0.38, s * 0.06),
          Radius.circular(s * 0.03),
        );
        canvas.drawRRect(visor, Paint()..color = const Color(0xFF1E88E5));
        canvas.drawRRect(visor, stroke);
        break;

      case 'hat_beanie':
        final beaniePaint = Paint()..color = const Color(0xFFFF7043);
        canvas.drawCircle(Offset(s * 0.50, s * 0.14), s * 0.045, beaniePaint);
        canvas.drawCircle(Offset(s * 0.50, s * 0.14), s * 0.045, stroke);
        final dome = Path()
          ..moveTo(s * 0.24, s * 0.36)
          ..quadraticBezierTo(s * 0.50, s * 0.12, s * 0.76, s * 0.36)
          ..close();
        canvas.drawPath(dome, beaniePaint);
        canvas.drawPath(dome, stroke);
        final cuff = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(s * 0.50, s * 0.35),
            width: s * 0.54,
            height: s * 0.08,
          ),
          Radius.circular(s * 0.035),
        );
        canvas.drawRRect(cuff, Paint()..color = const Color(0xFFF4511E));
        canvas.drawRRect(cuff, stroke);
        break;

      case 'hat_graduate':
        final capDark = Paint()..color = const Color(0xFF28243D);
        // Base skullcap
        final band = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(s * 0.50, s * 0.30),
            width: s * 0.34,
            height: s * 0.09,
          ),
          Radius.circular(s * 0.025),
        );
        canvas.drawRRect(band, capDark);
        canvas.drawRRect(band, stroke);
        // Diamond mortarboard top
        final top = Path()
          ..moveTo(s * 0.50, s * 0.13)
          ..lineTo(s * 0.77, s * 0.225)
          ..lineTo(s * 0.50, s * 0.305)
          ..lineTo(s * 0.23, s * 0.225)
          ..close();
        canvas.drawPath(top, capDark);
        canvas.drawPath(top, stroke);
        // Gold tassel
        final tassel = Paint()
          ..color = const Color(0xFFFFCA28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW * 0.85
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(s * 0.50, s * 0.22),
          Offset(s * 0.71, s * 0.25),
          tassel,
        );
        canvas.drawLine(
          Offset(s * 0.71, s * 0.25),
          Offset(s * 0.72, s * 0.35),
          tassel,
        );
        break;

      case 'hat_wizard':
        final wizPaint = Paint()..color = const Color(0xFF6A1B9A);
        final cone = Path()
          ..moveTo(s * 0.31, s * 0.33)
          ..quadraticBezierTo(s * 0.47, s * 0.06, s * 0.59, s * 0.09)
          ..quadraticBezierTo(s * 0.57, s * 0.19, s * 0.69, s * 0.33)
          ..close();
        canvas.drawPath(cone, wizPaint);
        canvas.drawPath(cone, stroke);
        // Gold ribbon band
        canvas.drawLine(
          Offset(s * 0.33, s * 0.31),
          Offset(s * 0.67, s * 0.31),
          Paint()
            ..color = const Color(0xFFFFD54F)
            ..strokeWidth = strokeW * 1.2
            ..strokeCap = StrokeCap.round,
        );
        // Wide brim
        final brim = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(s * 0.50, s * 0.335),
            width: s * 0.60,
            height: s * 0.065,
          ),
          Radius.circular(s * 0.035),
        );
        canvas.drawRRect(brim, wizPaint);
        canvas.drawRRect(brim, stroke);
        break;

      case 'crown':
        final crownPath = Path()
          ..moveTo(s * 0.32, s * 0.33)
          ..lineTo(s * 0.30, s * 0.17)
          ..lineTo(s * 0.41, s * 0.25)
          ..lineTo(s * 0.50, s * 0.12)
          ..lineTo(s * 0.59, s * 0.25)
          ..lineTo(s * 0.70, s * 0.17)
          ..lineTo(s * 0.68, s * 0.33)
          ..close();
        canvas.drawPath(crownPath, Paint()..color = const Color(0xFFFFCA28));
        canvas.drawPath(crownPath, stroke);
        // Ruby center jewel
        canvas.drawCircle(
          Offset(s * 0.50, s * 0.265),
          s * 0.025,
          Paint()..color = const Color(0xFFFF1744),
        );
        break;

      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ChibiCartoonAvatarPainter oldDelegate) {
    return oldDelegate.config != config;
  }
}

