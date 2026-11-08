import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// `.overview-card` dari `design_figma/scr_figma_new/StudentProgress.tsx` & `index.css`:
/// kartu ringkasan progres putih (`#ffffff` di light mode, `#161820` di dark mode)
/// dengan border `#f1edfc`, radius `24px`, `.lavender-track` (`#A6B1E1` di atas `#E6E4F2`),
/// serta dukungan opsional `.pink-track` (`#FFB6C1` di atas `#FCE6EC`) untuk metrik kedua.
class NlProgressSummary extends StatelessWidget {
  /// Label di kiri, mis. "Learning Progress" / "Modul Pembelajaran".
  final String label;

  /// Persentase yang sudah diformat pemanggil, mis. `25`. Tanda persen
  /// ditambahkan widget ini lewat [showPercentSign].
  final String percentage;

  /// Judul baris bawah kiri. Null kalau panel hanya punya satu baris.
  final String? leadingCaption;

  /// Baris bawah kanan, mis. "1 dari 4 modul".
  final String? trailingCaption;

  /// `0.0` sampai `1.0`.
  final double progress;

  /// Label metrik kedua opsional (mis. "Assessment & Evaluasi").
  final String? secondaryLabel;

  /// Persentase metrik kedua opsional (mis. `50`).
  final String? secondaryPercentage;

  /// Nilai progres metrik kedua opsional (`0.0` sampai `1.0`).
  final double? secondaryProgress;

  /// Persentase 0 sampai 100 yang dipakai untuk semantics.
  final int? progressPercent;

  /// Semantics override untuk panel ini.
  final String? semanticLabel;

  final bool showPercentSign;

  const NlProgressSummary({
    super.key,
    required this.label,
    required this.percentage,
    required this.progress,
    this.leadingCaption,
    this.trailingCaption,
    this.secondaryLabel,
    this.secondaryPercentage,
    this.secondaryProgress,
    this.progressPercent,
    this.semanticLabel,
    this.showPercentSign = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleColor = isDark
        ? NetLearnColors.darkText
        : NetLearnColors.neutral900;

    final captionColor = isDark
        ? NetLearnColors.darkMuted
        : NetLearnColors.neutral500;

    final panel = Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: NetLearnSpace.md),
      decoration: BoxDecoration(
        color: isDark ? NetLearnColors.darkSurface : NetLearnColors.white,
        border: Border.all(
          color: isDark
              ? NetLearnColors.darkLine
              : const Color(0xFFF1EDFC),
        ),
        borderRadius: BorderRadius.circular(NetLearnRadius.radiusLg),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0D8C52FF),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
              ),
              const SizedBox(width: NetLearnSpace.s8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF202330)
                      : const Color(0xFFF5F2FE),
                  borderRadius: BorderRadius.circular(
                    NetLearnRadius.radiusPill,
                  ),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: percentage,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      if (showPercentSign)
                        TextSpan(
                          text: '%',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // `.overview-track.lavender-track` (`#E6E4F2` -> `#A6B1E1`)
          _ProgressTrack(
            progress: progress,
            trackColor: isDark
                ? const Color(0xFF252738)
                : const Color(0xFFE6E4F2),
            fillColor: NetLearnColors.lavender300,
          ),

          if (secondaryLabel != null && secondaryProgress != null) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    secondaryLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                ),
                const SizedBox(width: NetLearnSpace.s8),
                if (secondaryPercentage != null)
                  Text(
                    '$secondaryPercentage/100%',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // `.overview-track.pink-track` (`#FCE6EC` -> `#FFB6C1`)
            _ProgressTrack(
              progress: secondaryProgress!,
              trackColor: isDark
                  ? const Color(0xFF33222C)
                  : const Color(0xFFFCE6EC),
              fillColor: NetLearnColors.pink300,
            ),
          ],

          const SizedBox(height: 10),

          if (leadingCaption != null || trailingCaption != null)
            Row(
              children: [
                if (leadingCaption != null)
                  Expanded(
                    child: Text(
                      leadingCaption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: captionColor),
                    ),
                  ),
                if (leadingCaption != null && trailingCaption != null)
                  const SizedBox(width: NetLearnSpace.s8),
                if (trailingCaption != null)
                  Flexible(
                    child: Text(
                      trailingCaption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(fontSize: 11, color: captionColor),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );

    return Semantics(
      label: semanticLabel ?? '$label $percentage%',
      excludeSemantics: true,
      child: panel,
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  final double progress;
  final Color trackColor;
  final Color fillColor;

  const _ProgressTrack({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(NetLearnRadius.radiusPill),
      child: Container(
        height: 16,
        color: trackColor,
        width: double.infinity,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value,
            heightFactor: 1,
            child: Container(
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(NetLearnRadius.radiusPill),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
