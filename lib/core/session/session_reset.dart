import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard_lecturer/lecturer_assessments_controller.dart';
import '../../features/dashboard_lecturer/lecturer_dashboard_controller.dart';
import '../../features/dashboard_lecturer/lecturer_materials_controller.dart';
import '../../features/dashboard_lecturer/lecturer_students_controller.dart';

/// Clears cached provider state belonging to a user session.
void resetUserSession(Ref ref) {
  try {
    ref.invalidate(lecturerProfileProvider);
  } catch (_) {}
  try {
    ref.invalidate(lecturerDashboardStatsProvider);
  } catch (_) {}
  try {
    ref.invalidate(lecturerStudentsProvider);
  } catch (_) {}
  try {
    ref.invalidate(lecturerMaterialsProvider);
  } catch (_) {}
  try {
    ref.invalidate(lecturerTasksProvider);
  } catch (_) {}
  try {
    ref.invalidate(lecturerAssessmentsProvider);
  } catch (_) {}
}
