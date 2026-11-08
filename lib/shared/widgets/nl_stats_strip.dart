import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// `.unified-stats` dari index.css: strip tiga metrik di bawah header profil.
///
/// ```css
/// .unified-stats{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));
///                 background:#fff;border:1px solid #eceef2;
///                 border-radius:16px;padding:19px 5px}
/// .unified-stats>div{text-align:center;border-right:1px solid #eceef2;padding:0 4px}
/// .unified-stats>div:last-child{border:0}
/// .unified-stats b{display:block;color:#543cd1;font-family:'Plus Jakarta Sans';
///                 font-size:23px;font-weight:800;letter-spacing:-.8px;line-height:1.4}
/// .unified-stats span{display:block;color:#6c727f;font-size:10px;line-height:1.5;
///                 margin-top:6px}
/// ```
///
/// Garis pemisah digambar di dalam tiap sel dan sel terakhir tidak
/// memperlakukannya secara khusus, jadi jumlah kolom bebas tanpa ada item yang
/// mendapat garis di tempat yang salah. Warna nilai mengikuti [context.accent]
/// sehingga mode gelap memakai `primaryDark` (`#b9a3ff`) seperti
/// `.dark-theme .unified-stats b`.
class NlStatsStrip extends StatelessWidget {
  final List<NlStatsStripItem> items;

  const NlStatsStrip({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        border: Border.all(color: context.border),
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
      ),
      // `padding:19px 5px`
      padding: const EdgeInsets.symmetric(
        vertical: NetLearnSpace.s19,
        horizontal: NetLearnSpace.s5,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < items.length; index++)
            Expanded(
              child: _Stat(
                item: items[index],
                showDivider: index != items.length - 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final NlStatsStripItem item;
  final bool showDivider;

  const _Stat({required this.item, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final cell = Container(
      // `>div` = `padding:0 4px`. Reduced to 2px for tighter fit at 360dp + 1.3x.
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(right: BorderSide(color: context.border))
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            // `.unified-stats b`
            style: NetLearnDisplay.stat.copyWith(color: context.accent),
          ),

          // `span` = `margin-top:6px`
          const SizedBox(height: NetLearnSpace.s6),

          // Label needs to fit in narrow cells (2 or 3 per row) at 360dp + 1.3x scale.
          // Use Flexible with loose fit so it sizes to content but wraps/overflows gracefully.
          Flexible(
            child: Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              // `span` = 10px / line-height 1.5. At 1.3x scale and 360dp,
              // "Rata-rata Nilai" (14 chars) needs smaller size to fit in cell.
              style: context.labelCaptionStyle?.copyWith(
                color: context.mutedText,
                fontSize: 9,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: item.semanticLabel ?? '${item.value} ${item.label}',
      excludeSemantics: true,
      child: cell,
    );
  }
}

/// Satu pasangan nilai dan label pada [NlStatsStrip].
///
/// [semanticLabel] menggantikan pembacaan "nilai lalu label" menjadi satu
/// pengumuman, mis. "Nilai rata-rata 88".
class NlStatsStripItem {
  final String value;
  final String label;
  final String? semanticLabel;

  const NlStatsStripItem({
    required this.value,
    required this.label,
    this.semanticLabel,
  });

  @override
  String toString() => 'NlStatsStripItem($label: $value)';
}
