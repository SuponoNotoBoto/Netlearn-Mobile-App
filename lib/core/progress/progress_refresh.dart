import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/assessment/assessment_controller.dart';
import '../../features/classes/class_controller.dart';
import '../../features/dashboard_lecturer/notification_controller.dart';
import '../../features/dashboard_student/student_dashboard_controller.dart';
import '../../features/materials/student_materials_controller.dart';
import '../../features/profile/student_assessment_history_page.dart';

/// Invalidates every provider whose value is derived from a student's
/// learning progress.
///
/// Progress is spread across a dozen providers, and several of them bake an
/// "unlocked" or "completed" flag into a cached object rather than recomputing
/// it from the row they hold. Invalidating only the obvious provider leaves
/// whichever screen was already mounted showing a stale lock, so every place
/// that writes progress refreshes all of them from here.
///
/// `studentDashboardProvider` and `assessmentListProvider` are not
/// auto-disposed, so they stay cached for the whole session and would
/// otherwise keep reporting the progress the student had when they first
/// opened the app.
void invalidateStudentProgress(WidgetRef ref) {
  ref.invalidate(studentMaterialsProvider);
  ref.invalidate(studentModuleStatesProvider);
  ref.invalidate(studentMaterialProgressProvider);
  ref.invalidate(studentMaterialStateProvider);
  ref.invalidate(studentLearningFlowStatusProvider);
  ref.invalidate(studentLearningProgressProvider);
  ref.invalidate(isMaterialUnlockedProvider);
  ref.invalidate(studentModulesProvider);
  ref.invalidate(studentDashboardProvider);
  ref.invalidate(assessmentListProvider);
  ref.invalidate(assessmentHistoryProvider);
  // Pengingat mahasiswa memasang "belum dikerjakan" dari quiz_attempts;
  // setelah submit asesmen, kartu pengingatnya harus hilang segera. Invalidate
  // di level provider (bukan instans user) karena tidak ada userId di sini.
  ref.invalidate(studentDeadlineRemindersProvider);
  ref.invalidate(userAnnouncementsProvider);
  // v7 class-scoped progress & leaderboard providers:
  ref.invalidate(studentClassesProvider);
  ref.invalidate(activeStudentClassProvider);
  ref.invalidate(classModulesProvider);
  ref.invalidate(classModuleMaterialsProvider);
  ref.invalidate(classLearningFlowStatusProvider);
  ref.invalidate(classLeaderboardProvider);
  ref.invalidate(assessmentLeaderboardProvider);
  ref.invalidate(classLeaderboardQuizzesProvider);
}
