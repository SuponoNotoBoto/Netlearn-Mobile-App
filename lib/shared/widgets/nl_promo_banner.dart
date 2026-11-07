import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class NlPromoBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onPressed;

  const NlPromoBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const bgColor = NetLearnColors.cardBannerBg;
    const titleColor = Color(0xFF1C1243);
    const subtitleColor = Color(0xFF5A5375);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(NetLearnRadius.radiusLg),
        boxShadow: NetLearnShadows.banner,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    letterSpacing: -0.3,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.45,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 14),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onPressed,
                    borderRadius: BorderRadius.circular(NetLearnRadius.radiusPill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: NetLearnColors.primary,
                        borderRadius: BorderRadius.circular(NetLearnRadius.radiusPill),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x478C52FF),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        ctaLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SizedBox(
            width: 100,
            height: 94,
            child: CustomPaint(
              painter: _PromoBannerArtPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoBannerArtPainter extends CustomPainter {
  const _PromoBannerArtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 120.0;
    final sy = size.height / 110.0;
    canvas.save();
    canvas.scale(sx, sy);

    final circlePaint = Paint()
      ..color = const Color(0xB3DDD2FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(68, 56), 44, circlePaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(22, 72, 76, 16),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF8C52FF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(26, 76, 66, 8),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFF6F4FD),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(28, 56, 68, 15),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFFFFB067),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(32, 60, 58, 7),
        const Radius.circular(2.5),
      ),
      Paint()..color = const Color(0xFFFFF8F0),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(34, 41, 58, 14),
        const Radius.circular(4.5),
      ),
      Paint()..color = const Color(0xFF6C9EFF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(38, 45, 48, 6),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFF2F7FF),
    );

    final capTop = Path()
      ..moveTo(62, 16)
      ..lineTo(94, 28)
      ..lineTo(62, 40)
      ..lineTo(30, 28)
      ..close();
    canvas.drawPath(capTop, Paint()..color = const Color(0xFF2E1A68));

    final capBase = Path()
      ..moveTo(43, 33)
      ..lineTo(43, 42)
      ..quadraticBezierTo(62, 49, 81, 42)
      ..lineTo(81, 33)
      ..close();
    canvas.drawPath(capBase, Paint()..color = const Color(0xFF472AA0));

    canvas.drawLine(
      const Offset(88, 30),
      const Offset(88, 45),
      Paint()
        ..color = const Color(0xFFFFB067)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      const Offset(88, 46),
      3,
      Paint()..color = const Color(0xFFFFB067),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

