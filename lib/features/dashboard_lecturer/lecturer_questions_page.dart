import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/language_controller.dart';
import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_empty_state.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/nl_topbar.dart';
import 'ai_question_generator_dialog.dart';
import 'lecturer_assessments_controller.dart';
import 'lecturer_bottom_navbar.dart';

/// The four multiple-choice options a question must all define.
///
/// The `questions.option_a..option_d` columns are NOT NULL, so a question with a
/// missing option cannot be inserted at all. Keeping the letter in the model
/// rather than indexing a list means the editor, the card and the answer key all
/// speak the same vocabulary.
const answerLetters = ['A', 'B', 'C', 'D'];

/// The question list of one assessment.
///
/// Layout reference: Figma `62:229` -- the header names the assessment
/// ("Assessment Questions — Pretest"), an Add Question action sits at the top of
/// the list, and each question is a card with its options and the correct one
/// marked.
///
/// Adding and editing happen on [LecturerQuestionFormPage] rather than in a
/// modal sheet, which is what the design's Add Question frames (`62:465` /
/// `62:672`) show; this page owns the list, the reordering and the delete
/// confirmation only.
class LecturerQuestionsPage extends ConsumerWidget {
  final String quizId;

  const LecturerQuestionsPage({
    super.key,
    required this.quizId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final questions = ref.watch(lecturerQuestionsProvider(quizId));

    // The design's header (`62:229`) is "Assessment Questions — Pretest", so it
    // names the assessment being edited rather than a bare "Manage Questions".
    // The title comes from the assessments list the lecturer already loaded;
    // until that resolves (or if it is not readable) it falls back to the plain
    // heading instead of inventing a name.
    final assessments = ref.watch(lecturerAssessmentsProvider).value;
    String? assessmentTitle;

    if (assessments != null) {
      for (final assessment in assessments) {
        if (assessment.id == quizId) {
          assessmentTitle = assessment.title;
          break;
        }
      }
    }

    final title = assessmentTitle == null || assessmentTitle.isEmpty
        ? l10n.manageQuestions
        : '${l10n.assessmentQuestions} — $assessmentTitle';

    return Scaffold(
      backgroundColor: context.background,

      appBar: NlTopBar(
        title: title,
        onBack: () => goBack(context, fallback: '/lecturer/assessments'),
      ),

      body: questions.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        error: (error, stackTrace) => Center(
          child: Padding(
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

                Text(
                  l10n.failedToLoad,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: NetLearnSpace.s12),

                OutlinedButton(
                  onPressed: () {
                    ref.invalidate(
                      lecturerQuestionsProvider(quizId),
                    );
                  },
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),

        data: (items) {
          return RefreshIndicator(
            color: context.accent,
            onRefresh: () async {
              ref.invalidate(lecturerQuestionsProvider(quizId));

              await ref.read(
                lecturerQuestionsProvider(quizId).future,
              );
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                NetLearnSpace.s20,
                NetLearnSpace.s16,
                NetLearnSpace.s20,
                NetLearnSpace.s32,
              ),
              children: [
                // The design's `questions` screen carries the add action at the
                // top of the list, not as a floating button, so it sits with the
                // content it appends to and cannot cover the last question.
                Row(
                  children: [
                    Expanded(
                      child: NlButton(
                        label: l10n.addQuestion,
                        icon: Icons.add,
                        onPressed: () => _openForm(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFF8C52FF)),
                        label: const Text('Buat Soal AI', style: TextStyle(color: Color(0xFF8C52FF), fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF8C52FF), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          AiQuestionGeneratorDialog.show(
                            context,
                            quizId: quizId,
                            currentQuestionCount: items.length,
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: NetLearnSpace.s16),

                if (items.isEmpty)
                  NlEmptyState(
                    icon: Icons.help_outline,
                    title: l10n.noQuestions,
                    message: l10n.noQuestionsDescription,
                    actionLabel: l10n.addQuestion,
                    onAction: () => _openForm(context),
                  )
                else
                  for (final entry in items.asMap().entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _QuestionCard(
                        question: entry.value,
                        languageCode: ref.watch(
                          languageProvider,
                        ).languageCode,
                        onEdit: () => _openForm(
                          context,
                          question: entry.value,
                        ),
                        onDelete: () {
                          _confirmDelete(context, ref, entry.value);
                        },
                        // Null at the boundaries disables the control instead of
                        // letting a tap send a no-op write.
                        onMoveUp: entry.key == 0
                            ? null
                            : () {
                                _move(context, ref, items, entry.key, -1);
                              },
                        onMoveDown: entry.key == items.length - 1
                            ? null
                            : () {
                                _move(context, ref, items, entry.key, 1);
                              },
                      ),
                    ),
              ],
            ),
          );
        },
      ),

      bottomNavigationBar: const LecturerBottomNavbar(
        currentIndex: 3,
      ),
    );
  }

  /// Opens the add/edit page for this assessment.
  ///
  /// The page writes the row itself and the controller invalidates this list, so
  /// nothing is returned through the pop.
  Future<void> _openForm(
    BuildContext context, {
    LecturerQuestion? question,
  }) {
    final path = question == null
        ? '/lecturer/assessments/$quizId/questions/create'
        : '/lecturer/assessments/$quizId/questions/${question.id}/edit';

    return context.push(path);
  }

  /// Moves one question by [delta] positions (`-1` up, `1` down).
  ///
  /// Reordering swaps the two questions' `order_index` values. There is no
  /// optimistic local move: the list re-sorts from the refetched provider, so a
  /// failed write leaves the on-screen order untouched instead of showing a move
  /// that never happened.
  Future<void> _move(
    BuildContext context,
    WidgetRef ref,
    List<LecturerQuestion> items,
    int index,
    int delta,
  ) async {
    final target = index + delta;

    if (target < 0 || target >= items.length) {
      return;
    }

    // Captured before the await: reading it afterwards would be a BuildContext
    // use across an async gap.
    final l10n = AppLocalizations.of(context)!;

    try {
      await swapQuestionOrder(ref, quizId, items[index], items[target]);
    } on AssessmentWriteException {
      if (!context.mounted) {
        return;
      }

      NlSnackBar.show(
        context,
        l10n.questionSaveFailed,
        tone: NlSnackTone.error,
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    LecturerQuestion question,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteQuestion),
          content: Text(l10n.deleteQuestionConfirmBody),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(l10n.deleteQuestion),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await deleteQuestion(ref, quizId, question.id);

      if (!context.mounted) {
        return;
      }

      NlSnackBar.show(
        context,
        l10n.questionDeleted,
        tone: NlSnackTone.success,
      );
    } on AssessmentWriteException catch (error) {
      if (!context.mounted) {
        return;
      }

      NlSnackBar.show(
        context,
        error.failure == AssessmentWriteFailure.notPermitted
            ? l10n.notPermittedError
            : l10n.questionSaveFailed,
        tone: NlSnackTone.error,
      );
    }
  }
}

class _QuestionCard extends StatelessWidget {
  final LecturerQuestion question;
  final String languageCode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Null disables the corresponding arrow (the question is already at that end
  /// of the list).
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const _QuestionCard({
    required this.question,
    required this.languageCode,
    required this.onEdit,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  /// Picks the localized question text, falling back to the base column the way
  /// `MaterialModel.localizedTitle` does: the base column is the Indonesian
  /// copy, so it serves as the last resort for both locales.
  String _localized(String localized, String base) {
    final value = localized.trim();

    return value.isNotEmpty ? value : base;
  }

  String get _questionText {
    if (languageCode == 'id') {
      return _localized(question.questionTextId, question.questionText);
    }

    return _localized(question.questionTextEn, question.questionText);
  }

  /// The other language's wording, shown under the localized question the way
  /// the design's question card does.
  ///
  /// Blank when the other language has no copy yet, so an untranslated question
  /// does not repeat itself on a second, identical line.
  String get _secondaryQuestionText {
    final other = languageCode == 'id'
        ? _localized(question.questionTextEn, question.questionText)
        : _localized(question.questionTextId, question.questionText);

    return other == _questionText ? '' : other;
  }

  String _optionText(String letter) {
    String baseFor(String letter) => switch (letter) {
          'A' => question.optionA,
          'B' => question.optionB,
          'C' => question.optionC,
          _ => question.optionD,
        };

    String localizedFor(String letter) => switch (letter) {
          'A' => question.optionAId,
          'B' => question.optionBId,
          'C' => question.optionCId,
          _ => question.optionDId,
        };

    String localizedEnFor(String letter) => switch (letter) {
          'A' => question.optionAEn,
          'B' => question.optionBEn,
          'C' => question.optionCEn,
          _ => question.optionDEn,
        };

    final localized = languageCode == 'id'
        ? localizedFor(letter)
        : localizedEnFor(letter);

    return _localized(localized, baseFor(letter));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final hasAnswerKey = question.hasAnswerKey;
    final secondary = _secondaryQuestionText;

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
          // Section heading: "Soal X" plus the reorder arrows. The numbering is
          // the stored `order_index`, so a save that renumbers is reflected here
          // on the next refetch rather than faked locally.
          Row(
            children: [
              Icon(Icons.help_outline, size: 15, color: context.mutedText),
              const SizedBox(width: NetLearnSpace.s8),
              Expanded(
                child: Text(
                  l10n.questionNumber(question.orderIndex),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.sectionHeadingStyle,
                ),
              ),
              IconButton(
                onPressed: onMoveUp,
                icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                tooltip: l10n.moveUp,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onMoveDown,
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                tooltip: l10n.moveDown,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          const SizedBox(height: NetLearnSpace.s8),

          // Question text, with the other language underneath so a lecturer can
          // spot a question that was only ever written in one of them.
          Text(
            _questionText,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),

          if (secondary.isNotEmpty) ...[
            const SizedBox(height: NetLearnSpace.s6),

            Text(
              secondary,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.mutedText,
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: NetLearnSpace.s16),

          // Options
          for (final letter in answerLetters)
            _OptionRow(
              letter: letter,
              text: _optionText(letter),
              isCorrect: question.correctAnswer == letter,
              hasAnswerKey: hasAnswerKey,
            ),

          const SizedBox(height: NetLearnSpace.s16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.edit),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.accent,
                    side: BorderSide(color: context.accent),
                    padding: const EdgeInsets.symmetric(
                      horizontal: NetLearnSpace.s16,
                      vertical: NetLearnSpace.s12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(NetLearnRadius.button),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: NetLearnSpace.s12),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(l10n.delete),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                    padding: const EdgeInsets.symmetric(
                      horizontal: NetLearnSpace.s16,
                      vertical: NetLearnSpace.s12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(NetLearnRadius.button),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String letter;
  final String text;
  final bool isCorrect;
  final bool hasAnswerKey;

  const _OptionRow({
    required this.letter,
    required this.text,
    required this.isCorrect,
    required this.hasAnswerKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: NetLearnSpace.s10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Letter badge
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCorrect ? context.accent : context.raisedSurface,
              borderRadius: BorderRadius.circular(NetLearnRadius.sm),
              border: Border.all(
                color: isCorrect ? Colors.transparent : context.border,
              ),
            ),
            child: Text(
              letter,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isCorrect
                    ? theme.colorScheme.onPrimary
                    : context.onSurface,
                fontWeight: FontWeight.w700,
                fontFamily: AppTheme.displayFontFamily,
                fontSize: 11,
              ),
            ),
          ),

          const SizedBox(width: NetLearnSpace.s10),

          // Option text
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.5,
                fontWeight: isCorrect ? FontWeight.w600 : FontWeight.w400,
                color: isCorrect ? context.accent : context.onSurface,
              ),
            ),
          ),

          // Correct indicator
          if (isCorrect && hasAnswerKey)
            Padding(
              padding: const EdgeInsets.only(left: NetLearnSpace.s8),
              child: Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: context.accent,
              ),
            ),

          // No answer key warning
          if (!hasAnswerKey && letter == 'A')
            Padding(
              padding: const EdgeInsets.only(left: NetLearnSpace.s8),
              child: Tooltip(
                message: AppLocalizations.of(context)!.noAnswerKey,
                child: Icon(
                  Icons.key_off_outlined,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
