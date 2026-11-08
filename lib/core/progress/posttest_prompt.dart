import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/models/learning_flow_status_model.dart';
import 'progress_refresh.dart';

/// Offers the post-test once, at the moment finishing the last module unlocks
/// it.
///
/// Both `mark_video_completed` and `mark_reading_completed` return nothing, so
/// the transition cannot be read from the mutation itself. Callers pass the
/// flow snapshot they already had and the refreshed one, and the prompt only
/// appears on the locked-to-unlocked edge. That keeps it from reappearing
/// every time the student revisits a finished module.
Future<void> maybePromptPosttest(
  BuildContext context,
  WidgetRef ref, {
  required bool wasUnlocked,
  required LearningFlowStatusModel flow,
}) async {
  if (wasUnlocked || !flow.posttestUnlocked || flow.posttestCompleted) {
    return;
  }

  if (!context.mounted) {
    return;
  }

  final l10n = AppLocalizations.of(context);

  if (l10n == null) {
    return;
  }

  final shouldStart = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.posttestUnlockedTitle),
        content: Text(l10n.posttestUnlockedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.startPosttest),
          ),
        ],
      );
    },
  );

  if (shouldStart != true || !context.mounted) {
    return;
  }

  // The prompt is shown after the providers were already refreshed, but
  // invalidating again keeps the assessment list honest about which assessment
  // is now the open one.
  invalidateStudentProgress(ref);

  context.push('/student/assessment/posttest');
}
