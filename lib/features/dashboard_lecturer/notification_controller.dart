import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_client.dart';
import '../../shared/models/announcement_model.dart';
import '../../shared/models/reminder_model.dart';
import '../../shared/models/student_model.dart';
import '../classes/class_controller.dart';
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
  } else if (role == 'lecturer') {
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
List<ReminderItem> buildStudentDeadlineReminders(
  List<Map<String, dynamic>> quizRows,
  Set<String> completedQuizIds,
  DateTime now, {
  Duration upcomingWindow = const Duration(days: 1),
}) {
  final notCompleted = <ReminderItem>[];
  final deadlineItems = <ReminderItem>[];
  final seenQuizIds = <String>{};

  for (final row in quizRows) {
    final quizId = row['id'].toString();
    final assessmentType = row['assessment_type']?.toString() ?? 'pretest';
    final isCore =
        assessmentType == 'pretest' || assessmentType == 'posttest';

    if (isCore && !completedQuizIds.contains(quizId)) {
      notCompleted.add(_reminderFromQuizRow(
        row,
        quizId,
        reason: ReminderReason.notCompleted,
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

    deadlineItems.add(_reminderFromQuizRow(
      row,
      quizId,
      reason: ReminderReason.deadline,
    ));
    seenQuizIds.add(quizId);
  }

  return [...notCompleted, ...deadlineItems];
}

ReminderItem _reminderFromQuizRow(
  Map<String, dynamic> row,
  String quizId, {
  required ReminderReason reason,
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
  );
}

/// Provides deadline reminders for students: assessment yang belum dikerjakan,
/// lalu deadline 24 jam. Nama provider dipertahankan agar ketiga call site
/// lama (dashboard pratinjau, halaman notifikasi mahasiswa, panel lonceng)
/// tidak berubah.
///
/// Query TANPA filter deadline: kuis inti yang belum disentuh sama sekali
/// tidak punya deadline yang mendekat, tapi justru itulah yang harus
/// diingatkan. Sumber kebenaran "sudah dikerjakan" adalah `quiz_attempts`
/// milik sendiri (RLS mengizinkan baca baris sendiri), bukan
/// `learning_progress` — barisnya satu per materi dan terduplikasi.
final studentDeadlineRemindersProvider = FutureProvider.autoDispose
    .family<List<ReminderItem>, String>((ref, userId) async {
  final now = DateTime.now();

  final quizRows = await supabase
      .from('quizzes')
      .select(_quizzesReminderColumns)
      .eq('status', 'published')
      .order('deadline');

  // Get completed quiz attempts for this student
  final attemptRows = await supabase
      .from('quiz_attempts')
      .select('quiz_id, status')
      .eq('user_id', userId)
      .eq('status', 'submitted');

  final completedQuizIds = attemptRows
      .map((row) => row['quiz_id'].toString())
      .toSet();

  return buildStudentDeadlineReminders(
    [
      for (final row in quizRows) Map<String, dynamic>.from(row as Map),
    ],
    completedQuizIds,
    now,
  );
});

/// Menyusun pengingat DOSEN: satu item per mahasiswa, berisi SEMUA asesmen
/// inti yang belum dikerjakan mahasiswa itu (bukan satu kartu per asesmen —
/// dua kartu Pretest+Posttest untuk orang yang sama menumpuk daftar),
/// mahasiswa dalam urutan daftar (RPC sudah urut nama). Murni agar bisa diuji
/// tanpa Supabase.
///
/// `publishedTypes` hanya asesmen yang benar-benar punya kuis published —
/// tanpa ini semua mahasiswa akan mendapat pengingat Posttest meski kuisnya
/// belum ada.
List<ReminderItem> buildLecturerMissingAssessmentReminders(
  List<StudentModel> students,
  Set<String> publishedTypes,
) {
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
    ));
  }

  return items;
}

/// Tab Pengingat di halaman/panel notifikasi DOSEN: mahasiswa mana yang belum
/// mengerjakan Pretest/Posttest.
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
  // Hanya jenis asesmen yang benar-benar punya kuis published. Tanpa ini,
  // semua mahasiswa akan mendapat pengingat Posttest meski kuisnya belum ada.
  final quizRows = await supabase
      .from('quizzes')
      .select('assessment_type')
      .eq('status', 'published')
      .inFilter('assessment_type', ['pretest', 'posttest']);

  final types = quizRows
      .map((row) => row['assessment_type'].toString())
      .toSet();

  final students = await ref.watch(lecturerStudentsProvider(null).future);

  return buildLecturerMissingAssessmentReminders(students, types);
});
