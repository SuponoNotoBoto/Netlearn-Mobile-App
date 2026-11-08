import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/localization/language_controller.dart';
import '../../core/supabase/supabase_client.dart';
import '../classes/class_controller.dart';
import '../classes/class_models.dart';
import '../dashboard_student/student_dashboard_controller.dart';
import '../materials/student_materials_controller.dart';

class AssessmentListItem {
  final String id;
  final String title;
  final String assessmentType;
  final int durationMinutes;
  final DateTime? deadline;
  final String status;
  final bool unlocked;
  final bool completed;
  final double? score;

  /// Attempt terakhir bila ada — menghidupkan dialog "sudah dikerjakan"
  /// (tombol "Lihat Hasil" perlu id attempt) dan rincian jawabannya. Semua
  /// opsional supaya pemanggil lama — termasuk override test — yang tidak
  /// mengisi attempt tetap cukup dibangun tanpa kelimanya.
  final String? attemptId;
  final int? correctCount;
  final int? wrongCount;
  final bool? passed;

  final int? module;
  final String? moduleId;
  final bool required;
  final bool leaderboardEnabled;
  final int attemptsAllowed;
  final int userAttemptCount;
  final double weight;
  final String? description;
  final String? instructions;
  final int questionCount;

  const AssessmentListItem({
    required this.id,
    required this.title,
    required this.assessmentType,
    required this.durationMinutes,
    required this.deadline,
    required this.status,
    required this.unlocked,
    required this.completed,
    required this.score,
    this.attemptId,
    this.correctCount,
    this.wrongCount,
    this.passed,
    this.module,
    this.moduleId,
    this.required = false,
    this.leaderboardEnabled = true,
    this.attemptsAllowed = 1,
    this.userAttemptCount = 0,
    this.weight = 1.0,
    this.description,
    this.instructions,
    this.questionCount = 0,
  });

  bool get isPretest => assessmentType == 'pretest';

  bool get isPosttest => assessmentType == 'posttest';

  bool get isTask =>
      assessmentType == 'task' ||
      assessmentType == 'class_assessment' ||
      assessmentType == 'module_assessment' ||
      (!isPretest && !isPosttest);

  /// True hanya bila mahasiswa sudah menyelesaikan asesmen ini **dan** masih
  /// punya jatah percobaan.
  ///
  /// Pretest/posttest selalu `false`: keduanya gerbang kelas, dan
  /// `assessment_access()` di server menjawab `pretest_done`/`posttest_done`
  /// begitu gate-nya selesai -- menawarkan "Coba Lagi" hanya akan menabrak
  /// penolakan yang sama.
  ///
  /// `userAttemptCount == 0` padahal `completed` di-floorkan ke 1: satu
  /// pengiriman selalu berarti minimal satu percobaan, jadi data attempt yang
  /// belum termuat tidak boleh dibaca sebagai "jatah masih penuh" (dulu itu
  /// membuat asesmen selesai menampilkan dialog "Coba Lagi", bukan dialog
  /// hasil).
  bool get canAttemptAgain {
    if (!completed || isPretest || isPosttest) return false;
    if (attemptsAllowed == 0) return true;

    final int used = userAttemptCount > 0 ? userAttemptCount : 1;
    return used < attemptsAllowed;
  }
}

class AssessmentQuestion {
  final String id;
  final int orderIndex;
  final String questionText;
  final String? imageUrl;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;

  const AssessmentQuestion({
    required this.id,
    required this.orderIndex,
    required this.questionText,
    required this.imageUrl,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
  });

  factory AssessmentQuestion.fromMap(
      Map<String, dynamic> map, {
        required bool isIndonesian,
      }) {
    String localizedValue(
        String baseKey,
        String fallbackKey,
        ) {
      final String? localized = isIndonesian
          ? map['${baseKey}_id']?.toString()
          : map['${baseKey}_en']?.toString();

      if (localized != null && localized.trim().isNotEmpty) {
        return localized;
      }

      return map[fallbackKey]?.toString() ?? '';
    }

    return AssessmentQuestion(
      id: map['id'].toString(),
      orderIndex: (map['order_index'] as num?)?.toInt() ?? 0,
      questionText: localizedValue(
        'question_text',
        'question_text',
      ),
      imageUrl: map['image_url']?.toString(),
      optionA: localizedValue(
        'option_a',
        'option_a',
      ),
      optionB: localizedValue(
        'option_b',
        'option_b',
      ),
      optionC: localizedValue(
        'option_c',
        'option_c',
      ),
      optionD: localizedValue(
        'option_d',
        'option_d',
      ),
    );
  }

  List<String> get options => [
    optionA,
    optionB,
    optionC,
    optionD,
  ];
}

class AssessmentAttempt {
  final String id;
  final String assessmentId;
  final String userId;
  final String status;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final double? score;
  final int? correctCount;
  final int? wrongCount;
  final bool? passed;

  const AssessmentAttempt({
    required this.id,
    required this.assessmentId,
    required this.userId,
    required this.status,
    required this.startedAt,
    required this.submittedAt,
    required this.score,
    required this.correctCount,
    required this.wrongCount,
    required this.passed,
  });

  factory AssessmentAttempt.fromMap(
      Map<String, dynamic> map,
      ) {
    return AssessmentAttempt(
      id: map['id'].toString(),
      assessmentId: map['quiz_id'].toString(),
      userId: map['user_id'].toString(),
      status: map['status']?.toString() ?? 'in_progress',
      startedAt: DateTime.parse(
        map['started_at'].toString(),
      ),
      submittedAt: map['submitted_at'] == null
          ? null
          : DateTime.tryParse(
        map['submitted_at'].toString(),
      ),
      score: (map['score'] as num?)?.toDouble(),
      correctCount: (map['correct_count'] as num?)?.toInt(),
      wrongCount: (map['wrong_count'] as num?)?.toInt(),
      passed: map['passed'] as bool?,
    );
  }
}

class AssessmentAnswerReview {
  final String questionId;
  final String selectedOption;
  final String correctOption;
  final bool isCorrect;

  const AssessmentAnswerReview({
    required this.questionId,
    required this.selectedOption,
    required this.correctOption,
    required this.isCorrect,
  });

  factory AssessmentAnswerReview.fromMap(
      Map<String, dynamic> map,
      ) {
    return AssessmentAnswerReview(
      questionId: map['question_id'].toString(),
      selectedOption:
      map['selected_option']?.toString() ?? '',
      correctOption:
      map['correct_option']?.toString() ?? '',
      isCorrect: map['is_correct'] == true,
    );
  }
}

class AssessmentSessionState {
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  final String? assessmentId;
  final String? assessmentTitle;
  final String? assessmentType;

  final int durationMinutes;
  final DateTime? startedAt;

  final List<AssessmentQuestion> questions;
  final Map<String, String> answers;

  final int currentQuestionIndex;

  final AssessmentAttempt? attempt;

  const AssessmentSessionState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.assessmentId,
    this.assessmentTitle,
    this.assessmentType,
    this.durationMinutes = 0,
    this.startedAt,
    this.questions = const [],
    this.answers = const {},
    this.currentQuestionIndex = 0,
    this.attempt,
  });

  AssessmentSessionState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? assessmentId,
    String? assessmentTitle,
    String? assessmentType,
    int? durationMinutes,
    DateTime? startedAt,
    List<AssessmentQuestion>? questions,
    Map<String, String>? answers,
    int? currentQuestionIndex,
    AssessmentAttempt? attempt,
  }) {
    return AssessmentSessionState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      assessmentId: assessmentId ?? this.assessmentId,
      assessmentTitle:
      assessmentTitle ?? this.assessmentTitle,
      assessmentType:
      assessmentType ?? this.assessmentType,
      durationMinutes:
      durationMinutes ?? this.durationMinutes,
      startedAt: startedAt ?? this.startedAt,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      currentQuestionIndex:
      currentQuestionIndex ??
          this.currentQuestionIndex,
      attempt: attempt ?? this.attempt,
    );
  }

  bool get hasQuestions => questions.isNotEmpty;

  int get totalQuestions => questions.length;

  int get answeredQuestions => answers.length;

  bool get isPretest => assessmentType == 'pretest';

  bool get isPosttest => assessmentType == 'posttest';

  AssessmentQuestion? get currentQuestion {
    if (currentQuestionIndex < 0 ||
        currentQuestionIndex >= questions.length) {
      return null;
    }

    return questions[currentQuestionIndex];
  }

  String? get currentAnswer {
    final question = currentQuestion;

    if (question == null) {
      return null;
    }

    return answers[question.id];
  }
}

class AssessmentController
    extends Notifier<AssessmentSessionState> {
  /// Answers that could not be written to `quiz_answers` when the student
  /// tapped an option. They are retried before the attempt is submitted so a
  /// flaky save never costs the student their response.
  final Map<String, String> _unsyncedAnswers = {};

  @override
  AssessmentSessionState build() {
    return const AssessmentSessionState();
  }

  bool get _isIndonesian {
    return ref.read(languageProvider).languageCode == 'id';
  }

  String _localizedTitle(
      Map<String, dynamic> map,
      ) {
    final String? localized = _isIndonesian
        ? map['title_id']?.toString()
        : map['title_en']?.toString();

    if (localized != null &&
        localized.trim().isNotEmpty) {
      return localized;
    }

    return map['title']?.toString() ?? '';
  }

  Future<List<AssessmentListItem>>
  loadAssessmentList() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('USER_NOT_AUTHENTICATED');
      }

      final profile = await supabase
          .from('profiles')
          .select('role, is_active')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        throw Exception('PROFILE_NOT_FOUND');
      }

      final String role =
          profile['role']?.toString() ?? '';

      final bool isActive =
          profile['is_active'] == true;

      if (role != 'student' || !isActive) {
        throw Exception('ASSESSMENT_STUDENT_ONLY');
      }

      final activeClass = await readActiveStudentClass(ref);
      final validClass = activeClass != null && !activeClass.isLegacyFallback;
      ClassLearningFlowStatus? classFlow;
      if (validClass) {
        try {
          classFlow = ref.read(classLearningFlowStatusProvider(activeClass.id)).value;
          classFlow ??= await ref
              .read(classLearningFlowStatusProvider(activeClass.id).future)
              .timeout(const Duration(seconds: 2), onTimeout: () => null);
        } catch (_) {}
      }

      final List<dynamic> resolvedAssessments;
      final bool resolvedPretestCompleted;
      final bool resolvedPosttestUnlocked;
      final bool resolvedPosttestCompleted;

      Future<List<dynamic>> fetchQuizzesSafely({String? classId, bool isNullClass = false}) async {
        const selectFull = '''
          id,
          title,
          title_en,
          title_id,
          duration_minutes,
          deadline,
          status,
          assessment_type,
          module,
          required,
          attempts_allowed,
          leaderboard_enabled,
          weight,
          description,
          instructions,
          created_at
        ''';

        const selectCompact = '''
          id,
          title,
          title_en,
          title_id,
          duration_minutes,
          deadline,
          status,
          assessment_type,
          instructions,
          created_at
        ''';

        const selectMinimal = '''
          id,
          title,
          title_en,
          title_id,
          duration_minutes,
          status,
          assessment_type,
          created_at
        ''';

        final selectCandidates = [selectFull, selectCompact, selectMinimal];

        for (final sel in selectCandidates) {
          try {
            var query = supabase.from('quizzes').select(sel).eq('status', 'published');
            if (isNullClass) {
              query = query.isFilter('class_id', null);
            } else if (classId != null) {
              query = query.eq('class_id', classId);
            }
            final res = await query.order('created_at');
            return res as List<dynamic>;
          } on PostgrestException catch (e) {
            final isColError = e.code == '42703' ||
                e.code == 'PGRST204' ||
                e.message.toLowerCase().contains('column');
            if (isColError) {
              continue;
            }
            rethrow;
          }
        }
        return const <dynamic>[];
      }

      if (validClass) {
        final List<dynamic> classQuizzes = await fetchQuizzesSafely(classId: activeClass.id);

        final hasClassPretest = classQuizzes.any(
          (dynamic q) => (q as Map)['assessment_type']?.toString() == 'pretest',
        );
        final hasClassPosttest = classQuizzes.any(
          (dynamic q) => (q as Map)['assessment_type']?.toString() == 'posttest',
        );

        final List<dynamic> combined = List.from(classQuizzes);

        // Fallback to global pretest/posttest templates if class has none
        if (!hasClassPretest || !hasClassPosttest) {
          final globalQuizzes = await fetchQuizzesSafely(isNullClass: true);

          for (final dynamic gq in globalQuizzes) {
            final t = (gq as Map)['assessment_type']?.toString();
            if (t == 'pretest' && !hasClassPretest) {
              combined.add(gq);
            } else if (t == 'posttest' && !hasClassPosttest) {
              combined.add(gq);
            }
          }
        }

        // Keep custom quizzes and curriculum evaluations accessible
        resolvedAssessments = combined.where((raw) {
          final t = (raw as Map)['assessment_type']?.toString() ?? '';
          if (t == 'pretest' && classFlow != null && !classFlow.pretestEnabled) {
            return false;
          }
          return true;
        }).toList();

        resolvedPretestCompleted = classFlow?.pretestCompleted ?? false;
        resolvedPosttestUnlocked = classFlow?.posttestUnlocked ?? false;
        resolvedPosttestCompleted = classFlow?.posttestCompleted ?? false;
      } else {
        final assessments = await fetchQuizzesSafely(isNullClass: true);

        final flowResponse = await supabase.rpc(
          'get_learning_flow_status',
          params: {
            'p_user': user.id,
          },
        );

        final Map<String, dynamic> flow =
        _extractFlowMap(flowResponse);

        resolvedPretestCompleted =
            flow['pretest_completed'] == true;
        resolvedPosttestUnlocked =
            flow['posttest_unlocked'] == true;
        resolvedPosttestCompleted =
            flow['posttest_completed'] == true;
        resolvedAssessments = assessments;
      }
      final attemptRows = await supabase
          .from('quiz_attempts')
          .select(
        '''
          id,
          quiz_id,
          user_id,
          status,
          started_at,
          submitted_at,
          score,
          correct_count,
          wrong_count,
          passed
        ''',
      )
          .eq('user_id', user.id)
          .eq('status', 'submitted')
          .order(
        'started_at',
        ascending: false,
      );

      final Map<String, Map<String, dynamic>> latestAttempts = {};
      final Map<String, int> userAttemptCounts = {};

      for (final dynamic raw in attemptRows) {
        final Map<String, dynamic> row = Map<String, dynamic>.from(raw as Map);
        final String quizId = row['quiz_id'].toString();
        latestAttempts.putIfAbsent(quizId, () => row);
        userAttemptCounts[quizId] = (userAttemptCounts[quizId] ?? 0) + 1;
      }

      final Map<String, int> questionCounts = {};
      try {
        final qRows = await supabase.from('questions').select('quiz_id');
        for (final raw in qRows as List) {
          final qId = (raw as Map)['quiz_id']?.toString();
          if (qId != null) {
            questionCounts[qId] = (questionCounts[qId] ?? 0) + 1;
          }
        }
      } catch (_) {}

      // The "any completed material means the post-test is open" heuristic is a
      // v6 escape hatch for the global template. Inside a class the real gate is
      // the class flow (all published modules done), so OR-ing the heuristic in
      // would advertise a post-test the server refuses to start.
      final bool actualPosttestUnlocked = resolvedPosttestUnlocked ||
          (classFlow == null && await _hasUserCompletedAllModules(user.id));

      return resolvedAssessments.map((dynamic raw) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(raw as Map);
        final String id = map['id'].toString();
        final Map<String, dynamic>? latestAttempt = latestAttempts[id];
        final String type = map['assessment_type']?.toString() ?? 'pretest';

        final String? instructions = map['instructions']?.toString();
        int? modNum = (map['module'] as num?)?.toInt();
        if (modNum == null && instructions != null) {
          final m = RegExp(r'<!--meta:module=(\d+)-->').firstMatch(instructions);
          if (m != null) modNum = int.tryParse(m.group(1)!);
        }

        DateTime? deadline = map['deadline'] == null
            ? null
            : DateTime.tryParse(map['deadline'].toString());
        if (deadline == null && instructions != null) {
          final m = RegExp(r'<!--meta:deadline=(.+?)-->').firstMatch(instructions);
          if (m != null) deadline = DateTime.tryParse(m.group(1)!);
        }

        final bool isRequired = map['required'] == true;
        final bool leaderboardEnabled = map['leaderboard_enabled'] != false;
        final int attemptsAllowed = (map['attempts_allowed'] as num?)?.toInt() ?? 1;
        final double weight = (map['weight'] as num?)?.toDouble() ?? 1.0;
        final String? description = map['description']?.toString();
        final int userAttemptCount = userAttemptCounts[id] ?? 0;
        final int questionCount = questionCounts[id] ?? (type == 'pretest' || type == 'posttest' ? 25 : 0);

        final bool completed = type == 'pretest'
            ? resolvedPretestCompleted
            : (type == 'posttest'
                ? resolvedPosttestCompleted
                : (userAttemptCount >= attemptsAllowed && attemptsAllowed > 0));

        final bool isModQuiz = modNum != null;
        final bool unlocked = type == 'pretest'
            ? true
            : (type == 'posttest'
                ? actualPosttestUnlocked
                : (isModQuiz
                    ? (classFlow != null ? classFlow.completedModules >= (modNum - 1) : true)
                    : true));

        final double? score = (latestAttempt?['score'] as num?)?.toDouble();

        return AssessmentListItem(
          id: id,
          title: _localizedTitle(map),
          assessmentType: type,
          durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 0,
          deadline: deadline,
          status: map['status']?.toString() ?? 'published',
          unlocked: unlocked,
          completed: completed,
          score: score,
          attemptId: latestAttempt?['id']?.toString(),
          correctCount: (latestAttempt?['correct_count'] as num?)?.toInt(),
          wrongCount: (latestAttempt?['wrong_count'] as num?)?.toInt(),
          passed: latestAttempt?['passed'] as bool?,
          module: modNum,
          moduleId: map['module_id']?.toString(),
          required: isRequired,
          leaderboardEnabled: leaderboardEnabled,
          attemptsAllowed: attemptsAllowed,
          userAttemptCount: userAttemptCount,
          weight: weight,
          description: description,
          instructions: instructions,
          questionCount: questionCount,
        );
      }).toList();
    } catch (error) {
      debugPrint(
        'loadAssessmentList error: $error',
      );
      rethrow;
    }
  }

  Future<AssessmentListItem?> getAssessmentByType(
      String assessmentType,
      ) async {
    final assessments =
    await loadAssessmentList();

    for (final assessment in assessments) {
      if (assessment.assessmentType ==
          assessmentType || assessment.id == assessmentType) {
        return assessment;
      }
    }

    // Direct fallback if not present in the current class list
    try {
      final isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(assessmentType);
      dynamic raw;
      try {
        final query = supabase
            .from('quizzes')
            .select('''
              id,
              title,
              title_en,
              title_id,
              duration_minutes,
              deadline,
              status,
              assessment_type,
              module,
              created_at
            ''')
            .eq('status', 'published');

        if (isUuid) {
          raw = await query.eq('id', assessmentType).maybeSingle();
        } else {
          final list = await query
              .eq('assessment_type', assessmentType)
              .order('created_at', ascending: false)
              .limit(1);
          if ((list as List).isNotEmpty) {
            raw = list.first;
          }
        }
      } on PostgrestException catch (e) {
        final isColError = e.code == '42703' ||
            e.code == 'PGRST204' ||
            e.message.toLowerCase().contains('column');
        if (isColError) {
          final fallbackQuery = supabase
              .from('quizzes')
              .select('''
                id,
                title,
                title_en,
                title_id,
                duration_minutes,
                status,
                assessment_type,
                created_at
              ''')
              .eq('status', 'published');

          if (isUuid) {
            raw = await fallbackQuery.eq('id', assessmentType).maybeSingle();
          } else {
            final list = await fallbackQuery
                .eq('assessment_type', assessmentType)
                .order('created_at', ascending: false)
                .limit(1);
            if ((list as List).isNotEmpty) {
              raw = list.first;
            }
          }
        } else {
          rethrow;
        }
      }

      if (raw != null) {
        final map = Map<String, dynamic>.from(raw as Map);
        return AssessmentListItem(
          id: map['id'].toString(),
          title: _localizedTitle(map),
          assessmentType: map['assessment_type']?.toString() ?? assessmentType,
          durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 0,
          deadline: map['deadline'] == null ? null : DateTime.tryParse(map['deadline'].toString()),
          status: map['status']?.toString() ?? 'published',
          unlocked: true,
          completed: false,
          score: null,
        );
      }
    } catch (_) {}

    return null;
  }

  Future<void> startAssessmentByType(
      String assessmentType,
      ) async {
    state = const AssessmentSessionState(
      isLoading: true,
    );

    try {
      final assessment =
      await getAssessmentByType(
        assessmentType,
      );

      if (assessment == null) {
        throw Exception(
          'ASSESSMENT_NOT_FOUND',
        );
      }

      await startAssessment(
        assessment.id,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
        error.toString(),
      );
      rethrow;
    }
  }

  Future<void> startAssessment(
      String assessmentId,
      ) async {
    _unsyncedAnswers.clear();

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception(
          'USER_NOT_AUTHENTICATED',
        );
      }

      final assessmentResponse =
      await supabase
          .from('quizzes')
          .select(
        '''
              id,
              title,
              title_en,
              title_id,
              duration_minutes,
              status,
              assessment_type,
              class_id
            ''',
      )
          .eq('id', assessmentId)
          .maybeSingle();

      if (assessmentResponse == null) {
        throw Exception(
          'ASSESSMENT_NOT_FOUND',
        );
      }

      final Map<String, dynamic> assessment =
      Map<String, dynamic>.from(
        assessmentResponse,
      );

      final String assessmentTitle =
      _localizedTitle(assessment);

      final String assessmentType =
          assessment['assessment_type']
              ?.toString() ??
              'task';

      final String status =
          assessment['status']?.toString() ??
              '';

      if (status != 'published') {
        throw Exception(
          'ASSESSMENT_NOT_PUBLISHED',
        );
      }

      String attemptId;
      try {
        final dynamic attemptResponse = await supabase.rpc(
          'start_assessment_attempt',
          params: {
            'p_quiz': assessmentId,
          },
        );
        attemptId = _extractUuid(attemptResponse);
      } on PostgrestException catch (rpcErr) {
        debugPrint('start_assessment_attempt RPC error: $rpcErr');

        // The client can never create the attempt itself: `quiz_attempts` has
        // a SELECT policy only, so an INSERT is always 42501. Resume an
        // attempt the server already opened, otherwise surface the real reason.
        final resumed = await _findOpenAttempt(assessmentId, user.id);

        if (resumed == null) {
          throw Exception(await _blockedAccessCode(rpcErr, assessmentId));
        }

        attemptId = resumed;
      }

      List<dynamic> rawQuestions = [];
      try {
        final qRes = await supabase
            .from('questions')
            .select(
          '''
                id,
                order_index,
                question_text,
                question_text_en,
                question_text_id,
                image_url,
                option_a,
                option_a_en,
                option_a_id,
                option_b,
                option_b_en,
                option_b_id,
                option_c,
                option_c_en,
                option_c_id,
                option_d,
                option_d_en,
                option_d_id
              ''',
        )
            .eq('quiz_id', assessmentId)
            .order('order_index');
        rawQuestions = qRes as List<dynamic>;
      } catch (qErr) {
        debugPrint('Direct questions select error: $qErr');
      }

      // If direct query returned 0 rows (e.g. RLS policy restriction), call SECURITY DEFINER RPC
      if (rawQuestions.isEmpty) {
        try {
          final dynamic rpcResp = await supabase.rpc(
            'get_assessment_questions',
            params: {'p_quiz': assessmentId},
          );
          if (rpcResp is List && rpcResp.isNotEmpty) {
            rawQuestions = rpcResp;
          }
        } catch (rpcErr) {
          debugPrint('get_assessment_questions RPC fallback error: $rpcErr');
        }
      }

      // If still empty on class pretest/posttest, fallback to global template questions
      if (rawQuestions.isEmpty && (assessmentType == 'pretest' || assessmentType == 'posttest')) {
        try {
          final globalQuizList = await supabase
              .from('quizzes')
              .select('id')
              .isFilter('class_id', null)
              .eq('assessment_type', assessmentType)
              .eq('status', 'published')
              .limit(1);
          if ((globalQuizList as List).isNotEmpty) {
            final globalId = (globalQuizList.first as Map)['id']?.toString();
            if (globalId != null && globalId != assessmentId) {
              final globalQRes = await supabase
                  .from('questions')
                  .select('''
                    id, order_index, question_text, question_text_en, question_text_id,
                    image_url, option_a, option_a_en, option_a_id, option_b, option_b_en,
                    option_b_id, option_c, option_c_en, option_c_id, option_d, option_d_en, option_d_id
                  ''')
                  .eq('quiz_id', globalId)
                  .order('order_index');
              if ((globalQRes as List).isNotEmpty) {
                rawQuestions = globalQRes;
              }
            }
          }
        } catch (_) {}
      }

      final List<AssessmentQuestion>
      questions =
      rawQuestions
          .map(
            (dynamic raw) =>
            AssessmentQuestion.fromMap(
              Map<String, dynamic>.from(
                raw as Map,
              ),
              isIndonesian:
              _isIndonesian,
            ),
      )
          .toList();

      if (questions.isEmpty) {
        throw Exception(
          'ASSESSMENT_NO_QUESTIONS',
        );
      }

      final bool isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(attemptId);
      final attemptResponseRow = isUuid
          ? await supabase
              .from('quiz_attempts')
              .select(
            '''
                  id,
                  quiz_id,
                  user_id,
                  status,
                  started_at,
                  submitted_at,
                  score,
                  correct_count,
                  wrong_count,
                  passed
                ''',
          )
              .eq('id', attemptId)
              .maybeSingle()
          : null;

      final attempt = attemptResponseRow != null
          ? AssessmentAttempt.fromMap(
              Map<String, dynamic>.from(
                attemptResponseRow,
              ),
            )
          : AssessmentAttempt(
              id: attemptId,
              assessmentId: assessmentId,
              userId: user.id,
              status: 'in_progress',
              startedAt: DateTime.now(),
              submittedAt: null,
              score: null,
              correctCount: null,
              wrongCount: null,
              passed: null,
            );

      final List<dynamic> answerRows = isUuid
          ? (await supabase
              .from('quiz_answers')
              .select(
            '''
              question_id,
              selected_option
            ''',
          )
              .eq(
            'attempt_id',
            attempt.id,
          ) as List<dynamic>)
          : const [];

      final Map<String, String> answers = {};

      for (final dynamic raw in answerRows) {
        final Map<String, dynamic> row =
        Map<String, dynamic>.from(
          raw as Map,
        );

        final String questionId =
        row['question_id'].toString();

        final String selectedOption =
            row['selected_option']
                ?.toString() ??
                '';

        if (selectedOption.isNotEmpty) {
          answers[questionId] =
              selectedOption;
        }
      }

      state = AssessmentSessionState(
        isLoading: false,
        isSubmitting: false,
        errorMessage: null,
        assessmentId: assessmentId,
        assessmentTitle: assessmentTitle,
        assessmentType: assessmentType,
        durationMinutes:
        (assessment['duration_minutes']
        as num?)
            ?.toInt() ??
            0,
        startedAt: attempt.startedAt,
        questions: questions,
        answers: answers,
        currentQuestionIndex: 0,
        attempt: attempt,
      );
    } catch (error) {
      debugPrint(
        'startAssessment error: $error',
      );

      state = state.copyWith(
        isLoading: false,
        errorMessage:
        error.toString(),
      );

      rethrow;
    }
  }

  Future<void> selectAnswer(
      String questionId,
      String selectedOption,
      ) async {
    final String? attemptId =
    state.attempt?.id;

    if (attemptId == null) {
      throw Exception(
        'ATTEMPT_NOT_FOUND',
      );
    }

    if (!['A', 'B', 'C', 'D']
        .contains(selectedOption)) {
      throw Exception(
        'INVALID_OPTION',
      );
    }

    // Record the answer locally before syncing. Persisting first meant a
    // failed save silently discarded the student's tap.
    final updatedAnswers =
    Map<String, String>.from(
      state.answers,
    );

    updatedAnswers[questionId] =
    selectedOption;

    state = state.copyWith(
      answers: updatedAnswers,
      errorMessage: null,
    );

    try {
      final isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(attemptId);
      if (isUuid) {
        await supabase.rpc(
          'save_assessment_answer',
          params: {
            'p_attempt': attemptId,
            'p_question': questionId,
            'p_option': selectedOption,
          },
        );
      }

      _unsyncedAnswers.remove(questionId);
    } catch (error) {
      debugPrint(
        'selectAnswer sync failed, will retry on submit: $error',
      );

      _unsyncedAnswers[questionId] =
          selectedOption;
    }
  }

  /// Retries every answer whose earlier save did not reach the server.
  Future<void> _flushUnsyncedAnswers(
      String attemptId,
      ) async {
    final isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(attemptId);
    if (_unsyncedAnswers.isEmpty || !isUuid) {
      return;
    }

    final pending =
    Map<String, String>.from(
      _unsyncedAnswers,
    );

    for (final entry in pending.entries) {
      await supabase.rpc(
        'save_assessment_answer',
        params: {
          'p_attempt': attemptId,
          'p_question': entry.key,
          'p_option': entry.value,
        },
      );

      _unsyncedAnswers.remove(entry.key);
    }
  }


  void goToQuestion(int index) {
    if (index < 0 ||
        index >= state.questions.length) {
      return;
    }

    state = state.copyWith(
      currentQuestionIndex: index,
    );
  }

  void nextQuestion() {
    if (state.currentQuestionIndex <
        state.questions.length - 1) {
      state = state.copyWith(
        currentQuestionIndex:
        state.currentQuestionIndex + 1,
      );
    }
  }

  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(
        currentQuestionIndex:
        state.currentQuestionIndex - 1,
      );
    }
  }

  Future<AssessmentAttempt>
  submitAssessment() async {
    final String? attemptId =
        state.attempt?.id;

    if (attemptId == null) {
      throw Exception(
        'ATTEMPT_NOT_FOUND',
      );
    }

    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
    );

    try {
      // Make sure nothing the student selected is lost before grading.
      await _flushUnsyncedAnswers(attemptId);

      // Grading only happens server-side. `quiz_attempts`/`quiz_answers` have
      // SELECT policies only, so the old "grade the attempt directly" fallback
      // could never persist anything - it just showed a submitted-looking
      // result for a row that stayed in_progress. A failed submit is a failed
      // submit.
      final dynamic response = await supabase.rpc(
        'submit_assessment_attempt',
        params: {
          'p_attempt': attemptId,
        },
      );
      final Map<String, dynamic> result = _extractMap(response);
      debugPrint('submitAssessment rpc result: $result');

      final AssessmentAttempt submittedAttempt =
      await getAttempt(attemptId);

      state = state.copyWith(
        isSubmitting: false,
        attempt: submittedAttempt,
      );

      // Passing the pretest is the gate that unlocks module 1, and finishing a
      // posttest updates the completion state of the whole course. This list
      // is kept inline rather than using `invalidateStudentProgress` because
      // that helper lives in a file that imports this controller.
      ref.invalidate(
        studentMaterialsProvider,
      );
      ref.invalidate(
        studentModuleStatesProvider,
      );
      ref.invalidate(
        studentMaterialProgressProvider,
      );
      ref.invalidate(
        studentMaterialStateProvider,
      );
      ref.invalidate(
        isMaterialUnlockedProvider,
      );
      ref.invalidate(
        studentModulesProvider,
      );
      ref.invalidate(
        studentLearningFlowStatusProvider,
      );
      ref.invalidate(
        studentLearningProgressProvider,
      );
      ref.invalidate(
        studentDashboardProvider,
      );
      ref.invalidate(
        assessmentListProvider,
      );
      // v7 class scope: the pretest gate and module unlocks are read from
      // the class flow snapshot. Without this, Module 1 stays "locked by the
      // pretest" on every mounted screen right after the pretest is passed.
      ref.invalidate(classLearningFlowStatusProvider);
      ref.invalidate(classModuleMaterialsProvider);
      ref.invalidate(classLeaderboardProvider);
      ref.invalidate(assessmentLeaderboardProvider);
      ref.invalidate(
        classModulesProvider,
      );

      return submittedAttempt;
    } catch (error) {
      debugPrint(
        'submitAssessment error: $error',
      );

      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
        error.toString(),
      );

      rethrow;
    }
  }

  Future<AssessmentAttempt> getAttempt(
      String attemptId,
      ) async {
    final bool isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(attemptId);
    if (!isUuid) {
      final s = state;
      return AssessmentAttempt(
        id: attemptId,
        assessmentId: s.assessmentId ?? '',
        userId: supabase.auth.currentUser?.id ?? '',
        status: 'submitted',
        startedAt: s.startedAt ?? DateTime.now(),
        submittedAt: DateTime.now(),
        score: s.attempt?.score ?? 100.0,
        correctCount: s.attempt?.correctCount ?? s.answers.length,
        wrongCount: s.attempt?.wrongCount ?? 0,
        passed: (s.attempt?.score ?? 100.0) >= 70.0,
      );
    }

    final response = await supabase
        .from('quiz_attempts')
        .select(
      '''
        id,
        quiz_id,
        user_id,
        status,
        started_at,
        submitted_at,
        score,
        correct_count,
        wrong_count,
        passed
      ''',
    )
        .eq('id', attemptId)
        .maybeSingle();

    if (response == null) {
      final s = state;
      return AssessmentAttempt(
        id: attemptId,
        assessmentId: s.assessmentId ?? '',
        userId: supabase.auth.currentUser?.id ?? '',
        status: 'submitted',
        startedAt: s.startedAt ?? DateTime.now(),
        submittedAt: DateTime.now(),
        score: s.attempt?.score ?? 100.0,
        correctCount: s.attempt?.correctCount ?? s.answers.length,
        wrongCount: s.attempt?.wrongCount ?? 0,
        passed: (s.attempt?.score ?? 100.0) >= 70.0,
      );
    }

    return AssessmentAttempt.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  Future<List<AssessmentAnswerReview>>
  getAttemptReview(
      String attemptId,
      ) async {
    final bool isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(attemptId);
    if (!isUuid) {
      return state.questions.map((q) {
        final userAns = state.answers[q.id] ?? '';
        return AssessmentAnswerReview(
          questionId: q.id,
          selectedOption: userAns,
          correctOption: userAns,
          isCorrect: true,
        );
      }).toList();
    }
    try {
      final dynamic response =
      await supabase.rpc(
        'get_attempt_review',
        params: {
          'p_attempt': attemptId,
        },
      );

      if (response is! List) {
        return [];
      }

      return response
          .map(
            (dynamic raw) =>
            AssessmentAnswerReview.fromMap(
              Map<String, dynamic>.from(
                raw as Map,
              ),
            ),
      )
          .toList();
    } catch (error) {
      debugPrint(
        'getAttemptReview error: $error',
      );

      rethrow;
    }
  }

  void reset() {
    _unsyncedAnswers.clear();

    state =
    const AssessmentSessionState();
  }

  Map<String, dynamic> _extractFlowMap(
      dynamic response,
      ) {
    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is Map) {
      return Map<String, dynamic>.from(
        response,
      );
    }

    if (response is List &&
        response.isNotEmpty &&
        response.first is Map) {
      return Map<String, dynamic>.from(
        response.first as Map,
      );
    }

    return {};
  }

  Map<String, dynamic> _extractMap(
      dynamic response,
      ) {
    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is Map) {
      return Map<String, dynamic>.from(
        response,
      );
    }

    if (response is List &&
        response.isNotEmpty &&
        response.first is Map) {
      return Map<String, dynamic>.from(
        response.first as Map,
      );
    }

    return {};
  }

  String _extractUuid(
      dynamic response,
      ) {
    if (response is String) {
      return response;
    }

    if (response is Map<String, dynamic>) {
      final dynamic value =
          response['attempt_id'] ??
              response['id'];

      if (value != null) {
        return value.toString();
      }
    }

    if (response is Map) {
      final dynamic value =
          response['attempt_id'] ??
              response['id'];

      if (value != null) {
        return value.toString();
      }
    }

    if (response is List &&
        response.isNotEmpty) {
      final dynamic first =
          response.first;

      if (first is String) {
        return first;
      }

      if (first is Map<String, dynamic>) {
        final dynamic value =
            first['attempt_id'] ??
                first['id'];

        if (value != null) {
          return value.toString();
        }
      }

      if (first is Map) {
        final dynamic value =
            first['attempt_id'] ??
                first['id'];

        if (value != null) {
          return value.toString();
        }
      }
    }

    throw Exception(
      'INVALID_ATTEMPT_RESPONSE',
    );
  }

  Future<bool> _hasUserCompletedAllModules(String userId) async {
    try {
      final flowResponse = await supabase.rpc(
        'get_learning_flow_status',
        params: {'p_user': userId},
      );
      final map = _extractFlowMap(flowResponse);
      if (map['posttest_unlocked'] == true || map['all_modules_completed'] == true) {
        return true;
      }
    } catch (_) {}

    try {
      final progressRows = await supabase
          .from('material_progress')
          .select('material_id, reading_completed')
          .eq('student_id', userId)
          .eq('reading_completed', true);
      if ((progressRows as List).isNotEmpty) {
        return true;
      }
    } catch (_) {}

    try {
      final lpRows = await supabase
          .from('learning_progress')
          .select('material_id, reading_completed')
          .eq('user_id', userId)
          .eq('reading_completed', true);
      if ((lpRows as List).isNotEmpty) {
        return true;
      }
    } catch (_) {}

    return true;
  }

  /// Looks for an attempt the server already opened, without ever creating
  /// one.
  ///
  /// `quiz_attempts` carries a SELECT policy only (`quiz_attempts_select`), so
  /// an INSERT from the client is always rejected with 42501. Attempts are
  /// created exclusively by `start_assessment_attempt`, and this helper only
  /// recovers the case where the RPC refused to resume a still-open attempt.
  Future<String?> _findOpenAttempt(String quizId, String userId) async {
    try {
      final existing = await supabase
          .from('quiz_attempts')
          .select('id')
          .eq('quiz_id', quizId)
          .eq('user_id', userId)
          .eq('status', 'in_progress')
          .order('started_at', ascending: false)
          .limit(1);

      if ((existing as List).isEmpty) {
        return null;
      }

      final id = (existing.first as Map)['id']?.toString() ?? '';
      return id.isEmpty ? null : id;
    } catch (e) {
      debugPrint('_findOpenAttempt warning: $e');
      return null;
    }
  }

  /// Turns a refused start into the reason the server is willing to state.
  ///
  /// `start_assessment_attempt` can only answer ASSESSMENT_LOCKED, which covers
  /// "deadline lewat", "jatah habis", "modul sebelumnya belum selesai" and
  /// "sudah dikerjakan" at once. `assessment_access` returns the actual code so
  /// the UI can say which one it is.
  ///
  /// When the access check says 'ok' but the start still failed, the refusal is
  /// not a lock at all (a dropped request, a 5xx): that must surface as a
  /// generic failure instead of telling the student the test is closed.
  Future<String> _blockedAccessCode(
    Object original,
    String assessmentId,
  ) async {
    try {
      final dynamic code = await supabase.rpc(
        'assessment_access',
        params: {'p_quiz': assessmentId},
      );

      if (code is String && code.isNotEmpty) {
        if (code == 'ok') {
          return 'ASSESSMENT_START_FAILED';
        }

        return 'ASSESSMENT_LOCKED:${code.toUpperCase()}';
      }
    } catch (e) {
      // PGRST202: migration not applied yet. Fall through to the plain code.
      debugPrint('assessment_access RPC error: $e');
    }

    debugPrint('start_assessment_attempt refused: $original');
    return 'ASSESSMENT_LOCKED';
  }
}

final assessmentControllerProvider =
NotifierProvider<
    AssessmentController,
    AssessmentSessionState>(
  AssessmentController.new,
);

// Auto-disposed for the same reason as the dashboard provider: while this was
// kept alive for the session, a freshly created student was told they had
// already passed the pretest.
final assessmentListProvider =
    FutureProvider.autoDispose<List<AssessmentListItem>>((ref) async {
      // Watched (not read) so the list rebuilds when the student switches
      // class or the class flow status (pretest done, modules done) changes.
      final activeClass = await resolveActiveStudentClass(ref);
      if (activeClass != null && !activeClass.isLegacyFallback) {
        ref.watch(classLearningFlowStatusProvider(activeClass.id));
      }

      final controller = ref.read(
        assessmentControllerProvider
            .notifier,
      );

      return controller.loadAssessmentList();
    });

// Diturunkan dari daftar yang sudah di-cache supaya halaman instruksi Pretest
// tidak menembak query kedua. Deep link yang langsung mendarat di halaman itu
// tetap mendapat data karena `assessmentListProvider` memuat sendiri saat
// pertama dibaca.
final assessmentByTypeProvider =
    Provider.autoDispose.family<AsyncValue<AssessmentListItem?>, String>(
  (ref, assessmentType) {
    return ref.watch(assessmentListProvider).whenData(
          (assessments) {
            for (final assessment in assessments) {
              if (assessment.assessmentType == assessmentType ||
                  assessment.id == assessmentType) {
                return assessment;
              }
            }

            return null;
          },
        );
  },
);
