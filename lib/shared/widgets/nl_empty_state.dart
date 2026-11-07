import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Placeholder for a section that has nothing to show.
///
/// The optional action is what separates "there is nothing here" from "there is
/// nothing here *and* here is the button that fixes it", which is the
/// difference between a dead end and an invitation on a management screen.
class NlEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const NlEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasAction = actionLabel != null && onAction != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: NetLearnSpace.s20,
        vertical: NetLearnSpace.s32,
      ),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            // `.circle` — bulat penuh dengan latar ungu muda.
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.accentTint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: context.accent,
              size: 26,
            ),
          ),

          const SizedBox(height: NetLearnSpace.s12),

          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),

          if (message != null) ...[
            const SizedBox(height: 5),

            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.mutedText,
                height: 1.4,
              ),
            ),
          ],

          if (hasAction) ...[
            const SizedBox(height: NetLearnSpace.s16),

            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}