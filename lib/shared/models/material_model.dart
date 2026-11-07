import 'package:flutter/foundation.dart';

@immutable
class MaterialModel {
  final String id;
  final int? moduleNumber;
  final bool isCore;
  final int orderIndex;

  // ============================================================
  // DEFAULT / LEGACY
  // ============================================================

  final String title;
  final String? description;
  final String? content;
  final String? summary;

  // ============================================================
  // BILINGUAL
  // ============================================================

  final String? titleEn;
  final String? titleId;

  final String? descriptionEn;
  final String? descriptionId;

  final String? contentEn;
  final String? contentId;

  final String? summaryEn;
  final String? summaryId;

  // ============================================================
  // MEDIA
  // ============================================================

  final String? pdfUrl;
  final String? videoUrl;
  final String? videoId;
  final int? durationMinutes;

  // ============================================================
  // STATUS
  // ============================================================

  final bool published;
  final String lockStatus;

  // ============================================================
  // AUDIT
  // ============================================================

  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MaterialModel({
    required this.id,
    this.moduleNumber,
    required this.isCore,
    required this.orderIndex,
    required this.title,
    this.description,
    this.content,
    this.summary,
    this.titleEn,
    this.titleId,
    this.descriptionEn,
    this.descriptionId,
    this.contentEn,
    this.contentId,
    this.summaryEn,
    this.summaryId,
    this.pdfUrl,
    this.videoUrl,
    this.videoId,
    this.durationMinutes,
    required this.published,
    required this.lockStatus,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory MaterialModel.fromMap(
      Map<String, dynamic> map,
      ) {
    return MaterialModel(
      id: map['id']?.toString() ?? '',

      moduleNumber: _parseInt(
        map['module_number'],
      ),

      isCore: map['is_core'] == true,

      orderIndex:
      _parseInt(map['order_index']) ?? 0,

      // ========================================================
      // DEFAULT / LEGACY
      // ========================================================

      title: map['title']?.toString() ?? '',

      description: _nullableString(
        map['description'],
      ),

      content: _nullableString(
        map['content'],
      ),

      summary: _nullableString(
        map['summary'],
      ),

      // ========================================================
      // BILINGUAL
      // ========================================================

      titleEn: _nullableString(
        map['title_en'],
      ),

      titleId: _nullableString(
        map['title_id'],
      ),

      descriptionEn: _nullableString(
        map['description_en'],
      ),

      descriptionId: _nullableString(
        map['description_id'],
      ),

      contentEn: _nullableString(
        map['content_en'],
      ),

      contentId: _nullableString(
        map['content_id'],
      ),

      summaryEn: _nullableString(
        map['summary_en'],
      ),

      summaryId: _nullableString(
        map['summary_id'],
      ),

      // ========================================================
      // MEDIA
      // ========================================================

      pdfUrl: _nullableString(
        map['pdf_url'],
      ),

      videoUrl: _nullableString(
        map['video_url'],
      ),

      videoId: _nullableString(
        map['video_id'],
      ),

      durationMinutes: _parseInt(
        map['duration_minutes'],
      ),

      // ========================================================
      // STATUS
      // ========================================================

      published:
      map['published'] == true,

      lockStatus:
      map['lock_status']?.toString() ?? 'default',

      // ========================================================
      // AUDIT
      // ========================================================

      createdBy: _nullableString(
        map['created_by'],
      ),

      createdAt: _parseDateTime(
        map['created_at'],
      ),

      updatedAt: _parseDateTime(
        map['updated_at'],
      ),
    );
  }

  // ============================================================
  // LOCALIZED CONTENT
  // ============================================================

  String localizedTitle(
      String languageCode,
      ) {
    if (languageCode == 'id') {
      return titleId?.isNotEmpty == true
          ? titleId!
          : title;
    }

    return titleEn?.isNotEmpty == true
        ? titleEn!
        : title;
  }

  String? localizedDescription(
      String languageCode,
      ) {
    if (languageCode == 'id') {
      return descriptionId?.isNotEmpty == true
          ? descriptionId
          : description;
    }

    return descriptionEn?.isNotEmpty == true
        ? descriptionEn
        : description;
  }

  String? localizedContent(
      String languageCode,
      ) {
    final resolved = languageCode == 'id'
        ? (contentId?.isNotEmpty == true ? contentId : content)
        : (contentEn?.isNotEmpty == true ? contentEn : content);

    return _normalizeNewlines(resolved);
  }

  // Some seed data stored paragraph breaks as the literal two-character
  // sequence backslash + 'n' rather than real newlines, which collapsed the
  // whole body onto one line. Converting them here keeps the reader correct
  // even if that data is loaded again.
  static String? _normalizeNewlines(String? value) {
    if (value == null) return null;
    return value.contains(r'\n') ? value.replaceAll(r'\n', '\n') : value;
  }

  String? localizedSummary(
      String languageCode,
      ) {
    if (languageCode == 'id') {
      return summaryId?.isNotEmpty == true
          ? summaryId
          : summary;
    }

    return summaryEn?.isNotEmpty == true
        ? summaryEn
        : summary;
  }

  // ============================================================
  // TO MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module_number': moduleNumber,
      'is_core': isCore,
      'order_index': orderIndex,

      // Legacy
      'title': title,
      'description': description,
      'content': content,
      'summary': summary,

      // Bilingual
      'title_en': titleEn,
      'title_id': titleId,
      'description_en': descriptionEn,
      'description_id': descriptionId,
      'content_en': contentEn,
      'content_id': contentId,
      'summary_en': summaryEn,
      'summary_id': summaryId,

      // Media
      'pdf_url': pdfUrl,
      'video_url': videoUrl,
      'video_id': videoId,
      'duration_minutes': durationMinutes,

      // Status
      'published': published,
      'lock_status': lockStatus,

      // Audit
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  MaterialModel copyWith({
    String? id,
    int? moduleNumber,
    bool? isCore,
    int? orderIndex,

    String? title,
    String? description,
    String? content,
    String? summary,

    String? titleEn,
    String? titleId,

    String? descriptionEn,
    String? descriptionId,

    String? contentEn,
    String? contentId,

    String? summaryEn,
    String? summaryId,

    String? pdfUrl,
    String? videoUrl,
    String? videoId,
    int? durationMinutes,

    bool? published,
    String? lockStatus,

    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaterialModel(
      id: id ?? this.id,
      moduleNumber:
      moduleNumber ?? this.moduleNumber,
      isCore: isCore ?? this.isCore,
      orderIndex:
      orderIndex ?? this.orderIndex,

      title: title ?? this.title,
      description:
      description ?? this.description,
      content:
      content ?? this.content,
      summary:
      summary ?? this.summary,

      titleEn:
      titleEn ?? this.titleEn,
      titleId:
      titleId ?? this.titleId,

      descriptionEn:
      descriptionEn ?? this.descriptionEn,
      descriptionId:
      descriptionId ?? this.descriptionId,

      contentEn:
      contentEn ?? this.contentEn,
      contentId:
      contentId ?? this.contentId,

      summaryEn:
      summaryEn ?? this.summaryEn,
      summaryId:
      summaryId ?? this.summaryId,

      pdfUrl:
      pdfUrl ?? this.pdfUrl,
      videoUrl:
      videoUrl ?? this.videoUrl,
      videoId:
      videoId ?? this.videoId,
      durationMinutes:
      durationMinutes ?? this.durationMinutes,

      published:
      published ?? this.published,
      lockStatus:
      lockStatus ?? this.lockStatus,

      createdBy:
      createdBy ?? this.createdBy,
      createdAt:
      createdAt ?? this.createdAt,
      updatedAt:
      updatedAt ?? this.updatedAt,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static int? _parseInt(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static String? _nullableString(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    final text =
    value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  static DateTime? _parseDateTime(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}