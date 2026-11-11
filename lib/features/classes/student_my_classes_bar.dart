import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_surface_card.dart';
import '../../shared/widgets/nl_tap_scale.dart';
import 'class_action_messages.dart';
import 'class_controller.dart';
import 'class_models.dart';

typedef JoinClassSubmitCallback = Future<String> Function(String code);

Future<void> showStudentJoinClassDialog(
  BuildContext context,
  WidgetRef ref, {
  JoinClassSubmitCallback? onJoinOverride,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final codeCtrl = TextEditingController();

  final submittedCode = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.studentJoinClassAction),
      content: TextField(
        key: const Key('student_join_code_input'),
        controller: codeCtrl,
        textCapitalization: TextCapitalization.characters,
        maxLength: 12,
        decoration: InputDecoration(
          labelText: l10n.classInviteCodeLabel,
          hintText: l10n.studentJoinClassHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('student_join_code_submit_btn'),
          onPressed: () => Navigator.of(ctx).pop(codeCtrl.text.trim()),
          child: Text(l10n.studentJoinClassAction),
        ),
      ],
    ),
  );

  if (submittedCode == null || submittedCode.isEmpty) return;

  try {
    if (onJoinOverride != null) {
      await onJoinOverride(submittedCode);
    } else {
      await joinClassByCodeAction(ref, submittedCode);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.studentJoinClassSuccess)),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(classActionErrorMessage(context, e)),
      ),
    );
  }
}

/// Modal dialog matching `ClassSwitcherModal` in `design_figma/src_figma_new1/ClassSystem.tsx`.
Future<void> showStudentClassSwitcherModal(
  BuildContext context,
  WidgetRef ref, {
  required List<StudentClass> classes,
  required StudentClass activeClass,
  required VoidCallback onAddClass,
}) async {
  final isId = Localizations.localeOf(context).languageCode == 'id';
  final isDark = Theme.of(context).brightness == Brightness.dark;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: isDark ? NetLearnColors.darkSurface : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isId ? 'Pilih Kelas Aktif' : 'Select Active Class',
                    style: TextStyle(
                      fontFamily: AppTheme.displayFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? NetLearnColors.darkText
                          : const Color(0xFF1D1C21),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Text(
                isId
                    ? 'Pilih kelas yang ingin Anda buka di Dashboard.'
                    : 'Choose the class you want to open on the Dashboard.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7E7B8F),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: classes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final cls = classes[index];
                    final isCurrent = cls.id == activeClass.id;
                    return InkWell(
                      onTap: () {
                        selectStudentActiveClass(ref, cls.id);
                        Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFFF5F1FF)
                              : (isDark
                                  ? NetLearnColors.darkApp
                                  : const Color(0xFFFAF9FD)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent
                                ? const Color(0xFF8C52FF)
                                : (isDark
                                    ? NetLearnColors.darkLine
                                    : const Color(0xFFEDEAF6)),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cls.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? NetLearnColors.darkText
                                          : const Color(0xFF1D1C21),
                                    ),
                                  ),
                                  if (cls.semester != null &&
                                      cls.semester!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      cls.semester!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF7E7B8F),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF8C52FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onAddClass();
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  isId
                      ? 'Gabung Kelas Lain dengan Kode'
                      : 'Join Another Class with Code',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8C52FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Active Class Bar shown at the top of StudentDashboardPage when the student
/// is enrolled in real v7 classes (`ClassSystem.tsx:749-819`).
class StudentMyClassesBar extends ConsumerWidget {
  const StudentMyClassesBar({
    super.key,
    required this.classes,
    required this.activeClass,
    this.onJoinOverride,
    this.leaderboardButtonKey,
  });

  final List<StudentClass> classes;
  final StudentClass activeClass;
  final JoinClassSubmitCallback? onJoinOverride;
  final Key? leaderboardButtonKey;

  void _openAddClass(BuildContext context, WidgetRef ref) {
    if (onJoinOverride != null) {
      showStudentJoinClassDialog(
        context,
        ref,
        onJoinOverride: onJoinOverride,
      );
      return;
    }
    try {
      context.push('/student/class-onboarding');
    } catch (_) {
      showStudentJoinClassDialog(context, ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final flowStatus = ref
        .watch(classLearningFlowStatusProvider(activeClass.id))
        .value;
    final pretestOn = flowStatus?.pretestEnabled ?? true;
    final posttestOn = flowStatus?.posttestEnabled ?? true;
    final leaderboardOn = flowStatus?.leaderboardEnabled ?? true;

    return Container(
      key: const Key('student_my_classes_bar'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? NetLearnColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? NetLearnColors.darkLine : const Color(0xFFEDEAF6),
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A1D1C21),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1ECFF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isId ? 'KELAS AKTIF' : 'ACTIVE CLASS',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: Color(0xFF6C2CE2),
                        ),
                      ),
                    ),
                    if (activeClass.semester != null &&
                        activeClass.semester!.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? NetLearnColors.darkApp
                              : const Color(0xFFF4F2FA),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          activeClass.semester!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? NetLearnColors.darkMuted
                                : const Color(0xFF4A4656),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                children: [
                  NlTapScale(
                    child: InkWell(
                      key: const Key('student_switch_class_modal_btn'),
                      onTap: () => showStudentClassSwitcherModal(
                        context,
                        ref,
                        classes: classes,
                        activeClass: activeClass,
                        onAddClass: () => _openAddClass(context, ref),
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F1FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.swap_horiz_rounded,
                              size: 14,
                              color: Color(0xFF6C2CE2),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isId
                                  ? 'Pindah (${classes.length})'
                                  : 'Switch (${classes.length})',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6C2CE2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  NlTapScale(
                    child: InkWell(
                      key: const Key('student_join_class_btn'),
                      onTap: () => _openAddClass(context, ref),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8C52FF),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x388C52FF),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isId ? 'Gabung Kode' : l10n.studentJoinClassAction,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            activeClass.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.displayFontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: isDark
                  ? NetLearnColors.darkText
                  : const Color(0xFF1D1C21),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: pretestOn
                      ? (isDark
                          ? const Color(0x2235C779)
                          : const Color(0xFFE8F8EE))
                      : (isDark
                          ? NetLearnColors.darkApp
                          : const Color(0xFFF1F0F5)),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: pretestOn
                        ? (isDark
                            ? const Color(0x4435C779)
                            : const Color(0xFFC7EED4))
                        : (isDark
                            ? NetLearnColors.darkLine
                            : const Color(0xFFE3E1EB)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: pretestOn
                            ? const Color(0xFF1EA95B)
                            : const Color(0xFF9E9BAA),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isId
                          ? (pretestOn ? 'Pretest Aktif' : 'Pretest Nonaktif')
                          : (pretestOn ? 'Pretest ON' : 'Pretest OFF'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: pretestOn
                            ? (isDark
                                ? const Color(0xFF67DF99)
                                : const Color(0xFF127B40))
                            : (isDark
                                ? NetLearnColors.darkMuted
                                : const Color(0xFF757283)),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: posttestOn
                      ? (isDark
                          ? const Color(0x2235C779)
                          : const Color(0xFFE8F8EE))
                      : (isDark
                          ? NetLearnColors.darkApp
                          : const Color(0xFFF1F0F5)),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: posttestOn
                        ? (isDark
                            ? const Color(0x4435C779)
                            : const Color(0xFFC7EED4))
                        : (isDark
                            ? NetLearnColors.darkLine
                            : const Color(0xFFE3E1EB)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: posttestOn
                            ? const Color(0xFF1EA95B)
                            : const Color(0xFF9E9BAA),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isId
                          ? (posttestOn
                              ? 'Post Test Aktif'
                              : 'Post Test Nonaktif')
                          : (posttestOn ? 'Post Test ON' : 'Post Test OFF'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: posttestOn
                            ? (isDark
                                ? const Color(0xFF67DF99)
                                : const Color(0xFF127B40))
                            : (isDark
                                ? NetLearnColors.darkMuted
                                : const Color(0xFF757283)),
                      ),
                    ),
                  ],
                ),
              ),
              if (activeClass.lecturerName != null &&
                  activeClass.lecturerName!.trim().isNotEmpty) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 13,
                      color: isDark
                          ? NetLearnColors.darkMuted
                          : const Color(0xFF7E7B8F),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      activeClass.lecturerName!.trim(),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? NetLearnColors.darkMuted
                            : const Color(0xFF5E5A6F),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          if (classes.length > 1) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final cls in classes) ...[
                    ChoiceChip(
                      key: Key('student_switch_class_${cls.id}'),
                      label: Text(cls.name),
                      selected: cls.id == activeClass.id,
                      onSelected: (_) => selectStudentActiveClass(ref, cls.id),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? NetLearnColors.darkLine
                      : const Color(0xFFEDEAF6),
                ),
              ),
            ),
            child: Row(
              children: [
                if (leaderboardOn) ...[
                  Expanded(
                    child: NlTapScale(
                      child: InkWell(
                        key: leaderboardButtonKey ??
                            const Key('student_open_leaderboard_btn'),
                        onTap: () => context.push('/student/leaderboard'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? NetLearnColors.darkApp
                                : const Color(0xFFFAF8FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? NetLearnColors.darkLine
                                  : const Color(0xFFE9E2FA),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.emoji_events_outlined,
                                size: 14,
                                color: Color(0xFF5B2EE8),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  isId
                                      ? 'Leaderboard Kelas'
                                      : l10n.classTabLeaderboard,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF5B2EE8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: NlTapScale(
                    child: InkWell(
                      key: const Key('student_open_discussions_btn'),
                      onTap: () => context.push(
                        '/student/discussions?classId=${activeClass.id}',
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? NetLearnColors.darkApp
                              : const Color(0xFFFAF8FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? NetLearnColors.darkLine
                                : const Color(0xFFE9E2FA),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.forum_outlined,
                              size: 14,
                              color: Color(0xFF5B2EE8),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                isId ? 'Forum Diskusi' : 'Q&A Forum',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5B2EE8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state card fallback if rendered inline outside the full-screen gate.
class StudentNoClassEmptyCard extends ConsumerWidget {
  const StudentNoClassEmptyCard({
    super.key,
    this.onJoinOverride,
  });

  final JoinClassSubmitCallback? onJoinOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return NlSurfaceCard(
      key: const Key('student_no_class_empty_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBlue,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  l10n.studentNoClassTitle,
                  style: AppTypography.cardTitle(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          Text(
            l10n.studentNoClassMessage,
            style: AppTypography.body(context),
          ),
          const SizedBox(height: AppSpacing.s14),
          FilledButton.icon(
            key: const Key('student_empty_join_class_btn'),
            onPressed: () => showStudentJoinClassDialog(
              context,
              ref,
              onJoinOverride: onJoinOverride,
            ),
            icon: const Icon(Icons.key_rounded, size: 18),
            label: Text(l10n.studentJoinClassAction),
          ),
        ],
      ),
    );
  }
}
