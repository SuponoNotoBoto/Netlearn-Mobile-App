import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/assessment/assessment_controller.dart';
import '../../features/classes/class_controller.dart';
import '../../features/dashboard_lecturer/announcement_controller.dart';
import '../../features/dashboard_lecturer/lecturer_dashboard_controller.dart';
import '../../features/dashboard_lecturer/notification_controller.dart';
import '../../features/dashboard_student/student_dashboard_controller.dart';
import '../../features/discussions/discussion_controller.dart';
import '../../features/materials/student_materials_controller.dart';
import '../../features/profile/student_profile_controller.dart';
import '../../features/virtual_lab/virtual_lab_controller.dart';
import '../notifications/announcement_read_store.dart';

/// Clears every provider whose value belongs to one specific signed-in user.
///
/// Most progress providers are auto-disposed and refetch on their own, but the
/// dashboard and the assessment list are kept alive for the whole session.
/// Without this they survive a sign-out and the next student to log in sees the
/// previous student's name, progress and completed assessments, which then
/// locks them out: the pretest reads as already passed while the modules are
/// still locked behind it.
///
/// Call this after signing out and again after signing in, so neither leaving
/// nor arriving can serve the wrong user's data.
///
/// Takes a [Ref] rather than a `WidgetRef` so it can be called from a
/// `Notifier`, where the available reference is the base type.
void resetUserSession(Ref ref) {
  ref.invalidate(studentDashboardProvider);
  ref.invalidate(assessmentListProvider);
  ref.invalidate(assessmentControllerProvider);

  // The auto-disposed ones are invalidated too because the sign-in and
  // sign-out transitions can happen faster than a listener is dropped.
  ref.invalidate(studentMaterialsProvider);
  ref.invalidate(studentModuleStatesProvider);
  ref.invalidate(studentLearningFlowStatusProvider);
  ref.invalidate(studentLearningProgressProvider);
  ref.invalidate(studentMaterialProgressProvider);
  ref.invalidate(studentMaterialStateProvider);
  ref.invalidate(isMaterialUnlockedProvider);
  ref.invalidate(studentModulesProvider);

  // notificationUserIdProvider adalah Provider biasa (bukan autoDispose) yang
  // meng-cache id pengguna pertama. Tanpa invalidasi ini, halaman notifikasi
  // setelah ganti akun (dosen -> mahasiswa) masih membaca id dosen dan
  // userAnnouncementsProvider(idDosen) difilter RLS menjadi nol baris —
  // pengumuman mahasiswa seolah hilang padahal datanya ada.
  // announcementReadIdsProvider autoDispose family, tapi di-invalidate
  // family-level (tanpa argumen) supaya seluruh instans per pengguna ikut
  // dibuang bersama cache id-nya.
  ref.invalidate(notificationUserIdProvider);
  ref.invalidate(userAnnouncementsProvider);
  ref.invalidate(announcementReadIdsProvider);
  ref.invalidate(studentDeadlineRemindersProvider);
  ref.invalidate(lecturerAnnouncementsProvider);
  ref.invalidate(lecturerMissingAssessmentRemindersProvider);

  // v7 class context, membership, and leaderboard providers must never leak
  // across sign-out / sign-in boundaries.
  ref.invalidate(activeStudentClassIdProvider);
  ref.invalidate(activeLecturerClassIdProvider);
  ref.invalidate(studentClassesProvider);
  ref.invalidate(activeStudentClassProvider);
  ref.invalidate(lecturerClassesProvider);
  ref.invalidate(activeLecturerClassProvider);
  ref.invalidate(lecturerArchivedClassesProvider);
  ref.invalidate(classSettingsProvider);
  ref.invalidate(classInviteProvider);
  ref.invalidate(classModulesProvider);
  ref.invalidate(classModuleMaterialsProvider);
  ref.invalidate(classGateAssessmentsProvider);
  ref.invalidate(classRosterProvider);
  ref.invalidate(classLearningFlowStatusProvider);
  ref.invalidate(classLeaderboardProvider);
  ref.invalidate(assessmentLeaderboardProvider);
  ref.invalidate(classLeaderboardQuizzesProvider);

  // Avatar/bio profile caches & Q&A discussion forum caches.
  ref.invalidate(studentProfileProvider);
  ref.invalidate(lecturerProfileProvider);
  ref.invalidate(classDiscussionThreadsProvider);
  ref.invalidate(discussionThreadDetailProvider);
  ref.invalidate(discussionThreadRepliesProvider);

  // Virtual Lab canvas provider
  ref.invalidate(virtualLabControllerProvider);

  // Clean up legacy device-global keys that could leak across account boundaries
  SharedPreferences.getInstance().then((prefs) {
    prefs.remove('has_completed_reading');
  }).catchError((_) {});
}

final _sessionResetRefProvider = Provider<Ref>((ref) => ref);

/// Convenience wrapper so widget callbacks holding a [WidgetRef] can trigger
/// the full [resetUserSession] graph cleanly.
void resetUserSessionFromWidget(WidgetRef ref) {
  resetUserSession(ref.read(_sessionResetRefProvider));
}
