import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/avatar/nl_avatar_models.dart';
import '../../core/supabase/supabase_client.dart';
import '../assessment/assessment_controller.dart';
import '../dashboard_student/student_dashboard_controller.dart';
import '../materials/student_materials_controller.dart';

/// The signed-in student's own `profiles` row, as a raw map.
///
/// Lives here (not on the profile page) so the profile sub-pages
/// (`/student/profile-info`, `/student/academic`, `/student/security`) can read
/// the same source without importing the page. Kept `autoDispose` because the
/// map is cheap to re-read on every visit, and a stale copy would show an old
/// name or a contradictory account status after an admin edits the row.
final studentProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = supabase.auth.currentUser;

  if (user == null) {
    return null;
  }

  final result = await supabase
      .from('profiles')
      .select(
        'id, name, identity_number, email, program, role, is_active, avatar_config, bio, unlocked_badges',
      )
      .eq('id', user.id)
      .maybeSingle();

  if (result != null && result['avatar_config'] == null) {
    final defaultCfg = AvatarConfig.defaultFor(user.id);
    result['avatar_config'] = defaultCfg.toMap();
    try {
      await supabase
          .from('profiles')
          .update({'avatar_config': defaultCfg.toMap()})
          .eq('id', user.id);
    } catch (_) {}
  }

  return result;
});

/// Aggregate numbers behind the student profile stats strip.
///
/// The strip shows three metrics — course progress, completed modules and the
/// average assessment score — and none of them is stored anywhere as one
/// number:
/// - progress comes from the dashboard controller, which counts published
///   materials against the signed-in student's `learning_progress` rows;
/// - module progress comes from [studentModulesProvider], whose `completed`
///   flag is baked in by the `get_learning_flow_status` RPC;
/// - the average score is the mean of the latest score of every assessment the
///   student has a submitted attempt for.
///
/// All three are derived from already-cached providers instead of fresh reads,
/// so the profile page never fans out to the database on its own.
class StudentProfileStats {
  final int progressPercent;
  final int completedModules;
  final int totalModules;
  final double? averageScore;

  const StudentProfileStats({
    required this.progressPercent,
    required this.completedModules,
    required this.totalModules,
    required this.averageScore,
  });

  String get modulesValue => '$completedModules/$totalModules';

  String get averageScoreValue =>
      averageScore == null ? '—' : averageScore!.round().toString();
}

/// Aggregates the stats, tolerating every failure.
///
/// The provider deliberately returns `null` instead of rethrowing when any of
/// its sources fail (say, in an offline widget test or while the backend is
/// unreachable). The page then keeps the design's placeholder strip instead of
/// flashing a second error tile right under a hero that loaded fine.
final studentProfileStatsProvider =
    FutureProvider.autoDispose<StudentProfileStats?>((ref) async {
  try {
    final dashboard = await ref.read(
      studentDashboardProvider.future,
    );

    final modules = await ref.read(
      studentModulesProvider.future,
    );

    final assessments = await ref.read(
      assessmentListProvider.future,
    );

    final scores = [
      for (final assessment in assessments)
        if (assessment.score != null) assessment.score!,
    ];

    final double? averageScore;
    if (scores.isEmpty) {
      averageScore = null;
    } else {
      averageScore = scores.reduce((a, b) => a + b) / scores.length;
    }

    return StudentProfileStats(
      progressPercent: dashboard.progressPercentage,
      completedModules: modules.where((module) => module.completed).length,
      totalModules: modules.length,
      averageScore: averageScore,
    );
  } catch (error) {
    // A stats failure must never break the rest of the profile page. The caller
    // maps this back to the placeholder strip, matching the design mock.
    debugPrint('studentProfileStats fell back to placeholders: $error');
    return null;
  }
});