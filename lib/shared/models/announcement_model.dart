import 'package:flutter/foundation.dart';

@immutable
class AnnouncementModel {
  final String id;
  final String lecturerId;
  final String? classId;
  final String title;
  final String content;
  final String recipientScope;
  final bool published;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AnnouncementModel({
    required this.id,
    required this.lecturerId,
    this.classId,
    required this.title,
    required this.content,
    required this.recipientScope,
    required this.published,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Mengembalikan konten yang bersih tanpa metadata internal class scoping
  String get displayContent {
    return content.replaceAll(RegExp(r'\s*<!--class:[a-zA-Z0-9_-]+-->'), '').trim();
  }

  factory AnnouncementModel.fromMap(Map<String, dynamic> map) {
    final rawContent = map['content']?.toString() ?? '';
    String? parsedClassId = map['class_id']?.toString();
    if (parsedClassId == null || parsedClassId.isEmpty) {
      final match = RegExp(r'<!--class:([a-zA-Z0-9_-]+)-->').firstMatch(rawContent);
      if (match != null) {
        parsedClassId = match.group(1);
      }
    }

    return AnnouncementModel(
      id: map['id']?.toString() ?? '',
      lecturerId: map['lecturer_id']?.toString() ?? '',
      classId: parsedClassId,
      title: map['title']?.toString() ?? '',
      content: rawContent,
      recipientScope: map['recipient_scope']?.toString() ?? 'all_students',
      published: map['published'] == true,
      publishedAt: _parseDateTime(map['published_at']),
      createdAt: _parseDateTime(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lecturer_id': lecturerId,
      if (classId != null) 'class_id': classId,
      'title': title,
      'content': content,
      'recipient_scope': recipientScope,
      'published': published,
      'published_at': publishedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}

