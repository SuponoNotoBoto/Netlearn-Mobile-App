import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_skeleton.dart';
import '../../shared/widgets/nl_surface_card.dart';
import '../../shared/widgets/nl_tap_scale.dart';
import 'class_controller.dart';
import 'class_models.dart';

/// Modal bottom sheet matching `ClassSwitcherModal` for Lecturer (`ClassSystem.tsx:961-1031`).
Future<void> showLecturerClassSwitcherModal(
  BuildContext context,
  WidgetRef ref, {
  required List<LecturerClass> classes,
  required LecturerClass activeClass,
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
                    ? 'Pilih kelas yang ingin Anda kelola di Dashboard.'
                    : 'Choose the class you want to manage on the Dashboard.',
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
                        selectLecturerActiveClass(ref, cls.id);
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
                                  Row(
                                    children: [
                                      if (cls.code != null &&
                                          cls.code!.isNotEmpty) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF4F2FA),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            cls.code!,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF4A4656),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      if (cls.semester != null &&
                                          cls.semester!.trim().isNotEmpty)
                                        Text(
                                          cls.semester!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF7E7B8F),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
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
                  context.push('/lecturer/classes/create');
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  isId
                      ? 'Buat Kelas Baru & Generate Kode'
                      : 'Create New Class & Generate Code',
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

/// Active Class Bar shown at the top of `LecturerDashboardPage` when the
/// lecturer has at least one active v7 class (`ClassSystem.tsx:749-819`).
class LecturerActiveClassBar extends ConsumerWidget {
  const LecturerActiveClassBar({
    super.key,
    required this.classes,
    required this.activeClass,
  });

  final List<LecturerClass> classes;
  final LecturerClass activeClass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: const Key('lecturer_active_class_bar'),
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
                    if (activeClass.code != null &&
                        activeClass.code!.isNotEmpty)
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
                          '${isId ? 'Kode' : 'Code'}: ${activeClass.code}',
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
                      key: const Key('lecturer_switch_class_modal_btn'),
                      onTap: () => showLecturerClassSwitcherModal(
                        context,
                        ref,
                        classes: classes,
                        activeClass: activeClass,
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
                      key: const Key('lecturer_active_bar_create_btn'),
                      onTap: () => context.push('/lecturer/classes/create'),
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
                              isId ? 'Buat Kelas' : l10n.createClassTitle,
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
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 13,
                    color: isDark
                        ? NetLearnColors.darkMuted
                        : const Color(0xFF7E7B8F),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.classModulesCount(activeClass.moduleCount),
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
              Container(
                width: 3.5,
                height: 3.5,
                decoration: BoxDecoration(
                  color: isDark
                      ? NetLearnColors.darkLine
                      : const Color(0xFFCBC7D8),
                  shape: BoxShape.circle,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 14,
                    color: isDark
                        ? NetLearnColors.darkMuted
                        : const Color(0xFF7E7B8F),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.classMembersCount(activeClass.memberCount),
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
              if (activeClass.semester != null &&
                  activeClass.semester!.trim().isNotEmpty) ...[
                Container(
                  width: 3.5,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? NetLearnColors.darkLine
                        : const Color(0xFFCBC7D8),
                    shape: BoxShape.circle,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: isDark
                          ? NetLearnColors.darkMuted
                          : const Color(0xFF7E7B8F),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      activeClass.semester!.trim(),
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
                Expanded(
                  child: NlTapScale(
                    child: InkWell(
                      key: const Key('lecturer_open_leaderboard_btn'),
                      onTap: () {
                        selectLecturerActiveClass(ref, activeClass.id);
                        context.push('/lecturer/classes/${activeClass.id}/leaderboard');
                      },
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
                Expanded(
                  child: NlTapScale(
                    child: InkWell(
                      key: const Key('lecturer_open_class_settings_btn'),
                      onTap: () =>
                          context.push('/lecturer/classes/${activeClass.id}'),
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
                              Icons.settings_outlined,
                              size: 14,
                              color: Color(0xFF5B2EE8),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                isId
                                    ? 'Pengaturan & Kode'
                                    : l10n.classManageButton,
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
          const SizedBox(height: 8),
          NlTapScale(
            child: InkWell(
              key: const Key('lecturer_open_discussions_btn'),
              onTap: () {
                selectLecturerActiveClass(ref, activeClass.id);
                context.push('/lecturer/discussions?classId=${activeClass.id}');
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
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
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isId
                            ? 'Forum Tanya-Jawab Kelas'
                            : 'Class Q&A Discussion Forum',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5B2EE8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: Color(0xFF5B2EE8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lecturer Dashboard "Manage Class" section per NETLEARN_PRD.md §4.1 and `ClassSystem.tsx:821-959`.
class LecturerManageClassSection extends ConsumerWidget {
  final bool showHeaderTitle;

  const LecturerManageClassSection({
    super.key,
    this.showHeaderTitle = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final classesAsync = ref.watch(lecturerClassesProvider);
    final activeClassId = ref.watch(activeLecturerClassIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            if (showHeaderTitle)
              Text(
                l10n.manageClassesTitle,
                style: AppTypography.sectionTitle(context),
              ),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                OutlinedButton.icon(
                  key: const Key('lecturer_archived_classes_button'),
                  onPressed: () => context.push('/lecturer/classes/archived'),
                  icon: const Icon(Icons.inventory_2_outlined, size: 16),
                  label: Text(l10n.archivedClassesTitle),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6C2CE2),
                    side: const BorderSide(color: Color(0xFFD9CEFF)),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s10,
                      vertical: AppSpacing.s6,
                    ),
                  ),
                ),
                FilledButton.icon(
                  key: const Key('lecturer_create_class_button'),
                  onPressed: () => context.push('/lecturer/classes/create'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.createClassTitle),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8C52FF),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                      vertical: AppSpacing.s6,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          l10n.manageClassesSubtitle,
          style: AppTypography.caption(context),
        ),
        const SizedBox(height: AppSpacing.s12),
        classesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s8),
            child: NlSkeletonList(itemCount: 2),
          ),
          error: (_, _) => NlSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.couldNotLoadData,
                  style: AppTypography.cardTitle(context),
                ),
                const SizedBox(height: AppSpacing.s8),
                TextButton.icon(
                  onPressed: () => ref.invalidate(lecturerClassesProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
          data: (rawClasses) {
            final classes = rawClasses
                .where((c) => c.id != kLegacyFallbackClassId)
                .toList(growable: false);

            if (classes.isEmpty) {
              return NlSurfaceCard(
                key: const Key('lecturer_classes_empty_card'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1ECFF),
                            borderRadius: BorderRadius.circular(AppRadius.r12),
                          ),
                          child: const Icon(
                            Icons.school_outlined,
                            color: Color(0xFF8C52FF),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: Text(
                            l10n.noClassesLecturerTitle,
                            style: AppTypography.cardTitle(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      l10n.noClassesLecturerMessage,
                      style: AppTypography.body(context),
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (classes.length > 1) ...[
                  _LecturerClassSwitcherRow(
                    classes: classes,
                    activeClassId: activeClassId ?? classes.first.id,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                ],
                for (int i = 0; i < classes.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.s12),
                  _LecturerClassCard(
                    cls: classes[i],
                    isSelected:
                        (activeClassId ?? classes.first.id) == classes[i].id,
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LecturerClassSwitcherRow extends ConsumerWidget {
  const _LecturerClassSwitcherRow({
    required this.classes,
    required this.activeClassId,
  });

  final List<LecturerClass> classes;
  final String activeClassId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text(
            '${l10n.switchClassAction}:',
            style: AppTypography.caption(context),
          ),
          const SizedBox(width: AppSpacing.s8),
          for (final cls in classes) ...[
            ChoiceChip(
              label: Text(cls.name),
              selected: cls.id == activeClassId,
              onSelected: (_) {
                selectLecturerActiveClass(ref, cls.id);
              },
            ),
            const SizedBox(width: AppSpacing.s8),
          ],
        ],
      ),
    );
  }
}

class _LecturerClassCard extends ConsumerWidget {
  const _LecturerClassCard({
    required this.cls,
    required this.isSelected,
  });

  final LecturerClass cls;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final statusLabel = switch (cls.status) {
      'published' => l10n.classStatusPublished,
      'archived' => l10n.classStatusArchived,
      _ => l10n.classStatusDraft,
    };
    final statusColor = switch (cls.status) {
      'published' => AppColors.successGreen,
      'archived' => AppColors.textMuted,
      _ => AppColors.warningAmber,
    };

    return NlSurfaceCard(
      key: Key('lecturer_class_card_${cls.id}'),
      onTap: () {
        selectLecturerActiveClass(ref, cls.id);
        context.push('/lecturer/classes/${cls.id}');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.rPill),
                ),
                child: Text(
                  statusLabel,
                  style: AppTypography.caption(context).copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (cls.semester != null && cls.semester!.trim().isNotEmpty)
                Text(
                  cls.semester!,
                  style: AppTypography.caption(context),
                ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1ECFF),
                    borderRadius: BorderRadius.circular(AppRadius.rPill),
                  ),
                  child: Text(
                    isId ? 'Aktif' : 'Active',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6C2CE2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          Text(
            cls.name,
            style: AppTypography.cardTitle(context),
          ),
          if (cls.description != null && cls.description!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              cls.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(context),
            ),
          ],
          const SizedBox(height: AppSpacing.s10),
          Wrap(
            spacing: AppSpacing.s12,
            runSpacing: AppSpacing.s6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.people_outline_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.classMembersCount(cls.memberCount),
                    style: AppTypography.caption(context),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.view_module_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.classModulesCount(cls.moduleCount),
                    style: AppTypography.caption(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              if (cls.code != null && cls.code!.isNotEmpty)
                InkWell(
                  key: Key('copy_invite_code_${cls.id}'),
                  borderRadius: BorderRadius.circular(AppRadius.r8),
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: cls.code!),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.classInviteCodeCopied)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s10,
                      vertical: AppSpacing.s6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F1FF),
                      borderRadius: BorderRadius.circular(AppRadius.r8),
                      border: Border.all(color: const Color(0xFFE0D4FF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.key_rounded,
                          size: 15,
                          color: Color(0xFF6C2CE2),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${l10n.classInviteCodeLabel}: ${cls.code}',
                          style: AppTypography.caption(context).copyWith(
                            color: const Color(0xFF6C2CE2),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: Color(0xFF6C2CE2),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              FilledButton.tonalIcon(
                key: Key('manage_class_btn_${cls.id}'),
                onPressed: () {
                  selectLecturerActiveClass(ref, cls.id);
                  context.push('/lecturer/classes/${cls.id}');
                },
                icon: const Icon(Icons.settings_outlined, size: 16),
                label: Text(l10n.classManageButton),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF1ECFF),
                  foregroundColor: const Color(0xFF6C2CE2),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
