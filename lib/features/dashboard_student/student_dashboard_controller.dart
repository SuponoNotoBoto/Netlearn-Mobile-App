import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/avatar/nl_avatar_models.dart';
import '../../core/localization/language_controller.dart';
import '../../core/supabase/supabase_client.dart';
import '../classes/class_controller.dart';

/// A piece of still-open work shown in "Upcoming Task".
///
/// [deadline] is nullable because the course assessments have no deadline set.
/// Requiring one meant this list was always empty for every student.
class StudentDashboardTask {
  final String id;
  final String title;
  final String? subject;
  final DateTime? deadline;
  final String assessmentType;

  const StudentDashboardTask({
    required this.id,
    required this.title,
    required this.subject,
    required this.deadline,
    required this.assessmentType,
  });

  bool get isPretest => assessmentType == 'pretest';

  bool get isPosttest => assessmentType == 'posttest';

  bool get hasDeadline => deadline != null;

  /// Picks the locale variant, preferring the explicit column and falling back
  /// to the base column, which holds the Indonesian copy.
  static String _localizedTitle(
    Map<String, dynamic> map,
    bool isIndonesian,
  ) {
    final String? localized = isIndonesian
        ? map['title_id']?.toString()
        : map['title_en']?.toString();

    if (localized != null && localized.trim().isNotEmpty) {
      return localized.trim();
    }

    return map['title']?.toString().trim() ?? '';
  }

  factory StudentDashboardTask.fromMap(
    Map<String, dynamic> map, {
    required bool isIndonesian,
  }) {
    final material = map['materials'];

    String? subject;

    if (material is Map) {
      final String materialTitle =
          material['title']?.toString().trim() ?? '';

      if (materialTitle.isNotEmpty) {
        subject = materialTitle;
      }
    }

    final String? rawDeadline = map['deadline']?.toString();

    return StudentDashboardTask(
      id: map['id'].toString(),
      title: _localizedTitle(map, isIndonesian),
      subject: subject,
      deadline: rawDeadline == null
          ? null
          : DateTime.tryParse(rawDeadline)?.toLocal(),
      assessmentType:
          map['assessment_type']?.toString() ?? 'pretest',
    );
  }
}

/// Selects the assessment the student still has to do next, in course order:
/// the pretest first, then the posttest once the modules are behind them.
///
/// Only one task is returned because that is the point of the card. Listing
/// both at once showed a new student a posttest they cannot open, and the
/// earlier version of this filtered on a non-null future deadline, which no
/// assessment has, so the card was permanently empty.
///
/// An assessment is skipped once it has a submitted attempt or the flow RPC
/// reports it as passed, and the posttest is skipped while it is still locked
/// so it is never offered as open work before it can be opened.
List<StudentDashboardTask> buildUpcomingTasks({
  required List<dynamic> rows,
  required Set<String> completedQuizIds,
  required Map<String, dynamic> flow,
  required bool isIndonesian,
}) {
  final pretestCompleted = flow['pretest_completed'] == true;
  final posttestCompleted = flow['posttest_completed'] == true;
  final posttestUnlocked = flow['posttest_unlocked'] == true;

  final tasks = rows
      .map(
        (dynamic row) => StudentDashboardTask.fromMap(
          Map<String, dynamic>.from(
            row as Map,
          ),
          isIndonesian: isIndonesian,
        ),
      )
      .where((task) => !completedQuizIds.contains(task.id))
      .toList();

  StudentDashboardTask? byType(String type) {
    for (final task in tasks) {
      if (task.assessmentType == type) {
        return task;
      }
    }

    return null;
  }

  if (!pretestCompleted) {
    return [?byType('pretest')];
  }

  if (!posttestCompleted && posttestUnlocked) {
    return [?byType('posttest')];
  }

  return const [];
}

class StudentDashboardData {
  final String userName;
  final int totalMaterials;
  final int completedMaterials;
  final int inProgressMaterials;
  final int notStartedMaterials;
  final List<StudentDashboardTask> upcomingTasks;

  /// The signed-in student's id and NIM. Optional because the dashboard hero
  /// degrades to a name-only greeting when a caller (or a test) does not
  /// provide them, and because the notification panel needs the id to scope
  /// its reads. Neither is required for the progress figures.
  final String? userId;
  final String? identityNumber;

  /// The study programme shown under the greeting. Optional so a caller (or a
  /// test) that does not supply it keeps the previous constant subtitle.
  final String? program;

  /// Flow flags for the two assessments that sit on the ends of the learning
  /// path. `StudentDashboardData` used to expose only material counts, so the
  /// dashboard could not tell whether the pretest was done or the posttest was
  /// open yet; the component list needs both. They default to the "not done /
  /// still gated" state so an older caller cannot accidentally claim progress.
  final bool pretestCompleted;
  final bool posttestCompleted;
  final bool posttestUnlocked;
  final AvatarConfig? avatarConfig;

  const StudentDashboardData({
    required this.userName,
    required this.totalMaterials,
    required this.completedMaterials,
    required this.inProgressMaterials,
    required this.notStartedMaterials,
    required this.upcomingTasks,
    this.userId,
    this.identityNumber,
    this.program,
    this.pretestCompleted = false,
    this.posttestCompleted = false,
    this.posttestUnlocked = false,
    this.avatarConfig,
  });

  /// The letter shown in the hero avatar circle.
  String get initial {
    final trimmed = userName.trim();

    if (trimmed.isEmpty) {
      return 'M';
    }

    return trimmed[0].toUpperCase();
  }

  double get progress {
    if (totalMaterials == 0) {
      return 0;
    }

    return completedMaterials / totalMaterials;
  }

  int get progressPercentage {
    return (progress * 100).round();
  }
}

class StudentDashboardController
    extends AsyncNotifier<StudentDashboardData> {
  @override
  Future<StudentDashboardData> build() async {
    return _loadDashboard();
  }

  bool _isIndonesian() {
    return ref.read(languageProvider).languageCode == 'id';
  }

  /// Reads the learning flow RPC, tolerating the shapes PostgREST uses for a
  /// function returning a single record.
  Future<Map<String, dynamic>> _loadFlowStatus(String userId) async {
    final dynamic response = await supabase.rpc(
      'get_learning_flow_status',
      params: {'p_user': userId},
    );

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    if (response is List && response.isNotEmpty && response.first is Map) {
      return Map<String, dynamic>.from(response.first as Map);
    }

    return const {};
  }

  Future<StudentDashboardData> _loadDashboard() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Sesi pengguna tidak ditemukan.');
    }

    final profile = await supabase
        .from('profiles')
        .select('name, identity_number, program, avatar_config')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      throw Exception(
        'Profil mahasiswa tidak ditemukan.',
      );
    }

    AvatarConfig? avatarConfig = AvatarConfig.fromDynamic(profile['avatar_config']);
    if (avatarConfig == null) {
      avatarConfig = AvatarConfig.defaultFor(user.id);
      try {
        await supabase
            .from('profiles')
            .update({'avatar_config': avatarConfig.toMap()})
            .eq('id', user.id);
      } catch (_) {}
    }

    final userName =
    profile['name']?.toString().trim();

    if (userName == null || userName.isEmpty) {
      throw Exception(
        'Nama mahasiswa tidak ditemukan.',
      );
    }

    final activeClass = await resolveActiveStudentClass(ref);
    final isClassScoped = activeClass != null && !activeClass.isLegacyFallback;

    final List<dynamic> materials;
    final Map<String, Map<String, dynamic>> progressByMaterial;

    if (isClassScoped) {
      final classMats = await supabase
          .from('materials')
          .select('id, published')
          .eq('class_id', activeClass.id)
          .eq('published', true);
      materials = classMats as List;

      final mpRows = await supabase
          .from('material_progress')
          .select('material_id, reading_completed, video_completed')
          .eq('class_id', activeClass.id)
          .eq('student_id', user.id);

      progressByMaterial = <String, Map<String, dynamic>>{
        for (final row in mpRows as List)
          row['material_id'].toString(): Map<String, dynamic>.from(row as Map),
      };
    } else {
      final globalMats = await supabase
          .from('materials')
          .select('id, published')
          .eq('published', true)
          .isFilter('class_id', null);
      materials = globalMats as List;

      final progressRows = await supabase
          .from('learning_progress')
          .select('material_id, reading_completed, video_completed')
          .eq('user_id', user.id);

      progressByMaterial = <String, Map<String, dynamic>>{
        for (final row in progressRows as List)
          row['material_id'].toString(): Map<String, dynamic>.from(row as Map),
      };
    }

    int completed = 0;
    int inProgress = 0;
    int notStarted = 0;

    for (final material in materials) {
      final materialId =
      material['id'].toString();

      final progress =
      progressByMaterial[materialId];

      final readingCompleted =
      progress?['reading_completed'] == true;

      final videoCompleted =
      progress?['video_completed'] == true;

      final hasProgress =
      readingCompleted || videoCompleted;

      // Per-material evaluation was replaced by the pretest / posttest, so a
      // material counts as completed once its reading and video are done.
      final isCompleted =
      readingCompleted && videoCompleted;

      if (isCompleted) {
        completed++;
      } else if (hasProgress) {
        inProgress++;
      } else {
        notStarted++;
      }
    }

    final bool isIndonesian = _isIndonesian();

    // Open work for this student: every published assessment they have not
    // passed yet. The previous query required a future, non-null deadline, and
    // neither the pretest nor the posttest has one, so the card was always
    // empty.
    final List<dynamic> quizRows;
    if (isClassScoped) {
      final rows = await supabase
          .from('quizzes')
          .select(
        'id, title, title_en, title_id, deadline, status, '
            'assessment_type, created_at, materials(title)',
      )
          .eq('class_id', activeClass.id)
          .eq('status', 'published')
          .order('created_at');
      quizRows = rows as List;
    } else {
      final rows = await supabase
          .from('quizzes')
          .select(
        'id, title, title_en, title_id, deadline, status, '
            'assessment_type, created_at, materials(title)',
      )
          .eq('status', 'published')
          .isFilter('class_id', null)
          .order('created_at');
      quizRows = rows as List;
    }

    final attemptRows = await supabase
        .from('quiz_attempts')
        .select('quiz_id, status')
        .eq('user_id', user.id)
        .eq('status', 'submitted');

    final Set<String> completedQuizIds = attemptRows
        .map(
          (row) => row['quiz_id'].toString(),
        )
        .toSet();

    final Map<String, dynamic> flow;
    if (isClassScoped) {
      final classFlow = await ref.watch(
        classLearningFlowStatusProvider(activeClass.id).future,
      );
      final pretestDone = classFlow != null &&
          (!classFlow.pretestEnabled || classFlow.pretestCompleted);
      final posttestDone = classFlow?.posttestCompleted ?? false;
      final posttestUnlocked = classFlow?.posttestUnlocked ?? false;
      flow = {
        'pretest_completed': pretestDone,
        'posttest_completed': posttestDone,
        'posttest_unlocked': posttestUnlocked,
      };
    } else {
      flow = await _loadFlowStatus(user.id);
    }

    final upcomingTasks = buildUpcomingTasks(
      rows: quizRows,
      completedQuizIds: completedQuizIds,
      flow: flow,
      isIndonesian: isIndonesian,
    );

    return StudentDashboardData(
      userName: userName,
      totalMaterials: materials.length,
      completedMaterials: completed,
      inProgressMaterials: inProgress,
      notStartedMaterials: notStarted,
      upcomingTasks: upcomingTasks,
      userId: user.id,
      identityNumber: profile['identity_number']?.toString(),
      program: profile['program']?.toString(),
      pretestCompleted: flow['pretest_completed'] == true,
      posttestCompleted: flow['posttest_completed'] == true,
      posttestUnlocked: flow['posttest_unlocked'] == true,
      avatarConfig: AvatarConfig.fromDynamic(profile['avatar_config']),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      _loadDashboard,
    );
  }
}

// Auto-disposed so the dashboard can never outlive the student it describes.
// Cached for the session, it greeted the next person to sign in with the
// previous student's name and progress.
final studentDashboardProvider =
    AsyncNotifierProvider.autoDispose<
      StudentDashboardController,
      StudentDashboardData>(
      StudentDashboardController.new,
    );
