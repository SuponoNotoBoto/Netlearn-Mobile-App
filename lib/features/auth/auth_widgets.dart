import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_netlearn_logo.dart';
import '../../shared/widgets/nl_segmented_tabs.dart';
import 'auth_controller.dart';

/// `.login-hero` — header gradien ungu dengan motif jaringan di tengah,
/// gelombang berlapis di bagian bawah, logo NetLearn terbaru, serta tagline
/// "Computer Networking LMS" (dipakai bersama oleh halaman Login & Register).
class AuthHero extends StatelessWidget {
  const AuthHero({super.key});

  @override
  Widget build(BuildContext context) {
    final pageBg = context.background;

    return ClipRect(
      child: CustomPaint(
        painter: _AuthHeroBackdropPainter(bottomCutoutColor: pageBg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 52),
          child: Column(
            children: [
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const NlNetLearnLogo(inverse: true, size: 42),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'NetLearn',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontWeight: FontWeight.w800,
                        fontSize: 34,
                        height: 40.8 / 34,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Computer Networking LMS',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  height: 19.8 / 13,
                  color: Color(0xFFE6E0FA),
                  letterSpacing: 0,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthHeroBackdropPainter extends CustomPainter {
  const _AuthHeroBackdropPainter({required this.bottomCutoutColor});

  final Color bottomCutoutColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Gradien latar belakang ungu hero.
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF722FF9),
          Color(0xFF5D21DF),
          Color(0xFF4918C0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Motif lingkaran besar kiri atas & kanan atas.
    final circleFillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.075);

    final leftCenter = Offset(w * 0.175, h * 0.25);
    canvas.drawCircle(leftCenter, w * 0.145, circleFillPaint);
    _drawDashedCircle(
      canvas,
      center: leftCenter,
      radius: w * 0.088,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.16),
      dashLength: 3.5,
      gapLength: 4.0,
    );

    final rightCenter = Offset(w * 0.825, h * 0.33);
    canvas.drawCircle(rightCenter, w * 0.125, circleFillPaint);
    canvas.drawCircle(
      rightCenter,
      w * 0.072,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.16),
    );

    // Garis diagonal halus di sekitar lingkaran.
    final thinLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.14);
    canvas.drawLine(
      Offset(w * 0.205, h * 0.335),
      Offset(w * 0.275, h * 0.44),
      thinLinePaint,
    );
    canvas.drawLine(
      Offset(w * 0.805, h * 0.29),
      Offset(w * 0.725, h * 0.39),
      thinLinePaint,
    );

    // 3. Motif jaringan tengah: garis putus-putus, titik tengah, dan 2 simpul heksagon.
    final meshPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.20);

    final leftHex = Offset(w * 0.228, h * 0.675);
    final topDot = Offset(w * 0.515, h * 0.305);
    final rightHex = Offset(w * 0.778, h * 0.615);

    _drawDashedLine(canvas, Offset(w * 0.14, h * 0.70), leftHex, meshPaint);
    _drawDashedLine(canvas, leftHex, topDot, meshPaint);
    _drawDashedLine(canvas, topDot, rightHex, meshPaint);
    _drawDashedLine(canvas, rightHex, Offset(w * 0.86, h * 0.53), meshPaint);

    // Jalur sekunder bentuk V halus di bawah wordmark.
    final midBottom = Offset(w * 0.498, h * 0.61);
    final secondaryMeshPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = Colors.white.withValues(alpha: 0.15);
    _drawDashedLine(
      canvas,
      Offset(w * 0.35, h * 0.46),
      midBottom,
      secondaryMeshPaint,
    );
    _drawDashedLine(
      canvas,
      midBottom,
      Offset(w * 0.65, h * 0.45),
      secondaryMeshPaint,
    );

    // Titik simpul atas dengan halo lembut.
    canvas.drawCircle(
      topDot,
      5.0,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      topDot,
      2.6,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );

    // Dua simpul heksagon dengan titik putih di tengah.
    _drawHexNode(canvas, center: leftHex, radius: 9.5, dotRadius: 2.7);
    _drawHexNode(canvas, center: rightHex, radius: 8.5, dotRadius: 2.5);

    // 4. Motif gelombang berlapis di bagian bawah.
    // Gelombang transparan lapis 1.
    final waveBack1 = Path()
      ..moveTo(0, h * 0.815)
      ..cubicTo(
        w * 0.14,
        h * 0.895,
        w * 0.28,
        h * 0.755,
        w * 0.44,
        h * 0.77,
      )
      ..cubicTo(
        w * 0.58,
        h * 0.785,
        w * 0.65,
        h * 0.90,
        w * 0.80,
        h * 0.855,
      )
      ..cubicTo(
        w * 0.90,
        h * 0.825,
        w * 0.96,
        h * 0.76,
        w,
        h * 0.735,
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      waveBack1,
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );

    // Gelombang transparan lapis 2 (fase berlawanan).
    final waveBack2 = Path()
      ..moveTo(0, h * 0.86)
      ..cubicTo(
        w * 0.16,
        h * 0.79,
        w * 0.34,
        h * 0.85,
        w * 0.50,
        h * 0.875,
      )
      ..cubicTo(
        w * 0.66,
        h * 0.90,
        w * 0.76,
        h * 0.745,
        w * 0.90,
        h * 0.79,
      )
      ..cubicTo(
        w * 0.95,
        h * 0.805,
        w * 0.98,
        h * 0.835,
        w,
        h * 0.855,
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      waveBack2,
      Paint()..color = Colors.white.withValues(alpha: 0.13),
    );

    // Gelombang solid penutup bawah sesuai warna latar halaman.
    final waveFront = Path()
      ..moveTo(0, h * 0.885)
      ..cubicTo(
        w * 0.12,
        h * 0.945,
        w * 0.28,
        h * 0.85,
        w * 0.44,
        h * 0.855,
      )
      ..cubicTo(
        w * 0.60,
        h * 0.86,
        w * 0.72,
        h * 0.955,
        w * 0.88,
        h * 0.90,
      )
      ..cubicTo(
        w * 0.94,
        h * 0.88,
        w * 0.975,
        h * 0.845,
        w,
        h * 0.815,
      )
      ..lineTo(w, h + 1)
      ..lineTo(0, h + 1)
      ..close();
    canvas.drawPath(
      waveFront,
      Paint()
        ..style = PaintingStyle.fill
        ..color = bottomCutoutColor,
    );
  }

  static void _drawHexNode(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double dotRadius,
  }) {
    final hex = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - (math.pi / 2);
      final pt = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        hex.moveTo(pt.dx, pt.dy);
      } else {
        hex.lineTo(pt.dx, pt.dy);
      }
    }
    hex.close();

    canvas.drawPath(
      hex,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: 0.10),
    );
    canvas.drawPath(
      hex,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..color = Colors.white.withValues(alpha: 0.30),
    );
    canvas.drawCircle(
      center,
      dotRadius,
      Paint()..color = Colors.white,
    );
  }

  static void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashLength = 3.2,
    double gapLength = 3.5,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance <= 0) return;

    final ux = dx / distance;
    final uy = dy / distance;
    var progress = 0.0;

    while (progress < distance) {
      final next = math.min(progress + dashLength, distance);
      canvas.drawLine(
        Offset(start.dx + ux * progress, start.dy + uy * progress),
        Offset(start.dx + ux * next, start.dy + uy * next),
        paint,
      );
      progress = next + gapLength;
    }
  }

  static void _drawDashedCircle(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Paint paint,
    required double dashLength,
    required double gapLength,
  }) {
    if (radius <= 0) return;
    final circumference = 2 * math.pi * radius;
    final stepAngle = (dashLength + gapLength) / radius;
    final dashAngle = dashLength / radius;
    final count = (circumference / (dashLength + gapLength)).floor();
    final rect = Rect.fromCircle(center: center, radius: radius);

    for (var i = 0; i < count; i++) {
      canvas.drawArc(rect, i * stepAngle, dashAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(_AuthHeroBackdropPainter oldDelegate) {
    return oldDelegate.bottomCutoutColor != bottomCutoutColor;
  }
}

/// `.tabs` — the Student/Lecturer selector shared by both auth screens.
class AuthRoleSegmented extends StatelessWidget {
  final AppUserRole role;
  final ValueChanged<AppUserRole> onChanged;

  const AuthRoleSegmented({
    super.key,
    required this.role,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return NlSegmentedTabs(
      labels: [l10n.student, l10n.lecturer],
      selectedIndex: role == AppUserRole.student ? 0 : 1,
      semanticLabel: l10n.role,
      onChanged: (index) {
        onChanged(index == 0 ? AppUserRole.student : AppUserRole.lecturer);
      },
    );
  }
}

enum AuthFeedbackKind { error, success }

class AuthFeedbackBanner extends StatelessWidget {
  final AuthFeedbackKind kind;
  final String message;

  const AuthFeedbackBanner({
    super.key,
    required this.kind,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final status = Theme.of(context).statusColors;

    final (bg, fg, icon) = kind == AuthFeedbackKind.error
        ? (status.dangerBg, status.dangerText, Icons.error_outline_rounded)
        : (status.positiveBg, status.positiveText,
            Icons.check_circle_outline_rounded);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w500,
                fontSize: 12,
                height: 18 / 12,
                color: fg,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final AutovalidateMode? autovalidateMode;

  const AuthField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.onFieldSubmitted,
    this.autovalidateMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = theme.statusColors;

    const errorShape = OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(NetLearnRadius.field),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          autovalidateMode: autovalidateMode,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            suffixIcon: suffixIcon,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            errorStyle: TextStyle(
              color: status.dangerText,
              fontSize: 11,
              height: 14.5 / 11,
            ),
            errorBorder: errorShape.copyWith(
              borderSide: const BorderSide(color: NetLearnColors.danger),
            ),
            focusedErrorBorder: errorShape.copyWith(
              borderSide:
                  const BorderSide(color: NetLearnColors.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

