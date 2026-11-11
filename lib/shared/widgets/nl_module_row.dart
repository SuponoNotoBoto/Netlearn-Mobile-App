import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'nl_tap_scale.dart';

/// `.module-row` dari index.css: satu baris modul yang bisa disentuh.
///
/// ```css
/// .module-row{background:#fff;border:1px solid #eceef2;border-radius:16px;
///             display:flex;align-items:center;padding:12px;gap:11px;width:100%;
///             text-align:left;min-height:68px}
/// .module-number{width:39px;height:39px;display:grid;place-items:center;
///             background:#f3e8ff;color:#885bc8;border-radius:11px;
///             flex-shrink:0;font-weight:700}
/// .muted-number{background:#f1f2f7;color:#a4a7b4}
/// .module-row>div{flex:1;min-width:0}
/// .module-row small{display:block;color:#8d91a0;font-size:8px;letter-spacing:.6px;
///             margin-bottom:4px}
/// .module-row strong{font-size:11px;font-weight:600;display:block;letter-spacing:-.2px}
/// ```
///
/// Dua versi private dari baris ini ada di repository -- satu di dashboard
/// mahasiswa dan satu di daftar materi -- masing-masing dengan ukuran berbeda.
/// Widget ini menggabungkannya: nomor modul selalu 39px dengan radius 11px, dan
/// [locked] beralih ke pasangan `.muted-number` beserta warna gelapnya.
///
/// [trailing] dipakai untuk menyisipkan [StatusBadge] yang sudah ada, bukan
/// untuk membuat badge kedua di dalam widget ini.
class NlModuleRow extends StatelessWidget {
  /// Angka modul, atau teks singkat untuk baris yang bukan modul.
  final String number;

  /// Label kecil di atas judul (`.module-row small`), mis. "MODULE 01".
  final String? eyebrow;

  /// Judul baris (`.module-row strong`).
  final String title;

  /// Baris kedua di bawah judul, mis. jumlah materi atau durasi.
  final String? subtitle;

  /// Modul terkunci: nomor memakai `.muted-number`. Statusnya sendiri tetap
  /// diserahkan ke [trailing] supaya warna tidak menjadi satu-satunya pembeda.
  final bool locked;

  final VoidCallback? onTap;

  /// Status di kanan baris, biasanya [StatusBadge].
  final Widget? trailing;

  /// `39px`.
  final double numberSize;

  const NlModuleRow({
    super.key,
    required this.number,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.locked = false,
    this.onTap,
    this.trailing,
    this.numberSize = 39,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    // `.module-number` dan `.muted-number` punya pasangan gelap di index.css,
    // jadi warnanya diambil dari sana, bukan dari token perkiraan.
    final Color numberBackground;
    final Color numberForeground;

    if (locked) {
      numberBackground = isDark
          ? NetLearnColors.darkMutedNumberBg
          : NetLearnColors.mutedNumberBg;
      numberForeground = isDark
          ? NetLearnColors.darkMutedNumberFg
          : NetLearnColors.mutedNumberFg;
    } else {
      numberBackground = isDark
          ? NetLearnColors.darkModuleNumberBg
          : NetLearnColors.moduleNumberBg;
      numberForeground = isDark
          ? NetLearnColors.darkModuleNumberFg
          : NetLearnColors.moduleNumberFg;
    }

    final body = Container(
      // `padding:12px` + `min-height:68px`
      padding: const EdgeInsets.all(NetLearnSpace.s12),
      constraints: const BoxConstraints(minHeight: 68),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border.all(color: context.border),
        boxShadow: isDark ? null : NetLearnShadows.softSm,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: numberSize,
            height: numberSize,
            decoration: BoxDecoration(
              color: numberBackground,
              borderRadius: BorderRadius.circular(NetLearnRadius.moduleNumber),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTheme.displayFontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: numberForeground,
              ),
            ),
          ),

          // `gap:11px`
          const SizedBox(width: NetLearnSpace.s11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    // `small` = 8px / letter-spacing .6px / `#8d91a0`
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 0.6,
                      color: isDark
                          ? context.mutedText
                          : NetLearnColors.moduleRowEyebrow,
                    ),
                  ),

                  // `margin-bottom:4px`
                  const SizedBox(height: NetLearnSpace.s4),
                ],

                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  // `strong` = 11px / weight 600 / letter-spacing -.2px
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: context.onSurface,
                  ),
                ),

                if (subtitle != null) ...[
                  const SizedBox(height: NetLearnSpace.s4),

                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.labelCaptionStyle?.copyWith(
                      color: context.mutedText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (trailing != null) ...[
            const SizedBox(width: NetLearnSpace.s8),

            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) {
      return body;
    }

    return NlTapScale(
      scaleDown: 0.98,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NetLearnRadius.card),
          child: body,
        ),
      ),
    );
  }
}
