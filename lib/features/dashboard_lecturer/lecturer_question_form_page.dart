import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_field.dart';
import '../../shared/widgets/nl_section_heading.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/nl_topbar.dart';
import 'lecturer_assessments_controller.dart';
import 'lecturer_bottom_navbar.dart';
import 'lecturer_questions_page.dart' show answerLetters;

/// Add / edit one question of an assessment.
///
/// Layout reference: Figma `62:465` (`Add Question`) and `62:672` (`Add Question
/// 2`). Both frames were read through the Figma MCP and returned the *same*
/// structure -- question text in Indonesian and English stacked, "Options &
/// answer key" with a per-option "Correct answers" radio and an Indonesian +
/// English field each, then one explanation and "Save Question". `62:672` is a
/// duplicate of the same screen rather than a second step, so only one page is
/// implemented.
///
/// The bilingual fields are stacked here instead of the single-language toggle
/// the material and task forms use, because that is what the two frames show;
/// the toggle hid half the question behind a tap.
///
/// Two fields the frames do not show are kept because the model and the list
/// need them: the order index (the list reorders by it) and the optional image
/// URL (the student side renders it). Everything else matches the frames.
///
/// [questionId] is null when adding. When editing, the question is resolved
/// from the cached list for [quizId] rather than passed as a route argument, so
/// a restored route cannot show one assessment's list next to another's
/// question. A question that is no longer in the list says so instead of
/// silently turning into an Add form that would quietly insert a duplicate.
class LecturerQuestionFormPage extends ConsumerStatefulWidget {
  final String quizId;
  final String? questionId;

  const LecturerQuestionFormPage({
    super.key,
    required this.quizId,
    this.questionId,
  });

  bool get isEditing => questionId != null;

  @override
  ConsumerState<LecturerQuestionFormPage> createState() =>
      _LecturerQuestionFormPageState();
}

class _LecturerQuestionFormPageState
    extends ConsumerState<LecturerQuestionFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _orderIndex;
  late final TextEditingController _questionTextId;
  late final TextEditingController _questionTextEn;
  late final TextEditingController _imageUrl;

  final _optionId = <String, TextEditingController>{
    for (final letter in answerLetters) letter: TextEditingController(),
  };

  final _optionEn = <String, TextEditingController>{
    for (final letter in answerLetters) letter: TextEditingController(),
  };

  /// Empty until the lecturer picks one. `question_keys.correct_answer` is
  /// nullable, but the quiz trigger treats a keyless question as unpublished
  /// content, so the form makes the choice mandatory.
  String? _correctAnswer;

  /// The question being edited, once the list has resolved [questionId].
  LecturerQuestion? _existing;

  bool _loading = false;
  bool _loadFailed = false;
  bool _notFound = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _orderIndex = TextEditingController();
    _questionTextId = TextEditingController();
    _questionTextEn = TextEditingController();
    _imageUrl = TextEditingController();

    if (widget.isEditing) {
      _loading = true;
      _loadQuestion();
    } else {
      _orderIndex.text = '${_nextOrderIndex()}';
    }
  }

  @override
  void dispose() {
    _orderIndex.dispose();
    _questionTextId.dispose();
    _questionTextEn.dispose();
    _imageUrl.dispose();

    for (final controller in _optionId.values) {
      controller.dispose();
    }

    for (final controller in _optionEn.values) {
      controller.dispose();
    }

    super.dispose();
  }

  /// Reads the already-cached list to pick the next order index.
  ///
  /// If the list has not loaded yet this returns 1 rather than waiting, so the
  /// form still opens immediately; the lecturer can change the order in the
  /// form, and a duplicated `order_index` is only a sort-order nit, not a
  /// constraint violation.
  int _nextOrderIndex() {
    final questions = ref.read(
      lecturerQuestionsProvider(widget.quizId),
    ).value;

    if (questions == null || questions.isEmpty) {
      return 1;
    }

    return questions
            .map((question) => question.orderIndex)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  Future<void> _loadQuestion() async {
    try {
      final questions = await ref.read(
        lecturerQuestionsProvider(widget.quizId).future,
      );

      if (!mounted) {
        return;
      }

      LecturerQuestion? existing;

      for (final question in questions) {
        if (question.id == widget.questionId) {
          existing = question;
          break;
        }
      }

      setState(() {
        _loading = false;
        _loadFailed = false;
        _notFound = existing == null;
        _existing = existing;

        // Filled inside the same setState as `_correctAnswer`, or the radio row
        // would render once with no key selected and never rebuild: the text
        // controllers notify their fields, but nothing would notify the radios.
        if (existing != null) {
          _fillFrom(existing);
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _loadFailed = true;
        _notFound = false;
      });
    }
  }

  /// Drops the stored values into the controllers.
  ///
  /// Call only from inside a `setState`: it sets [_correctAnswer] as well as the
  /// text controllers, so it has to be part of the same rebuild.
  void _fillFrom(LecturerQuestion question) {
    _orderIndex.text = '${question.orderIndex}';
    _questionTextId.text = question.questionTextId;
    _questionTextEn.text = question.questionTextEn;
    _imageUrl.text = question.imageUrl ?? '';

    _optionId['A']!.text = question.optionAId;
    _optionId['B']!.text = question.optionBId;
    _optionId['C']!.text = question.optionCId;
    _optionId['D']!.text = question.optionDId;

    _optionEn['A']!.text = question.optionAEn;
    _optionEn['B']!.text = question.optionBEn;
    _optionEn['C']!.text = question.optionCEn;
    _optionEn['D']!.text = question.optionDEn;

    _correctAnswer = question.hasAnswerKey ? question.correctAnswer : null;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;

    if (_correctAnswer == null) {
      NlSnackBar.show(
        context,
        l10n.pickAnswerKey,
        tone: NlSnackTone.warning,
      );

      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final existing = _existing;

    final question = LecturerQuestion(
      id: existing?.id ?? '',
      quizId: widget.quizId,
      orderIndex: int.tryParse(_orderIndex.text.trim()) ?? 1,

      // The base columns hold the Indonesian copy; leaving them as the loaded
      // value lets `_questionColumns` keep filling `question_text` and the four
      // base options from the Indonesian text the way it always has.
      questionText: existing?.questionText ?? '',
      questionTextId: _questionTextId.text,
      questionTextEn: _questionTextEn.text,

      optionA: existing?.optionA ?? '',
      optionB: existing?.optionB ?? '',
      optionC: existing?.optionC ?? '',
      optionD: existing?.optionD ?? '',

      optionAId: _optionId['A']!.text,
      optionBId: _optionId['B']!.text,
      optionCId: _optionId['C']!.text,
      optionDId: _optionId['D']!.text,

      optionAEn: _optionEn['A']!.text,
      optionBEn: _optionEn['B']!.text,
      optionCEn: _optionEn['C']!.text,
      optionDEn: _optionEn['D']!.text,

      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),

      correctAnswer: _correctAnswer,
    );

    setState(() {
      _saving = true;
    });

    try {
      if (widget.isEditing) {
        await updateQuestion(ref, widget.quizId, question);
      } else {
        await createQuestion(ref, widget.quizId, question);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      NlSnackBar.show(
        context,
        widget.isEditing ? l10n.questionUpdated : l10n.questionAdded,
        tone: NlSnackTone.success,
      );

      _close();
    } on AssessmentWriteException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      NlSnackBar.show(
        context,
        switch (error.failure) {
          AssessmentWriteFailure.quizIncomplete =>
            l10n.assessmentQuizIncomplete,
          AssessmentWriteFailure.notPermitted => l10n.notPermittedError,
          AssessmentWriteFailure.missingAnswerKey ||
          AssessmentWriteFailure.unknown =>
            l10n.questionSaveFailed,
        },
        tone: NlSnackTone.error,
      );
    }
  }

  String get _questionsPath =>
      '/lecturer/assessments/${widget.quizId}/questions';

  void _close() {
    goBack(context, fallback: _questionsPath);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.background,

      appBar: NlTopBar(
        title: widget.isEditing ? l10n.editQuestion : l10n.addQuestion,
        onBack: _close,
      ),

      body: _buildBody(l10n),

      bottomNavigationBar: const LecturerBottomNavbar(
        currentIndex: 3,
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_notFound) {
      return NlErrorView(
        message: l10n.questionNotFound,
        onRetry: () {
          setState(() {
            _loading = true;
            _notFound = false;
          });

          ref.invalidate(lecturerQuestionsProvider(widget.quizId));
          _loadQuestion();
        },
      );
    }

    if (_loadFailed) {
      return NlErrorView(
        message: l10n.failedToLoad,
        onRetry: () {
          setState(() {
            _loading = true;
            _loadFailed = false;
          });

          ref.invalidate(lecturerQuestionsProvider(widget.quizId));
          _loadQuestion();
        },
      );
    }

    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          NetLearnSpace.s20,
          NetLearnSpace.s16,
          NetLearnSpace.s20,
          NetLearnSpace.s32,
        ),
        children: [
          NlSectionHeading(
            title: l10n.questionText,
            leadingIcon: Icons.help_outline,
          ),

          const SizedBox(height: NetLearnSpace.s16),

          // Both languages at once, the way frames `62:465`/`62:672` lay the
          // question out -- not the one-language toggle the material form uses.
          NlField(
            label: '${l10n.questionText} (${l10n.indonesian})',
            placeholder: l10n.questionTextHint,
            controller: _questionTextId,
            keyboardType: TextInputType.multiline,
            maxLines: 4,
          ),

          const SizedBox(height: NetLearnSpace.s16),

          NlField(
            label: '${l10n.questionText} (${l10n.english})',
            placeholder: l10n.questionTextHint,
            controller: _questionTextEn,
            keyboardType: TextInputType.multiline,
            maxLines: 4,
          ),

          const SizedBox(height: NetLearnSpace.s16),

          // Not in the frames, but the list orders by it.
          NlField(
            label: l10n.orderIndex,
            placeholder: '1',
            controller: _orderIndex,
            keyboardType: TextInputType.number,
            validator: (value) {
              final parsed = int.tryParse((value ?? '').trim());

              if (parsed == null || parsed < 1) {
                return l10n.orderIndexInvalid;
              }

              return null;
            },
          ),

          const SizedBox(height: NetLearnSpace.s24),

          NlSectionHeading(
            title: l10n.answerOptionsAndKey,
            leadingIcon: Icons.checklist_rounded,
          ),

          const SizedBox(height: NetLearnSpace.s8),

          Text(
            l10n.answerKeyHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.mutedText,
            ),
          ),

          const SizedBox(height: NetLearnSpace.s12),

          RadioGroup<String>(
            groupValue: _correctAnswer,
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _correctAnswer = value;
              });
            },
            child: Column(
              children: [
                for (final letter in answerLetters) ...[
                  _OptionEditor(
                    letter: letter,
                    idController: _optionId[letter]!,
                    enController: _optionEn[letter]!,
                    isCorrect: _correctAnswer == letter,
                    onSelect: () {
                      setState(() {
                        _correctAnswer = letter;
                      });
                    },
                  ),
                  const SizedBox(height: NetLearnSpace.s12),
                ],
              ],
            ),
          ),

          const SizedBox(height: NetLearnSpace.s12),

          // Not in the frames either, but the model supports it and the student
          // side renders it.
          NlField(
            label: l10n.questionImage,
            placeholder: l10n.imageUrlHint,
            controller: _imageUrl,
            keyboardType: TextInputType.url,
          ),

          const SizedBox(height: NetLearnSpace.s32),

          Row(
            children: [
              Expanded(
                child: NlButton(
                  label: l10n.cancel,
                  variant: NlButtonVariant.outline,
                  onPressed: _saving ? null : _close,
                ),
              ),

              const SizedBox(width: NetLearnSpace.s12),

              Expanded(
                child: NlButton(
                  label: l10n.saveQuestion,
                  icon: Icons.check_rounded,
                  loading: _saving,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One answer option: the letter, the correct-answer radio and the option text
/// in Indonesian and English.
///
/// The whole card is the tap target rather than the 20dp circle, so choosing the
/// key is a full-width tap while the radio still shows which row is selected.
/// The radio reads its group from the [RadioGroup] in the form above it, which
/// is the non-deprecated way to bind `groupValue` in this Flutter version.
class _OptionEditor extends StatelessWidget {
  final String letter;
  final TextEditingController idController;
  final TextEditingController enController;
  final bool isCorrect;
  final VoidCallback onSelect;

  const _OptionEditor({
    required this.letter,
    required this.idController,
    required this.enController,
    required this.isCorrect,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(NetLearnRadius.button),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(NetLearnRadius.button),
        child: Container(
          padding: const EdgeInsets.all(NetLearnSpace.s12),
          decoration: BoxDecoration(
            color: isCorrect ? context.accentTint : context.raisedSurface,
            borderRadius: BorderRadius.circular(NetLearnRadius.button),
            border: Border.all(
              color: isCorrect ? context.accent : context.border,
              width: isCorrect ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.optionLabel(letter),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isCorrect ? context.accent : context.onSurface,
                      ),
                    ),
                  ),

                  Radio<String>(
                    value: letter,
                    activeColor: context.accent,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),

                  const SizedBox(width: NetLearnSpace.s4),

                  Text(
                    l10n.correctAnswer,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isCorrect ? context.accent : context.mutedText,
                      fontWeight: isCorrect ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),

                  if (isCorrect) ...[
                    const SizedBox(width: NetLearnSpace.s4),

                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: context.accent,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: NetLearnSpace.s4),

              NlField(
                label: l10n.indonesian,
                placeholder: l10n.optionHint,
                controller: idController,
                keyboardType: TextInputType.multiline,
                maxLines: 2,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return l10n.requiredField;
                  }

                  return null;
                },
              ),

              const SizedBox(height: NetLearnSpace.s8),

              NlField(
                label: l10n.english,
                placeholder: l10n.optionHint,
                controller: enController,
                keyboardType: TextInputType.multiline,
                maxLines: 2,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return l10n.requiredField;
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
