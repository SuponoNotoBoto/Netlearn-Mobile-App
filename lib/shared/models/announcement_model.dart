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

  /// Returns user-facing content with any internal class scoping metadata stripped out.
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

  AnnouncementModel copyWith({
    String? id,
    String? lecturerId,
    String? classId,
    String? title,
    String? content,
    String? recipientScope,
    bool? published,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      lecturerId: lecturerId ?? this.lecturerId,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      content: content ?? this.content,
      recipientScope: recipientScope ?? this.recipientScope,
      published: published ?? this.published,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

@immutable
class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final String? relatedEntityId;
  final String? relatedEntityType;
  final bool read;
  final DateTime scheduledAt;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedEntityId,
    this.relatedEntityType,
    required this.read,
    required this.scheduledAt,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      relatedEntityId: map['related_entity_id']?.toString(),
      relatedEntityType: map['related_entity_type']?.toString(),
      read: map['read'] == true,
      scheduledAt: _parseDateTime(map['scheduled_at']) ?? DateTime.now(),
      readAt: _parseDateTime(map['read_at']),
      createdAt: _parseDateTime(map['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'related_entity_id': relatedEntityId,
      'related_entity_type': relatedEntityType,
      'read': read,
      'scheduled_at': scheduledAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    String? relatedEntityId,
    String? relatedEntityType,
    bool? read,
    DateTime? scheduledAt,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      read: read ?? this.read,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

enum NotificationType { announcement, reminder }

enum RecipientScope { allStudents }