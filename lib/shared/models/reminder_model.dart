import 'package:flutter/foundation.dart';

/// Kenapa pengingat ini dibuat.
///
/// `deadline` — kuis punya deadline yang benar-benar mendekat (jendela 24 jam).
/// `notCompleted` — kuis published belum dikerjakan sama sekali, jadi tidak ada
/// deadline cue untuk ditampilkan; kartunya pakai lencana
/// "Belum dikerjakan", bukan countdown.
enum ReminderReason { deadline, notCompleted }

@immutable
class ReminderItem {
  final String id;
  final String title;
  final String? titleEn;
  final String? titleId;
  final String? subject;
  final String? studentId;
  final DateTime? deadline;
  final String assessmentType;

  /// Daftar asesmen inti yang belum dikerjakan oleh satu mahasiswa, untuk
  /// pengingat dosen yang digabung satu item per mahasiswa
  /// (`['pretest', 'posttest']` dsb). Kosong berarti item memakai
  /// [assessmentType] saja — jalur deadline mahasiswa yang lama.
  final List<String> assessmentTypes;
  final ReminderReason reason;

  const ReminderItem({
    required this.id,
    required this.title,
    this.titleEn,
    this.titleId,
    this.subject,
    this.studentId,
    /// `deadline` null berarti item "belum dikerjakan" (tidak ada waktu yang
    /// bisa di-countdown). Field ini dibuat nullable agar item semacam itu bisa
    /// dirender. `reason` default `deadline` supaya semua call site lama tetap
    /// kompilasi dan beralih ke jalur deadline yang lama.
    this.deadline,
    required this.assessmentType,
    this.assessmentTypes = const <String>[],
    this.reason = ReminderReason.deadline,
  });

  String localizedTitle(bool isIndonesian) {
    if (isIndonesian) {
      return titleId?.isNotEmpty == true ? titleId! : title;
    }
    return titleEn?.isNotEmpty == true ? titleEn! : title;
  }

  /// Teks baris meta kartu / pratinjau dashboard.
  ///
  /// Deadline memformat waktunya seperti sebelumnya; "belum dikerjakan"
  /// tidak punya waktu, jadi label asesmennya (atau subjek) yang ditampilkan —
  /// bukan countdown yang dibuat-buat di mana ada none.
  String subtitle(bool isIndonesian) {
    if (reason == ReminderReason.notCompleted) {
      if (subject != null && subject!.isNotEmpty) {
        return subject!;
      }
      return assessmentType == 'posttest' ? 'Posttest' : 'Pretest';
    }

    if (deadline == null) {
      return '';
    }
    return formatDeadline(isIndonesian);
  }

  String timeLeft(bool isIndonesian) {
    final activeDeadline = deadline;
    if (activeDeadline == null) {
      return '';
    }

    final now = DateTime.now();
    final difference = activeDeadline.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${isIndonesian ? "hari lagi" : "days left"}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${isIndonesian ? "jam lagi" : "hours left"}';
    } else {
      return '${difference.inMinutes} ${isIndonesian ? "menit lagi" : "minutes left"}';
    }
  }

  bool get isOverdue {
    final activeDeadline = deadline;
    if (activeDeadline == null) {
      return false;
    }
    return activeDeadline.isBefore(DateTime.now());
  }

  String get reminderType {
    final activeDeadline = deadline;
    if (activeDeadline == null) {
      return 'not_completed';
    }

    final now = DateTime.now();
    final difference = activeDeadline.difference(now);

    if (difference.inDays == 0 && difference.inHours < 24) {
      return 'due_soon';
    } else if (difference.inDays == 1) {
      return 'due_tomorrow';
    }
    return 'upcoming';
  }

  String formatDeadline(bool isIndonesian) {
    final activeDeadline = deadline;
    if (activeDeadline == null) {
      return '';
    }

    final monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthsId = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final months = isIndonesian ? monthsId : monthsEn;

    return '${activeDeadline.day} ${months[activeDeadline.month - 1]} ${activeDeadline.year} • '
        '${activeDeadline.hour.toString().padLeft(2, '0')}.${activeDeadline.minute.toString().padLeft(2, '0')}';
  }
}
