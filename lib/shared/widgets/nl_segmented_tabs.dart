import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Segmented tabs sesuai NetLearn 2.0:
/// Track warna #EAEAF3 dengan border radius 11px dan padding 4px.
/// Segmen terpilih memiliki latar putih, teks ungu #8C52FF, box shadow, dan font weight 700.
class NlSegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int>? onChanged;
  final bool compact;
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
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsets.all(NetLearnSpace.s4),
        decoration: BoxDecoration(
          color: NetLearnColors.tabsBg,
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
    final background = selected ? Colors.white : Colors.transparent;
    final foreground = selected ? NetLearnColors.primary : context.mutedText;

    final child = Container(
      padding: EdgeInsets.symmetric(
        vertical: compact ? NetLearnSpace.s6 : NetLearnSpace.s10,
        horizontal: compact ? NetLearnSpace.s5 : NetLearnSpace.s6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(NetLearnRadius.sm),
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

