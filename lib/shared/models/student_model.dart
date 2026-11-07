import 'package:flutter/foundation.dart';

/// A lecturer-facing student profile plus the latest submitted pretest/posttest
/// scores, delivered by the `get_lecturer_student_overview` RPC.
///
/// Only non-private fields are exposed to the lecturer UI. `email` is stored
/// on the model because it is part of the profile row, but it is intentionally
/// not rendered in the student list to avoid exposing contact data
/// unnecessarily. The RPC does not return it at all; it stays nullable for
/// older call sites.
@immutable
class StudentModel {
  final String id;
  final String name;
  final String? identityNumber; // NIM / student ID
  final String? email;
  final String? program;
  final bool isActive;
  final DateTime? createdAt;

  /// Latest submitted pretest score, 0–100. Null while the assessment has not
  /// been completed — deliberately null rather than 0, so the UI and CSV can
  /// say "not available" instead of reporting a real zero.
  final double? pretestScore;
  final DateTime? pretestSubmittedAt;

  /// Latest submitted posttest score, 0–100. See [pretestScore].
  final double? posttestScore;
  final DateTime? posttestSubmittedAt;

  const StudentModel({
    required this.id,
    required this.name,
    this.identityNumber,
    this.email,
    this.program,
    required this.isActive,
    this.createdAt,
    this.pretestScore,
    this.pretestSubmittedAt,
    this.posttestScore,
    this.posttestSubmittedAt,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      identityNumber: map['identity_number']?.toString(),
      email: map['email']?.toString(),
      program: map['program']?.toString(),
      isActive: map['is_active'] == true,
      createdAt: _parseDateTime(map['created_at']),
      pretestScore: _parseScore(map['pretest_score']),
      pretestSubmittedAt: _parseDateTime(map['pretest_submitted_at']),
      posttestScore: _parseScore(map['posttest_score']),
      posttestSubmittedAt: _parseDateTime(map['posttest_submitted_at']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  /// Parses a numeric score the way PostgREST may deliver it: as a JSON
  /// number (int or double) or as a string for `numeric` columns, or as null
  /// when the `left join lateral` found no attempt.
  static double? _parseScore(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().trim());
  }
}
