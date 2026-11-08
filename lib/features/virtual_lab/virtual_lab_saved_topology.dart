import 'dart:convert';

import 'virtual_lab_model.dart';

/// Model data untuk skenario topologi yang disimpan oleh pengguna.
class VirtualLabSavedTopology {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int deviceCount;
  final int cableCount;
  final Map<String, dynamic> sessionData;

  const VirtualLabSavedTopology({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceCount,
    required this.cableCount,
    required this.sessionData,
  });

  /// Mengonversi kembali snapshot `sessionData` menjadi objek `VirtualLabSession`.
  VirtualLabSession toSession() {
    return VirtualLabSession.fromJson(sessionData);
  }

  /// Membuat entri `VirtualLabSavedTopology` baru dari objek `VirtualLabSession`.
  factory VirtualLabSavedTopology.fromSession({
    required String id,
    required String name,
    String? description,
    required VirtualLabSession session,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return VirtualLabSavedTopology(
      id: id,
      name: name,
      description: description,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      deviceCount: session.devices.length,
      cableCount: session.cables.length,
      sessionData: session.toJson(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deviceCount': deviceCount,
      'cableCount': cableCount,
      'sessionData': sessionData,
    };
  }

  factory VirtualLabSavedTopology.fromJson(Map<String, dynamic> json) {
    return VirtualLabSavedTopology(
      id: json['id'] as String? ??
          'topo_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Topologi Tanpa Judul',
      description: json['description'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      deviceCount: (json['deviceCount'] as num?)?.toInt() ?? 0,
      cableCount: (json['cableCount'] as num?)?.toInt() ?? 0,
      sessionData: json['sessionData'] is Map
          ? Map<String, dynamic>.from(json['sessionData'] as Map)
          : <String, dynamic>{},
    );
  }

  static String encodeList(List<VirtualLabSavedTopology> list) {
    return jsonEncode(list.map((t) => t.toJson()).toList());
  }

  static List<VirtualLabSavedTopology> decodeList(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => VirtualLabSavedTopology.fromJson(
                Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {}
    return const [];
  }
}

