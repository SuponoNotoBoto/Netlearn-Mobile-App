import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'nl_tap_scale.dart';

/// A tappable row that leads to one section of a dashboard.
///
/// The badge circle is optional: sections that are the primary destination of a
/// dashboard get it, secondary ones do not, which is the only difference
/// between what the admin dashboard previously called two separate widgets.
class NlMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final IconData? badgeIcon;

  const NlMenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.badgeIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NlTapScale(
      scaleDown: 0.975,
      child: Material(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NetLearnRadius.card),
          child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(NetLearnSpace.s16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NetLearnRadius.card),
            border: Border.all(color: context.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 62,
                height: 58,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: context.accentTint,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        icon,
                        color: context.accent,
                        size: 26,
                      ),
                    ),

                    if (badgeIcon != null)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            color: context.accent,
                            shape: BoxShape.circle,
                            // Matches the bar behind it so the ring reads as a
                            // gap rather than as a second colour.
                            border: Border.all(
                              color: context.surface,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            badgeIcon,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary,
                            size: 15,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.mutedText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // `.shortcut-arrow` — chevron pucat di kanan.
              Icon(
                Icons.chevron_right,
                size: 18,
                color: context.mutedText,
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}