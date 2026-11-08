import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/material_model.dart';

class MaterialCacheService {
  static const String _keyPrefix = 'material_cache_';
  static const String _idsListKey = 'cached_material_ids';

  static Map<String, dynamic> _toMap(MaterialModel m) {
    return {
      'id': m.id,
      'module_number': m.moduleNumber,
      'is_core': m.isCore,
      'order_index': m.orderIndex,
      'title': m.title,
      'description': m.description,
      'content': m.content,
      'summary': m.summary,
      'title_en': m.titleEn,
      'title_id': m.titleId,
      'description_en': m.descriptionEn,
      'description_id': m.descriptionId,
      'content_en': m.contentEn,
      'content_id': m.contentId,
      'summary_en': m.summaryEn,
      'summary_id': m.summaryId,
      'pdf_url': m.pdfUrl,
      'video_url': m.videoUrl,
      'video_id': m.videoId,
      'duration_minutes': m.durationMinutes,
      'published': m.published,
      'lock_status': m.lockStatus,
      'created_by': m.createdBy,
      'created_at': m.createdAt?.toIso8601String(),
      'updated_at': m.updatedAt?.toIso8601String(),
    };
  }

  /// Caches a material locally for offline reading.
  static Future<void> cacheMaterial(MaterialModel material) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_toMap(material));
      await prefs.setString('$_keyPrefix${material.id}', jsonStr);

      final ids = prefs.getStringList(_idsListKey) ?? [];
      if (!ids.contains(material.id)) {
        ids.add(material.id);
        await prefs.setStringList(_idsListKey, ids);
      }
    } catch (_) {}
  }

  /// Loads a cached material if available.
  static Future<MaterialModel?> getCachedMaterial(String materialId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_keyPrefix$materialId');
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return MaterialModel.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  /// Checks if a material is available offline.
  static Future<bool> isCached(String materialId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('$_keyPrefix$materialId');
    } catch (_) {
      return false;
    }
  }
}

