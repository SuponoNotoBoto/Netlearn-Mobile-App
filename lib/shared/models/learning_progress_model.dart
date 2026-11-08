import 'package:flutter/foundation.dart';

@immutable
class LearningProgressModel {
  final String id;
  final String userId;
  final String materialId;
  final bool readingCompleted;
  final bool videoCompleted;
  final bool arUsed;
  final bool quizPassed;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  const LearningProgressModel({
    required this.id,
    required this.userId,
    required this.materialId,
    required this.readingCompleted,
    required this.videoCompleted,
    required this.arUsed,
    required this.quizPassed,
    this.completedAt,
    this.updatedAt,
  });

  factory LearningProgressModel.fromMap(
      Map<String, dynamic> map,
      ) {
    return LearningProgressModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      materialId: map['material_id']?.toString() ?? '',
      readingCompleted:
      map['reading_completed'] == true,
      videoCompleted:
      map['video_completed'] == true,
      arUsed: map['ar_used'] == true,
      quizPassed:
      map['quiz_passed'] == true,
      completedAt: _parseDateTime(
        map['completed_at'],
      ),
      updatedAt: _parseDateTime(
        map['updated_at'],
      ),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}