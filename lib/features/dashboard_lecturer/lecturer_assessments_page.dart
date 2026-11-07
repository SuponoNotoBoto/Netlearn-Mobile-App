import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/language_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_empty_state.dart';
import '../../shared/widgets/nl_segmented_tabs.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/nl_topbar.dart';
import '../../shared/widgets/status_badge.dart'
    show NetLearnStatus, StatusBadge;
import 'lecturer_assessments_controller.dart';
import 'lecturer_bottom_navbar.dart';
import 'lecturer_score_overview.dart';

class LecturerAssessmentsPage extends ConsumerStatefulWidget {
  const LecturerAssessmentsPage({super.key});

  @override
  ConsumerState<LecturerAssessmentsPage> createState() =>
      _LecturerAssessmentsPageState();
}

class _LecturerAssessmentsPageState
    extends ConsumerState<LecturerAssessmentsPage> {
  static const int _assessmentsTab = 0;
  static const int _scoreOverviewTab = 1;

  int _selectedTab = _assessmentsTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.background,

      appBar: NlTopBar(
        title: l10n.assessment,
        onBack: () => context.pop(),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NetLearnSpace.s20,
              NetLearnSpace.s16,
              NetLearnSpace.s20,
              0,
            ),
            child: NlSegmentedTabs(
              labels: [l10n.assessmentCoreTab, l10n.scoreOverview],
              selectedIndex: _selectedTab,
              semanticLabel: l10n.assessment,
              onChanged: (index) {
                setState(() {
                  _selectedTab = index;
                });
              },
            ),
          ),

          const SizedBox(height: NetLearnSpace.s16),

          Expanded(
            child: _selectedTab == _scoreOverviewTab
                ? const LecturerScoreOverviewTab()
                : _buildAssessmentsTab(context, l10n),
          ),
        ],
      ),

      floatingActionButton: _selectedTab == _assessmentsTab
          ? FloatingActionButton.extended(
              backgroundColor: context.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                ref.watch(languageProvider).languageCode == 'id'
                    ? 'Tambah Asesmen'
                    : 'Add Assessment',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () => context.push('/lecturer/assessments/task/create'),
            )
          : null,

      bottomNavigationBar: const LecturerBottomNavbar(currentIndex: 3),
    );
  }

  /// Tab pertama — mengelola asesmen utama (Pretest/Posttest) serta tugas & kuis kustom.
  Widget _buildAssessmentsTab(BuildContext context, AppLocalizations l10n) {
    final isId = ref.watch(languageProvider).languageCode == 'id';
    final theme = Theme.of(context);
    final assessments = ref.watch(lecturerAssessmentsProvider);
    final tasksAsync = ref.watch(lecturerTasksProvider);

    return RefreshIndicator(
      color: context.accent,
      onRefresh: () async {
        ref.invalidate(lecturerAssessmentsProvider);
        ref.invalidate(lecturerTasksProvider);
        await Future.wait([
          ref.read(lecturerAssessmentsProvider.future),
          ref.read(lecturerTasksProvider.future),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          NetLearnSpace.s20,
          NetLearnSpace.s16,
          NetLearnSpace.s20,
          NetLearnSpace.s32 + 64,
        ),
        children: [
          // Section 1: Core Assessments (Pretest & Posttest)
          Text(
            isId ? 'Asesmen Utama (Gerbang)' : 'Core Gate Assessments',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: NetLearnSpace.s12),
          assessments.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(NetLearnSpace.s24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stackTrace) => Padding(
              padding: const EdgeInsets.all(NetLearnSpace.s24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 46,
                    color: NetLearnColors.danger,
                  ),
                  const SizedBox(height: NetLearnSpace.s12),
                  Text(l10n.failedToLoad, textAlign: TextAlign.center),
                  const SizedBox(height: NetLearnSpace.s12),
                  OutlinedButton(
                    onPressed: () =>
                        ref.invalidate(lecturerAssessmentsProvider),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return NlEmptyState(
                  icon: Icons.quiz_outlined,
                  title: l10n.noAssessments,
                  message: l10n.noAssessmentsDescription,
                );
              }

              return Column(
                children: [
                  for (final assessment in orderAssessments(items))
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 16,
                      ),
                      child: _AssessmentCard(assessment: assessment),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: NetLearnSpace.s24),

          // Section 2: Custom Tasks & LMS Assessments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isId ? 'Tugas & Kuis Kustom' : 'Custom Tasks & Quizzes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: NetLearnSpace.s8),
              TextButton.icon(
                onPressed: () => context.push('/lecturer/assessments/task/create'),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: Text(
                  isId ? 'Buat Baru' : 'Create New',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: NetLearnSpace.s12),
          tasksAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(NetLearnSpace.s24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stackTrace) => Padding(
              padding: const EdgeInsets.all(NetLearnSpace.s24),
              child: Text(
                isId ? 'Gagal memuat tugas kustom' : 'Failed to load custom tasks',
                textAlign: TextAlign.center,
              ),
            ),
            data: (tasks) {
              if (tasks.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(NetLearnSpace.s24),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(NetLearnRadius.card),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.assignment_outlined, size: 40, color: context.mutedText),
                      const SizedBox(height: NetLearnSpace.s8),
                      Text(
                        isId ? 'Belum Ada Asesmen Kustom' : 'No Custom Assessments Yet',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isId
                            ? 'Buat asesmen kustom bebas atau kuis terikat modul untuk mahasiswa di kelas Anda.'
                            : 'Create standalone LMS tasks or module quizzes for students in your class.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.mutedText, fontSize: 12),
                      ),
                      const SizedBox(height: NetLearnSpace.s16),
                      FilledButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(isId ? 'Tambah Asesmen Sekarang' : 'Add Assessment Now'),
                        style: FilledButton.styleFrom(
                          backgroundColor: context.accent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => context.push('/lecturer/assessments/task/create'),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  for (final task in tasks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _TaskCard(task: task),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AssessmentCard extends ConsumerWidget {
  final LecturerAssessment assessment;

  const _AssessmentCard({required this.assessment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final bool isPublished = assessment.isPublished;
    final bool isPretest = assessment.isPretest;

    final String statusLabel = isPublished ? l10n.published : l10n.draft;

    final Color typeAccent = isPretest
        ? NetLearnAccents.purple
        : NetLearnAccents.pink;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: typeAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 22,
                  color: Colors.white,
                ),
              ),

              StatusBadge(
                status: isPublished
                    ? NetLearnStatus.linked
                    : NetLearnStatus.active,
                label: statusLabel,
              ),
            ],
          ),

          const SizedBox(height: NetLearnSpace.s10),

          Text(
            assessment.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: NetLearnSpace.s10),

          Text(
            l10n.assignmentMeta(
              assessment.questionCount.toString(),
              assessment.durationMinutes.toString(),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.mutedText,
            ),
          ),

          const SizedBox(height: NetLearnSpace.s4),

          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 16,
                color: NetLearnColors.forest,
              ),
              const SizedBox(width: NetLearnSpace.s6),
              Expanded(
                child: Text(
                  l10n.answerKeysConfigured(
                    assessment.answeredCount,
                    assessment.questionCount,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.mutedText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (!isPublished && assessment.unansweredCount > 0) ...[
            const SizedBox(height: NetLearnSpace.s12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: context.mutedText,
                ),
                const SizedBox(width: NetLearnSpace.s8),
                Expanded(
                  child: Text(
                    l10n.answerKeyMissing(assessment.unansweredCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.mutedText,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: NetLearnSpace.s16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    context.push(
                      '/lecturer/assessments/${assessment.id}/questions',
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: NetLearnColors.primaryTint,
                    foregroundColor: context.accent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(NetLearnRadius.button),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          l10n.manageQuestions,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: NetLearnSpace.s12),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: isPublished || assessment.canPublish
                      ? () => _togglePublished(context, ref)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.accent,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(NetLearnRadius.button),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPublished
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          isPublished ? l10n.unpublish : l10n.publish,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _togglePublished(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final next = !assessment.isPublished;

    try {
      await setAssessmentPublished(ref, assessment, next);

      if (!context.mounted) return;

      NlSnackBar.show(
        context,
        next ? l10n.assessmentPublished : l10n.assessmentUnpublished,
        tone: NlSnackTone.success,
      );
    } on AssessmentWriteException catch (error) {
      if (!context.mounted) return;

      NlSnackBar.show(
        context,
        switch (error.failure) {
          AssessmentWriteFailure.missingAnswerKey => l10n.answerKeyMissing(
            assessment.unansweredCount,
          ),
          AssessmentWriteFailure.quizIncomplete =>
            l10n.assessmentQuizIncomplete,
          AssessmentWriteFailure.notPermitted => l10n.notPermittedError,
          AssessmentWriteFailure.unknown => l10n.assessmentSaveFailed,
        },
        tone: NlSnackTone.error,
      );
    } catch (_) {
      if (!context.mounted) return;
      NlSnackBar.show(
        context,
        l10n.assessmentSaveFailed,
        tone: NlSnackTone.error,
      );
    }
  }
}

class _TaskCard extends ConsumerWidget {
  final LecturerTask task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isId = ref.watch(languageProvider).languageCode == 'id';

    final bool isPublished = task.isPublished;
    final bool isModuleQuiz = task.module != null;
    final String statusLabel = isPublished ? l10n.published : l10n.draft;

    final Color accentColor = isModuleQuiz ? const Color(0xFF00B4D8) : const Color(0xFF8C52FF);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isModuleQuiz ? Icons.menu_book_rounded : Icons.assignment_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              StatusBadge(
                status: isPublished ? NetLearnStatus.linked : NetLearnStatus.active,
                label: statusLabel,
              ),
            ],
          ),
          const SizedBox(height: NetLearnSpace.s10),
          Text(
            task.localizedTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: NetLearnSpace.s8),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (isModuleQuiz) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B4D8).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Modul ${task.module}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0077B6),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (task.required ? const Color(0xFFE65100) : const Color(0xFF4CAF50)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.required ? (isId ? 'Wajib Buka Modul' : 'Required Gate') : (isId ? 'Kuis Opsional' : 'Optional Quiz'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: task.required ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8C52FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isId ? 'Asesmen Bebas (LMS)' : 'Standalone LMS Task',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6C2CE2),
                    ),
                  ),
                ),
              ],
              if (task.leaderboardEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '🏆 Leaderboard',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: NetLearnSpace.s10),

          Row(
            children: [
              Icon(Icons.help_outline_rounded, size: 15, color: context.mutedText),
              const SizedBox(width: 4),
              Text(
                '${task.questionCount} ${l10n.questions}',
                style: theme.textTheme.bodySmall?.copyWith(color: context.mutedText),
              ),
              const SizedBox(width: 14),
              Icon(Icons.timer_outlined, size: 15, color: context.mutedText),
              const SizedBox(width: 4),
              Text(
                '${task.durationMinutes} ${l10n.minutesShort}',
                style: theme.textTheme.bodySmall?.copyWith(color: context.mutedText),
              ),
              if (task.deadline != null) ...[
                const SizedBox(width: 14),
                Icon(Icons.calendar_today_outlined, size: 14, color: context.mutedText),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${task.deadline!.day}/${task.deadline!.month}/${task.deadline!.year}',
                    style: theme.textTheme.bodySmall?.copyWith(color: context.mutedText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: NetLearnSpace.s16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: () {
                    context.push('/lecturer/assessments/${task.id}/questions');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: NetLearnColors.primaryTint,
                    foregroundColor: context.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(NetLearnRadius.button),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isId ? 'Kelola Soal (${task.questionCount})' : 'Manage Questions (${task.questionCount})',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.settings_outlined, size: 16),
                        label: Text(
                          isId ? 'Pengaturan' : 'Settings',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        onPressed: () {
                          context.push('/lecturer/assessments/task/${task.id}');
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: FilledButton.icon(
                        icon: Icon(
                          isPublished ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 16,
                        ),
                        label: Text(
                          isPublished ? l10n.unpublish : l10n.publish,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: isPublished ? context.raisedSurface : context.accent,
                          foregroundColor: isPublished ? context.onSurface : Colors.white,
                        ),
                        onPressed: isPublished || task.canPublish
                            ? () => _togglePublished(context, ref)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _togglePublished(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final next = !task.isPublished;

    try {
      await setTaskPublished(ref, task, next);

      if (!context.mounted) return;

      NlSnackBar.show(
        context,
        next ? l10n.assessmentPublished : l10n.assessmentUnpublished,
        tone: NlSnackTone.success,
      );
    } on AssessmentWriteException catch (error) {
      if (!context.mounted) return;

      NlSnackBar.show(
        context,
        switch (error.failure) {
          AssessmentWriteFailure.missingAnswerKey => l10n.answerKeyMissing(task.unansweredCount),
          AssessmentWriteFailure.quizIncomplete => l10n.assessmentQuizIncomplete,
          AssessmentWriteFailure.notPermitted => l10n.notPermittedError,
          AssessmentWriteFailure.unknown => l10n.assessmentSaveFailed,
        },
        tone: NlSnackTone.error,
      );
    } catch (_) {
      if (!context.mounted) return;
      NlSnackBar.show(
        context,
        l10n.assessmentSaveFailed,
        tone: NlSnackTone.error,
      );
    }
  }
}
