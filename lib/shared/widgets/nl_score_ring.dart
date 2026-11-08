import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// `.score` dari index.css: cincin skor 135px dengan tiga sisi terisi.
///
/// ```css
/// .score{width:135px;height:135px;border:8px solid #eae5f9;
///        border-top-color:#7656d3;border-right-color:#7656d3;
///        border-bottom-color:#7656d3;border-radius:50%;
///        margin:0 auto 16px;display:flex;align-items:center;
///        justify-content:center;flex-direction:column}
/// .score b{font-size:40px;font-weight:800;letter-spacing:-2px}
/// .score>span{font-size:11px;color:#9292a3}
/// ```
///
/// CSS hanya memberi warna pada tiga dari empat sisi, jadi cincin selalu dimulai
/// dari bagian atas dan berakhir di sebelum sisi kiri -- persis yang digambar
/// [_ScoreArcPainter]. Isian tengah memakai [NetLearnDisplay.score] dan
/// [NetLearnDisplay.scoreCaption].
///
/// Widget ini murni visual: tidak memanggil RPC dan tidak menyentuh progres.
class NlScoreRing extends StatelessWidget {
  /// Angka yang ditampilkan, mis. `88`.
  final int value;

  /// Nilai maksimum. Skor NetLearn selalu 100 lewat `quiz_attempts.score`.
  final int max;

  /// `135px` di desain.
  final double size;

  /// `border:8px solid`. Mengganti nilai ini mengubah rasio cincin.
  final double ringWidth;

  /// Label di bawah angka, mis. "dari 100".
  final String? caption;

  /// Warna track. Default memakai [NetLearnColors.scoreRingTrack], yang
  /// dialihkan ke [NetLearnColors.darkRaised] di mode gelap.
  final Color? trackColor;

  /// Warna arc terisi. Default memakai [NetLearnColors.scoreRingActive], yang
  /// dialihkan ke [NetLearnColors.primaryDark] di mode gelap.
  final Color? activeColor;

  /// Semantics override. Null memakai "Skor {value} dari {max}".
  final String? semanticLabel;

  const NlScoreRing({
    super.key,
    required this.value,
    this.max = 100,
    this.size = 135,
    this.ringWidth = 8,
    this.caption,
    this.trackColor,
    this.activeColor,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    // not verified: index.css tidak punya aturan `.dark-theme .score`, jadi kedua
    // warna diambil dari token gelap yang sudah ada.
    final track =
        trackColor ??
        (isDark ? NetLearnColors.darkRaised : NetLearnColors.scoreRingTrack);

    final active =
        activeColor ??
        (isDark ? NetLearnColors.primaryDark : NetLearnColors.scoreRingActive);

    final progress = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);

    final ring = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ScoreArcPainter(
          progress: progress,
          trackColor: track,
          activeColor: active,
          ringWidth: ringWidth,
        ),
        // `margin:0 auto 16px`
        child: Padding(
          padding: const EdgeInsets.only(top: NetLearnSpace.s16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Text(
                  '$value',
                  // `onSurface`, bukan `surface`: cincin ini berdiri di atas page
                  // background, bukan di atas kartu. `index.css` tidak memberi
                  // `.score b` warna apa pun sehingga ia mewarisi `body`
                  // (`#1a1d26`), dan memakai `surface` akan menghasilkan teks
                  // putih di atas `#f4f5fa` dengan rasio kontras 1.10:1.
                  style: NetLearnDisplay.score.copyWith(
                    color: context.onSurface,
                  ),
                ),
              ),

              if (caption != null)
                Text(
                  caption!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NetLearnDisplay.scoreCaption.copyWith(
                    color: context.mutedText,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      label: semanticLabel ?? 'Skor $value dari $max',
      excludeSemantics: true,
      child: Center(child: ring),
    );
  }
}

/// Menggambar track penuh lalu arc dari jam 12 sepanjang [progress].
///
/// Batas 270 derajat (tiga sisi CSS) bentuknya hardcoded, bukan parameter,
/// supaya widget ini tidak bisa dipakai untuk cincin penuh yang tidak ada di
/// desain.
class _ScoreArcPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color activeColor;
  final double ringWidth;

  /// CSS mewarnai `border-top`, `border-right`, dan `border-bottom`, tapi tidak
  /// `border-left`: total 270 derajat, dimulai dari atas dan berputar searah
  /// jarum jam.
  static const double _sweep = 3 * math.pi / 2;

  const _ScoreArcPainter({
    required this.progress,
    required this.trackColor,
    required this.activeColor,
    required this.ringWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = (math.min(size.width, size.height) - ringWidth) / 2;

    final bounds = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..color = trackColor;

    canvas.drawArc(bounds, -math.pi / 2, _sweep, false, track);

    if (progress <= 0) {
      return;
    }

    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.butt
      ..color = activeColor;

    canvas.drawArc(bounds, -math.pi / 2, _sweep * progress, false, active);
  }

  @override
  bool shouldRepaint(_ScoreArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.ringWidth != ringWidth;
  }
}
