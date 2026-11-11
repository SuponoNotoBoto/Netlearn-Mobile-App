import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'nl_tap_scale.dart';

/// Satu tile pada `.shortcut-grid` Figma.
///
/// Lingkaran ikon 40px di atas, judul, subjudul, lalu chevron kecil di pojok
/// kanan bawah. Tinggi minimum 119px — bukan tinggi tetap — supaya pada text
/// scale 1,3x tile boleh tumbuh alih-alih memotong label: `.learning-space-grid`
/// di desain juga memakai `min-height:119px;height:auto`.
///
/// [onTap] `null` adalah keadaan nonaktif. Tab yang belum rilis tetap harus
/// tampil di grid supaya pengguna tahu ia akan datang, tetapi tidak boleh
/// terlihat bisa ditekan: ink yang tidak dijalankan saja masih menyisakan
/// chevron yang menjanjikan tujuan, jadi tile ini juga diredupkan dan
/// chevronnya dibuang.
class NlShortcutTile extends StatelessWidget {
  final IconData icon;

  /// Warna lingkaran. Ambil dari [NetLearnAccents.grid] agar urutannya sama
  /// dengan desain.
  final Color accentColor;

  final String title;
  final String subtitle;

  /// Jumlah baris maksimum judul. Default 1 (perilaku lama, `nowrap`); desain
  /// "Your learning space" membiarkan judul panjang seperti "Assessment History"
  /// membungkus ke dua baris di dalam sel 110px, jadi dashboard mahasiswa
  /// mengirim 2.
  final int maxTitleLines;

  /// `null` menonaktifkan tile: tanpa navigasi dan tanpa umpan balik tekan.
  final VoidCallback? onTap;

  const NlShortcutTile({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.maxTitleLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // `onTap == null` sudah membuat InkWell berhenti merespons, jadi satu tile
    // yang identik dengan yang aktif tetap terbaca sebagai tersedia.
    final enabled = onTap != null;

    final tile = Material(
      color: context.surface,
      borderRadius: BorderRadius.circular(NetLearnRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        child: Container(
          constraints: const BoxConstraints(minHeight: 119),
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NetLearnRadius.card),
            border: Border.all(color: context.border),
            boxShadow: theme.brightness == Brightness.dark
                ? null
                : NetLearnShadows.softSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // `.circle` — 40px bulat, ikon putih di atas warna aksen.
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: NetLearnColors.white,
                  size: 20,
                ),
              ),

              const SizedBox(height: 9),

              // maxLines 1 + ellipsis, bukan wrap: desain memakai
              // `white-space:nowrap` supaya tinggi tile tidak bergantung pada
              // isi label.
              Text(
                title,
                maxLines: maxTitleLines,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  letterSpacing: -0.15,
                  color: context.mutedText,
                ),
              ),

              const Spacer(),

              // `.shortcut-arrow` — chevron pucat absolute di pojok kanan
              // bawah. Chevron menjanjikan tujuan, jadi hanya digambar saat
              // tile benar-benar bisa pergi ke suatu tempat.
              if (enabled)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: context.mutedText.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (enabled) {
      return NlTapScale(
        scaleDown: 0.955,
        child: tile,
      );
    }

    return Opacity(opacity: 0.55, child: tile);
  }
}