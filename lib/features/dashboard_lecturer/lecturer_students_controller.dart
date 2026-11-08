import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_client.dart';
import '../../shared/models/student_model.dart';
import '../classes/class_controller.dart';
import '../classes/class_models.dart';

/// Exception thrown when the student list cannot be loaded.
class LecturerStudentsException implements Exception {
  final String message;

  const LecturerStudentsException(this.message);

  @override
  String toString() => 'LecturerStudentsException($message)';
}

/// Maps Supabase errors to readable, user-safe messages.
///
/// Error messages are kept generic to avoid leaking whether a particular
/// student record exists or what columns the table has.
LecturerStudentsException mapStudentsError(Object error) {
  final message = error.toString();

  if (message.contains('permission denied') ||
      message.contains('42501') ||
      // `get_lecturer_student_overview` raises plain NOT_PERMITTED for a
      // non-lecturer caller.
      message.contains('NOT_PERMITTED')) {
    return const LecturerStudentsException(
      'You are not authorized to view the student list.',
    );
  }

  // The overview RPC exists only after its migration is applied. Until then
  // every load fails with PGRST202 ("schema cache ... could not find
  // function"), which should read as "scores are not set up yet", not as the
  // account being locked out.
  if (message.contains('PGRST202')) {
    return const LecturerStudentsException(
      'Score data is not available yet. It will appear once it has been set up.',
    );
  }

  return LecturerStudentsException('Failed to load the student list.');
}

/// Student roster scoped to the active class when one is selected, or all
/// students with role='student' plus their latest submitted pretest/posttest
/// scores in fallback mode.
final lecturerStudentsProvider = FutureProvider.autoDispose
    .family<List<StudentModel>, void>((ref, _) async {
  final activeClass = await resolveActiveLecturerClass(ref);
  final validClass = activeClass != null &&
      activeClass.id.isNotEmpty &&
      activeClass.id != kLegacyFallbackClassId;

  if (validClass) {
    final Set<String> enrolledStudentIds = {};
    final Map<String, Map<String, dynamic>> rosterMap = {};

    try {
      final rosterRes = await supabase.rpc(
        'class_roster',
        params: {'p_class': activeClass.id},
      );
      if (rosterRes is List) {
        for (final r in rosterRes) {
          final map = Map<String, dynamic>.from(r as Map);
          final sid = map['student_id']?.toString() ?? map['id']?.toString();
          if (sid != null && sid.isNotEmpty) {
            enrolledStudentIds.add(sid);
            rosterMap[sid] = map;
          }
        }
      }
    } catch (_) {
      try {
        final enrollRes = await supabase
            .from('enrollments')
            .select('student_id')
            .eq('class_id', activeClass.id);
        for (final e in enrollRes) {
          final sid = (e as Map)['student_id']?.toString();
          if (sid != null && sid.isNotEmpty) {
            enrolledStudentIds.add(sid);
          }
        }
      } catch (_) {}
    }

    if (enrolledStudentIds.isEmpty) {
      return const <StudentModel>[];
    }

    List<StudentModel> overviewStudents = [];
    try {
      final response = await supabase.rpc('get_lecturer_student_overview');
      if (response is List) {
        overviewStudents = response
            .map((row) => StudentModel.fromMap(Map<String, dynamic>.from(row as Map)))
            .toList();
      }
    } catch (e) {
      if (rosterMap.isEmpty) {
        rethrow;
      }
    }

    final classStudents = overviewStudents
        .where((s) => enrolledStudentIds.contains(s.id))
        .toList();

    final foundIds = classStudents.map((s) => s.id).toSet();
    for (final sid in enrolledStudentIds) {
      if (!foundIds.contains(sid)) {
        final r = rosterMap[sid];
        classStudents.add(StudentModel(
          id: sid,
          name: r?['name']?.toString() ?? 'Mahasiswa',
          identityNumber: r?['identity_number']?.toString(),
          program: r?['program']?.toString(),
          isActive: r?['is_active'] != false,
          createdAt: DateTime.tryParse(r?['joined_at']?.toString() ?? ''),
        ));
      }
    }
    return classStudents;
  }

  final response = await supabase.rpc('get_lecturer_student_overview');

  final rows = response as List;

  return rows
      .map((row) => StudentModel.fromMap(Map<String, dynamic>.from(row as Map)))
      .toList();
});
