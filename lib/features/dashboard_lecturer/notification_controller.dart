import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../core/supabase/supabase_client.dart';
import '../../shared/models/announcement_model.dart';
import '../../shared/models/reminder_model.dart';
import '../../shared/models/student_model.dart';
import '../classes/class_controller.dart';
import '../classes/class_models.dart';
import 'lecturer_students_controller.dart';

/// Provides announcements for the current user based on their role.
///
/// Returns an empty list for unknown roles rather than throwing, so a transient
/// profile issue degrades to an empty panel instead of an error state.
final userAnnouncementsProvider = FutureProvider.autoDispose
    .family<List<AnnouncementModel>, String>((ref, userId) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final profile = await supabase
      .from('profiles')
      .select('role')
      .eq('id', userId)
      .maybeSingle();

  final role = profile?['role']?.toString();

  if (role == 'student') {
    return _loadStudentAnnouncements(ref);
  } else if (role == 'lecturer' || role == 'admin') {
    return _loadLecturerAnnouncements(ref, userId);
  }

  return <AnnouncementModel>[];
});

/// Loads published announcements for students, scoped to the active class.
Future<List<AnnouncementModel>> _loadStudentAnnouncements(Ref ref) async {
  ref.watch(activeStudentClassIdProvider);
  final activeClass = await resolveActiveStudentClass(ref);

  List<dynamic> response;
  try {
    response = await supabase
        .from('announcements')
        .select('''
          id,
          lecturer_id,
          title,
          content,
          recipient_scope,
          published,
          published_at,
          class_id,
          created_at,
          updated_at
        ''')
        .eq('published', true)
        .eq('recipient_scope', 'all_students')
        .order('published_at', ascending: false);
  } catch (_) {
    response = await supabase
        .from('announcements')
        .select('''
          id,
          lecturer_id,
          title,
          content,
          recipient_scope,
          published,
          published_at,
          created_at,
          updated_at
        ''')
        .eq('published', true)
        .eq('recipient_scope', 'all_students')
        .order('published_at', ascending: false);
  }

  final list = response
      .map((item) => AnnouncementModel.fromMap(Map<String, dynamic>.from(item)))
      .toList();

  if (activeClass != null && !activeClass.isLegacyFallback) {
    return list.where((item) => item.classId == null || item.classId == activeClass.id).toList();
  }

  return list.where((item) => item.classId == null).toList();
}

/// Loads announcements created by the lecturer, scoped to the active class.
Future<List<AnnouncementModel>> _loadLecturerAnnouncements(Ref ref, String lecturerId) async {
  ref.watch(activeLecturerClassIdProvider);
  final activeClass = await resolveActiveLecturerClass(ref);

  List<dynamic> response;
  try {
    response = await supabase
        .from('announcements')
        .select('''
          id,
          lecturer_id,
          title,
          content,
          recipient_scope,
          published,
          published_at,
          class_id,
          created_at,
          updated_at
        ''')
        .eq('lecturer_id', lecturerId)
        .order('created_at', ascending: false);
  } catch (_) {
    response = await supabase
        .from('announcements')
        .select('''
          id,
          lecturer_id,
          title,
          content,
          recipient_scope,
          published,
          published_at,
          created_at,
          updated_at
        ''')
        .eq('lecturer_id', lecturerId)
        .order('created_at', ascending: false);
  }

  final list = response
      .map((item) => AnnouncementModel.fromMap(Map<String, dynamic>.from(item)))
      .toList();

  if (activeClass != null && !activeClass.isLegacyFallback) {
    return list.where((item) => item.classId == activeClass.id).toList();
  }

  return list;
}

/// Kolom `quizzes` yang dibaca penyusun pengingat mahasiswa. Disamakan dengan
/// query asli supaya builder murni bisa diuji dengan baris palsu yang berbentuk
/// sama.
const _quizzesReminderColumns = '''
  id,
  title,
  title_en,
  title_id,
  deadline,
  status,
  assessment_type,
  materials(title)
''';

/// Menyusun pengingat untuk MAHASISWA dari baris kuis published.
///
/// Dua jalur:
///   * Kuis inti (pretest/posttest) yang belum disubmit → item
///     `ReminderReason.notCompleted`. Deadline-nya boleh null — status
///     "belum dikerjakan" adalah pengingatnya, bukan countdown.
///   * Kuis lain tetap memakai jendela deadline 24 jam seperti semula.
///
/// Satu item per kuis: kuis inti yang belum dikerjakan DAN mendekati deadline
/// hanya muncul sekali, sebagai "belum dikerjakan" (bukan dua kartu).
/// Item notCompleted selalu di awal, lalu item deadline terurut
/// `deadline ASC` — bagian urutan dikerjakan query.
/// Menggabungkan baris kuis milik kelas dengan fallback kuis inti global
/// (Pretest/Posttest) hanya jika kelas tersebut belum memiliki salinan sendiri.
List<Map<String, dynamic>> mergeClassWithMissingCoreQuizzes(
  List<Map<String, dynamic>> classRows,
  List<Map<String, dynamic>> globalRows,
) {
  final hasClassPretest = classRows.any(
    (row) => row['assessment_type']?.toString() == 'pretest',
  );
  final hasClassPosttest = classRows.any(
    (row) => row['assessment_type']?.toString() == 'posttest',
  );

  if (hasClassPretest && hasClassPosttest) {
    return classRows;
  }

  return [
    ...classRows,
    for (final row in globalRows)
      if ((row['assessment_type']?.toString() == 'pretest' &&
              !hasClassPretest) ||
          (row['assessment_type']?.toString() == 'posttest' &&
              !hasClassPosttest))
        row,
  ];
}

Future<List<Map<String, dynamic>>> _fetchPublishedReminderQuizzes({
  String? classId,
  bool isNullClass = false,
}) async {
  try {
    var query = supabase
        .from('quizzes')
        .select(_quizzesReminderColumns)
        .eq('status', 'published');
    if (isNullClass) {
      query = query.isFilter('class_id', null);
    } else if (classId != null) {
      query = query.eq('class_id', classId);
    }
    final rows = await query.order('deadline');
    return [for (final row in rows) Map<String, dynamic>.from(row as Map)];
  } on PostgrestException catch (e) {
    final isColError = e.code == '42703' ||
        e.code == 'PGRST204' ||
        e.message.toLowerCase().contains('column');
    if (!isColError) rethrow;
    // Fallback jika skema lama belum punya kolom `class_id`.
    final rows = await supabase
        .from('quizzes')
        .select(_quizzesReminderColumns)
        .eq('status', 'published')
        .order('deadline');
    return [for (final row in rows) Map<String, dynamic>.from(row as Map)];
  }
}

Future<List<Map<String, dynamic>>> _loadClassScopedQuizRows({
  String? activeClassId,
}) async {
  if (activeClassId == null) {
    return _fetchPublishedReminderQuizzes(isNullClass: true);
  }

  final classRows = await _fetchPublishedReminderQuizzes(
    classId: activeClassId,
  );
  final hasClassPretest = classRows.any(
    (row) => row['assessment_type']?.toString() == 'pretest',
  );
  final hasClassPosttest = classRows.any(
    (row) => row['assessment_type']?.toString() == 'posttest',
  );

  if (hasClassPretest && hasClassPosttest) {
    return classRows;
  }

  final globalRows = await _fetchPublishedReminderQuizzes(isNullClass: true);
  return mergeClassWithMissingCoreQuizzes(classRows, globalRows);
}

List<ReminderItem> buildStudentDeadlineReminders(
  List<Map<String, dynamic>> quizRows,
  Set<String> completedQuizIds,
  DateTime now, {
  Duration upcomingWindow = const Duration(days: 1),
  String? className,
  bool pretestEnabled = true,
  bool posttestEnabled = true,
  bool pretestCompleted = false,
  bool posttestCompleted = false,
}) {
  final notCompleted = <ReminderItem>[];
  final deadlineItems = <ReminderItem>[];
  final seenQuizIds = <String>{};
  final seenCoreTypes = <String>{};
  final seenTaskKeys = <String>{};

  final completedCoreTypes = <String>{
    if (pretestCompleted) 'pretest',
    if (posttestCompleted) 'posttest',
    for (final row in quizRows)
      if (completedQuizIds.contains(row['id']?.toString()) &&
          (row['assessment_type']?.toString() == 'pretest' ||
              row['assessment_type']?.toString() == 'posttest'))
        row['assessment_type']!.toString(),
  };

  for (final row in quizRows) {
    final quizId = row['id'].toString();
    final assessmentType = row['assessment_type']?.toString() ?? 'pretest';
    final isCore =
        assessmentType == 'pretest' || assessmentType == 'posttest';

    if (isCore) {
      final enabled =
          assessmentType == 'pretest' ? pretestEnabled : posttestEnabled;
      if (!enabled || completedCoreTypes.contains(assessmentType)) {
        seenQuizIds.add(quizId);
        continue;
      }
      if (!seenCoreTypes.add(assessmentType)) {
        seenQuizIds.add(quizId);
        continue;
      }
      notCompleted.add(_reminderFromQuizRow(
        row,
        quizId,
        reason: ReminderReason.notCompleted,
        className: className,
      ));
      seenQuizIds.add(quizId);
      continue;
    }

    if (seenQuizIds.contains(quizId)) {
      continue;
    }

    // Jalur deadline 24 jam lama. Kuis yang sudah disubmit tidak perlu
    // pengingat apa pun, sehingga tetap dilewati di sini.
    if (completedQuizIds.contains(quizId)) {
      continue;
    }

    final deadlineStr = row['deadline']?.toString();
    if (deadlineStr == null) continue;

    final deadline = DateTime.tryParse(deadlineStr)?.toLocal();
    if (deadline == null || deadline.isBefore(now)) continue;
    if (deadline.isAfter(now.add(upcomingWindow))) continue;

    final taskKey =
        '$assessmentType|${(row['title'] ?? '').toString().trim().toLowerCase()}|$deadlineStr';
    if (!seenTaskKeys.add(taskKey)) {
      seenQuizIds.add(quizId);
      continue;
    }

    deadlineItems.add(_reminderFromQuizRow(
      row,
      quizId,
      reason: ReminderReason.deadline,
      className: className,
    ));
    seenQuizIds.add(quizId);
  }

  return [...notCompleted, ...deadlineItems];
}

ReminderItem _reminderFromQuizRow(
  Map<String, dynamic> row,
  String quizId, {
  required ReminderReason reason,
  String? className,
}) {
  final material = row['materials'];
  String? subject;
  if (material is Map) {
    subject = material['title']?.toString().trim();
  }

  final deadlineStr = row['deadline']?.toString();
  final deadline = deadlineStr == null
      ? null
      : DateTime.tryParse(deadlineStr)?.toLocal();

  return ReminderItem(
    id: quizId,
    title: row['title']?.toString() ?? '',
    titleEn: row['title_en']?.toString(),
    titleId: row['title_id']?.toString(),
    subject: subject,
    deadline: deadline,
    assessmentType: row['assessment_type']?.toString() ?? 'pretest',
    reason: reason,
    className: className,
  );
}

/// Provides deadline reminders for students: assessment yang belum dikerjakan
/// di kelas aktif, lalu deadline 24 jam. Nama provider dipertahankan agar ketiga
/// call site lama (dashboard pratinjau, halaman notifikasi mahasiswa, panel
/// lonceng) tidak berubah.
///
/// Query TANPA filter deadline: kuis inti yang belum disentuh sama sekali
/// tidak punya deadline yang mendekat, tapi justru itulah yang harus
/// diingatkan. Sumber kebenaran "sudah dikerjakan" adalah `quiz_attempts`
/// milik sendiri dan `classLearningFlowStatusProvider` per kelas aktif.
final studentDeadlineRemindersProvider = FutureProvider.autoDispose
    .family<List<ReminderItem>, String>((ref, userId) async {
  final now = DateTime.now();

  ref.watch(activeStudentClassIdProvider);
  final activeClass = await resolveActiveStudentClass(ref);
  final validClass = activeClass != null && !activeClass.isLegacyFallback;

  var pretestEnabled = true;
  var posttestEnabled = true;
  var pretestCompleted = false;
  var posttestCompleted = false;

  if (validClass) {
    ClassLearningFlowStatus? classFlow;
    try {
      classFlow = await ref.watch(
        classLearningFlowStatusProvider(activeClass.id).future,
      );
    } catch (_) {}

    if (classFlow != null) {
      pretestEnabled = classFlow.pretestEnabled;
      posttestEnabled = classFlow.posttestEnabled;
      pretestCompleted = classFlow.pretestCompleted;
      posttestCompleted = classFlow.posttestCompleted;
    }
  } else {
    try {
      final flowResponse = await supabase.rpc(
        'get_learning_flow_status',
        params: {'p_user': userId},
      );
      if (flowResponse is Map) {
        pretestCompleted = flowResponse['pretest_completed'] == true;
        posttestCompleted = flowResponse['posttest_completed'] == true;
      } else if (flowResponse is List && flowResponse.isNotEmpty) {
        final first = flowResponse.first;
        if (first is Map) {
          pretestCompleted = first['pretest_completed'] == true;
          posttestCompleted = first['posttest_completed'] == true;
        }
      }
    } catch (_) {}
  }

  final quizRows = await _loadClassScopedQuizRows(
    activeClassId: validClass ? activeClass.id : null,
  );

  // Get completed quiz attempts for this student
  final attemptRows = await supabase
      .from('quiz_attempts')
      .select('quiz_id, status')
      .eq('user_id', userId)
      .eq('status', 'submitted');

  final completedQuizIds = attemptRows
      .map((row) => row['quiz_id'].toString())
      .toSet();

  final trimmedClassName =
      validClass && activeClass.name.trim().isNotEmpty
          ? activeClass.name.trim()
          : null;

  return buildStudentDeadlineReminders(
    quizRows,
    completedQuizIds,
    now,
    className: trimmedClassName,
    pretestEnabled: pretestEnabled,
    posttestEnabled: posttestEnabled,
    pretestCompleted: pretestCompleted,
    posttestCompleted: posttestCompleted,
  );
});

/// Menyusun pengingat DOSEN: satu item per mahasiswa, berisi SEMUA asesmen
/// inti yang belum dikerjakan mahasiswa itu (bukan satu kartu per asesmen —
/// dua kartu Pretest+Posttest untuk orang yang sama menumpuk daftar),
/// mahasiswa dalam urutan daftar (RPC sudah urut nama). Murni agar bisa diuji
/// tanpa Supabase.
///
/// `publishedTypes` hanya asesmen yang benar-benar punya kuis published di
/// kelas aktif — tanpa ini semua mahasiswa akan mendapat pengingat Posttest
/// meski kuisnya belum ada atau dinonaktifkan.
List<ReminderItem> buildLecturerMissingAssessmentReminders(
  List<StudentModel> students,
  Set<String> publishedTypes, {
  String? className,
}) {
  final items = <ReminderItem>[];

  for (final student in students) {
    final missing = <String>[
      if (publishedTypes.contains('pretest') && student.pretestScore == null)
        'pretest',
      if (publishedTypes.contains('posttest') && student.posttestScore == null)
        'posttest',
    ];
    if (missing.isEmpty) continue;

    items.add(ReminderItem(
      id: 'missing-${student.id}',
      title: student.name,
      subject: student.identityNumber == null
          ? null
          : 'NIM: ${student.identityNumber}',
      deadline: null,
      // assessmentType tetap diisi (src kartu yang lebih tua membacanya)
      // dengan item pertama; daftar lengkapnya ada di assessmentTypes.
      assessmentType: missing.first,
      assessmentTypes: missing,
      reason: ReminderReason.notCompleted,
      studentId: student.id,
      className: className,
    ));
  }

  return items;
}

/// Tab Pengingat di halaman/panel notifikasi DOSEN: mahasiswa mana yang belum
/// mengerjakan Pretest/Posttest pada kelas aktif dosen.
///
/// Kenapa bukan query `quiz_attempts`: RLS mengizinkan dosen membaca attempt
/// mahasiswa lain hanya lewat `lecturer_teaches_student(user_id)`, yang false
/// karena `classes`/`enrollments` masih kosong. Keadaan "sudah dikerjakan"
/// ditarik dari `get_lecturer_student_overview` (`lecturerStudentsProvider`),
/// satu sumber yang sama dengan Student List — nilai null berarti belum
/// disubmit. Deadline null aman: item ini selalu reason `notCompleted`, dan
/// [ReminderItem] null-safe untuk semua format waktunya.
final lecturerMissingAssessmentRemindersProvider = FutureProvider.autoDispose
    <List<ReminderItem>>((ref) async {
  ref.watch(activeLecturerClassIdProvider);
  final activeClass = await resolveActiveLecturerClass(ref);
  final validClass = activeClass != null && !activeClass.isLegacyFallback;

  final quizRows = await _loadClassScopedQuizRows(
    activeClassId: validClass ? activeClass.id : null,
  );
  final types = quizRows
      .map((row) => row['assessment_type']?.toString() ?? '')
      .where((type) => type == 'pretest' || type == 'posttest')
      .toSet();

  if (validClass) {
    try {
      final settings = await ref.watch(
        classSettingsProvider(activeClass.id).future,
      );
      if (settings != null) {
        if (!settings.pretestEnabled) types.remove('pretest');
        if (!settings.posttestEnabled) types.remove('posttest');
      }
    } catch (_) {}
  }

  final students = await ref.watch(lecturerStudentsProvider(null).future);
  final trimmedClassName =
      validClass && activeClass.name.trim().isNotEmpty
          ? activeClass.name.trim()
          : null;

  return buildLecturerMissingAssessmentReminders(
    students,
    types,
    className: trimmedClassName,
  );
});
