import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/avatar/nl_avatar_models.dart';
import '../../core/supabase/supabase_client.dart';
import '../classes/class_controller.dart';
import '../classes/class_models.dart';
import 'lecturer_students_controller.dart';

// ============================================================
// PROFILE
// ============================================================

class LecturerProfile {
  final String id;
  final String name;
  final String identityNumber;
  final String email;
  final String? program;
  final bool isActive;
  final AvatarConfig? avatarConfig;
  final String? bio;

  const LecturerProfile({
    required this.id,
    required this.name,
    required this.identityNumber,
    required this.email,
    required this.program,
    required this.isActive,
    this.avatarConfig,
    this.bio,
  });

  factory LecturerProfile.fromMap(
    Map<String, dynamic> map,
  ) {
    final rawBio = map['bio']?.toString().trim();
    return LecturerProfile(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      identityNumber:
          map['identity_number']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      program: map['program']?.toString(),
      isActive: map['is_active'] == true,
      avatarConfig: AvatarConfig.fromDynamic(map['avatar_config']),
      bio: (rawBio == null || rawBio.isEmpty) ? null : rawBio,
    );
  }

  /// The letters shown in the avatar circle.
  String get initial {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return 'D';
    }

    return trimmed[0].toUpperCase();
  }
}

/// The signed-in lecturer, or null when there is no session.
///
/// The router already refuses non-lecturers, so the null branch is a second
/// line of defence rather than the primary gate: it keeps a screen that is
/// somehow mounted without a lecturer from rendering somebody else's data.
final lecturerProfileProvider =
    FutureProvider.autoDispose<LecturerProfile?>((ref) async {
      final user = supabase.auth.currentUser;

      if (user == null) {
        return null;
      }

      final response = await supabase
          .from('profiles')
          .select(
        'id, name, identity_number, email, program, is_active, role, avatar_config, bio',
      )
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      final profile = LecturerProfile.fromMap(
        Map<String, dynamic>.from(response),
      );

      final role = response['role']?.toString();

      if (role != 'lecturer' || !profile.isActive) {
        return null;
      }

      return profile;
    });

// ============================================================
// DASHBOARD STATS
// ============================================================

class LecturerDashboardStats {
  final int totalStudents;
  final int classCount;
  final int activeClassCount;
  final int materialCount;
  final int publishedMaterialCount;
  final int assessmentCount;
  final int publishedAssessmentCount;
  final double? averageScore;

  const LecturerDashboardStats({
    required this.totalStudents,
    required this.classCount,
    required this.activeClassCount,
    required this.materialCount,
    required this.publishedMaterialCount,
    required this.assessmentCount,
    required this.publishedAssessmentCount,
    required this.averageScore,
  });

  /// Whether the student-derived figures mean anything yet.
  ///
  /// `lecturer_dashboard()` counts students through `classes` and `enrollments`.
  /// When the lecturer owns no classes every student figure is zero, and that
  /// zero is indistinguishable from "this lecturer genuinely has no students".
  /// The dashboard uses this to say so instead of printing a confident `0`.
  bool get hasClassContext => classCount > 0;

  /// True when a score average exists to show.
  bool get hasAverageScore => averageScore != null;
}

final lecturerDashboardStatsProvider =
    FutureProvider.autoDispose<LecturerDashboardStats>((ref) async {
      final activeClass = await resolveActiveLecturerClass(ref);
      final validClass = activeClass != null &&
          activeClass.id.isNotEmpty &&
          activeClass.id != kLegacyFallbackClassId;

      Map<String, dynamic>? summary;
      try {
        final rpcResponse = await supabase.rpc('lecturer_dashboard');
        summary = _firstRow(rpcResponse);
      } catch (_) {}

      if (validClass) {
        final materialsResponse = await supabase
            .from('materials')
            .select('id, published, class_id');

        final allMaterials = (materialsResponse as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        final classMaterials = allMaterials
            .where((r) => r['class_id']?.toString() == activeClass.id)
            .toList();
        final materialsToCount = classMaterials.isNotEmpty
            ? classMaterials
            : allMaterials.where((r) => r['class_id'] == null).toList();

        int publishedMaterials = materialsToCount
            .where((r) => r['published'] == true)
            .length;

        final quizzesResponse = await supabase
            .from('quizzes')
            .select('id, status, class_id');

        final allQuizzes = (quizzesResponse as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        final classQuizzes = allQuizzes
            .where((q) => q['class_id']?.toString() == activeClass.id)
            .toList();
        final quizzesToCount = classQuizzes.isNotEmpty
            ? classQuizzes
            : allQuizzes.where((q) => q['class_id'] == null).toList();

        int publishedAssessments = quizzesToCount
            .where((q) => q['status']?.toString() == 'published')
            .length;

        int classTotalStudents = activeClass.memberCount;
        double? classAverageScore;

        try {
          final students = await ref.watch(lecturerStudentsProvider(null).future);
          classTotalStudents = students.length;
          final scores = <double>[];
          for (final s in students) {
            if (s.pretestScore != null) scores.add(s.pretestScore!);
            if (s.posttestScore != null) scores.add(s.posttestScore!);
          }
          if (scores.isNotEmpty) {
            classAverageScore = scores.reduce((a, b) => a + b) / scores.length;
          }
        } catch (_) {}

        return LecturerDashboardStats(
          totalStudents: classTotalStudents,
          classCount: _readInt(summary?['class_count']),
          activeClassCount: _readInt(summary?['active_class_count']),
          materialCount: materialsToCount.length,
          publishedMaterialCount: publishedMaterials,
          assessmentCount: quizzesToCount.length,
          publishedAssessmentCount: publishedAssessments,
          averageScore: classAverageScore ?? _readDouble(summary?['average_score']),
        );
      }

      final materialsResponse = await supabase
          .from('materials')
          .select('id, published');

      final quizzesResponse = await supabase
          .from('quizzes')
          .select('id, status');

      int publishedMaterials = 0;

      for (final dynamic raw in materialsResponse as List) {
        final row = Map<String, dynamic>.from(raw as Map);

        if (row['published'] == true) {
          publishedMaterials++;
        }
      }

      int publishedAssessments = 0;

      for (final dynamic raw in quizzesResponse as List) {
        final row = Map<String, dynamic>.from(raw as Map);

        if (row['status']?.toString() == 'published') {
          publishedAssessments++;
        }
      }

      return LecturerDashboardStats(
        totalStudents: _readInt(summary?['total_students']),
        classCount: _readInt(summary?['class_count']),
        activeClassCount:
            _readInt(summary?['active_class_count']),
        materialCount: _readInt(summary?['material_count']),
        publishedMaterialCount: publishedMaterials,
        assessmentCount: quizzesResponse.length,
        publishedAssessmentCount: publishedAssessments,
        averageScore: _readDouble(summary?['average_score']),
      );
    });

/// Pulls the first row out of an RPC result.
///
/// `RETURNS TABLE` functions arrive as a list, but a `returns jsonb` or a
/// set-returning scalar can arrive as a bare map, so both shapes are accepted
/// rather than casting and crashing on the second one.
Map<String, dynamic>? _firstRow(dynamic response) {
  if (response is Map) {
    return Map<String, dynamic>.from(response);
  }

  if (response is List && response.isNotEmpty) {
    final first = response.first;

    if (first is Map) {
      return Map<String, dynamic>.from(first);
    }
  }

  return null;
}

int _readInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? 0;
  }

  return 0;
}

double? _readDouble(dynamic value) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value);
  }

  return null;
}
