import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/localization/language_controller.dart';
import '../../core/supabase/supabase_client.dart';
import '../classes/class_controller.dart';
import '../classes/class_models.dart';
import 'lecturer_dashboard_controller.dart';

// ============================================================
// ASSESSMENT LIST
// ============================================================

class LecturerAssessment {
  final String id;
  final String title;
  final String titleEn;
  final String titleId;
  final String assessmentType;
  final int durationMinutes;
  final String status;
  final int questionCount;
  final int answeredCount;

  const LecturerAssessment({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.titleId,
    required this.assessmentType,
    required this.durationMinutes,
    required this.status,
    required this.questionCount,
    required this.answeredCount,
  });

  bool get isPretest => assessmentType == 'pretest';

  bool get isPublished => status == 'published';

  /// Whether the `quizzes_before_write` trigger would accept a publish.
  ///
  /// The trigger rejects `status = 'published'` unless every question has a row
  /// in `question_keys`. Recomputing it here means the button can be disabled
  /// with a reason instead of letting the lecturer submit and read a
  /// `QUIZ_INCOMPLETE` check violation.
  bool get canPublish => questionCount > 0 && answeredCount == questionCount;

  /// Questions still missing an answer key, or 0 when the assessment is not
  /// ready to publish for some other reason.
  int get unansweredCount => questionCount - answeredCount;
}

/// Visual order for the assessments list: Post-test first, then Pre-test,
/// then anything else.
///
/// The database order (`created_at`) is not the order the design shows, and
/// `assessment_type` sorts `posttest` before `pretest` only by the accident of
/// the alphabet. Ranking is explicit here so the two assessments always render
/// Post Test → Pretest regardless of row insertion order. The original index
/// breaks ties, so this is a stable sort and no assessment is dropped.
List<LecturerAssessment> orderAssessments(
  List<LecturerAssessment> assessments,
) {
  final indexed = assessments.asMap().entries.toList();

  indexed.sort((a, b) {
    final rank = _assessmentRank(a.value).compareTo(_assessmentRank(b.value));

    return rank != 0 ? rank : a.key.compareTo(b.key);
  });

  return [for (final entry in indexed) entry.value];
}

int _assessmentRank(LecturerAssessment assessment) {
  switch (assessment.assessmentType) {
    case 'posttest':
      return 0;
    case 'pretest':
      return 1;
    default:
      return 2;
  }
}

/// Every assessment, published or not.
///
/// The two assessments are global to the course rather than per module, so this
/// is a fixed, very small list. `question_keys` is fetched alongside the
/// questions in one round trip because PostgREST cannot count rows on an
/// embedded resource that RLS keeps separate.
final lecturerAssessmentsProvider =
    FutureProvider.autoDispose<List<LecturerAssessment>>((ref) async {
      final languageCode = ref.watch(languageProvider).languageCode;
      final activeClass = await resolveActiveLecturerClass(ref);
      final validClass = activeClass != null &&
          activeClass.id.isNotEmpty &&
          activeClass.id != kLegacyFallbackClassId;
      if (validClass) {
        await ensureClassGateAssessmentsExist(activeClass.id);
      }

      final response = await supabase.from('quizzes').select('''
            class_id,
            id,
            title,
            title_en,
            title_id,
            assessment_type,
            duration_minutes,
            status
          ''')
          .order('assessment_type')
          .order('created_at');

      final rawQuizzes = (response as List)
          .map(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();

      final classQuizzes = validClass
          ? rawQuizzes
              .where((q) => q['class_id']?.toString() == activeClass.id)
              .toList()
          : const <Map<String, dynamic>>[];
      final quizzes = validClass
          ? classQuizzes
          : rawQuizzes.where((q) => q['class_id'] == null).toList();
      if (quizzes.isEmpty) {
        return [];
      }

      final quizIds =
          quizzes.map((quiz) => quiz['id'].toString()).toList();

      final questionsResponse = await supabase
          .from('questions')
          .select('id, quiz_id')
          .inFilter('quiz_id', quizIds);

      final keysResponse = await supabase
          .from('question_keys')
          .select('question_id')
          .inFilter(
            'question_id',
            (questionsResponse as List)
                .map((row) => (row as Map)['id'].toString())
                .toList(),
          );

      final answeredQuestionIds = <String>{
        for (final row in keysResponse as List)
          (row as Map)['question_id'].toString(),
      };

      final totals = <String, int>{};
      final answered = <String, int>{};

      for (final row in questionsResponse) {
        final question = row as Map;
        final quizId = question['quiz_id'].toString();

        totals.update(
          quizId,
          (count) => count + 1,
          ifAbsent: () => 1,
        );

        if (answeredQuestionIds.contains(question['id'].toString())) {
          answered.update(
            quizId,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }

      return quizzes.map((quiz) {
        final id = quiz['id'].toString();

        return LecturerAssessment(
          id: id,
          title: quiz['title']?.toString() ?? '',
          titleEn: quiz['title_en']?.toString() ?? '',
          titleId: quiz['title_id']?.toString() ?? '',
          assessmentType:
              quiz['assessment_type']?.toString() ?? 'posttest',
          durationMinutes:
              (quiz['duration_minutes'] as num?)?.toInt() ?? 0,
          status: quiz['status']?.toString() ?? 'draft',
          questionCount: totals[id] ?? 0,
          answeredCount: answered[id] ?? 0,
        );
      }).map(
            // The base `title` column is NOT NULL and holds the Indonesian copy,
            // so it is the fallback for both locales -- same order as
            // MaterialModel.localizedTitle.
            (assessment) => _localizedAssessment(
              assessment,
              languageCode,
            ),
          )
          .toList();
    });

LecturerAssessment _localizedAssessment(
  LecturerAssessment assessment,
  String languageCode,
) {
  String pick(
    String localized,
    String fallback,
  ) {
    final value = localized.trim();

    return value.isNotEmpty ? value : fallback;
  }

  final title = languageCode == 'id'
      ? pick(assessment.titleId, assessment.title)
      : pick(assessment.titleEn, assessment.title);

  return LecturerAssessment(
    id: assessment.id,
    title: title,
    titleEn: assessment.titleEn,
    titleId: assessment.titleId,
    assessmentType: assessment.assessmentType,
    durationMinutes: assessment.durationMinutes,
    status: assessment.status,
    questionCount: assessment.questionCount,
    answeredCount: assessment.answeredCount,
  );
}

/// Publishes or unpublishes an assessment.
///
/// The `quizzes_before_write` trigger is the real gate: it refuses
/// `status = 'published'` while any question lacks an answer key. This only
/// refuses early with a readable reason.
Future<void> setAssessmentPublished(
  WidgetRef ref,
  LecturerAssessment assessment,
  bool published,
) async {
  if (published && !assessment.canPublish) {
    throw const AssessmentWriteException(
      AssessmentWriteFailure.missingAnswerKey,
    );
  }

  try {
    await supabase
        .from('quizzes')
        .update({'status': published ? 'published' : 'draft'})
        .eq('id', assessment.id);

    ref.invalidate(lecturerAssessmentsProvider);
    ref.invalidate(lecturerDashboardStatsProvider);
    ref.invalidate(classGateAssessmentsProvider);
    ref.invalidate(classLeaderboardQuizzesProvider);
    ref.invalidate(classLeaderboardProvider);
    ref.invalidate(lecturerClassesProvider);
  } catch (error) {
    throw mapAssessmentWriteError(error);
  }
}

// ============================================================
// QUESTIONS
// ============================================================

class LecturerQuestion {
  final String id;
  final String quizId;
  final int orderIndex;

  final String questionText;
  final String questionTextEn;
  final String questionTextId;

  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;

  final String optionAEn;
  final String optionBEn;
  final String optionCEn;
  final String optionDEn;

  final String optionAId;
  final String optionBId;
  final String optionCId;
  final String optionDId;

  final String? imageUrl;
  final String? correctAnswer;

  const LecturerQuestion({
    required this.id,
    required this.quizId,
    required this.orderIndex,
    required this.questionText,
    required this.questionTextEn,
    required this.questionTextId,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.optionAEn,
    required this.optionBEn,
    required this.optionCEn,
    required this.optionDEn,
    required this.optionAId,
    required this.optionBId,
    required this.optionCId,
    required this.optionDId,
    required this.imageUrl,
    required this.correctAnswer,
  });

  factory LecturerQuestion.fromMap(
    Map<String, dynamic> map,
  ) {
    String text(String key) => map[key]?.toString() ?? '';

    return LecturerQuestion(
      id: map['id'].toString(),
      quizId: map['quiz_id'].toString(),
      orderIndex: (map['order_index'] as num?)?.toInt() ?? 0,

      questionText: text('question_text'),
      questionTextEn: text('question_text_en'),
      questionTextId: text('question_text_id'),

      optionA: text('option_a'),
      optionB: text('option_b'),
      optionC: text('option_c'),
      optionD: text('option_d'),

      optionAEn: text('option_a_en'),
      optionBEn: text('option_b_en'),
      optionCEn: text('option_c_en'),
      optionDEn: text('option_d_en'),

      optionAId: text('option_a_id'),
      optionBId: text('option_b_id'),
      optionCId: text('option_c_id'),
      optionDId: text('option_d_id'),

      imageUrl: map['image_url']?.toString(),
      correctAnswer: map['correct_answer']?.toString(),
    );
  }

  bool get hasAnswerKey =>
      correctAnswer != null && correctAnswer!.isNotEmpty;
}

final lecturerQuestionsProvider = FutureProvider.autoDispose
    .family<List<LecturerQuestion>, String>((ref, quizId) async {
      // Only columns that actually exist on `questions`. The previous version
      // selected `explanation`, `explanation_en`, `explanation_id` and ordered
      // by `created_at` — none of which exist on the table, so PostgREST
      // answered every request with a 400 (PGRST204) and the page could never
      // leave its loading state.
      final response = await supabase
          .from('questions')
          .select('''
            id,
            quiz_id,
            order_index,

            question_text,
            question_text_en,
            question_text_id,

            option_a,
            option_b,
            option_c,
            option_d,

            option_a_en,
            option_b_en,
            option_c_en,
            option_d_en,

            option_a_id,
            option_b_id,
            option_c_id,
            option_d_id,

            image_url
          ''')
          .eq('quiz_id', quizId)
          .order('order_index');

      final questions = (response as List)
          .map(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();

      if (questions.isEmpty) {
        return [];
      }

      // Answer keys are fetched separately rather than embedded, so the choice
      // list and the key travel together into one editor round trip.
      final keysResponse = await supabase
          .from('question_keys')
          .select('question_id, correct_answer')
          .inFilter(
            'question_id',
            questions
                .map((question) => question['id'].toString())
                .toList(),
          );

      final keys = <String, String>{
        for (final row in keysResponse as List)
          (row as Map)['question_id'].toString():
              row['correct_answer']?.toString() ?? '',
      };

      return questions.map((question) {
        final id = question['id'].toString();

        return LecturerQuestion.fromMap({
          ...question,
          'correct_answer': keys[id],
        });
      }).toList();
    });

// ============================================================
// QUESTION WRITES
// ============================================================

enum AssessmentWriteFailure {
  missingAnswerKey,
  quizIncomplete,
  notPermitted,
  unknown,
}

class AssessmentWriteException implements Exception {
  final AssessmentWriteFailure failure;
  final String? detail;

  const AssessmentWriteException(this.failure, [this.detail]);

  @override
  String toString() => 'AssessmentWriteException($failure)';
}

AssessmentWriteException mapAssessmentWriteError(Object error) {
  if (error is! PostgrestException) {
    return AssessmentWriteException(
      AssessmentWriteFailure.unknown,
      error.toString(),
    );
  }

  final code = error.code ?? '';

  // `message` is non-nullable on PostgrestException, and the quiz trigger's
  // QUIZ_INCOMPLETE arrives inside it.
  final message = error.message;

  if (message.contains('QUIZ_INCOMPLETE')) {
    return AssessmentWriteException(
      AssessmentWriteFailure.quizIncomplete,
      message,
    );
  }

  if (code == '42501') {
    return AssessmentWriteException(
      AssessmentWriteFailure.notPermitted,
      message,
    );
  }

  return AssessmentWriteException(
    AssessmentWriteFailure.unknown,
    message.isEmpty ? error.toString() : message,
  );
}

/// The columns a question is made of, ready to be written.
///
/// The four base option columns and `question_text` are NOT NULL and hold the
/// Indonesian copy, so they are filled from the Indonesian text when there is
/// any and from the English text otherwise. Writing only the bilingual columns
/// produces a question that renders blank for half the app.
Map<String, dynamic> _questionColumns(
  LecturerQuestion question, {
  String? quizId,
}) {
  String base(String id, String en, String fallback) {
    final indonesian = id.trim();

    if (indonesian.isNotEmpty) {
      return indonesian;
    }

    return en.trim().isNotEmpty ? en.trim() : fallback.trim();
  }

  String? nullIfEmpty(String value) {
    final trimmed = value.trim();

    return trimmed.isEmpty ? null : trimmed;
  }

  return {
    // Null-aware entry rather than sending null: `quiz_id` is NOT NULL and an
    // UPDATE must not try to move a question to another assessment.
    'quiz_id': ?quizId,

    'order_index': question.orderIndex,

    'question_text': base(
      question.questionTextId,
      question.questionTextEn,
      question.questionText,
    ),
    'question_text_en': nullIfEmpty(question.questionTextEn),
    'question_text_id': nullIfEmpty(question.questionTextId),

    'option_a': base(
      question.optionAId,
      question.optionAEn,
      question.optionA,
    ),
    'option_b': base(
      question.optionBId,
      question.optionBEn,
      question.optionB,
    ),
    'option_c': base(
      question.optionCId,
      question.optionCEn,
      question.optionC,
    ),
    'option_d': base(
      question.optionDId,
      question.optionDEn,
      question.optionD,
    ),

    'option_a_en': nullIfEmpty(question.optionAEn),
    'option_b_en': nullIfEmpty(question.optionBEn),
    'option_c_en': nullIfEmpty(question.optionCEn),
    'option_d_en': nullIfEmpty(question.optionDEn),

    'option_a_id': nullIfEmpty(question.optionAId),
    'option_b_id': nullIfEmpty(question.optionBId),
    'option_c_id': nullIfEmpty(question.optionCId),
    'option_d_id': nullIfEmpty(question.optionDId),

    'image_url': nullIfEmpty(question.imageUrl ?? ''),
  };
}

void _invalidateQuestionReads(WidgetRef ref, String quizId) {
  ref.invalidate(lecturerQuestionsProvider(quizId));
  ref.invalidate(lecturerAssessmentsProvider);
  ref.invalidate(lecturerDashboardStatsProvider);
}

/// Creates a question together with its answer key.
///
/// The two writes are not atomic and there is no RPC to make them so. A question
/// with no key is not corrupt -- `question_keys_question_id_fkey` cascades, so
/// the next edit fills it in -- but it does block publishing through the
/// trigger. So a failed key insert removes the question again, which is the one
/// case where leaving a partial row behind would be worse than undoing work the
/// lecturer just did.
Future<String> createQuestion(
  WidgetRef ref,
  String quizId,
  LecturerQuestion question,
) async {
  String questionId;

  try {
    final response = await supabase
        .from('questions')
        .insert(_questionColumns(question, quizId: quizId))
        .select('id')
        .single();

    questionId = response['id'].toString();
  } catch (error) {
    throw mapAssessmentWriteError(error);
  }

  try {
    await supabase.from('question_keys').insert({
      'question_id': questionId,
      'correct_answer': question.correctAnswer,
    });
  } catch (error) {
    await supabase
        .from('questions')
        .delete()
        .eq('id', questionId);

    _invalidateQuestionReads(ref, quizId);

    throw mapAssessmentWriteError(error);
  }

  _invalidateQuestionReads(ref, quizId);

  return questionId;
}

/// Saves an edited question and its answer key.
Future<void> updateQuestion(
  WidgetRef ref,
  String quizId,
  LecturerQuestion question,
) async {
  try {
    await supabase
        .from('questions')
        .update(_questionColumns(question))
        .eq('id', question.id);

    final answer = question.correctAnswer;

    if (answer == null || answer.isEmpty) {
      // `question_keys_question_id_fkey` is ON DELETE CASCADE, so clearing the
      // key is a delete rather than an update to an empty string.
      await supabase
          .from('question_keys')
          .delete()
          .eq('question_id', question.id);
    } else {
      await supabase.from('question_keys').upsert({
        'question_id': question.id,
        'correct_answer': answer,
      });
    }

    _invalidateQuestionReads(ref, quizId);
  } catch (error) {
    throw mapAssessmentWriteError(error);
  }
}

/// Swaps the `order_index` of two questions.
///
/// Reordering is a swap rather than a renumber so a single move is two small
/// updates on the two affected rows, not a rewrite of the whole list. The two
/// values are exchanged in memory first: writing `a` then reading `b` would
/// otherwise send `a`'s old index back for `b` only if the caller got the
/// arguments the wrong way round, and this keeps the intent explicit.
Future<void> swapQuestionOrder(
  WidgetRef ref,
  String quizId,
  LecturerQuestion first,
  LecturerQuestion second,
) async {
  try {
    await supabase
        .from('questions')
        .update({'order_index': second.orderIndex})
        .eq('id', first.id);

    await supabase
        .from('questions')
        .update({'order_index': first.orderIndex})
        .eq('id', second.id);

    _invalidateQuestionReads(ref, quizId);
  } catch (error) {
    throw mapAssessmentWriteError(error);
  }
}

/// Deletes a question.
///
/// The key goes with it through the cascade. So do the student's recorded
/// answers -- `quiz_answers_question_id_fkey` is also ON DELETE CASCADE -- which
/// the confirmation dialog says out loud, because that is not a detail a
/// lecturer can undo.
Future<void> deleteQuestion(
  WidgetRef ref,
  String quizId,
  String questionId,
) async {
  try {
    await supabase
        .from('questions')
        .delete()
        .eq('id', questionId);

    _invalidateQuestionReads(ref, quizId);
  } catch (error) {
    throw mapAssessmentWriteError(error);
  }
}

// ============================================================
// TASKS (assessment_type = 'task')
// ============================================================

class LecturerTask {
  final String id;
  final String title;
  final String titleEn;
  final String titleId;
  final String assessmentType;
  final int durationMinutes;
  final String status;
  final int questionCount;
  final int answeredCount;
  final int? module;
  final String? description;
  final String? descriptionEn;
  final String? descriptionId;
  final String? instructions;
  final String? instructionsEn;
  final String? instructionsId;
  final int timeLimit;
  final DateTime? deadline;
  final int submittedCount;
  final bool required;
  final bool leaderboardEnabled;
  final int attemptsAllowed;
  final double weight;

  /// Number of students the task is assigned to, or null when that is not
  /// derivable from the data the lecturer can read.
  ///
  /// It used to be hardcoded to 30, which made the "submission rate" a made-up
  /// number. `enrollments` is empty for every lecturer here and `quizzes` has no
  /// per-task audience column, so there is genuinely nothing to count per task;
  /// null renders as "unavailable" rather than as a confident wrong figure.
  final int? studentsCount;

  const LecturerTask({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.titleId,
    required this.assessmentType,
    required this.durationMinutes,
    required this.status,
    required this.questionCount,
    required this.answeredCount,
    this.module,
    this.description,
    this.descriptionEn,
    this.descriptionId,
    this.instructions,
    this.instructionsEn,
    this.instructionsId,
    required this.timeLimit,
    this.deadline,
    required this.submittedCount,
    this.studentsCount,
    this.required = false,
    this.leaderboardEnabled = true,
    this.attemptsAllowed = 1,
    this.weight = 1.0,
  });

  bool get isPublished => status == 'published';

  bool get isTask => assessmentType == 'task';

  String get localizedTitle {
    final languageCode = 'id'; // Will be overridden by provider
    if (languageCode == 'id') {
      return (descriptionId?.trim().isNotEmpty == true) ? descriptionId! : (description?.trim().isNotEmpty == true ? description! : title);
    }
    return titleEn.trim().isNotEmpty ? titleEn : title;
  }

  String get localizedDescription {
    final languageCode = 'id';
    if (languageCode == 'id') {
      return descriptionId?.trim().isNotEmpty == true ? descriptionId! : (description?.trim().isNotEmpty == true ? description! : '');
    }
    return descriptionEn?.trim().isNotEmpty == true ? descriptionEn! : (description?.trim().isNotEmpty == true ? description! : '');
  }

  String get localizedInstructions {
    final languageCode = 'id';
    if (languageCode == 'id') {
      return instructionsId?.trim().isNotEmpty == true ? instructionsId! : (instructions?.trim().isNotEmpty == true ? instructions! : '');
    }
    return instructionsEn?.trim().isNotEmpty == true ? instructionsEn! : (instructions?.trim().isNotEmpty == true ? instructions! : '');
  }
}

LecturerTask _localizedTask(LecturerTask task, String languageCode) {
  String pick(String localized, String fallback) {
    final value = localized.trim();
    return value.isNotEmpty ? value : fallback;
  }

  final title = languageCode == 'id'
      ? pick(task.titleId, task.title)
      : pick(task.titleEn, task.title);

  final description = languageCode == 'id'
      ? pick(task.descriptionId ?? '', task.description ?? '')
      : pick(task.descriptionEn ?? '', task.description ?? '');

  final instructions = languageCode == 'id'
      ? pick(task.instructionsId ?? '', task.instructions ?? '')
      : pick(task.instructionsEn ?? '', task.instructions ?? '');

  return LecturerTask(
    id: task.id,
    title: title,
    titleEn: task.titleEn,
    titleId: task.titleId,
    assessmentType: task.assessmentType,
    durationMinutes: task.durationMinutes,
    status: task.status,
    questionCount: task.questionCount,
    answeredCount: task.answeredCount,
    module: task.module,
    description: description,
    descriptionEn: task.descriptionEn,
    descriptionId: task.descriptionId,
    instructions: instructions,
    instructionsEn: task.instructionsEn,
    instructionsId: task.instructionsId,
    timeLimit: task.timeLimit,
    deadline: task.deadline,
    submittedCount: task.submittedCount,
    studentsCount: task.studentsCount,
    required: task.required,
    leaderboardEnabled: task.leaderboardEnabled,
    attemptsAllowed: task.attemptsAllowed,
    weight: task.weight,
  );
}

/// Helper to parse deadline from column or instruction comment
DateTime? _parseDeadline(Map<String, dynamic> quiz) {
  if (quiz['deadline'] != null) {
    return DateTime.tryParse(quiz['deadline'].toString())?.toLocal();
  }
  final instructions = quiz['instructions']?.toString() ??
      quiz['instructions_id']?.toString() ??
      quiz['instructions_en']?.toString();
  if (instructions != null && instructions.contains('<!--meta:deadline=')) {
    final match = RegExp(r'<!--meta:deadline=([^>]+)-->').firstMatch(instructions);
    if (match != null) {
      return DateTime.tryParse(match.group(1)!)?.toLocal();
    }
  }
  return null;
}

/// Helper to remove meta comments from instructions for display
String? _cleanInstructions(String? raw) {
  if (raw == null) return null;
  final cleaned = raw.replaceAll(RegExp(r'\s*<!--meta:[^>]+-->'), '').trim();
  return cleaned.isEmpty ? null : cleaned;
}

/// All tasks (assessment_type = 'task' or custom LMS tasks), published or draft.
final lecturerTasksProvider = FutureProvider.autoDispose<List<LecturerTask>>((ref) async {
  try {
    final languageCode = ref.watch(languageProvider).languageCode;
    final activeClass = await resolveActiveLecturerClass(ref);
    final validClass = activeClass != null &&
        activeClass.id.isNotEmpty &&
        !activeClass.isLegacyFallback;

    List<dynamic> response = const [];
    try {
      var query = supabase.from('quizzes').select('''
            id,
            title,
            title_en,
            title_id,
            assessment_type,
            duration_minutes,
            status,
            module,
            description,
            description_en,
            description_id,
            instructions,
            instructions_en,
            instructions_id,
            time_limit,
            deadline,
            required,
            leaderboard_enabled,
            attempts_allowed,
            weight,
            class_id,
            created_at
          ''');

      if (validClass) {
        query = query.eq('class_id', activeClass.id);
      }

      response = await query.order('created_at');
    } catch (e1) {
      debugPrint('lecturerTasksProvider full query error ($e1), attempting fallback query');
      try {
        var fallbackQuery = supabase.from('quizzes').select('''
              id,
              title,
              title_en,
              title_id,
              assessment_type,
              duration_minutes,
              status,
              class_id,
              created_at
            ''');

        if (validClass) {
          fallbackQuery = fallbackQuery.eq('class_id', activeClass.id);
        }

        response = await fallbackQuery.order('created_at');
      } catch (e2) {
        debugPrint('lecturerTasksProvider fallback failed: $e2');
        return const <LecturerTask>[];
      }
    }

    final rawQuizzes = response
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    // A quiz belongs in Custom Tasks & Quizzes if:
    // 1. assessment_type == 'task'
    // 2. OR instructions / description has tag <!--type:task-->
    // 3. OR module is not null (module checkpoint quiz)
    // 4. In a class context, any quiz that is not a pretest/posttest gate
    final quizzes = rawQuizzes.where((quiz) {
      final type = quiz['assessment_type']?.toString();
      final instructions = quiz['instructions']?.toString() ?? '';
      final description = quiz['description']?.toString() ?? '';
      if (type == 'task') return true;
      if (instructions.contains('<!--type:task-->') || description.contains('<!--type:task-->')) {
        return true;
      }
      if (quiz['module'] != null) return true;
      return false;
    }).toList();

    if (quizzes.isEmpty) {
      return const <LecturerTask>[];
    }

    final quizIds = quizzes.map((quiz) => quiz['id'].toString()).toList();

    final totals = <String, int>{};
    final answered = <String, int>{};

    try {
      final questionsResponse = await supabase
          .from('questions')
          .select('id, quiz_id')
          .inFilter('quiz_id', quizIds);

      final questionIds = (questionsResponse as List)
          .map((row) => (row as Map)['id'].toString())
          .toList();

      final answeredQuestionIds = <String>{};
      if (questionIds.isNotEmpty) {
        try {
          final keysResponse = await supabase
              .from('question_keys')
              .select('question_id')
              .inFilter('question_id', questionIds);

          for (final row in keysResponse as List) {
            answeredQuestionIds.add((row as Map)['question_id'].toString());
          }
        } catch (_) {}
      }

      for (final row in questionsResponse) {
        final question = row as Map;
        final quizId = question['quiz_id'].toString();
        totals.update(quizId, (count) => count + 1, ifAbsent: () => 1);
        if (answeredQuestionIds.contains(question['id'].toString())) {
          answered.update(quizId, (count) => count + 1, ifAbsent: () => 1);
        }
      }
    } catch (e) {
      debugPrint('lecturerTasksProvider questions fetch error: $e');
    }

    // Fetch attempt counts for submitted (safely guarded against RLS)
    final submittedCounts = <String, int>{};
    try {
      final attemptsResponse = await supabase
          .from('quiz_attempts')
          .select('quiz_id')
          .inFilter('quiz_id', quizIds)
          .eq('status', 'submitted');

      for (final row in attemptsResponse as List) {
        final quizId = (row as Map)['quiz_id'].toString();
        submittedCounts.update(quizId, (count) => count + 1, ifAbsent: () => 1);
      }
    } catch (_) {}

    return quizzes.map((quiz) {
      final id = quiz['id'].toString();
      final deadline = _parseDeadline(quiz);

      return _localizedTask(LecturerTask(
        id: id,
        title: quiz['title']?.toString() ?? '',
        titleEn: quiz['title_en']?.toString() ?? '',
        titleId: quiz['title_id']?.toString() ?? '',
        assessmentType: quiz['assessment_type']?.toString() ?? 'task',
        durationMinutes: (quiz['duration_minutes'] as num?)?.toInt() ?? 0,
        status: quiz['status']?.toString() ?? 'draft',
        questionCount: totals[id] ?? 0,
        answeredCount: answered[id] ?? 0,
        module: (quiz['module'] as num?)?.toInt(),
        description: quiz['description']?.toString(),
        descriptionEn: quiz['description_en']?.toString(),
        descriptionId: quiz['description_id']?.toString(),
        instructions: _cleanInstructions(quiz['instructions']?.toString()),
        instructionsEn: quiz['instructions_en']?.toString(),
        instructionsId: quiz['instructions_id']?.toString(),
        timeLimit: (quiz['time_limit'] as num?)?.toInt() ?? 0,
        deadline: deadline,
        submittedCount: submittedCounts[id] ?? 0,
        studentsCount: null,
        required: quiz['required'] == true,
        leaderboardEnabled: quiz['leaderboard_enabled'] != false,
        attemptsAllowed: (quiz['attempts_allowed'] as num?)?.toInt() ?? 1,
        weight: (quiz['weight'] as num?)?.toDouble() ?? 1.0,
      ), languageCode);
    }).toList();
  } catch (err, st) {
    debugPrint('lecturerTasksProvider unhandled error: $err\n$st');
    return const <LecturerTask>[];
  }
});

/// Single task by ID
final lecturerTaskProvider = FutureProvider.autoDispose.family<LecturerTask?, String>((ref, taskId) async {
  final languageCode = ref.watch(languageProvider).languageCode;

  Map<String, dynamic>? quiz;
  try {
    final response = await supabase.from('quizzes').select('''
          id,
          title,
          title_en,
          title_id,
          assessment_type,
          duration_minutes,
          status,
          module,
          description,
          description_en,
          description_id,
          instructions,
          instructions_en,
          instructions_id,
          time_limit,
          deadline,
          required,
          leaderboard_enabled,
          attempts_allowed,
          weight
        ''')
        .eq('id', taskId)
        .maybeSingle();
    if (response != null) quiz = Map<String, dynamic>.from(response);
  } catch (e) {
    debugPrint('lecturerTaskProvider fallback for $taskId due to: $e');
    try {
      final response = await supabase.from('quizzes').select('''
            id,
            title,
            title_en,
            title_id,
            assessment_type,
            duration_minutes,
            status
          ''')
          .eq('id', taskId)
          .maybeSingle();
      if (response != null) quiz = Map<String, dynamic>.from(response);
    } catch (_) {
      return null;
    }
  }

  if (quiz == null) {
    return null;
  }

  // Fetch question counts
  int questionCount = 0;
  int answeredCount = 0;
  try {
    final questionsResponse = await supabase
        .from('questions')
        .select('id')
        .eq('quiz_id', taskId);

    questionCount = (questionsResponse as List).length;
    final questionIds = questionsResponse.map((row) => (row as Map)['id'].toString()).toList();

    if (questionIds.isNotEmpty) {
      final keysResponse = await supabase
          .from('question_keys')
          .select('question_id')
          .inFilter('question_id', questionIds);
      answeredCount = (keysResponse as List).length;
    }
  } catch (_) {}

  // Fetch attempt counts safely
  int submittedCount = 0;
  try {
    final attemptsResponse = await supabase
        .from('quiz_attempts')
        .select('id')
        .eq('quiz_id', taskId)
        .eq('status', 'submitted');
    submittedCount = (attemptsResponse as List).length;
  } catch (_) {}

  final deadline = _parseDeadline(quiz);

  return _localizedTask(LecturerTask(
    id: quiz['id'].toString(),
    title: quiz['title']?.toString() ?? '',
    titleEn: quiz['title_en']?.toString() ?? '',
    titleId: quiz['title_id']?.toString() ?? '',
    assessmentType: quiz['assessment_type']?.toString() ?? 'task',
    durationMinutes: (quiz['duration_minutes'] as num?)?.toInt() ?? 0,
    status: quiz['status']?.toString() ?? 'draft',
    questionCount: questionCount,
    answeredCount: answeredCount,
    module: (quiz['module'] as num?)?.toInt(),
    description: quiz['description']?.toString(),
    descriptionEn: quiz['description_en']?.toString(),
    descriptionId: quiz['description_id']?.toString(),
    instructions: _cleanInstructions(quiz['instructions']?.toString()),
    instructionsEn: quiz['instructions_en']?.toString(),
    instructionsId: quiz['instructions_id']?.toString(),
    timeLimit: (quiz['time_limit'] as num?)?.toInt() ?? 0,
    deadline: deadline,
    submittedCount: submittedCount,
    studentsCount: null,
    required: quiz['required'] == true,
    leaderboardEnabled: quiz['leaderboard_enabled'] != false,
    attemptsAllowed: (quiz['attempts_allowed'] as num?)?.toInt() ?? 1,
    weight: (quiz['weight'] as num?)?.toDouble() ?? 1.0,
  ), languageCode);
});

Future<Map<String, dynamic>> _tryInsertTask(Map<String, dynamic> initialPayload) async {
  final payload = Map<String, dynamic>.from(initialPayload);
  final optionalColumns = [
    'deadline',
    'leaderboard_enabled',
    'attempts_allowed',
    'weight',
    'required',
    'instructions_en',
    'instructions_id',
    'description_en',
    'description_id',
    'time_limit',
    'module',
    'instructions',
    'description',
    'class_id',
  ];

  for (var i = 0; i <= optionalColumns.length + 3; i++) {
    try {
      final response = await supabase
          .from('quizzes')
          .insert(payload)
          .select('id')
          .single();
      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (e) {
      debugPrint('Insert task attempt $i failed [${e.code}]: ${e.message}');

      // 1. Check for enum error on assessment_type
      final isEnumError = e.code == '22P02' ||
          e.message.toLowerCase().contains('enum') ||
          e.message.toLowerCase().contains('assessment_type');
      if (isEnumError && payload['assessment_type'] == 'task') {
        debugPrint('Fallback assessment_type from task to posttest with tag');
        payload['assessment_type'] = 'posttest';
        final inst = payload['instructions']?.toString() ?? '';
        if (!inst.contains('<!--type:task-->')) {
          payload['instructions'] = inst.isEmpty ? '<!--type:task-->' : '<!--type:task-->\n$inst';
        }
        continue;
      }

      // 2. Check for RLS failure on class_id
      if (e.code == '42501' && payload.containsKey('class_id')) {
        debugPrint('RLS failure on class_id, retrying without class_id');
        payload.remove('class_id');
        continue;
      }

      // 3. Check for missing column error
      final isColError = e.code == '42703' ||
          e.code == 'PGRST204' ||
          e.message.toLowerCase().contains('column');
      if (isColError) {
        String? colToRemove;
        for (final key in payload.keys.toList()) {
          if (e.message.toLowerCase().contains(key.toLowerCase()) && key != 'title') {
            colToRemove = key;
            break;
          }
        }
        colToRemove ??= optionalColumns.firstWhere(
          (col) => payload.containsKey(col),
          orElse: () => '',
        );

        if (colToRemove.isNotEmpty) {
          debugPrint('Removing missing column from payload: $colToRemove');
          payload.remove(colToRemove);
          continue;
        }
      }

      rethrow;
    } catch (e) {
      debugPrint('Unexpected error in _tryInsertTask: $e');
      rethrow;
    }
  }

  final response = await supabase
      .from('quizzes')
      .insert(payload)
      .select('id')
      .single();
  return Map<String, dynamic>.from(response);
}

Future<void> _tryUpdateTask(String id, Map<String, dynamic> initialPayload) async {
  final payload = Map<String, dynamic>.from(initialPayload);
  final optionalColumns = [
    'deadline',
    'leaderboard_enabled',
    'attempts_allowed',
    'weight',
    'required',
    'instructions_en',
    'instructions_id',
    'description_en',
    'description_id',
    'time_limit',
    'module',
    'instructions',
    'description',
    'class_id',
  ];

  for (var i = 0; i <= optionalColumns.length + 3; i++) {
    try {
      await supabase
          .from('quizzes')
          .update(payload)
          .eq('id', id);
      return;
    } on PostgrestException catch (e) {
      debugPrint('Update task attempt $i failed [${e.code}]: ${e.message}');

      final isEnumError = e.code == '22P02' ||
          e.message.toLowerCase().contains('enum') ||
          e.message.toLowerCase().contains('assessment_type');
      if (isEnumError && payload['assessment_type'] == 'task') {
        payload['assessment_type'] = 'posttest';
        final inst = payload['instructions']?.toString() ?? '';
        if (!inst.contains('<!--type:task-->')) {
          payload['instructions'] = inst.isEmpty ? '<!--type:task-->' : '<!--type:task-->\n$inst';
        }
        continue;
      }

      if (e.code == '42501' && payload.containsKey('class_id')) {
        payload.remove('class_id');
        continue;
      }

      final isColError = e.code == '42703' ||
          e.code == 'PGRST204' ||
          e.message.toLowerCase().contains('column');
      if (isColError) {
        String? colToRemove;
        for (final key in payload.keys.toList()) {
          if (e.message.toLowerCase().contains(key.toLowerCase()) && key != 'title') {
            colToRemove = key;
            break;
          }
        }
        colToRemove ??= optionalColumns.firstWhere(
          (col) => payload.containsKey(col),
          orElse: () => '',
        );

        if (colToRemove.isNotEmpty) {
          payload.remove(colToRemove);
          continue;
        }
      }

      rethrow;
    }
  }
}

/// Creates a new task (quiz with assessment_type = 'task')
Future<String> createTask(
  WidgetRef ref,
  LecturerTask task,
) async {
  final user = supabase.auth.currentUser;

  // `quizzes_insert` requires `created_by = auth.uid()`. Without a session the
  // insert would fail with an opaque RLS `42501`, so it is refused here with the
  // same `notPermitted` failure the form already knows how to phrase.
  if (user == null) {
    throw const AssessmentWriteException(AssessmentWriteFailure.notPermitted);
  }

  final activeClass = await resolveActiveLecturerClass(ref);
  final validClass = activeClass != null &&
      activeClass.id.isNotEmpty &&
      !activeClass.isLegacyFallback;

  String taskId;

  try {
    final response = await _tryInsertTask({
      ..._taskColumns(task),
      'created_by': user.id,
      if (validClass) 'class_id': activeClass.id,
    });

    taskId = response['id'].toString();
  } catch (error) {
    debugPrint('createTask error: $error');
    throw mapAssessmentWriteError(error);
  }

  ref.invalidate(lecturerTasksProvider);
  ref.invalidate(lecturerDashboardStatsProvider);
  ref.invalidate(classLeaderboardQuizzesProvider);
  ref.invalidate(classLeaderboardProvider);

  return taskId;
}

/// Updates an existing task
Future<void> updateTask(
  WidgetRef ref,
  LecturerTask task,
) async {
  try {
    await _tryUpdateTask(task.id, _taskColumns(task));

    ref.invalidate(lecturerTasksProvider);
    ref.invalidate(lecturerTaskProvider(task.id));
    ref.invalidate(lecturerDashboardStatsProvider);
    ref.invalidate(classLeaderboardQuizzesProvider);
    ref.invalidate(classLeaderboardProvider);
  } catch (error) {
    throw mapAssessmentWriteError(error);
  }
}

/// Deletes a task and its questions
Future<void> deleteTask(
  WidgetRef ref,
  String taskId,
) async {
  try {
    await supabase
        .from('quizzes')
        .delete()
        .eq('id', taskId);

    ref.invalidate(lecturerTasksProvider);
    ref.invalidate(lecturerDashboardStatsProvider);
    ref.invalidate(classLeaderboardQuizzesProvider);
    ref.invalidate(classLeaderboardProvider);
  } catch (error) {
    throw mapAssessmentWriteError(error);
  }
}

/// Publishes or unpublishes a task
Future<void> setTaskPublished(
  WidgetRef ref,
  LecturerTask task,
  bool published,
) async {
  if (published && !task.canPublish) {
    throw const AssessmentWriteException(
      AssessmentWriteFailure.missingAnswerKey,
    );
  }

  try {
    await supabase
        .from('quizzes')
        .update({'status': published ? 'published' : 'draft'})
        .eq('id', task.id);

    ref.invalidate(lecturerTasksProvider);
    ref.invalidate(lecturerTaskProvider(task.id));
    ref.invalidate(lecturerDashboardStatsProvider);
    ref.invalidate(classLeaderboardQuizzesProvider);
    ref.invalidate(classLeaderboardProvider);
  } catch (error) {
    throw mapAssessmentWriteError(error);
  }
}

/// Columns for task write operations
Map<String, dynamic> _taskColumns(LecturerTask task) {
  String? nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  // `quizzes.title` is NOT NULL and holds the Indonesian copy. When the
  // lecturer only filled the English title, the base column still has to be
  // non-null or the INSERT is rejected before RLS is even checked.
  final baseTitle = task.title.trim().isNotEmpty
      ? task.title.trim()
      : task.titleEn.trim();

  // Preserve deadline in instructions metadata so it survives even if
  // quizzes.deadline column has not yet been applied to the remote schema.
  String? rawInstructions = nullIfEmpty(task.instructions ?? '');
  if (task.deadline != null) {
    final meta = '<!--meta:deadline=${task.deadline!.toUtc().toIso8601String()}-->';
    final clean = (rawInstructions ?? '').replaceAll(RegExp(r'\s*<!--meta:deadline=[^>]+-->'), '').trim();
    rawInstructions = clean.isEmpty ? meta : '$clean\n$meta';
  }

  return {
    'title': baseTitle.isEmpty ? null : baseTitle,
    'title_en': nullIfEmpty(task.titleEn),
    'title_id': nullIfEmpty(task.titleId),
    'assessment_type': 'task',
    'duration_minutes': task.durationMinutes,
    'status': task.status,
    'module': task.module,
    'description': nullIfEmpty(task.description ?? ''),
    'description_en': nullIfEmpty(task.descriptionEn ?? ''),
    'description_id': nullIfEmpty(task.descriptionId ?? ''),
    'instructions': rawInstructions,
    'instructions_en': nullIfEmpty(task.instructionsEn ?? ''),
    'instructions_id': nullIfEmpty(task.instructionsId ?? ''),
    'time_limit': task.timeLimit,
    'deadline': task.deadline?.toUtc().toIso8601String(),
    'required': task.required,
    'leaderboard_enabled': task.leaderboardEnabled,
    'attempts_allowed': task.attemptsAllowed,
    'weight': task.weight,
  };
}

// Add canPublish getter to LecturerTask
extension LecturerTaskExtension on LecturerTask {
  bool get canPublish => questionCount > 0 && answeredCount == questionCount;
  int get unansweredCount => questionCount - answeredCount;
}