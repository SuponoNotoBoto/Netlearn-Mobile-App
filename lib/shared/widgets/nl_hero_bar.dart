import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// `.hero` dari index.css: header gradasi ungu di atas halaman.
///
/// ```css
/// .hero{height:167px;background:linear-gradient(115deg,#1e126b,#4e33c8);
///       border-radius:0 0 24px 24px;color:white;padding:14px 24px 32px;
///       position:relative;overflow:hidden}
/// .hero-top{display:flex;align-items:center;justify-content:space-between}
/// .greeting{margin-top:20px;display:flex;justify-content:space-between;
///           align-items:center}
/// .greeting p{font-size:8px;letter-spacing:1.5px;font-weight:600;color:#c9c1ee;
///           margin-bottom:4px}
/// .greeting h1{font-size:25px;letter-spacing:-.8px;font-weight:800;margin-bottom:5px}
/// .greeting>div>span{font-size:11px;color:#d4cdf2}
/// .avatar{width:49px;height:49px;background:#e6dcff;color:#6040ad;
///       border:3px solid #ffffff45;border-radius:50%;font-family:'Plus Jakarta Sans';
///       font-weight:800;font-size:23px;display:grid;place-items:center;position:relative}
/// ```
///
/// Tinggi desain 167px, tapi angka itu tidak bisa dipakai apa adanya: pada
/// lebar 360dp dengan text scale 1.3 nama yang panjang membuat baris greeting
/// lebih dari satu baris. Karena itu [height] hanya dipakai sebagai tinggi
/// minimum lewat `constraints`, danColumn memakai [Flexible] supaya isinya boleh
/// tumbuh alih-alih terpotong.
///
/// Warna teks di dalam gradien sengaja tidak membaca tema: permukaannya selalu
/// gradient, jadi mode gelap tidak mengubah apa pun di sini.
class NlHeroBar extends StatelessWidget {
  /// Baris paling atas, mis. nama brand atau judul halaman.
  final Widget? leading;

  /// Kontrol di kanan baris paling atas, mis. lonceng notifikasi.
  final Widget? actions;

  /// Label kecil di atas nama (`.greeting p`), mis. nama hari.
  final String? eyebrow;

  /// Nama pengguna (`.greeting h1`).
  final String title;

  /// Baris pendukung (`.greeting>div>span`).
  final String? subtitle;

  /// Inisial untuk avatar. Null menyembunyikan avatar.
  final String? initial;

  /// Indikator aktif di pojok kanan bawah avatar (`.avatar>span`).
  final bool showOnlineDot;

  final VoidCallback? onAvatarTap;

  /// `height:167px` dipakai sebagai tinggi minimum.
  final double height;

  final EdgeInsetsGeometry padding;

  const NlHeroBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.eyebrow,
    this.subtitle,
    this.initial,
    this.showOnlineDot = true,
    this.onAvatarTap,
    this.height = 167,
    this.padding = const EdgeInsets.fromLTRB(
      NetLearnSpace.s24,
      NetLearnSpace.s14,
      NetLearnSpace.s24,
      NetLearnSpace.s32,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // `width:100%` dan gradien penuh, bukan setengah kolom.
      width: double.infinity,
      constraints: BoxConstraints(minHeight: height),
      decoration: BoxDecoration(
        gradient: NetLearnGradients.hero,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // `.hero-top`
          Row(
            children: [
              Expanded(child: leading ?? const SizedBox.shrink()),

              if (leading != null && actions != null)
                const SizedBox(width: NetLearnSpace.s10),

              ?actions,
            ],
          ),

          // `.greeting` = `margin-top:20px`
          const SizedBox(height: NetLearnSpace.s20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (eyebrow != null) ...[
                      Flexible(
                        child: Text(
                          eyebrow!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          // `p` = 8px / letter-spacing 1.5px / `#c9c1ee`
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: NetLearnColors.heroSurfaceLabel,
                          ),
                        ),
                      ),

                      // `margin-bottom:4px`
                      const SizedBox(height: NetLearnSpace.s4),
                    ],

                    Flexible(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        // `h1` = 25px / weight 800 / letter-spacing -.8px
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: NetLearnColors.white,
                        ),
                      ),
                    ),

                    if (subtitle != null) ...[
                      // `margin-bottom:5px`
                      const SizedBox(height: NetLearnSpace.s5),

                      Flexible(
                        child: Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          // `span` = 11px / `#d4cdf2`
                          style: TextStyle(
                            fontSize: 11,
                            color: NetLearnColors.heroSurfaceBody,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (initial != null) ...[
                const SizedBox(width: NetLearnSpace.s12),

                _HeroAvatar(
                  initial: initial!,
                  showOnlineDot: showOnlineDot,
                  onTap: onAvatarTap,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  final String initial;
  final bool showOnlineDot;
  final VoidCallback? onTap;

  const _HeroAvatar({
    required this.initial,
    required this.showOnlineDot,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: 49,
      height: 49,
      decoration: BoxDecoration(
        color: NetLearnColors.heroAvatarBg,
        shape: BoxShape.circle,
        border: Border.all(
          color: NetLearnColors.white.withValues(alpha: 0.27),
          width: 3,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: const TextStyle(
          fontFamily: AppTheme.displayFontFamily,
          fontWeight: FontWeight.w800,
          // `font-size:23px`
          fontSize: 23,
          color: NetLearnColors.heroAvatarFg,
        ),
      ),
    );

    final withDot = Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,

        if (showOnlineDot)
          // `.avatar>span` = 10px / border 2px `#4230b4`
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: NetLearnColors.heroOnlineDot,
                shape: BoxShape.circle,
                border: Border.all(
                  color: NetLearnColors.heroOnlineDotRing,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );

    if (onTap == null) {
      return withDot;
    }

    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: withDot),
      ),
    );
  }
}
