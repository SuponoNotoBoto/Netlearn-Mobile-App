import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Logo NetLearn — tile bersudut dengan huruf "N" yang disusun sebagai jalur
/// (path) jaringan: dua titik simpul yang dihubungkan garis diagonal, bentuk
/// tulang punggung dari logo Make `NetLearnLogo.tsx`.
class NlNetLearnLogo extends StatelessWidget {
  const NlNetLearnLogo({
    super.key,
    this.size = 40,
    this.inverse = false,
  });

  /// Ukuran kotak logo (mark selalu persegi).
  final double size;

  /// `true` memakai bentuk untuk permukaan gelap (tile putih, N brand).
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final tile = inverse ? NetLearnColors.white : NetLearnColors.primary;
    final mark = inverse ? NetLearnColors.primary : NetLearnColors.white;

    return Semantics(
      label: 'NetLearn',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _NetLearnMarkPainter(tileColor: tile, markColor: mark),
      ),
    );
  }
}

class _NetLearnMarkPainter extends CustomPainter {
  const _NetLearnMarkPainter({
    required this.tileColor,
    required this.markColor,
  });

  final Color tileColor;
  final Color markColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Skala viewBox 40x40 ke ukuran yang diminta.
    canvas.scale(size.width / 40);

    final tilePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = tileColor;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = markColor;

    // `<rect x="1" y="1" width="38" height="38" rx="11">`.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(1, 1, 38, 38),
        const Radius.circular(11),
      ),
      tilePaint,
    );

    // `M12 28V12L28 28V12` — kaki kiri, diagonal, kaki kanan.
    final nPath = Path()
      ..moveTo(12, 28)
      ..lineTo(12, 12)
      ..lineTo(28, 28)
      ..lineTo(28, 12);
    canvas.drawPath(nPath, strokePaint);

    // Dua simpul: `(12,12)` dan `(28,28)` dengan `r=3`.
    final nodePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = markColor;
    canvas.drawCircle(const Offset(12, 12), 3, nodePaint);
    canvas.drawCircle(const Offset(28, 28), 3, nodePaint);
  }

  @override
  bool shouldRepaint(_NetLearnMarkPainter oldDelegate) {
    return oldDelegate.tileColor != tileColor ||
        oldDelegate.markColor != markColor;
  }
}

