import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_empty_state.dart'
    show NlEmptyState;
import '../../shared/widgets/nl_section_heading.dart';
import '../../shared/widgets/nl_skeleton.dart';
import '../../shared/widgets/nl_topbar.dart';
import '../../shared/widgets/status_badge.dart'
    show NetLearnStatus, StatusBadge;
import 'lecturer_assessments_controller.dart';
import 'lecturer_bottom_navbar.dart';
import 'lecturer_dashboard_controller.dart';

class LecturerTaskDetailPage extends ConsumerWidget {
  final String taskId;

  const LecturerTaskDetailPage({
    super.key,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final taskAsync = ref.watch(lecturerTaskProvider(taskId));

    // Total students is the lecturer's whole-class figure from `lecturer_dashboard()`
    // rather than a per-task number, because no per-task audience exists in the
    // schema. `hasClassContext` is false while the lecturer owns no classes, and
    // then the count is genuinely unknown instead of a confident zero.
    final statsAsync = ref.watch(lecturerDashboardStatsProvider);
    final int? totalStudents = statsAsync.maybeWhen(
      data: (stats) => stats.hasClassContext ? stats.totalStudents : null,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: context.background,
      appBar: NlTopBar(
        title: l10n.taskDetails,
        onBack: () => context.pop(),
      ),
      body: taskAsync.when(
        loading: () => const NlSkeletonDetail(
          showBanner: false,
          paragraphBlocks: 3,
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(NetLearnSpace.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 46, color: NetLearnColors.danger),
                const SizedBox(height: NetLearnSpace.s12),
                Text(l10n.failedToLoad, textAlign: TextAlign.center),
                const SizedBox(height: NetLearnSpace.s12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(lecturerTaskProvider(taskId)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (task) {
          if (task == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(NetLearnSpace.s24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_outlined, size: 46, color: context.mutedText),
                    const SizedBox(height: NetLearnSpace.s12),
                    Text(l10n.taskNotFound, textAlign: TextAlign.center),
                    const SizedBox(height: NetLearnSpace.s12),
                    NlButton(
                      label: l10n.backToAssessments,
                      onPressed: () => context.go('/lecturer/assessments'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: context.accent,
            onRefresh: () async {
              ref.invalidate(lecturerTaskProvider(taskId));
              await ref.read(lecturerTaskProvider(taskId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                NetLearnSpace.s20,
                NetLearnSpace.s16,
                NetLearnSpace.s20,
                NetLearnSpace.s32,
              ),
              children: _buildTaskContent(
                context,
                theme,
                l10n,
                task,
                taskId,
                totalStudents,
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const LecturerBottomNavbar(currentIndex: 3),
    );
  }

  List<Widget> _buildTaskContent(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    LecturerTask task,
    String taskId,
    int? totalStudents,
  ) {
    final widgets = <Widget>[];

    // Module & Type
    widgets.add(
      Row(
        children: [
          if (task.module != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: NetLearnSpace.s8,
                vertical: NetLearnSpace.s4,
              ),
              decoration: BoxDecoration(
                color: context.accentTint,
                borderRadius: BorderRadius.circular(NetLearnRadius.badge),
              ),
              child: Text(
                '${l10n.module} ${task.module}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: NetLearnSpace.s8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: NetLearnSpace.s8,
              vertical: NetLearnSpace.s4,
            ),
            decoration: BoxDecoration(
              color: context.raisedSurface,
              borderRadius: BorderRadius.circular(NetLearnRadius.badge),
            ),
            child: Text(
              l10n.multipleChoice,
              style: theme.textTheme.labelSmall?.copyWith(
                color: context.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    widgets.add(const SizedBox(height: NetLearnSpace.s16));

    // Task Title
    widgets.add(
      Text(
        task.title,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    widgets.add(const SizedBox(height: NetLearnSpace.s24));

    // Description Card
    widgets.add(
      _InfoCard(
        title: l10n.description,
        leadingIcon: Icons.description_outlined,
        child: Text(
          task.localizedDescription.isNotEmpty
              ? task.localizedDescription
              : l10n.noDescription,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: task.localizedDescription.isNotEmpty
                ? context.onSurface
                : context.mutedText,
            height: 1.6,
          ),
        ),
      ),
    );

    widgets.add(const SizedBox(height: NetLearnSpace.s16));

    // Instructions Card
    widgets.add(
      _InfoCard(
        title: l10n.instructions,
        leadingIcon: Icons.assignment_outlined,
        child: Text(
          task.localizedInstructions.isNotEmpty
              ? task.localizedInstructions
              : l10n.noInstructions,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: task.localizedInstructions.isNotEmpty
                ? context.onSurface
                : context.mutedText,
            height: 1.6,
          ),
        ),
      ),
    );

    widgets.add(const SizedBox(height: NetLearnSpace.s16));

    // Meta info: Questions, Duration, Deadline
    widgets.add(
      Wrap(
        spacing: NetLearnSpace.s16,
        runSpacing: NetLearnSpace.s8,
        children: [
          _MetaChip(
            icon: Icons.help_outline,
            label: '${task.questionCount} ${l10n.questionsShort}',
          ),
          _MetaChip(
            icon: Icons.timer_outlined,
            label: '${task.durationMinutes} ${l10n.minutesShort}',
          ),
          if (task.timeLimit > 0)
            _MetaChip(
              icon: Icons.schedule_outlined,
              label: '${task.timeLimit} ${l10n.minutesShort} ${l10n.timeLimitShort}',
            ),
          if (task.deadline != null)
            _MetaChip(
              icon: Icons.calendar_today_outlined,
              label: _formatDeadline(task.deadline!, l10n),
            ),
        ],
      ),
    );

    widgets.add(const SizedBox(height: NetLearnSpace.s24));

    // Task Results Card
    widgets.add(
      _InfoCard(
        title: l10n.taskResults,
        leadingIcon: Icons.analytics_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    value: '${task.submittedCount}',
                    label: l10n.submitted,
                    color: context.accent,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    // "—" rather than a zero when the total cannot be derived:
                    // a class total here is the lecturer's whole cohort, not this
                    // task's audience.
                    value: totalStudents == null ? '—' : '$totalStudents',
                    label: l10n.totalStudents,
                    color: context.mutedText,
                  ),
                ),
              ],
            ),
            if (task.submittedCount > 0 &&
                totalStudents != null &&
                totalStudents > 0) ...[
              const SizedBox(height: NetLearnSpace.s12),
              Text(
                '${l10n.submissionRate} ${((task.submittedCount / totalStudents) * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.mutedText,
                ),
              ),
            ] else if (task.submittedCount > 0) ...[
              const SizedBox(height: NetLearnSpace.s12),
              Text(
                l10n.submissionRateUnavailable,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.mutedText,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    widgets.add(const SizedBox(height: NetLearnSpace.s16));

    // Status Badge
    widgets.add(
      StatusBadge(
        status: task.isPublished ? NetLearnStatus.linked : NetLearnStatus.active,
        label: task.isPublished ? l10n.published : l10n.draft,
      ),
    );

    widgets.add(const SizedBox(height: NetLearnSpace.s24));

    // Edit Button — opens the task form, which owns the task's own metadata.
    widgets.add(
      NlButton(
        label: l10n.editTaskAndQuestions,
        icon: Icons.edit_outlined,
        onPressed: () {
          context.push('/lecturer/assessments/task/$taskId/edit');
        },
      ),
    );

    widgets.add(const SizedBox(height: NetLearnSpace.s16));

    // Questions Section
    widgets.add(
      NlSectionHeading(
        title: l10n.questions,
        actionLabel: l10n.manageQuestions,
        onAction: () {
          context.push('/lecturer/assessments/$taskId/questions');
        },
        leadingIcon: Icons.quiz_outlined,
      ),
    );

    widgets.add(const SizedBox(height: NetLearnSpace.s8));

    widgets.add(
      _TaskQuestionsList(
        taskId: taskId,
        onManage: () {
          context.push('/lecturer/assessments/$taskId/questions');
        },
      ),
    );

    return widgets;
  }

  String _formatDeadline(DateTime deadline, AppLocalizations l10n) {
    final months = [
      l10n.january,
      l10n.february,
      l10n.march,
      l10n.april,
      l10n.may,
      l10n.june,
      l10n.july,
      l10n.august,
      l10n.september,
      l10n.october,
      l10n.november,
      l10n.december,
    ];
    return '${deadline.day} ${months[deadline.month - 1]} ${deadline.year} ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData leadingIcon;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.leadingIcon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NetLearnSpace.s16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(leadingIcon, size: 18, color: context.accent),
              const SizedBox(width: NetLearnSpace.s8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: NetLearnSpace.s12),
          child,
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NetLearnSpace.s10,
        vertical: NetLearnSpace.s6,
      ),
      decoration: BoxDecoration(
        color: context.raisedSurface,
        borderRadius: BorderRadius.circular(NetLearnRadius.pill),
        border: Border.all(color: context.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.mutedText),
          const SizedBox(width: NetLearnSpace.s6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: NetLearnSpace.s4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.mutedText,
          ),
        ),
      ],
    );
  }
}

class _TaskQuestionsList extends ConsumerWidget {
  final String taskId;
  final VoidCallback onManage;

  const _TaskQuestionsList({
    required this.taskId,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final questionsAsync = ref.watch(lecturerQuestionsProvider(taskId));

    return questionsAsync.when(
      loading: () => const NlSkeletonList(
        itemCount: 3,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: NetLearnSpace.s8),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(NetLearnSpace.s16),
        child: Text(
          l10n.failedToLoadQuestions,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
      data: (questions) {
        if (questions.isEmpty) {
          return NlEmptyState(
            icon: Icons.help_outline,
            title: l10n.noQuestions,
            message: l10n.noQuestionsDescription,
            actionLabel: l10n.addQuestion,
            onAction: onManage,
          );
        }

        return Column(
          children: [
            for (int i = 0; i < questions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: NetLearnSpace.s10),
                child: _TaskQuestionCard(
                  question: questions[i],
                  index: i + 1,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TaskQuestionCard extends StatelessWidget {
  final LecturerQuestion question;
  final int index;

  const _TaskQuestionCard({
    required this.question,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(NetLearnSpace.s16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.accentTint,
                  borderRadius: BorderRadius.circular(NetLearnRadius.sm),
                ),
                child: Text(
                  '$index',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: context.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: NetLearnSpace.s12),
              Expanded(
                child: Text(
                  question.questionText,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!question.hasAnswerKey)
                Tooltip(
                  message: l10n.noAnswerKey,
                  child: Icon(
                    Icons.key_off_outlined,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: NetLearnSpace.s12),
          for (final letter in ['A', 'B', 'C', 'D'])
            Padding(
              padding: const EdgeInsets.only(bottom: NetLearnSpace.s6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: question.correctAnswer == letter
                          ? context.accent
                          : context.raisedSurface,
                      borderRadius: BorderRadius.circular(NetLearnRadius.sm),
                      border: Border.all(
                        color: question.correctAnswer == letter
                            ? Colors.transparent
                            : context.border,
                      ),
                    ),
                    child: Text(
                      letter,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: question.correctAnswer == letter
                            ? theme.colorScheme.onPrimary
                            : context.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        fontFamily: AppTheme.displayFontFamily,
                      ),
                    ),
                  ),
                  const SizedBox(width: NetLearnSpace.s8),
                  Expanded(
                    child: Text(
                      _getOptionText(question, letter),
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.5,
                        fontWeight: question.correctAnswer == letter
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: question.correctAnswer == letter
                            ? context.accent
                            : context.onSurface,
                      ),
                    ),
                  ),
                  if (question.correctAnswer == letter)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: context.accent,
                    ),
                ],
              ),
          ),
        ],
      ),
    );
  }

  String _getOptionText(LecturerQuestion question, String letter) {
    switch (letter) {
      case 'A':
        return question.optionA;
      case 'B':
        return question.optionB;
      case 'C':
        return question.optionC;
      default:
        return question.optionD;
    }
  }
}