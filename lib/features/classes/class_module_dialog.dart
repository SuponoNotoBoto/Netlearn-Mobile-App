import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import 'class_action_messages.dart';
import 'class_controller.dart';
import 'class_models.dart';

/// Opens a dialog to create or edit a module in [classId].
///
/// Returns `true` when the module mutation succeeds.
Future<bool> showClassModuleDialog(
  BuildContext context,
  WidgetRef ref, {
  required String classId,
  ClassModule? editing,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final titleIdCtrl =
      TextEditingController(text: editing?.titleId ?? editing?.title ?? '');
  final titleEnCtrl = TextEditingController(text: editing?.titleEn ?? '');
  final descIdCtrl = TextEditingController(
    text: editing?.descriptionId ?? editing?.description ?? '',
  );
  final descEnCtrl =
      TextEditingController(text: editing?.descriptionEn ?? '');

  try {
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          editing == null
              ? l10n.classAddModuleAction
              : l10n.classEditModuleAction,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('module_dialog_title_id'),
                controller: titleIdCtrl,
                decoration: InputDecoration(
                  labelText: l10n.classModuleTitleIdLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.s10),
              TextField(
                key: const Key('module_dialog_title_en'),
                controller: titleEnCtrl,
                decoration: InputDecoration(
                  labelText: l10n.classModuleTitleEnLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.s10),
              TextField(
                key: const Key('module_dialog_desc_id'),
                controller: descIdCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.classModuleDescIdLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.s10),
              TextField(
                key: const Key('module_dialog_desc_en'),
                controller: descEnCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.classModuleDescEnLabel,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('module_dialog_save_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (saved == true && context.mounted) {
      return await runClassAction(
        context,
        () async {
          if (editing == null) {
            await createClassModuleAction(
              ref,
              classId: classId,
              titleId: titleIdCtrl.text,
              titleEn: titleEnCtrl.text,
              descriptionId: descIdCtrl.text,
              descriptionEn: descEnCtrl.text,
            );
          } else {
            await updateClassModuleAction(
              ref,
              classId: classId,
              moduleId: editing.id,
              titleId: titleIdCtrl.text,
              titleEn: titleEnCtrl.text,
              descriptionId: descIdCtrl.text,
              descriptionEn: descEnCtrl.text,
            );
          }
        },
        successMessage: l10n.classUpdatedSuccess,
      );
    }

    return false;
  } finally {
    titleIdCtrl.dispose();
    titleEnCtrl.dispose();
    descIdCtrl.dispose();
    descEnCtrl.dispose();
  }
}
