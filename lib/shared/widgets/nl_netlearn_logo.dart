import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Logo NetLearn terbaru — diadaptasi 1:1 secara vektor dari
/// `assets/logo/Logo_Baru.png` (huruf "N" berongga dengan jalur sirkuit dan
/// dua simpul jaringan di bagian diagonal).
///
/// - Ketika `inverse == true` (untuk latar belakang ungu/gelap seperti Auth
///   Hero, Splash Screen, dan Create/Join Class), ikon "N" digambar langsung
///   berwarna putih tanpa kotak latar agar menyatu mulus dengan gradient.
/// - Ketika `inverse == false` (untuk permukaan terang seperti bar atas
///   Onboarding dan kartu About NetLearn), ikon "N" putih ditampilkan di dalam
///   tile ungu bersudut membulat yang serasi dengan `assets/logo/Logo_Baru.png`.
class NlNetLearnLogo extends StatelessWidget {
  const NlNetLearnLogo({
    super.key,
    this.size = 40,
    this.inverse = false,
  });

  /// Ukuran kotak logo (mark selalu persegi).
  final double size;

  /// `true` merender mark putih langsung di atas latar gelap/ungu.
  /// `false` merender mark putih di dalam tile ungu untuk permukaan terang.
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'NetLearn',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _NetLearnMarkPainter(inverse: inverse),
      ),
    );
  }
}

class _NetLearnMarkPainter extends CustomPainter {
  const _NetLearnMarkPainter({required this.inverse});

  final bool inverse;

  /// Warna ungu latar logo dari `assets/logo/Logo_Baru.png` (`#7A2DEB`).
  static const Color _tileColor = Color(0xFF7A2DEB);

  // Koordinat vektor 1:1 dalam viewBox 40x40 dari kontur `Logo_Baru.png`.
  static const _leftMark = <Offset>[
    Offset(4.52, 1.72),
    Offset(8.75, 1.72),
    Offset(9.77, 1.79),
    Offset(10.59, 1.96),
    Offset(11.57, 2.28),
    Offset(12.16, 2.54),
    Offset(12.98, 3.04),
    Offset(14.2, 4.07),
    Offset(28.39, 17.7),
    Offset(28.54, 17.87),
    Offset(28.54, 24.36),
    Offset(31.31, 27.1),
    Offset(31.8, 27.0),
    Offset(32.3, 27.04),
    Offset(32.82, 27.27),
    Offset(33.18, 27.59),
    Offset(33.46, 28.1),
    Offset(33.53, 28.69),
    Offset(33.39, 29.25),
    Offset(33.08, 29.7),
    Offset(32.52, 30.07),
    Offset(31.87, 30.18),
    Offset(31.28, 30.04),
    Offset(30.74, 29.64),
    Offset(30.51, 29.31),
    Offset(30.38, 28.95),
    Offset(30.34, 28.49),
    Offset(30.43, 27.97),
    Offset(24.65, 22.33),
    Offset(24.61, 19.48),
    Offset(11.08, 6.51),
    Offset(10.26, 5.99),
    Offset(9.48, 5.73),
    Offset(8.16, 5.68),
    Offset(6.46, 5.73),
    Offset(5.77, 5.99),
    Offset(5.21, 6.46),
    Offset(4.78, 7.08),
    Offset(4.62, 7.54),
    Offset(4.55, 7.97),
    Offset(4.55, 30.59),
    Offset(4.62, 31.34),
    Offset(4.78, 31.93),
    Offset(5.14, 32.66),
    Offset(5.78, 33.41),
    Offset(6.56, 33.94),
    Offset(7.28, 34.21),
    Offset(7.87, 34.3),
    Offset(8.75, 34.31),
    Offset(9.57, 34.2),
    Offset(10.39, 33.87),
    Offset(10.79, 33.62),
    Offset(11.25, 33.21),
    Offset(11.68, 32.66),
    Offset(11.91, 32.23),
    Offset(12.1, 31.67),
    Offset(12.2, 31.08),
    Offset(12.23, 24.05),
    Offset(16.15, 27.84),
    Offset(16.11, 31.48),
    Offset(15.88, 32.69),
    Offset(15.55, 33.67),
    Offset(15.1, 34.56),
    Offset(14.47, 35.44),
    Offset(13.87, 36.13),
    Offset(13.15, 36.76),
    Offset(12.26, 37.32),
    Offset(11.18, 37.81),
    Offset(10.1, 38.11),
    Offset(9.05, 38.24),
    Offset(7.74, 38.24),
    Offset(6.56, 38.08),
    Offset(5.54, 37.78),
    Offset(4.66, 37.38),
    Offset(3.87, 36.89),
    Offset(2.92, 36.11),
    Offset(2.03, 35.08),
    Offset(1.37, 33.97),
    Offset(0.88, 32.66),
    Offset(0.61, 31.18),
    Offset(0.57, 5.7),
  ];

  static const _rightMark = <Offset>[
    Offset(31.38, 1.73),
    Offset(32.89, 1.76),
    Offset(34.36, 2.09),
    Offset(35.61, 2.64),
    Offset(36.75, 3.43),
    Offset(37.71, 4.39),
    Offset(38.56, 5.7),
    Offset(39.09, 7.05),
    Offset(39.35, 8.39),
    Offset(39.39, 34.03),
    Offset(35.18, 38.27),
    Offset(32.07, 38.27),
    Offset(31.15, 38.2),
    Offset(30.39, 38.08),
    Offset(29.51, 37.82),
    Offset(28.72, 37.48),
    Offset(27.9, 36.99),
    Offset(27.18, 36.44),
    Offset(12.22, 22.1),
    Offset(12.21, 15.8),
    Offset(9.18, 12.85),
    Offset(8.79, 12.94),
    Offset(8.26, 12.93),
    Offset(7.9, 12.83),
    Offset(7.57, 12.63),
    Offset(7.15, 12.13),
    Offset(6.97, 11.61),
    Offset(6.97, 11.15),
    Offset(7.11, 10.69),
    Offset(7.41, 10.26),
    Offset(7.77, 9.99),
    Offset(8.2, 9.83),
    Offset(8.72, 9.8),
    Offset(9.11, 9.89),
    Offset(9.57, 10.16),
    Offset(9.88, 10.49),
    Offset(10.11, 11.02),
    Offset(10.14, 11.44),
    Offset(10.08, 12.0),
    Offset(16.15, 17.87),
    Offset(16.16, 20.44),
    Offset(29.8, 33.55),
    Offset(30.62, 34.04),
    Offset(31.44, 34.27),
    Offset(32.3, 34.3),
    Offset(33.25, 34.08),
    Offset(34.07, 33.61),
    Offset(34.7, 32.98),
    Offset(35.19, 32.13),
    Offset(35.39, 31.28),
    Offset(35.41, 9.18),
    Offset(35.35, 8.49),
    Offset(35.19, 7.87),
    Offset(34.77, 7.08),
    Offset(34.13, 6.42),
    Offset(33.31, 5.93),
    Offset(32.49, 5.7),
    Offset(31.54, 5.7),
    Offset(30.69, 5.93),
    Offset(29.9, 6.38),
    Offset(29.3, 6.95),
    Offset(29.04, 7.34),
    Offset(28.74, 8.0),
    Offset(28.55, 8.98),
    Offset(28.52, 15.87),
    Offset(24.6, 12.03),
    Offset(24.61, 8.89),
    Offset(24.71, 7.8),
    Offset(25.11, 6.39),
    Offset(25.69, 5.21),
    Offset(26.29, 4.39),
    Offset(26.75, 3.88),
    Offset(27.44, 3.27),
    Offset(28.26, 2.71),
    Offset(29.64, 2.09),
    Offset(30.52, 1.86),
  ];

  static Path _buildPolygon(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 40, size.height / 40);

    if (!inverse) {
      final tilePaint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..color = _tileColor;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0.5, 0.5, 39, 39),
          const Radius.circular(11),
        ),
        tilePaint,
      );

      // Pusatkan mark putih di dalam tile ungu dengan margin yang proporsional.
      canvas.translate(20, 20);
      canvas.scale(0.68);
      canvas.translate(-20, -20);
    }

    final markPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = NetLearnColors.white;

    canvas.drawPath(_buildPolygon(_leftMark), markPaint);
    canvas.drawPath(_buildPolygon(_rightMark), markPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_NetLearnMarkPainter oldDelegate) {
    return oldDelegate.inverse != inverse;
  }
}
