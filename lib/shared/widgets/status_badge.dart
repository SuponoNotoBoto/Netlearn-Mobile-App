import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum NetLearnStatus {
  linked,
  active,
  down,
}

/// StatusBadge: badge status dengan ikon + teks + warna latar dan foreground.
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
    late final Color color;
    late final Color background;
    late final IconData icon;

    switch (status) {
      case NetLearnStatus.linked:
        color = NetLearnColors.success;
        background = const Color(0xFFE8F6EF);
        icon = Icons.check_circle;
        break;
      case NetLearnStatus.active:
        color = NetLearnColors.primary;
        background = NetLearnColors.primaryTint;
        icon = Icons.circle;
        break;
      case NetLearnStatus.down:
        color = NetLearnColors.danger;
        background = const Color(0xFFFDF0F0);
        icon = Icons.lock;
        break;
    }

    return Container(
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
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

