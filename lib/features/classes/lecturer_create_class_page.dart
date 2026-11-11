import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_surface_card.dart';
import '../dashboard_lecturer/lecturer_bottom_navbar.dart';
import 'class_action_messages.dart';
import 'class_controller.dart';

typedef CreateClassSubmitCallback = Future<String> Function({
  required String name,
  String? description,
  String? semester,
  required bool useTemplate,
  required bool pretestEnabled,
  required bool posttestEnabled,
});

class LecturerCreateClassPage extends ConsumerStatefulWidget {
  const LecturerCreateClassPage({
    super.key,
    this.onSubmitOverride,
  });

  final CreateClassSubmitCallback? onSubmitOverride;

  @override
  ConsumerState<LecturerCreateClassPage> createState() =>
      _LecturerCreateClassPageState();
}

class _LecturerCreateClassPageState
    extends ConsumerState<LecturerCreateClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _semesterCtrl = TextEditingController();

  bool _useTemplate = true;
  bool _pretestEnabled = true;
  bool _posttestEnabled = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _semesterCtrl.dispose();
    super.dispose();
  }

  void _selectCreationMode(bool useTemplate) {
    if (_useTemplate == useTemplate) return;
    setState(() {
      _useTemplate = useTemplate;
      // PRD §2.2.6: Template defaults to ON/ON, Custom defaults to OFF/OFF.
      _pretestEnabled = useTemplate;
      _posttestEnabled = useTemplate;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      final submitFn = widget.onSubmitOverride ??
          ({
            required String name,
            String? description,
            String? semester,
            required bool useTemplate,
            required bool pretestEnabled,
            required bool posttestEnabled,
          }) async =>
              (await createClassAction(
                ref,
                name: name,
                description: description,
                semester: semester,
                useTemplate: useTemplate,
                pretestEnabled: pretestEnabled,
                posttestEnabled: posttestEnabled,
              ))
                  .classId;

      final classId = await submitFn(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        semester: _semesterCtrl.text.trim(),
        useTemplate: _useTemplate,
        pretestEnabled: _pretestEnabled,
        posttestEnabled: _posttestEnabled,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.classCreatedSuccess)),
      );
      if (!_useTemplate) {
        context.pushReplacement('/lecturer/classes/$classId?walkthrough=1');
      } else {
        context.pushReplacement('/lecturer/classes/$classId');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(classActionErrorMessage(context, e))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createClassTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NlSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.basicInformation,
                        style: AppTypography.cardTitle(context),
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      TextFormField(
                        key: const Key('create_class_name_field'),
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.classNameLabel,
                          hintText: l10n.classNameHint,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return l10n.classNameRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      TextFormField(
                        key: const Key('create_class_semester_field'),
                        controller: _semesterCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.classSemesterLabel,
                          hintText: l10n.classSemesterHint,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      TextFormField(
                        key: const Key('create_class_desc_field'),
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: l10n.classDescriptionLabel,
                          hintText: l10n.classDescriptionHint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                NlSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.classCreationModeTitle,
                        style: AppTypography.cardTitle(context),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      _ModeOptionTile(
                        tileKey: const Key('create_class_mode_template'),
                        selected: _useTemplate,
                        title: l10n.classUseTemplateTitle,
                        subtitle: l10n.classUseTemplateSubtitle,
                        icon: Icons.auto_awesome_mosaic_outlined,
                        onTap: () => _selectCreationMode(true),
                      ),
                      const SizedBox(height: AppSpacing.s10),
                      _ModeOptionTile(
                        tileKey: const Key('create_class_mode_custom'),
                        selected: !_useTemplate,
                        title: l10n.classCreateCustomTitle,
                        subtitle: l10n.classCreateCustomSubtitle,
                        icon: Icons.dashboard_customize_outlined,
                        onTap: () => _selectCreationMode(false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                NlSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.classTabSettings,
                        style: AppTypography.cardTitle(context),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      SwitchListTile(
                        key: const Key('create_class_pretest_switch'),
                        contentPadding: EdgeInsets.zero,
                        value: _pretestEnabled,
                        onChanged: (v) => setState(() => _pretestEnabled = v),
                        title: Text(l10n.classPretestEnabledLabel),
                        subtitle: Text(l10n.classPretestEnabledHelper),
                      ),
                      const Divider(),
                      SwitchListTile(
                        key: const Key('create_class_posttest_switch'),
                        contentPadding: EdgeInsets.zero,
                        value: _posttestEnabled,
                        onChanged: (v) => setState(() => _posttestEnabled = v),
                        title: Text(l10n.classPosttestEnabledLabel),
                        subtitle: Text(l10n.classPosttestEnabledHelper),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
                FilledButton.icon(
                  key: const Key('create_class_submit_button'),
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(l10n.createClassTitle),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const LecturerBottomNavbar(currentIndex: 0),
    );
  }
}

class _ModeOptionTile extends StatelessWidget {
  const _ModeOptionTile({
    required this.tileKey,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final Key tileKey;
  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? AppColors.primaryBlue : AppColors.borderSubtle(context);
    final bgColor = selected
        ? AppColors.primaryBlue.withValues(alpha: 0.08)
        : Colors.transparent;

    return InkWell(
      key: tileKey,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(
            color: borderColor,
            width: selected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primaryBlue : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.s10),
            Icon(
              icon,
              color: selected ? AppColors.primaryBlue : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.cardTitle(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.body(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

