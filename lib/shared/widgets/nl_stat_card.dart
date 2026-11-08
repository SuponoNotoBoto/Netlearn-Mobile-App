import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// One number in a dashboard summary row.
///
/// Split out of the admin dashboard so both dashboards can use it without
/// either feature owning the other. The admin copy of this widget was private
/// to its page and hardcoded a near-black icon colour, which disappeared on the
/// dark surface; this one reads every colour off the active theme.
class NlStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  /// Rendered under the label instead of the number row when the figure is not
  /// knowable yet, e.g. a student count that depends on classes existing.
  final String? hint;

  const NlStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(NetLearnSpace.s16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
        boxShadow: theme.brightness == Brightness.dark
            ? null
            : NetLearnShadows.softSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // `.circle` — 40px bulat, latar ungu muda, ikon ungu.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.accentTint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: context.accent,
              size: 20,
            ),
          ),

          const SizedBox(height: 14),

          // `.metrics b` — angka selalu ungu, bukan warna teks utama.
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.displayMedium?.copyWith(
              color: context.accent,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.mutedText,
            ),
          ),

          // A figure that cannot be computed should say so. Showing "0" for
          // "unknown" is how a dashboard ends up quietly lying.
          if (hint != null) ...[
            const SizedBox(height: NetLearnSpace.s4),

            Text(
              hint!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.accent,
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }
}