import '../../core/avatar/nl_avatar_models.dart';
import '../../shared/models/material_model.dart';

/// Bilingual text resolution for class content.
///
/// Mirrors the fallback order used by `_localizedValue` in
/// `student_materials_controller.dart`: the base column is the Indonesian copy,
/// so `id` prefers `*_id`, then the base column, then `*_en`. Do not "simplify"
/// this into `english ?? indonesian` - that would silently serve English text to
/// an Indonesian reader whenever the `*_id` column is empty.
String localizedClassText({
  required String languageCode,
  required String? english,
  required String? indonesian,
  required String fallback,
}) {
  final normalized = languageCode.toLowerCase();
  final en = _clean(english);
  final id = _clean(indonesian);
  final base = _clean(fallback);

  if (normalized == 'id') {
    return id ?? base ?? en ?? '';
  }
  return en ?? base ?? id ?? '';
}

String? _clean(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

/// Sentinel ID used only when a widget test pumps a student screen without
/// initializing Supabase or overriding `studentClassesProvider`.
const String kLegacyFallbackClassId = '__legacy_fallback_class__';

/// A class as the student sees it (`my_classes()` RPC).
class StudentClass {
  const StudentClass({
    required this.id,
    required this.name,
    required this.status,
    this.description,
    this.semester,
    this.lecturerName,
    this.joinedAt,
    this.moduleCount = 0,
  });

  final String id;
  final String name;
  final String status;
  final String? description;
  final String? semester;
  final String? lecturerName;
  final DateTime? joinedAt;

  /// Filled by the UI from [ClassSummary] when both are known; `my_classes()`
  /// does not aggregate module counts.
  final int moduleCount;

  bool get isPublished => status == 'published';
  bool get isLegacyFallback => id == kLegacyFallbackClassId;

  StudentClass copyWith({int? moduleCount}) => StudentClass(
        id: id,
        name: name,
        status: status,
        description: description,
        semester: semester,
        lecturerName: lecturerName,
        joinedAt: joinedAt,
        moduleCount: moduleCount ?? this.moduleCount,
      );

  factory StudentClass.fromMap(Map<String, dynamic> map) {
    return StudentClass(
      id: map['class_id']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      status: map['status']?.toString() ?? 'draft',
      description: _clean(map['description']?.toString()),
      semester: _clean(map['semester']?.toString()),
      lecturerName: _clean(map['lecturer_name']?.toString()),
      joinedAt: DateTime.tryParse(map['joined_at']?.toString() ?? ''),
      moduleCount: (map['module_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A class as its owning lecturer sees it (`lecturer_classes()` RPC).
class LecturerClass {
  const LecturerClass({
    required this.id,
    required this.name,
    required this.status,
    this.description,
    this.semester,
    this.code,
    this.memberCount = 0,
    this.moduleCount = 0,
    this.pretestEnabled = false,
    this.posttestEnabled = false,
    this.leaderboardEnabled = true,
    this.policyVersion = 1,
    this.createdAt,
  });

  final String id;
  final String name;
  final String status;
  final String? description;
  final String? semester;
  final String? code;
  final int memberCount;
  final int moduleCount;
  final bool pretestEnabled;
  final bool posttestEnabled;
  final bool leaderboardEnabled;
  final int policyVersion;
  final DateTime? createdAt;

  bool get isPublished => status == 'published';
  bool get isDraft => status == 'draft';
  bool get isArchived => status == 'archived';
  bool get isLegacyFallback => id == kLegacyFallbackClassId;

  factory LecturerClass.fromMap(Map<String, dynamic> map) {
    return LecturerClass(
      id: map['class_id']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      status: map['status']?.toString() ?? 'draft',
      description: _clean(map['description']?.toString()),
      semester: _clean(map['semester']?.toString()),
      code: _clean(map['code']?.toString()),
      memberCount: (map['member_count'] as num?)?.toInt() ?? 0,
      moduleCount: (map['module_count'] as num?)?.toInt() ?? 0,
      pretestEnabled: map['pretest_enabled'] == true,
      posttestEnabled: map['posttest_enabled'] == true,
      leaderboardEnabled: map['leaderboard_enabled'] != false,
      policyVersion: (map['policy_version'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }
}

/// Settings for a class (`public.class_settings`).
class ClassSettingsModel {
  const ClassSettingsModel({
    required this.classId,
    required this.pretestEnabled,
    required this.posttestEnabled,
    required this.leaderboardEnabled,
    this.policyVersion = 1,
  });

  final String classId;
  final bool pretestEnabled;
  final bool posttestEnabled;
  final bool leaderboardEnabled;
  final int policyVersion;

  factory ClassSettingsModel.fromMap(Map<String, dynamic> map) {
    return ClassSettingsModel(
      classId: map['class_id']?.toString() ?? '',
      pretestEnabled: map['pretest_enabled'] == true,
      posttestEnabled: map['posttest_enabled'] == true,
      leaderboardEnabled: map['leaderboard_enabled'] != false,
      policyVersion: (map['policy_version'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Invite code state for a class (`public.class_invites`).
class ClassInviteModel {
  const ClassInviteModel({
    required this.classId,
    required this.code,
    required this.active,
    this.rotatedAt,
  });

  final String classId;
  final String code;
  final bool active;
  final DateTime? rotatedAt;

  factory ClassInviteModel.fromMap(Map<String, dynamic> map) {
    return ClassInviteModel(
      classId: map['class_id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      active: map['active'] != false,
      rotatedAt: DateTime.tryParse(map['rotated_at']?.toString() ?? ''),
    );
  }
}

/// One module ("bab") of a class, with material counters resolved by
/// `classModulesProvider` so a card can show progress without a second request.
class ClassModule {
  const ClassModule({
    required this.id,
    required this.classId,
    required this.title,
    required this.position,
    required this.status,
    this.titleEn,
    this.titleId,
    this.description,
    this.descriptionEn,
    this.descriptionId,
    this.templateModuleNumber,
    this.materialCount = 0,
    this.publishedMaterialCount = 0,
  });

  final String id;
  final String classId;
  final String title;
  final int position;
  final String status;
  final String? titleEn;
  final String? titleId;
  final String? description;
  final String? descriptionEn;
  final String? descriptionId;
  final int? templateModuleNumber;
  final int materialCount;
  final int publishedMaterialCount;

  bool get isPublished => status == 'published';
  bool get isArchived => status == 'archived';
  bool get isDraft => status == 'draft';

  String localizedTitle(String languageCode) => localizedClassText(
        languageCode: languageCode,
        english: titleEn,
        indonesian: titleId,
        fallback: title,
      );

  String localizedDescription(String languageCode) => localizedClassText(
        languageCode: languageCode,
        english: descriptionEn,
        indonesian: descriptionId,
        fallback: description ?? '',
      );

  ClassModule copyWith({
    int? materialCount,
    int? publishedMaterialCount,
    int? position,
    String? status,
  }) =>
      ClassModule(
        id: id,
        classId: classId,
        title: title,
        position: position ?? this.position,
        status: status ?? this.status,
        titleEn: titleEn,
        titleId: titleId,
        description: description,
        descriptionEn: descriptionEn,
        descriptionId: descriptionId,
        templateModuleNumber: templateModuleNumber,
        materialCount: materialCount ?? this.materialCount,
        publishedMaterialCount:
            publishedMaterialCount ?? this.publishedMaterialCount,
      );

  factory ClassModule.fromMap(Map<String, dynamic> map) {
    return ClassModule(
      id: map['id']?.toString() ?? '',
      classId: map['class_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      position: (map['position'] as num?)?.toInt() ?? 0,
      status: map['status']?.toString() ?? 'draft',
      titleEn: _clean(map['title_en']?.toString()),
      titleId: _clean(map['title_id']?.toString()),
      description: _clean(map['description']?.toString()),
      descriptionEn: _clean(map['description_en']?.toString()),
      descriptionId: _clean(map['description_id']?.toString()),
      templateModuleNumber:
          (map['template_module_number'] as num?)?.toInt(),
      materialCount: (map['material_count'] as num?)?.toInt() ?? 0,
      publishedMaterialCount:
          (map['published_material_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One member of a class roster (`class_roster()` RPC).
class ClassMember {
  const ClassMember({
    required this.studentId,
    required this.name,
    required this.isActive,
    this.identityNumber,
    this.program,
    this.joinedAt,
  });

  final String studentId;
  final String name;
  final bool isActive;
  final String? identityNumber;
  final String? program;
  final DateTime? joinedAt;

  factory ClassMember.fromMap(Map<String, dynamic> map) {
    return ClassMember(
      studentId: map['student_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      isActive: map['is_active'] == true,
      identityNumber: _clean(map['identity_number']?.toString()),
      program: _clean(map['program']?.toString()),
      joinedAt: DateTime.tryParse(map['joined_at']?.toString() ?? ''),
    );
  }
}

/// A class-scoped pretest/posttest row (only the fields the gate card needs).
class ClassGateAssessment {
  const ClassGateAssessment({
    required this.id,
    required this.assessmentType,
    required this.status,
    required this.title,
    this.titleEn,
    this.titleId,
    this.durationMinutes,
    this.questionCount = 0,
    this.answeredCount = 0,
  });

  final String id;
  final String assessmentType;
  final String status;
  final String title;
  final String? titleEn;
  final String? titleId;
  final int? durationMinutes;
  final int questionCount;
  final int answeredCount;

  bool get isPretest => assessmentType == 'pretest';
  bool get isPosttest => assessmentType == 'posttest';
  bool get isPublished => status == 'published';
  bool get canPublish => questionCount > 0 && answeredCount == questionCount;

  String localizedTitle(String languageCode) => localizedClassText(
        languageCode: languageCode,
        english: titleEn,
        indonesian: titleId,
        fallback: title,
      );

  factory ClassGateAssessment.fromMap(Map<String, dynamic> map) {
    return ClassGateAssessment(
      id: map['id']?.toString() ?? '',
      assessmentType: map['assessment_type']?.toString() ?? '',
      status: map['status']?.toString() ?? 'draft',
      title: map['title']?.toString() ?? '',
      titleEn: _clean(map['title_en']?.toString()),
      titleId: _clean(map['title_id']?.toString()),
      durationMinutes: (map['duration_minutes'] as num?)?.toInt(),
      questionCount: (map['question_count'] as num?)?.toInt() ?? 0,
      answeredCount: (map['answered_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A material row plus the class/module it belongs to.
///
/// [MaterialModel] deliberately keeps its v6 shape; the class id travels
/// alongside it so callers can pass class context to the reader without
/// changing the shared model (and every existing provider override in tests).
class ClassMaterialEntry {
  const ClassMaterialEntry({
    required this.material,
    required this.classId,
    required this.moduleId,
    required this.published,
    required this.isCore,
    this.orderIndex = 0,
    this.contentVersion = 1,
  });

  final MaterialModel material;
  final String classId;
  final String? moduleId;
  final bool published;
  final bool isCore;
  final int orderIndex;
  final int contentVersion;

  factory ClassMaterialEntry.fromMap(Map<String, dynamic> map) {
    return ClassMaterialEntry(
      material: MaterialModel.fromMap(map),
      classId: map['class_id']?.toString() ?? '',
      moduleId: _clean(map['module_id']?.toString()),
      published: map['published'] == true,
      isCore: map['is_core'] == true,
      orderIndex: (map['order_index'] as num?)?.toInt() ?? 0,
      contentVersion: (map['content_version'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Snapshot of a student's progress and unlock state within one class,
/// covering all four Pretest/Posttest combinations (PRD §8.3, §8.4).
class ClassLearningFlowStatus {
  const ClassLearningFlowStatus({
    required this.pretestEnabled,
    required this.posttestEnabled,
    required this.leaderboardEnabled,
    required this.policyVersion,
    required this.pretestCompleted,
    required this.allModulesCompleted,
    required this.posttestUnlocked,
    required this.posttestCompleted,
    required this.classCompleted,
    required this.totalModules,
    required this.completedModules,
  });

  final bool pretestEnabled;
  final bool posttestEnabled;
  final bool leaderboardEnabled;
  final int policyVersion;
  final bool pretestCompleted;
  final bool allModulesCompleted;
  final bool posttestUnlocked;
  final bool posttestCompleted;
  final bool classCompleted;
  final int totalModules;
  final int completedModules;

  /// Module 1 is open immediately when pretest is disabled, or once the
  /// pretest is submitted when enabled (PRD §8.3, §8.4.2).
  bool get isFirstModuleUnlocked =>
      totalModules > 0 && (!pretestEnabled || pretestCompleted);

  /// Pure evaluation of the 4 Pretest/Posttest combinations (PRD §8.3, §8.4).
  ///
  /// Used both by tests and as a deterministic client model of the backend
  /// `get_class_learning_flow_status` contract.
  factory ClassLearningFlowStatus.evaluate({
    required bool pretestEnabled,
    required bool posttestEnabled,
    bool leaderboardEnabled = true,
    int policyVersion = 1,
    required bool pretestCompleted,
    required int totalPublishedModules,
    required int completedPublishedModules,
    required bool posttestCompleted,
    bool grandfatheredPretest = false,
  }) {
    final pretestSatisfied =
        !pretestEnabled || pretestCompleted || grandfatheredPretest;

    // PRD §8.4.8: an empty class with 0 published modules is never complete.
    final allModsDone = totalPublishedModules > 0 &&
        completedPublishedModules >= totalPublishedModules &&
        pretestSatisfied;

    final postUnlocked = posttestEnabled && allModsDone;
    final courseDone =
        allModsDone && (!posttestEnabled || posttestCompleted);

    return ClassLearningFlowStatus(
      pretestEnabled: pretestEnabled,
      posttestEnabled: posttestEnabled,
      leaderboardEnabled: leaderboardEnabled,
      policyVersion: policyVersion,
      pretestCompleted: pretestCompleted,
      allModulesCompleted: allModsDone,
      posttestUnlocked: postUnlocked,
      posttestCompleted: posttestCompleted,
      classCompleted: courseDone,
      totalModules: totalPublishedModules,
      completedModules: completedPublishedModules,
    );
  }

  factory ClassLearningFlowStatus.fromMap(Map<String, dynamic> map) {
    return ClassLearningFlowStatus(
      pretestEnabled: map['pretest_enabled'] == true,
      posttestEnabled: map['posttest_enabled'] == true,
      leaderboardEnabled: map['leaderboard_enabled'] != false,
      policyVersion: (map['policy_version'] as num?)?.toInt() ?? 1,
      pretestCompleted: map['pretest_completed'] == true,
      allModulesCompleted: map['all_modules_completed'] == true,
      posttestUnlocked: map['posttest_unlocked'] == true,
      posttestCompleted: map['posttest_completed'] == true,
      classCompleted: map['class_completed'] == true,
      totalModules: (map['total_modules'] as num?)?.toInt() ?? 0,
      completedModules: (map['completed_modules'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Masks a student's name for peer leaderboard display (PRD §2.2.10, §10.3).
///
/// The owning lecturer and the student viewing their own row see the full name;
/// peers see the first name plus initials (or a masked prefix for single-word
/// names), never exposing NIM or email.
String maskStudentDisplayName(String fullName, {bool reveal = false}) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) {
    return 'Student';
  }
  if (reveal) {
    return trimmed;
  }

  final parts =
      trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) {
    return 'Student';
  }
  if (parts.length == 1) {
    final word = parts.first;
    if (word.length <= 2) {
      return '$word***';
    }
    return '${word.substring(0, 2)}***';
  }

  final buffer = StringBuffer(parts.first);
  for (var i = 1; i < parts.length; i++) {
    buffer.write(' ${parts[i][0].toUpperCase()}.');
  }
  return buffer.toString();
}

/// One row on an Assessment Leaderboard (`get_assessment_leaderboard()` RPC).
class AssessmentLeaderboardEntry {
  const AssessmentLeaderboardEntry({
    required this.rankPosition,
    required this.studentId,
    required this.displayName,
    required this.bestScore,
    required this.attemptCount,
    required this.achievedAt,
    required this.isMe,
    this.identityNumber,
    this.avatarConfig,
  });

  final int rankPosition;
  final String studentId;
  final String displayName;
  final String? identityNumber;
  final double bestScore;
  final int attemptCount;
  final DateTime achievedAt;
  final bool isMe;
  final AvatarConfig? avatarConfig;

  factory AssessmentLeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return AssessmentLeaderboardEntry(
      rankPosition: (map['rank_position'] as num?)?.toInt() ?? 0,
      studentId: map['student_id']?.toString() ?? '',
      displayName: map['display_name']?.toString() ?? 'Student',
      identityNumber: _clean(map['identity_number']?.toString()),
      bestScore: (map['best_score'] as num?)?.toDouble() ?? 0,
      attemptCount: (map['attempt_count'] as num?)?.toInt() ?? 1,
      achievedAt: DateTime.tryParse(map['achieved_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isMe: map['is_me'] == true,
      avatarConfig: AvatarConfig.fromDynamic(map['avatar_config']),
    );
  }
}

/// One row on the Overall Class Leaderboard (`get_class_leaderboard()` RPC).
class ClassLeaderboardEntry {
  const ClassLeaderboardEntry({
    required this.rankPosition,
    required this.studentId,
    required this.displayName,
    required this.cohort,
    required this.weightedScore,
    required this.unweightedAvg,
    required this.completedAssessments,
    required this.totalRankedAssessments,
    required this.policyVersion,
    required this.isMe,
    this.identityNumber,
    this.completedAt,
    this.avatarConfig,
  });

  final int rankPosition;
  final String studentId;
  final String displayName;
  final String? identityNumber;

  /// Either `'final'` (completed all required ranked assessments) or
  /// `'in_progress'` (provisional score, PRD §10.2).
  final String cohort;
  final double weightedScore;
  final double unweightedAvg;
  final int completedAssessments;
  final int totalRankedAssessments;
  final DateTime? completedAt;
  final int policyVersion;
  final bool isMe;
  final AvatarConfig? avatarConfig;

  bool get isFinal => cohort == 'final';
  bool get isProvisional => cohort != 'final';

  factory ClassLeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return ClassLeaderboardEntry(
      rankPosition: (map['rank_position'] as num?)?.toInt() ?? 0,
      studentId: map['student_id']?.toString() ?? '',
      displayName: map['display_name']?.toString() ?? 'Student',
      identityNumber: _clean(map['identity_number']?.toString()),
      cohort: map['cohort']?.toString() ?? 'in_progress',
      weightedScore: (map['weighted_score'] as num?)?.toDouble() ?? 0,
      unweightedAvg: (map['unweighted_avg'] as num?)?.toDouble() ?? 0,
      completedAssessments:
          (map['completed_assessments'] as num?)?.toInt() ?? 0,
      totalRankedAssessments:
          (map['total_ranked_assessments'] as num?)?.toInt() ?? 0,
      completedAt: DateTime.tryParse(map['completed_at']?.toString() ?? ''),
      policyVersion: (map['policy_version'] as num?)?.toInt() ?? 1,
      isMe: map['is_me'] == true,
      avatarConfig: AvatarConfig.fromDynamic(map['avatar_config']),
    );
  }
}
