import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// `.promo-banner` dari `design_figma/scr_figma_new/App.tsx` & `index.css`:
///
/// ```css
/// .promo-banner{position:relative;display:flex;align-items:center;
///   justify-content:space-between;gap:12px;min-height:140px;
///   background:#ece6ff;border-radius:24px;padding:18px 16px 18px 20px;
///   margin-bottom:22px;overflow:hidden;
///   box-shadow:0 6px 20px rgba(140,82,255,.08)}
/// .dark-theme .promo-banner{background:#231d38;box-shadow:none}
/// ```
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? const Color(0xFF231D38)
        : NetLearnColors.cardBannerBg;
    final titleColor = isDark
        ? const Color(0xFFF3EEFF)
        : const Color(0xFF1C1243);
    final subtitleColor = isDark
        ? const Color(0xFFC8BFE5)
        : const Color(0xFF5A5375);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(NetLearnRadius.radiusLg),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x148C52FF),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
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
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
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
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
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
                    borderRadius: BorderRadius.circular(
                      NetLearnRadius.radiusPill,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: NetLearnColors.primary,
                        borderRadius: BorderRadius.circular(
                          NetLearnRadius.radiusPill,
                        ),
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
                          fontFamily: AppTheme.fontFamily,
                          color: NetLearnColors.white,
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

/// Menggambar ilustrasi buku bertumpuk + topi wisuda + pensil dari SVG
/// `.promo-banner-art` di `design_figma/scr_figma_new/App.tsx`.
class _PromoBannerArtPainter extends CustomPainter {
  const _PromoBannerArtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 120.0;
    final sy = size.height / 110.0;
    canvas.save();
    canvas.scale(sx, sy);

    // Soft background circle (`cx="68" cy="56" r="44" fill="#DDD2FF" opacity="0.7"`)
    final circlePaint = Paint()
      ..color = const Color(0xB3DDD2FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(68, 56), 44, circlePaint);

    // Bottom book (`x="22" y="72" width="76" height="16" rx="5" fill="#8C52FF"`)
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

    // Middle book (`x="28" y="56" width="68" height="15" rx="5" fill="#FFB067"`)
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

    // Top book (`x="34" y="41" width="58" height="14" rx="4.5" fill="#6C9EFF"`)
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

    // Graduation cap (`M62 16L94 28L62 40L30 28L62 16Z` fill `#2E1A68`)
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

    // Tassel (`M88 30V45` stroke `#FFB067`, circle `cx="88" cy="46" r="3"`)
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

