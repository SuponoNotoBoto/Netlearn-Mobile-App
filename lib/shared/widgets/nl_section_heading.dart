import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// `.section-heading` dari index.css.
///
/// ```css
/// .section-heading{display:flex;align-items:center;justify-content:space-between;
///                   gap:8px;margin-bottom:13px}
/// .section-heading h2{font-size:16px;letter-spacing:-.4px}
/// .section-heading>button,.link{color:#543cd1;font-size:10px;font-weight:600;
///                   display:flex;align-items:center;gap:5px}
/// ```
///
/// Judul memakai [context.sectionHeadingStyle] dan aksi memakai
/// [context.linkSmallStyle], jadi ukuran dan warnanya mengikuti tema.
/// Lebar widget mengikuti parent: padding horizontal halaman tetap milik
/// `Column` induk, bukan milik heading ini.
class NlSectionHeading extends StatelessWidget {
  final String title;

  /// Teks aksi di kanan, mis. "Lihat semua". Null kalau section ini tidak punya
  /// aksi.
  final String? actionLabel;

  /// Dipanggil saat aksi ditekan. [actionLabel] tanpa [onAction] tidak dirender.
  final VoidCallback? onAction;

  /// Ikon kecil di kiri judul (`.small-icon` = `#9d92cb`).
  final IconData? leadingIcon;

  /// Panah kecil di kanan aksi (`.link` = `gap:5px`).
  final IconData actionIcon;

  const NlSectionHeading({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.leadingIcon,
    this.actionIcon = Icons.chevron_right_rounded,
  });

  bool get _hasAction => actionLabel != null && onAction != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    // `.small-icon` tidak punya pasangan dark di index.css, jadi label kecil
    // ikut teks sekunder tema.
    final iconColor = isDark ? context.mutedText : NetLearnColors.sectionIcon;

    final action = _hasAction
        ? TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: context.accent,
              padding: const EdgeInsets.symmetric(horizontal: NetLearnSpace.s4),
              minimumSize: const Size(0, 32),
              textStyle: context.linkSmallStyle,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    actionLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: NetLearnSpace.s4),

                Icon(actionIcon, size: 14),
              ],
            ),
          )
        : null;

    return Padding(
      // `margin-bottom:13px`
      padding: const EdgeInsets.only(bottom: NetLearnSpace.s13),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 15, color: iconColor),

            const SizedBox(width: NetLearnSpace.s8),
          ],

          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.sectionHeadingStyle,
            ),
          ),

          if (action != null) ...[
            const SizedBox(width: NetLearnSpace.s8),

            Flexible(child: action),
          ],
        ],
      ),
    );
  }
}
