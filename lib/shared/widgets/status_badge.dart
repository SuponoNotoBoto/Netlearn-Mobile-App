import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum NetLearnStatus {
  linked,
  active,
  down,
}

/// Badge status — selalu ikon + teks + warna.
///
/// Dipakai untuk status modul, kuis, dan koneksi/tracking AR.
class StatusBadge extends StatelessWidget {
  final NetLearnStatus status;
  final String label;

  const StatusBadge({
    super.key,
    required this.status,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusColors =
    theme.extension<NetLearnStatusColors>();

    late final Color color;
    late final Color background;
    late final IconData icon;

    switch (status) {
      case NetLearnStatus.linked:
        color = statusColors?.positiveText ?? scheme.primary;
        background =
            statusColors?.positiveBg ?? scheme.primary.withValues(alpha: 0.12);
        icon = Icons.check_circle;

      case NetLearnStatus.active:
        color = scheme.primary;
        background =
            statusColors?.neutralBg ?? scheme.primary.withValues(alpha: 0.12);
        icon = Icons.circle;

      case NetLearnStatus.down:
        color = statusColors?.dangerText ?? scheme.error;
        background =
            statusColors?.dangerBg ?? scheme.error.withValues(alpha: 0.12);
        icon = Icons.lock;
    }

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Container(
          // `.badge` — padding 5px 7px, radius 6px, teks 8px weight 600.
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(
              NetLearnRadius.badge,
            ),
          ),
child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: color,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
}