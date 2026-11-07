import 'package:flutter/foundation.dart';

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
  final List<String> assessmentTypes;
  final ReminderReason reason;

  const ReminderItem({
    required this.id,
    required this.title,
    this.titleEn,
    this.titleId,
    this.subject,
    this.studentId,
    this.deadline,
    required this.assessmentType,
    this.assessmentTypes = const <String>[],
    this.reason = ReminderReason.deadline,
  });

  String localizedTitle({bool isIndonesian = true}) {
    if (isIndonesian) {
      return titleId?.isNotEmpty == true ? titleId! : title;
    }
    return titleEn?.isNotEmpty == true ? titleEn! : title;
  }

  String subtitle({bool isIndonesian = true}) {
    if (reason == ReminderReason.notCompleted) {
      if (subject != null && subject!.isNotEmpty) {
        return subject!;
      }
      return assessmentType == 'posttest' ? 'Posttest' : 'Pretest';
    }

    if (deadline == null) {
      return '';
    }
    return formatDeadline(isIndonesian: isIndonesian);
  }

  String formatDeadline({bool isIndonesian = true}) {
    if (deadline == null) return '';
    final difference = deadline!.difference(DateTime.now());
    if (difference.isNegative) {
      return isIndonesian ? 'Telah berakhir' : 'Overdue';
    }
    if (difference.inHours < 1) {
      final mins = difference.inMinutes;
      return isIndonesian ? 'Tersisa $mins menit' : '$mins min left';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return isIndonesian ? 'Tersisa $hours jam' : '$hours hrs left';
    }
    final days = difference.inDays;
    return isIndonesian ? 'Tersisa $days hari' : '$days days left';
  }
}

