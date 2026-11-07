import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// `.tabs` dari index.css: segmented control untuk pilihan yang sedikit.
///
/// ```css
/// .tabs{display:flex;gap:4px;border-radius:11px;padding:4px;background:#eaeaf3}
/// .tabs button{flex:1;font-size:11px;padding:10px 6px;border-radius:8px;color:#6c727f}
/// .tabs .selected{background:white;color:#543cd1;box-shadow:0 2px 5px #2920520b;
///                 font-weight:700}
/// ```
///
/// Yang paling sering hilang di implementasi lama adalah `font-weight:700` pada
/// segmen terpilih: tanpa itu, terpilih hanya dibedakan dari latar putih dan teks
/// ungu, dan dua pembeda itu sendiri sudah hilang di tema gelap. Widget ini
/// memaksakan pen tebal pada segmen terpilih.
///
/// Versi `.unified-language` di index.css memakai bentuk yang sama dengan
/// radius `8px` dan label `9px`; itu lewat [compact], bukan kelas terpisah.
class NlSegmentedTabs extends StatelessWidget {
  final List<String> labels;

  final int selectedIndex;

  final ValueChanged<int>? onChanged;

  /// `font-size:11px` + `padding:10px 6px` untuk `.tabs`.
  final bool compact;

  /// Nama kontrol untuk pembaca layar, mis. "Role".
  final String? semanticLabel;

  const NlSegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    this.onChanged,
    this.compact = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    // not verified: `.dark-theme .tabs` memakai pasangan `#1d2030` / `#262936`
    // yang sudah ada, jadi hanya diambil lewat token dark yang sama.
    final trackColor = isDark
        ? NetLearnColors.darkRaised
        : NetLearnColors.tabsBg;

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        // `padding:4px` + `gap:4px` + `border-radius:11px`
        padding: const EdgeInsets.all(NetLearnSpace.s4),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(NetLearnRadius.moduleNumber),
        ),
        child: Row(
          children: [
            for (var index = 0; index < labels.length; index++) ...[
              if (index > 0) const SizedBox(width: NetLearnSpace.s4),

              Expanded(
                child: _Segment(
                  label: labels[index],
                  selected: index == selectedIndex,
                  compact: compact,
                  onTap: onChanged == null ? null : () => onChanged!(index),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.compact,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    // `.selected` = `background:#fff`. Di mode gelap `index.css` memakai
    // `#34304e` dengan teks `#d0c2ff`.
    final Color selectedBackground;
    final Color selectedForeground;

    if (isDark) {
      selectedBackground = NetLearnColors.tabsSelectedDark;
      selectedForeground = NetLearnColors.primaryDarkSoft;
    } else {
      selectedBackground = NetLearnColors.white;
      selectedForeground = NetLearnColors.primary;
    }

    final background = selected ? selectedBackground : Colors.transparent;

    final foreground = selected ? selectedForeground : context.mutedText;

    final child = Container(
      // `padding:10px 6px` untuk `.tabs`; versi language memakai `6px 5px`.
      padding: EdgeInsets.symmetric(
        vertical: compact ? NetLearnSpace.s6 : NetLearnSpace.s10,
        horizontal: compact ? NetLearnSpace.s5 : NetLearnSpace.s6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(NetLearnRadius.sm),
        // `.tabs .selected` = `0 2px 5px #2920520b`
        boxShadow: selected ? NetLearnShadows.tabsSelected : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: compact ? 9 : 11,
          // `font-weight:700` hanya pada segmen terpilih.
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          color: foreground,
        ),
      ),
    );

    if (onTap == null) {
      return child;
    }

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(NetLearnRadius.sm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NetLearnRadius.sm),
          child: child,
        ),
      ),
    );
  }
}
