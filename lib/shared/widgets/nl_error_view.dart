import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Centered error state with an optional retry button.
///
/// Shared by the student and lecturer profile pages so a failed profile read
/// looks the same on both sides instead of each role inventing its own icon
/// colour and retry placement.
class NlErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const NlErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NetLearnSpace.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 46,
              color: NetLearnColors.danger,
            ),

            const SizedBox(height: NetLearnSpace.s12),

            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            if (onRetry != null) ...[
              const SizedBox(height: NetLearnSpace.s16),

              OutlinedButton(
                onPressed: onRetry,
                child: Text(l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}