import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/progress/progress_refresh.dart';
import '../../core/supabase/supabase_client.dart';
import '../../shared/models/material_model.dart';
import '../dashboard_lecturer/announcement_controller.dart';
import '../dashboard_lecturer/lecturer_assessments_controller.dart';
import '../dashboard_lecturer/lecturer_dashboard_controller.dart';
import '../dashboard_lecturer/lecturer_materials_controller.dart';
import '../dashboard_lecturer/lecturer_students_controller.dart';
import '../dashboard_lecturer/notification_controller.dart';
import 'class_models.dart';

// ============================================================
// ERROR MAPPING
// ============================================================

enum ClassActionFailure {
  classNameRequired,
  classNotReady,
  pretestNotReady,
  posttestNotReady,
  moduleTitleRequired,
  moduleNotReady,
  assessmentNotReady,
  invalidClassCode,
  tooManyAttempts,
  classArchived,
  notPermitted,
  leaderboardDisabled,
  unknown,
}

class ClassActionException implements Exception {
  const ClassActionException(this.failure, [this.detail]);

  final ClassActionFailure failure;
  final String? detail;

  @override
  String toString() => 'ClassActionException($failure)';
}

ClassActionException mapClassActionError(Object error) {
  if (error is ClassActionException) {
    return error;
  }

  if (error is! PostgrestException) {
    return ClassActionException(
      ClassActionFailure.unknown,
      error.toString(),
    );
  }

  final message = error.message;
  final code = error.code ?? '';

  if (message.contains('CLASS_NAME_REQUIRED')) {
    return ClassActionException(ClassActionFailure.classNameRequired, message);
  }
  if (message.contains('CLASS_NOT_READY')) {
    return ClassActionException(ClassActionFailure.classNotReady, message);
  }
  if (message.contains('PRETEST_NOT_READY')) {
    return ClassActionException(ClassActionFailure.pretestNotReady, message);
  }
  if (message.contains('POSTTEST_NOT_READY')) {
    return ClassActionException(ClassActionFailure.posttestNotReady, message);
  }
  if (message.contains('MODULE_TITLE_REQUIRED')) {
    return ClassActionException(
      ClassActionFailure.moduleTitleRequired,
      message,
    );
  }
  if (message.contains('MODULE_NOT_READY')) {
    return ClassActionException(ClassActionFailure.moduleNotReady, message);
  }
  if (message.contains('ASSESSMENT_NOT_READY') ||
      message.contains('QUIZ_INCOMPLETE')) {
    return ClassActionException(ClassActionFailure.assessmentNotReady, message);
  }
  if (message.contains('INVALID_CLASS_CODE')) {
    return ClassActionException(ClassActionFailure.invalidClassCode, message);
  }
  if (message.contains('TOO_MANY_ATTEMPTS')) {
    return ClassActionException(ClassActionFailure.tooManyAttempts, message);
  }
  if (message.contains('CLASS_ARCHIVED')) {
    return ClassActionException(ClassActionFailure.classArchived, message);
  }
  if (message.contains('LEADERBOARD_DISABLED')) {
    return ClassActionException(
      ClassActionFailure.leaderboardDisabled,
      message,
    );
  }
  if (message.contains('NOT_PERMITTED') ||
      message.contains('NOT_SIGNED_IN') ||
      message.contains('NOT_A_STUDENT') ||
      code == '42501') {
    return ClassActionException(ClassActionFailure.notPermitted, message);
  }

  return ClassActionException(
    ClassActionFailure.unknown,
    message.isEmpty ? error.toString() : message,
  );
}

// ============================================================
// SAFE SUPABASE ACCESS FOR OFFLINE WIDGET TESTS
// ============================================================

SupabaseClient? _supabaseOrNull() {
  try {
    return supabase;
  } catch (_) {
    // Widget tests do not call Supabase.initialize(); returning null lets
    // dashboard providers degrade gracefully when not explicitly overridden.
    return null;
  }
}

// ============================================================
// ACTIVE CLASS SELECTION (STUDENT & LECTURER)
// ============================================================

class ActiveClassIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? classId) {
    state = classId;
  }
}

final activeStudentClassIdProvider =
    NotifierProvider<ActiveClassIdNotifier, String?>(
  ActiveClassIdNotifier.new,
);

final activeLecturerClassIdProvider =
    NotifierProvider<ActiveClassIdNotifier, String?>(
  ActiveClassIdNotifier.new,
);

/// Switches the student's active class and invalidates every progress-derived
/// provider so no progress or lock state from the previous class lingers
/// (Requirement 5.6, 11.6).
void selectStudentActiveClass(WidgetRef ref, String? classId) {
  final current = ref.read(activeStudentClassIdProvider);
  ref.read(activeStudentClassIdProvider.notifier).select(classId);

  final client = _supabaseOrNull();
  final uid = client?.auth.currentUser?.id;
  if (uid != null) {
    SharedPreferences.getInstance().then((prefs) {
      if (classId != null && classId.isNotEmpty) {
        prefs.setString('active_student_class_id_$uid', classId);
      } else {
        prefs.remove('active_student_class_id_$uid');
      }
    }).catchError((_) {});
  }

  if (current != classId) {
    invalidateStudentProgress(ref);
    ref.invalidate(userAnnouncementsProvider);
  }
}

/// Switches the lecturer's active class and invalidates class-scoped providers.
void selectLecturerActiveClass(dynamic ref, String? classId) {
  final notifier = ref is WidgetRef
      ? ref.read(activeLecturerClassIdProvider.notifier)
      : (ref as Ref).read(activeLecturerClassIdProvider.notifier);
  final current = ref is WidgetRef
      ? ref.read(activeLecturerClassIdProvider)
      : (ref as Ref).read(activeLecturerClassIdProvider);
  notifier.select(classId);

  final client = _supabaseOrNull();
  final uid = client?.auth.currentUser?.id;
  if (uid != null) {
    SharedPreferences.getInstance().then((prefs) {
      if (classId != null && classId.isNotEmpty) {
        prefs.setString('active_lecturer_class_id_$uid', classId);
      } else {
        prefs.remove('active_lecturer_class_id_$uid');
      }
    }).catchError((_) {});
  }

  if (current != classId) {
    if (ref is WidgetRef) {
      ref.invalidate(lecturerStudentsProvider);
      ref.invalidate(lecturerMaterialsProvider);
      ref.invalidate(lecturerAssessmentsProvider);
      ref.invalidate(lecturerTasksProvider);
      ref.invalidate(lecturerDashboardStatsProvider);
      ref.invalidate(lecturerAnnouncementsProvider);
      ref.invalidate(userAnnouncementsProvider);
      ref.invalidate(lecturerMissingAssessmentRemindersProvider);
      ref.invalidate(classGateAssessmentsProvider);
      ref.invalidate(classLeaderboardQuizzesProvider);
    } else {
      final r = ref as Ref;
      r.invalidate(lecturerStudentsProvider);
      r.invalidate(lecturerMaterialsProvider);
      r.invalidate(lecturerAssessmentsProvider);
      r.invalidate(lecturerTasksProvider);
      r.invalidate(lecturerDashboardStatsProvider);
      r.invalidate(lecturerAnnouncementsProvider);
      r.invalidate(userAnnouncementsProvider);
      r.invalidate(lecturerMissingAssessmentRemindersProvider);
      r.invalidate(classGateAssessmentsProvider);
      r.invalidate(classLeaderboardQuizzesProvider);
    }
  }
}

// ============================================================
// CLASS LIST PROVIDERS
// ============================================================

/// Classes the signed-in student is enrolled in (`my_classes()` RPC).
final studentClassesProvider =
    FutureProvider.autoDispose<List<StudentClass>>((ref) async {
  final client = _supabaseOrNull();
  if (client == null) {
    // Offline widget tests that do not override `studentClassesProvider`
    // expect the legacy v6 single-class flow to render.
    return const [
      StudentClass(
        id: kLegacyFallbackClassId,
        name: 'NetLearn 2.0',
        status: 'published',
      ),
    ];
  }

  if (client.auth.currentUser == null) {
    return const <StudentClass>[];
  }

  final response = await client.rpc('my_classes');
  if (response is! List) {
    return const <StudentClass>[];
  }

  final list = response
      .map((item) => StudentClass.fromMap(Map<String, dynamic>.from(item as Map)))
      .toList();

  final currentSelected = ref.read(activeStudentClassIdProvider);
  if (currentSelected == null && client.auth.currentUser != null) {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(
        'active_student_class_id_${client.auth.currentUser!.id}',
      );
      if (savedId != null && list.any((c) => c.id == savedId)) {
        ref.read(activeStudentClassIdProvider.notifier).select(savedId);
      }
    } catch (_) {}
  }

  return list;
});

/// Resolves the currently active [StudentClass], defaulting to the first
/// enrolled class when the student has not manually picked one yet.
final activeStudentClassProvider =
    Provider.autoDispose<AsyncValue<StudentClass?>>((ref) {
  final classesAsync = ref.watch(studentClassesProvider);
  final selectedId = ref.watch(activeStudentClassIdProvider);

  return classesAsync.whenData((classes) {
    if (classes.isEmpty) {
      return null;
    }
    if (selectedId != null) {
      for (final item in classes) {
        if (item.id == selectedId) {
          return item;
        }
      }
    }
    return classes.first;
  });
});

/// Async helper for providers/controllers that need the resolved [StudentClass].
Future<StudentClass?> resolveActiveStudentClass(dynamic ref) async {
  try {
    final classes = await (ref is WidgetRef
        ? ref.read(studentClassesProvider.future)
        : (ref as Ref).watch(studentClassesProvider.future));
    final selectedId = ref is WidgetRef
        ? ref.read(activeStudentClassIdProvider)
        : (ref as Ref).watch(activeStudentClassIdProvider);
    if (classes.isEmpty) return null;
    if (selectedId != null) {
      for (final item in classes) {
        if (item.id == selectedId) return item;
      }
    }
    return classes.first;
  } catch (_) {
    return null;
  }
}

/// Like [resolveActiveStudentClass] but uses `ref.read`, for Notifier methods
/// (e.g. the assessment session) that must not rebuild — and lose their
/// in-progress state — when the class list is invalidated.
Future<StudentClass?> readActiveStudentClass(Ref ref) async {
  final classes = await ref.read(studentClassesProvider.future);
  final selectedId = ref.read(activeStudentClassIdProvider);
  if (classes.isEmpty) return null;
  if (selectedId != null) {
    for (final item in classes) {
      if (item.id == selectedId) return item;
    }
  }
  return classes.first;
}

/// Async helper for providers/controllers that need the resolved [LecturerClass].
Future<LecturerClass?> resolveActiveLecturerClass(dynamic ref) async {
  try {
    final classes = await (ref is WidgetRef
        ? ref.read(lecturerClassesProvider.future)
        : (ref as Ref).watch(lecturerClassesProvider.future));
    final selectedId = ref is WidgetRef
        ? ref.read(activeLecturerClassIdProvider)
        : (ref as Ref).watch(activeLecturerClassIdProvider);
    if (classes.isEmpty) return null;
    if (selectedId != null) {
      for (final item in classes) {
        if (item.id == selectedId) return item;
      }
    }
    return classes.first;
  } catch (_) {
    return null;
  }
}

/// Active (non-archived) classes owned by the signed-in lecturer
/// (`lecturer_classes()` RPC).
final lecturerClassesProvider =
    FutureProvider.autoDispose<List<LecturerClass>>((ref) async {
  final client = _supabaseOrNull();
  if (client == null) {
    // Offline widget tests that do not override `lecturerClassesProvider`
    // expect the legacy v6 single-class flow to render.
    return const [
      LecturerClass(
        id: kLegacyFallbackClassId,
        name: 'NetLearn 2.0',
        status: 'published',
      ),
    ];
  }
  if (client.auth.currentUser == null) {
    return const <LecturerClass>[];
  }

  final response = await client.rpc('lecturer_classes');
  if (response is! List) {
    return const <LecturerClass>[];
  }

  final list = response
      .map(
        (item) => LecturerClass.fromMap(Map<String, dynamic>.from(item as Map)),
      )
      .toList();

  final currentSelected = ref.read(activeLecturerClassIdProvider);
  if (currentSelected == null && client.auth.currentUser != null) {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(
        'active_lecturer_class_id_${client.auth.currentUser!.id}',
      );
      if (savedId != null && list.any((c) => c.id == savedId)) {
        ref.read(activeLecturerClassIdProvider.notifier).select(savedId);
      }
    } catch (_) {}
  }

  return list;
});

/// Resolves the currently active [LecturerClass], defaulting to the first
/// owned class when the lecturer has not manually picked one yet.
final activeLecturerClassProvider =
    Provider.autoDispose<AsyncValue<LecturerClass?>>((ref) {
  final classesAsync = ref.watch(lecturerClassesProvider);
  final selectedId = ref.watch(activeLecturerClassIdProvider);

  return classesAsync.whenData((classes) {
    if (classes.isEmpty) {
      return null;
    }
    if (selectedId != null) {
      for (final item in classes) {
        if (item.id == selectedId) {
          return item;
        }
      }
    }
    return classes.first;
  });
});

/// Archived classes owned by the signed-in lecturer.
final lecturerArchivedClassesProvider =
    FutureProvider.autoDispose<List<LecturerClass>>((ref) async {
  final client = _supabaseOrNull();
  if (client == null || client.auth.currentUser == null) {
    return const <LecturerClass>[];
  }

  try {
    final response = await client.rpc('lecturer_archived_classes');
    if (response is List) {
      return response
          .map(
            (item) =>
                LecturerClass.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    }
  } on PostgrestException catch (error) {
    // Fallback to direct table read if migration 20261104120000 has not been
    // applied to the remote DB yet.
    if (error.code != 'PGRST202') {
      rethrow;
    }
  }

  final rows = await client
      .from('classes')
      .select('id, name, description, semester, status, created_at')
      .eq('lecturer_id', client.auth.currentUser!.id)
      .eq('status', 'archived')
      .order('created_at', ascending: false);

  return (rows as List)
      .map(
        (item) => LecturerClass.fromMap(Map<String, dynamic>.from(item as Map)),
      )
      .toList();
});

// ============================================================
// PER-CLASS DETAIL PROVIDERS
// ============================================================

final classSettingsProvider = FutureProvider.autoDispose
    .family<ClassSettingsModel?, String>((ref, classId) async {
  final client = _supabaseOrNull();
  if (client == null ||
      classId.isEmpty ||
      classId == kLegacyFallbackClassId) {
    return null;
  }

  final row = await client
      .from('class_settings')
      .select(
        'class_id, pretest_enabled, posttest_enabled, '
        'leaderboard_enabled, policy_version',
      )
      .eq('class_id', classId)
      .maybeSingle();

  if (row == null) {
    return null;
  }
  return ClassSettingsModel.fromMap(Map<String, dynamic>.from(row));
});

final classInviteProvider = FutureProvider.autoDispose
    .family<ClassInviteModel?, String>((ref, classId) async {
  final client = _supabaseOrNull();
  if (client == null ||
      classId.isEmpty ||
      classId == kLegacyFallbackClassId) {
    return null;
  }

  final row = await client
      .from('class_invites')
      .select('class_id, code, active, rotated_at')
      .eq('class_id', classId)
      .maybeSingle();

  if (row == null) {
    return null;
  }
  return ClassInviteModel.fromMap(Map<String, dynamic>.from(row));
});

int _resolveClassModuleNumber(ClassModule cm) {
  if (cm.templateModuleNumber != null && cm.templateModuleNumber! > 0) {
    return cm.templateModuleNumber!;
  }
  final match = RegExp(
    r'(?:modul|module)\s*(\d+)',
    caseSensitive: false,
  ).firstMatch(cm.title);
  if (match != null) {
    final parsed = int.tryParse(match.group(1)!);
    if (parsed != null && parsed > 0) return parsed;
  }
  return cm.position > 0 ? cm.position : 1;
}

/// Ordered modules (`class_modules`) for [classId] with material counts.
final classModulesProvider = FutureProvider.autoDispose
    .family<List<ClassModule>, String>((ref, classId) async {
  final client = _supabaseOrNull();
  if (client == null ||
      classId.isEmpty ||
      classId == kLegacyFallbackClassId) {
    return const <ClassModule>[];
  }

  final moduleRows = await client
      .from('class_modules')
      .select(
        'id, class_id, position, title, title_en, title_id, '
        'description, description_en, description_id, status, '
        'template_module_number',
      )
      .eq('class_id', classId)
      .order('position');

  final modules = (moduleRows as List)
      .map((row) => ClassModule.fromMap(Map<String, dynamic>.from(row as Map)))
      .toList();

  modules.sort((a, b) {
    final numA = _resolveClassModuleNumber(a);
    final numB = _resolveClassModuleNumber(b);
    if (numA != numB) return numA.compareTo(numB);
    return a.position.compareTo(b.position);
  });

  if (modules.isEmpty) {
    return const <ClassModule>[];
  }

  final materialRows = await client
      .from('materials')
      .select('id, module_id, published')
      .eq('class_id', classId);

  final totalByModule = <String, int>{};
  final publishedByModule = <String, int>{};

  for (final raw in materialRows as List) {
    final map = Map<String, dynamic>.from(raw as Map);
    final modId = map['module_id']?.toString();
    if (modId == null || modId.isEmpty) continue;
    totalByModule[modId] = (totalByModule[modId] ?? 0) + 1;
    if (map['published'] == true) {
      publishedByModule[modId] = (publishedByModule[modId] ?? 0) + 1;
    }
  }

  return [
    for (final mod in modules)
      mod.copyWith(
        materialCount: totalByModule[mod.id] ?? 0,
        publishedMaterialCount: publishedByModule[mod.id] ?? 0,
      ),
  ];
});

/// Materials belonging to a specific `(classId, moduleId)`.
final classModuleMaterialsProvider = FutureProvider.autoDispose
    .family<List<ClassMaterialEntry>, ({String classId, String moduleId})>(
  (ref, arg) async {
    final client = _supabaseOrNull();
    if (client == null || arg.classId.isEmpty || arg.moduleId.isEmpty) {
      return const <ClassMaterialEntry>[];
    }

    final rows = await client
        .from('materials')
        .select('''
          id,
          class_id,
          module_id,
          module_number,
          is_core,
          order_index,
          content_version,
          title,
          description,
          content,
          summary,
          title_en,
          title_id,
          description_en,
          description_id,
          content_en,
          content_id,
          summary_en,
          summary_id,
          pdf_url,
          video_url,
          video_id,
          duration_minutes,
          published,
          lock_status,
          created_by,
          created_at,
          updated_at
        ''')
        .eq('class_id', arg.classId)
        .eq('module_id', arg.moduleId)
        .order('order_index')
        .order('id');

    return (rows as List)
        .map(
          (row) =>
              ClassMaterialEntry.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  },
);

/// Pretest & Posttest gate rows for [classId] with question and key counts.
final classGateAssessmentsProvider = FutureProvider.autoDispose
    .family<List<ClassGateAssessment>, String>((ref, classId) async {
  final client = _supabaseOrNull();
  if (client == null ||
      classId.isEmpty ||
      classId == kLegacyFallbackClassId) {
    return const <ClassGateAssessment>[];
  }

  final quizRows = await client
      .from('quizzes')
      .select(
        'id, title, title_en, title_id, assessment_type, '
        'duration_minutes, status',
      )
      .eq('class_id', classId)
      .inFilter('assessment_type', ['pretest', 'posttest'])
      .order('assessment_type');

  final quizzes = (quizRows as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();

  if (quizzes.isEmpty) {
    return const <ClassGateAssessment>[];
  }

  final quizIds = quizzes.map((q) => q['id'].toString()).toList();
  final questionRows = await client
      .from('questions')
      .select('id, quiz_id')
      .inFilter('quiz_id', quizIds);

  final questionList = (questionRows as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();
  final questionIds = questionList.map((q) => q['id'].toString()).toList();

  final answeredQuestionIds = <String>{};
  if (questionIds.isNotEmpty) {
    final keyRows = await client
        .from('question_keys')
        .select('question_id')
        .inFilter('question_id', questionIds);
    for (final raw in keyRows as List) {
      answeredQuestionIds.add((raw as Map)['question_id'].toString());
    }
  }

  final qCountByQuiz = <String, int>{};
  final aCountByQuiz = <String, int>{};
  for (final q in questionList) {
    final qid = q['quiz_id'].toString();
    qCountByQuiz[qid] = (qCountByQuiz[qid] ?? 0) + 1;
    if (answeredQuestionIds.contains(q['id'].toString())) {
      aCountByQuiz[qid] = (aCountByQuiz[qid] ?? 0) + 1;
    }
  }

  return [
    for (final q in quizzes)
      ClassGateAssessment.fromMap({
        ...q,
        'question_count': qCountByQuiz[q['id'].toString()] ?? 0,
        'answered_count': aCountByQuiz[q['id'].toString()] ?? 0,
      }),
  ];
});

/// All quizzes for [classId] that participate in the leaderboard
/// or can be inspected in the Per-Asesmen tab (includes Pretest, Posttest,
/// custom tasks, module quizzes, and class assessments).
final classLeaderboardQuizzesProvider = FutureProvider.autoDispose
    .family<List<ClassGateAssessment>, String>((ref, classId) async {
  final client = _supabaseOrNull();
  if (client == null ||
      classId.isEmpty ||
      classId == kLegacyFallbackClassId) {
    return const <ClassGateAssessment>[];
  }

  // Fetch quizzes strictly scoped to this class so each class keeps its own
  // leaderboard and per-assessment inspection space.
  final quizRows = await client
      .from('quizzes')
      .select(
        'id, title, title_en, title_id, assessment_type, '
        'duration_minutes, status, leaderboard_enabled, class_id',
      )
      .eq('class_id', classId)
      .order('assessment_type')
      .order('created_at');

  final rawQuizzes = (quizRows as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();

  final quizzes = <Map<String, dynamic>>[];
  for (final q in rawQuizzes) {
    final type = q['assessment_type']?.toString() ?? '';
    final isGate = type == 'pretest' || type == 'posttest';

    // Leaderboard inclusion rule:
    // - Pretest & Posttest are ALWAYS included for inspection
    // - Custom tasks and quizzes are included unless explicitly disabled
    if (!isGate && q['leaderboard_enabled'] == false) {
      continue;
    }

    quizzes.add(q);
  }

  // Sort: Pretest first -> Custom tasks / module quizzes -> Posttest last
  quizzes.sort((a, b) {
    final typeA = a['assessment_type']?.toString() ?? '';
    final typeB = b['assessment_type']?.toString() ?? '';
    int rank(String t) {
      if (t == 'pretest') return 0;
      if (t == 'posttest') return 2;
      return 1;
    }
    final rCmp = rank(typeA).compareTo(rank(typeB));
    if (rCmp != 0) return rCmp;
    final titleA = a['title']?.toString() ?? '';
    final titleB = b['title']?.toString() ?? '';
    return titleA.compareTo(titleB);
  });

  if (quizzes.isEmpty) {
    return const <ClassGateAssessment>[];
  }

  final quizIds = quizzes.map((q) => q['id'].toString()).toList();
  final questionRows = await client
      .from('questions')
      .select('id, quiz_id')
      .inFilter('quiz_id', quizIds);

  final questionList = (questionRows as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();

  final qCountByQuiz = <String, int>{};
  for (final q in questionList) {
    final qid = q['quiz_id'].toString();
    qCountByQuiz[qid] = (qCountByQuiz[qid] ?? 0) + 1;
  }

  return [
    for (final q in quizzes)
      ClassGateAssessment.fromMap({
        ...q,
        'question_count': qCountByQuiz[q['id'].toString()] ?? 0,
        'answered_count': qCountByQuiz[q['id'].toString()] ?? 0,
      }),
  ];
});

/// Enrolled student roster for [classId] (`class_roster()` RPC).
final classRosterProvider = FutureProvider.autoDispose
    .family<List<ClassMember>, String>((ref, classId) async {
  final client = _supabaseOrNull();
  if (client == null ||
      classId.isEmpty ||
      classId == kLegacyFallbackClassId) {
    return const <ClassMember>[];
  }

  final response = await client.rpc(
    'class_roster',
    params: {'p_class': classId},
  );

  if (response is! List) {
    return const <ClassMember>[];
  }

  return response
      .map((row) => ClassMember.fromMap(Map<String, dynamic>.from(row as Map)))
      .toList();
});

/// Class-scoped learning flow status (`get_class_learning_flow_status()` RPC,
/// with client synthesis fallback if the migration has not been applied yet).
final classLearningFlowStatusProvider = FutureProvider.autoDispose
    .family<ClassLearningFlowStatus?, String>((ref, classId) async {
  final client = _supabaseOrNull();
  if (client == null ||
      classId.isEmpty ||
      classId == kLegacyFallbackClassId) {
    return null;
  }

  ClassLearningFlowStatus? rpcStatus;
  try {
    final response = await client.rpc(
      'get_class_learning_flow_status',
      params: {'p_class': classId},
    );
    if (response is List && response.isNotEmpty) {
      rpcStatus = ClassLearningFlowStatus.fromMap(
        Map<String, dynamic>.from(response.first as Map),
      );
    } else if (response is Map<String, dynamic>) {
      rpcStatus = ClassLearningFlowStatus.fromMap(response);
    }
  } on PostgrestException catch (error) {
    // PGRST202: RPC not applied yet. Any other failure also falls through to
    // the client synthesis below instead of surfacing as an error, because a
    // failed class flow made callers fall back to the v6 *global* flow, which
    // reports the class pretest as not done and locks Module 1.
    debugPrint('get_class_learning_flow_status failed: ${error.code} ${error.message}');
  }

  final userId = client.auth.currentUser?.id;

  if (rpcStatus != null) {
    // The RPC is the source of truth, but a pretest finished on the global
    // template (or on a class copy that was later re-created) is not seen by
    // older versions of has_completed_class_gate(). Re-check the student's own
    // submitted attempts so a finished pretest never keeps Module 1 locked.
    var effectivePretestDone = rpcStatus.pretestCompleted;
    if (rpcStatus.pretestEnabled && !effectivePretestDone && userId != null) {
      effectivePretestDone = await hasSubmittedClassGateAttempt(
        client,
        classId: classId,
        userId: userId,
        assessmentType: 'pretest',
      );
    }

    // Verify completed modules against client synthesis / global learning progress
    // so that students who finished reading materials never have Posttest locked out.
    var effectiveCompletedModules = rpcStatus.completedModules;
    if (effectiveCompletedModules < rpcStatus.totalModules && userId != null) {
      try {
        final modules = await ref.watch(classModulesProvider(classId).future);
        final publishedModules = modules.where((m) => m.isPublished).toList();
        final clientCount = await _countCompletedClassModules(
          client,
          classId: classId,
          userId: userId,
          publishedModuleIds: publishedModules.map((m) => m.id).toList(),
        );
        if (clientCount > effectiveCompletedModules) {
          effectiveCompletedModules = clientCount;
        }

        // Also check global learning_progress (v6) fallback
        if (effectiveCompletedModules < rpcStatus.totalModules) {
          final lpRows = await client
              .from('learning_progress')
              .select('material_id')
              .eq('user_id', userId)
              .eq('reading_completed', true);
          if ((lpRows as List).length >= 4) {
            effectiveCompletedModules = rpcStatus.totalModules;
          }
        }
      } catch (_) {}
    }

    if (effectivePretestDone != rpcStatus.pretestCompleted ||
        effectiveCompletedModules != rpcStatus.completedModules) {
      return ClassLearningFlowStatus.evaluate(
        pretestEnabled: rpcStatus.pretestEnabled,
        posttestEnabled: rpcStatus.posttestEnabled,
        leaderboardEnabled: rpcStatus.leaderboardEnabled,
        policyVersion: rpcStatus.policyVersion,
        pretestCompleted: effectivePretestDone,
        totalPublishedModules: rpcStatus.totalModules,
        completedPublishedModules: effectiveCompletedModules,
        posttestCompleted: rpcStatus.posttestCompleted,
      );
    }
    return rpcStatus;
  }

  // Fallback synthesis from class_settings + class_modules + the student's own
  // attempts / material progress if the RPC is not yet applied on the remote.
  final settings = await ref.watch(classSettingsProvider(classId).future);
  final modules = await ref.watch(classModulesProvider(classId).future);
  final publishedModules = modules.where((m) => m.isPublished).toList();

  var pretestCompleted = false;
  var posttestCompleted = false;
  var completedModules = 0;

  if (userId != null) {
    pretestCompleted = await hasSubmittedClassGateAttempt(
      client,
      classId: classId,
      userId: userId,
      assessmentType: 'pretest',
    );
    posttestCompleted = await hasSubmittedClassGateAttempt(
      client,
      classId: classId,
      userId: userId,
      assessmentType: 'posttest',
    );
    completedModules = await _countCompletedClassModules(
      client,
      classId: classId,
      userId: userId,
      publishedModuleIds: publishedModules.map((m) => m.id).toList(),
    );
  }

  return ClassLearningFlowStatus.evaluate(
    pretestEnabled: settings?.pretestEnabled ?? false,
    posttestEnabled: settings?.posttestEnabled ?? false,
    leaderboardEnabled: settings?.leaderboardEnabled ?? true,
    policyVersion: settings?.policyVersion ?? 1,
    pretestCompleted: pretestCompleted,
    totalPublishedModules: publishedModules.length,
    completedPublishedModules: completedModules,
    posttestCompleted: posttestCompleted,
  );
});

/// Whether [userId] has a submitted attempt on a gate assessment of
/// [assessmentType] for [classId].
///
/// Mirrors `has_completed_class_gate()` (migration `20261105100000`): any
/// submitted attempt on the class's own copy counts, and for the pretest an
/// attempt on the global template counts too (the class copy is a clone of it).
Future<bool> hasSubmittedClassGateAttempt(
  SupabaseClient client, {
  required String classId,
  required String userId,
  required String assessmentType,
}) async {
  try {
    final filter = 'class_id.eq.$classId,class_id.is.null';
    final quizRows = await client
        .from('quizzes')
        .select('id')
        .eq('assessment_type', assessmentType)
        .or(filter);
    final quizIds = (quizRows as List)
        .map((row) => (row as Map)['id'].toString())
        .toList();
    if (quizIds.isEmpty) {
      return false;
    }

    final attempts = await client
        .from('quiz_attempts')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'submitted')
        .inFilter('quiz_id', quizIds)
        .limit(1);
    return (attempts as List).isNotEmpty;
  } catch (_) {
    return false;
  }
}

Future<int> _countCompletedClassModules(
  SupabaseClient client, {
  required String classId,
  required String userId,
  required List<String> publishedModuleIds,
}) async {
  if (publishedModuleIds.isEmpty) {
    return 0;
  }
  try {
    final matRows = await client
        .from('materials')
        .select('id, module_id, video_id, lock_status')
        .eq('class_id', classId)
        .eq('published', true);
    final progressRows = await client
        .from('material_progress')
        .select('material_id, reading_completed, video_completed')
        .eq('class_id', classId)
        .eq('student_id', userId);

    final progress = <String, Map<String, dynamic>>{
      for (final raw in progressRows as List)
        (raw as Map)['material_id'].toString(): Map<String, dynamic>.from(raw),
    };

    final materialsByModule = <String, List<Map<String, dynamic>>>{};
    for (final raw in matRows as List) {
      final map = Map<String, dynamic>.from(raw as Map);
      final modId = map['module_id']?.toString();
      if (modId == null) continue;
      materialsByModule.putIfAbsent(modId, () => []).add(map);
    }

    var done = 0;
    for (final modId in publishedModuleIds) {
      final mats = materialsByModule[modId] ?? const <Map<String, dynamic>>[];
      final complete = mats.every((m) {
        if ((m['lock_status']?.toString() ?? 'default') != 'default') {
          return true;
        }
        final p = progress[m['id'].toString()];
        final read = p?['reading_completed'] == true;
        final hasVideo =
            m['video_id'] != null && m['video_id'].toString().isNotEmpty;
        final video = !hasVideo || p?['video_completed'] == true;
        return read && video;
      });
      if (complete) done++;
    }
    return done;
  } catch (_) {
    return 0;
  }
}

// ============================================================
// LEADERBOARD PROVIDERS & PURE CALCULATORS (PRD §10)
// ============================================================

/// Pure calculation of per-assessment leaderboard (PRD §10.1).
///
/// Rules:
/// - Only `submitted` (or `graded`) attempts with a non-null score are included.
/// - Score is clamped to `0..100`.
/// - Multiple attempts: highest score wins (`bestScore`).
/// - Tie-break: (1) highest score DESC, (2) earliest `submittedAt` that reached
///   that highest score ASC, (3) `studentId` ASC.
/// - Students without a valid submitted attempt are omitted (never shown as 0).
List<AssessmentLeaderboardEntry> computeAssessmentLeaderboard({
  required List<Map<String, dynamic>> attempts,
  required String currentUserId,
  required bool isLecturerView,
}) {
  final grouped = <String, List<Map<String, dynamic>>>{};

  for (final raw in attempts) {
    final status = raw['status']?.toString() ?? '';
    if (status != 'submitted' && status != 'graded') {
      continue;
    }
    final rawScore = raw['score'];
    if (rawScore is! num) {
      continue;
    }
    final studentId = raw['student_id']?.toString() ??
        raw['user_id']?.toString() ??
        '';
    if (studentId.isEmpty) {
      continue;
    }
    grouped.putIfAbsent(studentId, () => []).add(raw);
  }

  final entries = <AssessmentLeaderboardEntry>[];

  for (final entry in grouped.entries) {
    final studentId = entry.key;
    final rows = entry.value;

    double bestScore = -1;
    DateTime? bestAt;
    String fullName = 'Student';
    String? identityNumber;

    for (final row in rows) {
      final score = (row['score'] as num).toDouble().clamp(0.0, 100.0);
      final ts = DateTime.tryParse(
            row['submitted_at']?.toString() ??
                row['started_at']?.toString() ??
                '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      fullName = row['name']?.toString() ?? fullName;
      identityNumber = row['identity_number']?.toString() ?? identityNumber;

      if (score > bestScore ||
          (score == bestScore && (bestAt == null || ts.isBefore(bestAt)))) {
        bestScore = score;
        bestAt = ts;
      }
    }

    final isMe = studentId == currentUserId;
    final reveal = isLecturerView || isMe;

    entries.add(
      AssessmentLeaderboardEntry(
        rankPosition: 0,
        studentId: studentId,
        displayName: maskStudentDisplayName(fullName, reveal: reveal),
        identityNumber: isLecturerView ? identityNumber : null,
        bestScore: double.parse(bestScore.toStringAsFixed(2)),
        attemptCount: rows.length,
        achievedAt: bestAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        isMe: isMe,
      ),
    );
  }

  entries.sort((a, b) {
    final scoreCmp = b.bestScore.compareTo(a.bestScore);
    if (scoreCmp != 0) return scoreCmp;
    final timeCmp = a.achievedAt.compareTo(b.achievedAt);
    if (timeCmp != 0) return timeCmp;
    return a.studentId.compareTo(b.studentId);
  });

  return [
    for (var i = 0; i < entries.length; i++)
      AssessmentLeaderboardEntry(
        rankPosition: i + 1,
        studentId: entries[i].studentId,
        displayName: entries[i].displayName,
        identityNumber: entries[i].identityNumber,
        bestScore: entries[i].bestScore,
        attemptCount: entries[i].attemptCount,
        achievedAt: entries[i].achievedAt,
        isMe: entries[i].isMe,
      ),
  ];
}

/// Pure calculation of the Overall Class Leaderboard (PRD §10.2).
///
/// Rules:
/// - Only assessments with `status == 'published'` and
///   `leaderboard_enabled == true` are considered.
/// - `pretest` is excluded by default; `posttest` is included only when
///   `posttestEnabled` is true; optional assessments (`required == false` and
///   type != `'posttest'`) are excluded from the overall weighted score by
///   default so students who skip optional assessments are not penalized.
/// - Weighted score: `Σ(best_score × weight) / Σ(weight)`.
/// - Students who completed all counted assessments are placed in `'final'`;
///   those with partial completion are placed in `'in_progress'` (provisional).
/// - Tie-break:
///   (1) cohort (`final` before `in_progress`)
///   (2) `weightedScore` DESC
///   (3) `completedAssessments` DESC
///   (4) `unweightedAvg` DESC
///   (5) `completedAt` ASC
///   (6) `studentId` ASC
List<ClassLeaderboardEntry> computeClassLeaderboard({
  required List<Map<String, dynamic>> assessments,
  required List<Map<String, dynamic>> attempts,
  required bool posttestEnabled,
  required int policyVersion,
  required String currentUserId,
  required bool isLecturerView,
}) {
  final rankedWeights = <String, double>{};

  for (final quiz in assessments) {
    final status = quiz['status']?.toString() ?? '';
    final lbOn = quiz['leaderboard_enabled'] != false;
    final type = quiz['assessment_type']?.toString() ?? '';
    final id = quiz['id']?.toString() ?? '';

    if (id.isEmpty || status != 'published' || !lbOn) {
      continue;
    }
    if (type == 'posttest' && !posttestEnabled) {
      continue;
    }

    final rawWeight = (quiz['weight'] as num?)?.toDouble() ?? 1.0;
    rankedWeights[id] = rawWeight <= 0 ? 1.0 : rawWeight;
  }

  final totalRanked = rankedWeights.length;
  if (totalRanked == 0) {
    return const <ClassLeaderboardEntry>[];
  }

  // Map: studentId -> quizId -> (bestScore, earliestAt, name, nim)
  final bestPerStudentQuiz =
      <String, Map<String, ({double score, DateTime at})>>{};
  final names = <String, String>{};
  final nims = <String, String?>{};

  for (final raw in attempts) {
    final status = raw['status']?.toString() ?? '';
    if (status != 'submitted' && status != 'graded') continue;

    final quizId = raw['quiz_id']?.toString() ?? '';
    if (!rankedWeights.containsKey(quizId)) continue;

    final rawScore = raw['score'];
    if (rawScore is! num) continue;

    final studentId = raw['student_id']?.toString() ??
        raw['user_id']?.toString() ??
        '';
    if (studentId.isEmpty) continue;

    final score = rawScore.toDouble().clamp(0.0, 100.0);
    final ts = DateTime.tryParse(
          raw['submitted_at']?.toString() ??
              raw['started_at']?.toString() ??
              '',
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    names[studentId] = raw['name']?.toString() ?? names[studentId] ?? 'Student';
    nims[studentId] =
        raw['identity_number']?.toString() ?? nims[studentId];

    final quizMap = bestPerStudentQuiz.putIfAbsent(studentId, () => {});
    final prev = quizMap[quizId];
    if (prev == null ||
        score > prev.score ||
        (score == prev.score && ts.isBefore(prev.at))) {
      quizMap[quizId] = (score: score, at: ts);
    }
  }

  final rawEntries = <ClassLeaderboardEntry>[];

  for (final entry in bestPerStudentQuiz.entries) {
    final studentId = entry.key;
    final quizScores = entry.value;
    if (quizScores.isEmpty) continue;

    double weightedSum = 0;
    double unweightedSum = 0;
    DateTime? latestCompletion;

    for (final qEntry in quizScores.entries) {
      final weight = rankedWeights[qEntry.key] ?? 1.0;
      weightedSum += qEntry.value.score * weight;
      unweightedSum += qEntry.value.score;
      if (latestCompletion == null ||
          qEntry.value.at.isAfter(latestCompletion)) {
        latestCompletion = qEntry.value.at;
      }
    }

    final completedCount = quizScores.length;
    final unweightedAvg = unweightedSum / completedCount;
    final isFinal = completedCount >= totalRanked;
    final isMe = studentId == currentUserId;
    final reveal = isLecturerView || isMe;

    rawEntries.add(
      ClassLeaderboardEntry(
        rankPosition: 0,
        studentId: studentId,
        displayName: maskStudentDisplayName(
          names[studentId] ?? 'Student',
          reveal: reveal,
        ),
        identityNumber: isLecturerView ? nims[studentId] : null,
        cohort: isFinal ? 'final' : 'in_progress',
        weightedScore: double.parse(weightedSum.toStringAsFixed(1)),
        unweightedAvg: double.parse(unweightedAvg.toStringAsFixed(2)),
        completedAssessments: completedCount,
        totalRankedAssessments: totalRanked,
        completedAt: latestCompletion,
        policyVersion: policyVersion,
        isMe: isMe,
      ),
    );
  }

  rawEntries.sort((a, b) {
    final cohortA = a.isFinal ? 0 : 1;
    final cohortB = b.isFinal ? 0 : 1;
    if (cohortA != cohortB) return cohortA.compareTo(cohortB);

    final wCmp = b.weightedScore.compareTo(a.weightedScore);
    if (wCmp != 0) return wCmp;

    final cntCmp = b.completedAssessments.compareTo(a.completedAssessments);
    if (cntCmp != 0) return cntCmp;

    final uCmp = b.unweightedAvg.compareTo(a.unweightedAvg);
    if (uCmp != 0) return uCmp;

    final timeA = a.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final timeB = b.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final tCmp = timeA.compareTo(timeB);
    if (tCmp != 0) return tCmp;

    return a.studentId.compareTo(b.studentId);
  });

  return [
    for (var i = 0; i < rawEntries.length; i++)
      ClassLeaderboardEntry(
        rankPosition: i + 1,
        studentId: rawEntries[i].studentId,
        displayName: rawEntries[i].displayName,
        identityNumber: rawEntries[i].identityNumber,
        cohort: rawEntries[i].cohort,
        weightedScore: rawEntries[i].weightedScore,
        unweightedAvg: rawEntries[i].unweightedAvg,
        completedAssessments: rawEntries[i].completedAssessments,
        totalRankedAssessments: rawEntries[i].totalRankedAssessments,
        completedAt: rawEntries[i].completedAt,
        policyVersion: rawEntries[i].policyVersion,
        isMe: rawEntries[i].isMe,
      ),
  ];
}

final assessmentLeaderboardProvider = FutureProvider.autoDispose.family<
    List<AssessmentLeaderboardEntry>,
    ({String classId, String quizId})>((ref, arg) async {
  final client = _supabaseOrNull();
  if (client == null ||
      arg.classId.isEmpty ||
      arg.quizId.isEmpty ||
      arg.classId == kLegacyFallbackClassId) {
    return const <AssessmentLeaderboardEntry>[];
  }

  final response = await client.rpc(
    'get_assessment_leaderboard',
    params: {
      'p_class': arg.classId,
      'p_quiz': arg.quizId,
    },
  );

  if (response is! List) {
    return const <AssessmentLeaderboardEntry>[];
  }

  return response
      .map(
        (row) => AssessmentLeaderboardEntry.fromMap(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
});

final classLeaderboardProvider = FutureProvider.autoDispose
    .family<List<ClassLeaderboardEntry>, String>((ref, classId) async {
  final client = _supabaseOrNull();
  if (client == null ||
      classId.isEmpty ||
      classId == kLegacyFallbackClassId) {
    return const <ClassLeaderboardEntry>[];
  }

  final response = await client.rpc(
    'get_class_leaderboard',
    params: {'p_class': classId},
  );

  if (response is! List) {
    return const <ClassLeaderboardEntry>[];
  }

  return response
      .map(
        (row) => ClassLeaderboardEntry.fromMap(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
});

// ============================================================
// MUTATION ACTIONS
// ============================================================

void _invalidateLecturerClassReads(WidgetRef ref, [String? classId]) {
  ref.invalidate(lecturerClassesProvider);
  ref.invalidate(lecturerArchivedClassesProvider);
  ref.invalidate(lecturerDashboardStatsProvider);
  ref.invalidate(lecturerAssessmentsProvider);
  ref.invalidate(lecturerTasksProvider);
  ref.invalidate(lecturerMissingAssessmentRemindersProvider);
  if (classId != null && classId.isNotEmpty) {
    ref.invalidate(classSettingsProvider(classId));
    ref.invalidate(classInviteProvider(classId));
    ref.invalidate(classModulesProvider(classId));
    ref.invalidate(classGateAssessmentsProvider(classId));
    ref.invalidate(classRosterProvider(classId));
    ref.invalidate(classLeaderboardProvider(classId));
    ref.invalidate(classLeaderboardQuizzesProvider(classId));
  }
}

/// Creates a class from the NetLearn template or as an empty custom class
/// (PRD §6.1, §6.2, §6.3). Returns `(classId, code)`.
Future<({String classId, String code})> createClassAction(
  WidgetRef ref, {
  required String name,
  String? description,
  String? semester,
  required bool useTemplate,
  required bool pretestEnabled,
  required bool posttestEnabled,
}) async {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    throw const ClassActionException(ClassActionFailure.classNameRequired);
  }

  try {
    final rpcName =
        useTemplate ? 'create_class_from_template' : 'create_custom_class';
    final response = await supabase.rpc(
      rpcName,
      params: {
        'p_name': trimmed,
        'p_description':
            description?.trim().isEmpty == true ? null : description?.trim(),
        'p_semester':
            semester?.trim().isEmpty == true ? null : semester?.trim(),
        'p_pretest': pretestEnabled,
        'p_posttest': posttestEnabled,
      },
    );

    Map<String, dynamic>? row;
    if (response is List && response.isNotEmpty) {
      row = Map<String, dynamic>.from(response.first as Map);
    } else if (response is Map<String, dynamic>) {
      row = response;
    }

    final classId = row?['class_id']?.toString() ?? '';
    final code = row?['code']?.toString() ?? '';

    if (classId.isNotEmpty) {
      if (useTemplate) {
        // Template classes already carry the 4 core modules, their materials,
        // and the keyed pretest/posttest questions. Auto-publishing them makes
        // the newly created class immediately joinable by students using the
        // invite code displayed on the creation screen.
        await _autoPublishTemplateClassBestEffort(
          classId,
          pretestEnabled: pretestEnabled,
          posttestEnabled: posttestEnabled,
        );
      } else {
        // Custom classes still benefit from having pretest/posttest gate copies
        // ready in case the lecturer enables either gate.
        await ensureClassGateAssessmentsExist(classId);
      }
    }

    _invalidateLecturerClassReads(ref, classId);
    if (classId.isNotEmpty) {
      ref.read(activeLecturerClassIdProvider.notifier).select(classId);
    }

    return (classId: classId, code: code);
  } catch (error) {
    throw mapClassActionError(error);
  }
}

/// Ensures `pretest` and `posttest` rows exist for [classId] in `public.quizzes`
/// (cloning the global template gate quizzes and their keyed questions if
/// missing, such as in a custom class).
Future<void> ensureClassGateAssessmentsExist(String classId) async {
  final client = _supabaseOrNull();
  final userId = client?.auth.currentUser?.id;
  if (client == null || userId == null || classId.isEmpty) {
    return;
  }

  try {
    final existingRows = await client
        .from('quizzes')
        .select('id, assessment_type')
        .eq('class_id', classId)
        .inFilter('assessment_type', ['pretest', 'posttest']);

    final existingQuizByType = <String, String>{};
    for (final raw in existingRows as List) {
      final map = raw as Map;
      final type = map['assessment_type']?.toString() ?? '';
      final id = map['id']?.toString() ?? '';
      if (type.isNotEmpty && id.isNotEmpty && !existingQuizByType.containsKey(type)) {
        existingQuizByType[type] = id;
      }
    }

    for (final gateType in const ['pretest', 'posttest']) {
      var targetQuizId = existingQuizByType[gateType] ?? '';
      if (targetQuizId.isNotEmpty) {
        final existingQuestions = await client
            .from('questions')
            .select('id')
            .eq('quiz_id', targetQuizId)
            .limit(1);
        if ((existingQuestions as List).isNotEmpty) {
          continue;
        }
      }

      final tplQuiz = await client
          .from('quizzes')
          .select(
            'id, title, title_en, title_id, description, description_en, '
            'description_id, duration_minutes, assessment_type',
          )
          .isFilter('class_id', null)
          .eq('assessment_type', gateType)
          .order('created_at')
          .limit(1)
          .maybeSingle();

      if (tplQuiz == null) continue;
      final tplMap = Map<String, dynamic>.from(tplQuiz);
      final tplQuizId = tplMap['id']?.toString() ?? '';
      if (tplQuizId.isEmpty) continue;

      if (targetQuizId.isEmpty) {
        final insertedQuiz = await client
            .from('quizzes')
            .insert({
              'class_id': classId,
              'module_id': null,
              'material_id': null,
              'title': tplMap['title'],
              'title_en': tplMap['title_en'],
              'title_id': tplMap['title_id'],
              'description': tplMap['description'],
              'description_en': tplMap['description_en'],
              'description_id': tplMap['description_id'],
              'duration_minutes': tplMap['duration_minutes'] ?? 30,
              'assessment_type': gateType,
              'status': 'draft',
              'required': true,
              'attempts_allowed': 1,
              'weight': 1,
              'leaderboard_enabled': true,
              'sort_order': gateType == 'pretest' ? 1 : 99,
              'created_by': userId,
            })
            .select('id')
            .single();

        targetQuizId = insertedQuiz['id']?.toString() ?? '';
      }
      if (targetQuizId.isEmpty) continue;

      final tplQuestions = await client
          .from('questions')
          .select(
            'id, order_index, question_text, question_text_en, '
            'question_text_id, option_a, option_a_en, option_a_id, '
            'option_b, option_b_en, option_b_id, option_c, option_c_en, '
            'option_c_id, option_d, option_d_en, option_d_id, image_url',
          )
          .eq('quiz_id', tplQuizId)
          .order('order_index');

      final qList = (tplQuestions as List)
          .map((q) => Map<String, dynamic>.from(q as Map))
          .toList();
      if (qList.isEmpty) continue;

      final tplQIds = qList.map((q) => q['id'].toString()).toList();
      final keyRows = await client
          .from('question_keys')
          .select('question_id, correct_answer')
          .inFilter('question_id', tplQIds);
      final keyByOldQId = <String, String>{
        for (final k in keyRows as List)
          (k as Map)['question_id'].toString():
              k['correct_answer']?.toString() ?? '',
      };

      for (final q in qList) {
        final oldQId = q['id'].toString();
        final newQ = await client
            .from('questions')
            .insert({
              'quiz_id': targetQuizId,
              'order_index': q['order_index'],
              'question_text': q['question_text'],
              'question_text_en': q['question_text_en'],
              'question_text_id': q['question_text_id'],
              'option_a': q['option_a'],
              'option_a_en': q['option_a_en'],
              'option_a_id': q['option_a_id'],
              'option_b': q['option_b'],
              'option_b_en': q['option_b_en'],
              'option_b_id': q['option_b_id'],
              'option_c': q['option_c'],
              'option_c_en': q['option_c_en'],
              'option_c_id': q['option_c_id'],
              'option_d': q['option_d'],
              'option_d_en': q['option_d_en'],
              'option_d_id': q['option_d_id'],
              'image_url': q['image_url'],
            })
            .select('id')
            .single();
        final newQId = newQ['id']?.toString() ?? '';
        final correctAns = keyByOldQId[oldQId];
        if (newQId.isNotEmpty &&
            correctAns != null &&
            correctAns.isNotEmpty) {
          await client.from('question_keys').insert({
            'question_id': newQId,
            'correct_answer': correctAns,
          });
        }
      }
    }
  } catch (_) {
    // Best-effort helper; never block class creation if offline or mocked.
  }
}

Future<void> _autoPublishTemplateClassBestEffort(
  String classId, {
  required bool pretestEnabled,
  required bool posttestEnabled,
}) async {
  try {
    await supabase
        .from('materials')
        .update({'published': true})
        .eq('class_id', classId);

    final modRows = await supabase
        .from('class_modules')
        .select('id')
        .eq('class_id', classId)
        .order('position');

    for (final raw in modRows as List) {
      final modId = (raw as Map)['id']?.toString() ?? '';
      if (modId.isNotEmpty) {
        await supabase.rpc(
          'set_class_module_status',
          params: {'p_module': modId, 'p_status': 'published'},
        );
      }
    }

    for (final gateType in const ['pretest', 'posttest']) {
      try {
        await supabase.rpc(
          'set_class_gate_assessment',
          params: {
            'p_class': classId,
            'p_type': gateType,
            'p_published': true,
          },
        );
      } catch (_) {
        // Ignore if a gate assessment is not present.
      }
    }

    await supabase.rpc(
      'set_class_status',
      params: {'p_class': classId, 'p_status': 'published'},
    );
  } catch (_) {
    // Best-effort during template creation; lecturer can still publish manually.
  }
}

/// Updates class name, description, and semester.
Future<void> updateClassInfoAction(
  WidgetRef ref, {
  required String classId,
  required String name,
  String? description,
  String? semester,
}) async {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    throw const ClassActionException(ClassActionFailure.classNameRequired);
  }

  try {
    try {
      await supabase.rpc(
        'update_class_info',
        params: {
          'p_class': classId,
          'p_name': trimmed,
          'p_description':
              description?.trim().isEmpty == true ? null : description?.trim(),
          'p_semester':
              semester?.trim().isEmpty == true ? null : semester?.trim(),
        },
      );
    } on PostgrestException catch (error) {
      if (error.code != 'PGRST202') rethrow;
      await supabase.from('classes').update({
        'name': trimmed,
        'description':
            description?.trim().isEmpty == true ? null : description?.trim(),
        'semester':
            semester?.trim().isEmpty == true ? null : semester?.trim(),
      }).eq('id', classId);
    }

    _invalidateLecturerClassReads(ref, classId);
  } catch (error) {
    throw mapClassActionError(error);
  }
}

/// Transitions a class between `draft`, `published`, and `archived`
/// (`set_class_status` RPC, PRD §6.6).
///
/// When transitioning to `'published'`, automatically prepares any un-published
/// template/module content and enabled gate assessments when they are ready so
/// the lecturer does not hit `CLASS_NOT_READY` or `PRETEST_NOT_READY` on a
/// class that already has valid content.
Future<void> setClassStatusAction(
  WidgetRef ref, {
  required String classId,
  required String status,
}) async {
  try {
    if (status == 'published') {
      await _prepareClassForPublish(classId);
    }

    await supabase.rpc(
      'set_class_status',
      params: {
        'p_class': classId,
        'p_status': status,
      },
    );

    _invalidateLecturerClassReads(ref, classId);
  } catch (error) {
    throw mapClassActionError(error);
  }
}

Future<void> _prepareClassForPublish(String classId) async {
  try {
    await ensureClassGateAssessmentsExist(classId);

    // 1. Inspect class materials; if the class has materials but none are
    //    published yet (e.g. a newly created template class), publish them.
    final matRows = await supabase
        .from('materials')
        .select('id, module_id, published')
        .eq('class_id', classId);
    final mats = (matRows as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();

    if (mats.isNotEmpty && !mats.any((m) => m['published'] == true)) {
      await supabase
          .from('materials')
          .update({'published': true})
          .eq('class_id', classId);
      for (final m in mats) {
        m['published'] = true;
      }
    }

    final modulesWithPublishedMat = <String>{
      for (final m in mats)
        if (m['published'] == true && m['module_id'] != null)
          m['module_id'].toString(),
    };

    // 2. Inspect class modules; if none are published yet, publish every module
    //    that contains at least one published material.
    final modRows = await supabase
        .from('class_modules')
        .select('id, status')
        .eq('class_id', classId)
        .order('position');
    final mods = (modRows as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();

    final hasPublishedMod = mods.any(
      (m) =>
          m['status']?.toString() == 'published' &&
          modulesWithPublishedMat.contains(m['id']?.toString()),
    );

    if (!hasPublishedMod) {
      for (final mod in mods) {
        final modId = mod['id']?.toString() ?? '';
        if (modId.isNotEmpty && modulesWithPublishedMat.contains(modId)) {
          await supabase.rpc(
            'set_class_module_status',
            params: {'p_module': modId, 'p_status': 'published'},
          );
        }
      }
    }

    // 3. Ensure enabled gate assessments (pretest / posttest) are published.
    final settingsRow = await supabase
        .from('class_settings')
        .select('pretest_enabled, posttest_enabled')
        .eq('class_id', classId)
        .maybeSingle();

    final pretestOn = settingsRow?['pretest_enabled'] == true;
    final posttestOn = settingsRow?['posttest_enabled'] == true;

    if (pretestOn) {
      try {
        await supabase.rpc(
          'set_class_gate_assessment',
          params: {
            'p_class': classId,
            'p_type': 'pretest',
            'p_published': true,
          },
        );
      } catch (_) {}
    }

    if (posttestOn) {
      try {
        await supabase.rpc(
          'set_class_gate_assessment',
          params: {
            'p_class': classId,
            'p_type': 'posttest',
            'p_published': true,
          },
        );
      } catch (_) {}
    }
  } catch (_) {
    // Let set_class_status perform the authoritative check and raise the exact
    // domain exception if anything is genuinely missing.
  }
}

/// Updates Pretest, Posttest, and Leaderboard toggles for [classId] with
/// policy version bump and audit entry (`update_class_settings` RPC, PRD §8.5).
Future<void> updateClassSettingsAction(
  WidgetRef ref, {
  required String classId,
  required bool pretestEnabled,
  required bool posttestEnabled,
  required bool leaderboardEnabled,
}) async {
  try {
    if (pretestEnabled || posttestEnabled) {
      await ensureClassGateAssessmentsExist(classId);
      if (pretestEnabled) {
        try {
          await supabase.rpc(
            'set_class_gate_assessment',
            params: {
              'p_class': classId,
              'p_type': 'pretest',
              'p_published': true,
            },
          );
        } catch (_) {}
      }
      if (posttestEnabled) {
        try {
          await supabase.rpc(
            'set_class_gate_assessment',
            params: {
              'p_class': classId,
              'p_type': 'posttest',
              'p_published': true,
            },
          );
        } catch (_) {}
      }
    }

    await supabase.rpc(
      'update_class_settings',
      params: {
        'p_class': classId,
        'p_pretest_enabled': pretestEnabled,
        'p_posttest_enabled': posttestEnabled,
        'p_leaderboard_enabled': leaderboardEnabled,
      },
    );

    _invalidateLecturerClassReads(ref, classId);
  } catch (error) {
    throw mapClassActionError(error);
  }
}

/// Rotates the invite code for [classId], returning the new code
/// (`rotate_class_invite` RPC, PRD §6.4).
Future<String> rotateClassInviteAction(
  WidgetRef ref,
  String classId,
) async {
  try {
    final response = await supabase.rpc(
      'rotate_class_invite',
      params: {'p_class': classId},
    );

    final newCode = response?.toString() ?? '';
    _invalidateLecturerClassReads(ref, classId);
    return newCode;
  } catch (error) {
    throw mapClassActionError(error);
  }
}

/// Enables or disables the invite code for [classId] without rotating it.
Future<void> setClassInviteActiveAction(
  WidgetRef ref, {
  required String classId,
  required bool active,
}) async {
  try {
    await supabase.rpc(
      'set_class_invite_active',
      params: {
        'p_class': classId,
        'p_active': active,
      },
    );

    _invalidateLecturerClassReads(ref, classId);
  } catch (error) {
    throw mapClassActionError(error);
  }
}

/// Joins a published class by invite code (`join_by_code` RPC, PRD §6.4).
///
/// Idempotent on the server. Also selects the joined class as the student's
/// active class and refreshes student progress providers.
Future<({String classId, String className})> joinClassByCodeAction(
  WidgetRef ref,
  String code,
) async {
  final normalized = code.trim().toUpperCase();
  if (normalized.isEmpty) {
    throw const ClassActionException(ClassActionFailure.invalidClassCode);
  }

  try {
    final response = await supabase.rpc(
      'join_by_code',
      params: {'p_code': normalized},
    );

    Map<String, dynamic>? row;
    if (response is List && response.isNotEmpty) {
      row = Map<String, dynamic>.from(response.first as Map);
    } else if (response is Map<String, dynamic>) {
      row = response;
    }

    final classId = row?['class_id']?.toString() ?? '';
    final className = row?['class_name']?.toString() ?? '';

    ref.invalidate(studentClassesProvider);
    if (classId.isNotEmpty) {
      ref.read(activeStudentClassIdProvider.notifier).select(classId);
    }
    invalidateStudentProgress(ref);

    return (classId: classId, className: className);
  } catch (error) {
    throw mapClassActionError(error);
  }
}

/// Student leaves a class (`enrollments` delete).
Future<void> leaveClassAction(
  WidgetRef ref,
  String classId,
) async {
  try {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const ClassActionException(ClassActionFailure.notPermitted);
    }

    await supabase
        .from('enrollments')
        .delete()
        .eq('class_id', classId)
        .eq('student_id', userId);

    if (ref.read(activeStudentClassIdProvider) == classId) {
      ref.read(activeStudentClassIdProvider.notifier).select(null);
    }
    ref.invalidate(studentClassesProvider);
    invalidateStudentProgress(ref);
  } catch (error) {
    throw mapClassActionError(error);
  }
}

/// Lecturer removes a student from a class (`enrollments` delete, preserving
/// assessment & progress history per PRD §6.5).
Future<void> removeClassMemberAction(
  WidgetRef ref, {
  required String classId,
  required String studentId,
}) async {
  try {
    try {
      await supabase.rpc(
        'remove_class_member',
        params: {
          'p_class': classId,
          'p_student': studentId,
        },
      );
    } on PostgrestException catch (error) {
      if (error.code != 'PGRST202') rethrow;
      await supabase
          .from('enrollments')
          .delete()
          .eq('class_id', classId)
          .eq('student_id', studentId);
    }

    _invalidateLecturerClassReads(ref, classId);
  } catch (error) {
    throw mapClassActionError(error);
  }
}

/// Creates a new module inside [classId] (`create_class_module` RPC, PRD §7.1).
Future<String> createClassModuleAction(
  WidgetRef ref, {
  required String classId,
  required String titleId,
  String? titleEn,
  String? descriptionId,
  String? descriptionEn,
  int? position,
}) async {
  final idText = titleId.trim();
  final enText = (titleEn ?? '').trim();
  final baseTitle = idText.isNotEmpty ? idText : enText;

  if (baseTitle.isEmpty) {
    throw const ClassActionException(ClassActionFailure.moduleTitleRequired);
  }

  try {
    final response = await supabase.rpc(
      'create_class_module',
      params: {
        'p_class': classId,
        'p_title': baseTitle,
        'p_title_en': enText.isEmpty ? null : enText,
        'p_title_id': idText.isEmpty ? null : idText,
        'p_description': (descriptionId ?? '').trim().isNotEmpty
            ? descriptionId!.trim()
            : (descriptionEn ?? '').trim().isEmpty
                ? null
                : descriptionEn!.trim(),
        'p_description_en': (descriptionEn ?? '').trim().isEmpty
            ? null
            : descriptionEn!.trim(),
        'p_description_id': (descriptionId ?? '').trim().isEmpty
            ? null
            : descriptionId!.trim(),
        'p_position': position,
      },
    );

    final moduleId = response?.toString() ?? '';
    _invalidateLecturerClassReads(ref, classId);
    return moduleId;
  } catch (error) {
    throw mapClassActionError(error);
  }
}

/// Updates a module's bilingual title and description (`update_class_module`).
Future<void> updateClassModuleAction(
  WidgetRef ref, {
  required String classId,
  required String moduleId,
  required String titleId,
  String? titleEn,
  String? descriptionId,
  String? descriptionEn,
}) async {
  final idText = titleId.trim();
  final enText = (titleEn ?? '').trim();
  final baseTitle = idText.isNotEmpty ? idText : enText;

  if (baseTitle.isEmpty) {
    throw const ClassActionException(ClassActionFailure.moduleTitleRequired);
  }

  try {
    await supabase.rpc(
      'update_class_module',
      params: {
        'p_module': moduleId,
        'p_title': baseTitle,
        'p_title_en': enText.isEmpty ? null : enText,
        'p_title_id': idText.isEmpty ? null : idText,
        'p_description': (descriptionId ?? '').trim().isNotEmpty
            ? descriptionId!.trim()
            : (descriptionEn ?? '').trim().isEmpty
                ? null
                : descriptionEn!.trim(),
        'p_description_en': (descriptionEn ?? '').trim().isEmpty
            ? null
            : descriptionEn!.trim(),
        'p_description_id': (descriptionId ?? '').trim().isEmpty
            ? null
            : descriptionId!.trim(),
      },
    );

    _invalidateLecturerClassReads(ref, classId);
  } catch (error) {
    throw mapClassActionError(error);
  }
}

/// Reorders modules in [classId] (`reorder_class_modules` RPC, PRD §7.3).
Future<void> reorderClassModulesAction(
  WidgetRef ref, {
  required String classId,
  required List<String> moduleIds,
}) async {
  try {
    await supabase.rpc(
      'reorder_class_modules',
      params: {
        'p_class': classId,
        'p_module_ids': moduleIds,
      },
    );

    _invalidateLecturerClassReads(ref, classId);
  } catch (error) {
    throw mapClassActionError(error);
  }
}

/// Changes a module's status between `draft`, `published`, and `archived`
/// (`set_class_module_status` RPC).
///
/// When publishing a module whose materials are all still in draft, marks its
/// materials as published first so the lecturer does not hit `MODULE_NOT_READY`
/// on a module that already contains materials.
Future<void> setClassModuleStatusAction(
  WidgetRef ref, {
  required String classId,
  required String moduleId,
  required String status,
}) async {
  try {
    if (status == 'published') {
      try {
        final matRows = await supabase
            .from('materials')
            .select('id, published')
            .eq('class_id', classId)
            .eq('module_id', moduleId);
        final list = (matRows as List)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList();
        if (list.isNotEmpty && !list.any((m) => m['published'] == true)) {
          await supabase
              .from('materials')
              .update({'published': true})
              .eq('class_id', classId)
              .eq('module_id', moduleId);
        }
      } catch (_) {}
    }

    await supabase.rpc(
      'set_class_module_status',
      params: {
        'p_module': moduleId,
        'p_status': status,
      },
    );

    _invalidateLecturerClassReads(ref, classId);
    ref.invalidate(
      classModuleMaterialsProvider((classId: classId, moduleId: moduleId)),
    );
  } catch (error) {
    throw mapClassActionError(error);
  }
}

/// Publishes or unpublishes a class gate assessment (`pretest` or `posttest`)
/// via `set_class_gate_assessment`.
Future<void> setClassGateAssessmentPublishedAction(
  WidgetRef ref, {
  required String classId,
  required String assessmentType,
  required bool published,
}) async {
  try {
    await ensureClassGateAssessmentsExist(classId);
    await supabase.rpc(
      'set_class_gate_assessment',
      params: {
        'p_class': classId,
        'p_type': assessmentType,
        'p_published': published,
      },
    );

    _invalidateLecturerClassReads(ref, classId);
  } catch (error) {
    throw mapClassActionError(error);
  }
}

/// Toggles `published` on a single class material inside `(classId, moduleId)`.
Future<void> toggleClassMaterialPublishedAction(
  WidgetRef ref, {
  required String classId,
  required String moduleId,
  required String materialId,
  required bool published,
}) async {
  try {
    await supabase
        .from('materials')
        .update({'published': published})
        .eq('id', materialId)
        .eq('class_id', classId);

    _invalidateLecturerClassReads(ref, classId);
    ref.invalidate(
      classModuleMaterialsProvider((classId: classId, moduleId: moduleId)),
    );
    ref.invalidate(lecturerMaterialsProvider);
  } catch (error) {
    throw mapClassActionError(error);
  }
}

/// Updates `lock_status` (`'default'`, `'unlocked'`, `'locked'`) on a single
/// class material inside `(classId, moduleId)`.
Future<void> updateClassMaterialLockStatusAction(
  WidgetRef ref, {
  required String classId,
  required String moduleId,
  required String materialId,
  required String lockStatus,
}) async {
  try {
    await supabase
        .from('materials')
        .update({'lock_status': lockStatus})
        .eq('id', materialId)
        .eq('class_id', classId);

    _invalidateLecturerClassReads(ref, classId);
    ref.invalidate(
      classModuleMaterialsProvider((classId: classId, moduleId: moduleId)),
    );
    ref.invalidate(lecturerMaterialsProvider);
  } catch (error) {
    throw mapClassActionError(error);
  }
}

/// Deletes a class-scoped material (`is_core = false`) from `(classId, moduleId)`.
Future<void> deleteClassMaterialAction(
  WidgetRef ref, {
  required String classId,
  required String moduleId,
  required String materialId,
}) async {
  try {
    await supabase
        .from('materials')
        .delete()
        .eq('id', materialId)
        .eq('class_id', classId);

    _invalidateLecturerClassReads(ref, classId);
    ref.invalidate(
      classModuleMaterialsProvider((classId: classId, moduleId: moduleId)),
    );
    ref.invalidate(lecturerMaterialsProvider);
  } catch (error) {
    throw mapClassActionError(error);
  }
}

/// Creates a material scoped to a specific `(classId, moduleId)`
/// (PRD §7.1, §7.2). Always sets `is_core = false`.
Future<String?> createClassMaterialAction(
  WidgetRef ref, {
  required String classId,
  required String moduleId,
  required int modulePosition,
  required MaterialModel draft,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw const LecturerWriteException(LecturerWriteFailure.notPermitted);
  }

  try {
    final response = await supabase
        .from('materials')
        .insert({
          'class_id': classId,
          'module_id': moduleId,
          'module_number': modulePosition.clamp(1, 99),
          'order_index': draft.orderIndex,
          'is_core': false,
          'created_by': user.id,
          'title': draft.title,
          'description': draft.description,
          'content': draft.content,
          'summary': draft.summary,
          'title_en': draft.titleEn,
          'title_id': draft.titleId,
          'description_en': draft.descriptionEn,
          'description_id': draft.descriptionId,
          'content_en': draft.contentEn,
          'content_id': draft.contentId,
          'summary_en': draft.summaryEn,
          'summary_id': draft.summaryId,
          'video_url': draft.videoUrl,
          'duration_minutes': draft.durationMinutes,
          'pdf_url': draft.pdfUrl,
          'published': draft.published,
          'lock_status': draft.lockStatus,
        })
        .select('id')
        .single();

    _invalidateLecturerClassReads(ref, classId);
    ref.invalidate(
      classModuleMaterialsProvider((classId: classId, moduleId: moduleId)),
    );
    ref.invalidate(lecturerMaterialsProvider);

    return response['id']?.toString();
  } catch (error) {
    throw mapLecturerWriteError(error);
  }
}

/// Copies all materials from `sourceClassId` (or global template if null) into `targetClassId`.
Future<int> cloneClassCurriculumAction(
  WidgetRef ref, {
  required String? sourceClassId,
  required String targetClassId,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw const LecturerWriteException(LecturerWriteFailure.notPermitted);
  }

  try {
    var query = supabase.from('materials').select();
    if (sourceClassId != null && sourceClassId.isNotEmpty) {
      query = query.eq('class_id', sourceClassId);
    } else {
      query = query.isFilter('class_id', null);
    }
    final sourceRows = await query as List<dynamic>;
    if (sourceRows.isEmpty) return 0;

    int clonedCount = 0;
    for (final row in sourceRows) {
      final map = Map<String, dynamic>.from(row as Map);
      await supabase.from('materials').insert({
        'class_id': targetClassId,
        'module_number': map['module_number'] ?? 1,
        'order_index': map['order_index'] ?? 0,
        'is_core': false,
        'created_by': user.id,
        'title': map['title'] ?? '',
        'description': map['description'] ?? '',
        'content': map['content'] ?? '',
        'summary': map['summary'] ?? '',
        'title_en': map['title_en'],
        'title_id': map['title_id'],
        'description_en': map['description_en'],
        'description_id': map['description_id'],
        'content_en': map['content_en'],
        'content_id': map['content_id'],
        'summary_en': map['summary_en'],
        'summary_id': map['summary_id'],
        'video_url': map['video_url'],
        'duration_minutes': map['duration_minutes'] ?? 10,
        'pdf_url': map['pdf_url'],
        'published': true,
        'lock_status': 'unlocked',
      });
      clonedCount++;
    }

    _invalidateLecturerClassReads(ref, targetClassId);
    ref.invalidate(lecturerMaterialsProvider);
    return clonedCount;
  } catch (error) {
    throw mapLecturerWriteError(error);
  }
}


