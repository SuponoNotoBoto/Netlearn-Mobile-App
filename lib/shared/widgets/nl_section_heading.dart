import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Section heading sesuai spesifikasi index.css NetLearn 2.0:
/// Row dengan title (16px weight 800), optional leading icon, dan optional action button.
class NlSectionHeading extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? leadingIcon;
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: 18,
                color: NetLearnColors.sectionIcon,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: NetLearnColors.neutral900,
              ),
            ),
          ],
        ),
        if (_hasAction)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: context.accent,
              padding: const EdgeInsets.symmetric(horizontal: NetLearnSpace.s4),
              minimumSize: const Size(0, 32),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: NetLearnColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(actionIcon, size: 16),
              ],
            ),
          ),
      ],
    );
  }
}

