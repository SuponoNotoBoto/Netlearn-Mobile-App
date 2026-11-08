import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../models/learning_flow_status_model.dart';
import '../models/learning_progress_model.dart';
import '../models/material_model.dart';
import '../models/module_state_model.dart';

class StudentService {
  StudentService._();

  static final StudentService instance = StudentService._();

  SupabaseClient get _client => supabase;

  String get _userId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'Sesi pengguna tidak ditemukan.',
      );
    }

    return user.id;
  }

  static const String _materialSelectColumns = '''
    id,
    class_id,
    module_id,
    module_number,
    is_core,
    order_index,

    title,
    description,
    content,
    summary,

    title_en,
    title_id,
    description_en,
    description_id,
    content_en,
    content_id,
    summary_en,
    summary_id,

    pdf_url,
    video_url,
    video_id,
    duration_minutes,

    published,
    lock_status,

    created_by,
    created_at,
    updated_at
  ''';

  // ============================================================
  // MATERIALS
  // ============================================================

  Future<List<MaterialModel>> getPublishedMaterials({String? classId}) async {
    final validClass = classId != null &&
        classId.isNotEmpty &&
        classId != '__legacy_fallback_class__';

    if (validClass) {
      final classRows = await _client
          .from('materials')
          .select(_materialSelectColumns)
          .eq('published', true)
          .eq('class_id', classId)
          .order('module_number')
          .order('order_index')
          .order('id');

      final list = (classRows as List)
          .map((item) => MaterialModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();

      if (list.isNotEmpty) {
        return list;
      }

      // If the class owns modules, return the empty list rather than falling
      // back to global template rows (e.g. a custom class with no published
      // materials yet).
      final modCheck = await _client
          .from('class_modules')
          .select('id')
          .eq('class_id', classId)
          .limit(1);
      if ((modCheck as List).isNotEmpty) {
        return const <MaterialModel>[];
      }
    }

    final response = await _client
        .from('materials')
        .select(_materialSelectColumns)
        .eq('published', true)
        .isFilter('class_id', null)
        .order('module_number')
        .order('order_index')
        .order('id');

    return (response as List)
        .map(
          (item) => MaterialModel.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  // ============================================================
  // MATERIAL BY ID
  // ============================================================

  Future<MaterialModel?> getMaterialById(
    String materialId,
  ) async {
    final response = await _client
        .from('materials')
        .select(_materialSelectColumns)
        .eq('id', materialId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return MaterialModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // MATERIALS BY MODULE
  // ============================================================

  Future<List<MaterialModel>> getMaterialsByModule(
    int moduleNumber, {
    String? classId,
  }) async {
    final validClass = classId != null &&
        classId.isNotEmpty &&
        classId != '__legacy_fallback_class__';

    if (validClass) {
      final classRows = await _client
          .from('materials')
          .select(_materialSelectColumns)
          .eq('published', true)
          .eq('class_id', classId)
          .eq('module_number', moduleNumber)
          .order('order_index')
          .order('id');

      final list = (classRows as List)
          .map((item) => MaterialModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();

      if (list.isNotEmpty) {
        return list;
      }

      try {
        final modRows = await _client
            .from('class_modules')
            .select('id, position, template_module_number, title')
            .eq('class_id', classId);
        String? targetModuleId;
        for (final r in modRows as List) {
          final pos = (r['position'] as num?)?.toInt();
          final tpl = (r['template_module_number'] as num?)?.toInt();
          final title = r['title']?.toString() ?? '';
          final match = RegExp(
            r'(?:modul|module)\s*(\d+)',
            caseSensitive: false,
          ).firstMatch(title);
          final titleNum = match != null ? int.tryParse(match.group(1)!) : null;
          if (pos == moduleNumber || tpl == moduleNumber || titleNum == moduleNumber) {
            targetModuleId = r['id']?.toString();
            break;
          }
        }
        if (targetModuleId != null) {
          final matsByMod = await _client
              .from('materials')
              .select(_materialSelectColumns)
              .eq('published', true)
              .eq('class_id', classId)
              .eq('module_id', targetModuleId)
              .order('order_index')
              .order('id');
          final listByMod = (matsByMod as List)
              .map((item) => MaterialModel.fromMap(Map<String, dynamic>.from(item)))
              .toList();
          if (listByMod.isNotEmpty) {
            return listByMod;
          }
        }
      } catch (_) {}

      final modCheck = await _client
          .from('class_modules')
          .select('id')
          .eq('class_id', classId)
          .limit(1);
      if ((modCheck as List).isNotEmpty) {
        return const <MaterialModel>[];
      }
    }

    final response = await _client
        .from('materials')
        .select(_materialSelectColumns)
        .eq('published', true)
        .isFilter('class_id', null)
        .eq('module_number', moduleNumber)
        .order('order_index')
        .order('id');

    return (response as List)
        .map(
          (item) => MaterialModel.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  // ============================================================
  // LEARNING FLOW STATUS (RPC BARU)
  // ============================================================

  Future<LearningFlowStatusModel> getLearningFlowStatus() async {
    final response = await _client.rpc(
      'get_learning_flow_status',
      params: {
        'p_user': _userId,
      },
    );

    if (response is List && response.isNotEmpty) {
      return LearningFlowStatusModel.fromMap(
        Map<String, dynamic>.from(response.first),
      );
    } else if (response is Map<String, dynamic>) {
      return LearningFlowStatusModel.fromMap(response);
    }

    // Returning an all-false model here would be indistinguishable from a
    // genuine "nothing unlocked yet" state and would silently lock every
    // module in the UI, so the failure is surfaced instead.
    throw const PostgrestException(
      message: 'Gagal memuat status pembelajaran.',
      code: 'FLOW_STATUS_EMPTY',
    );
  }

  // ============================================================
  // MODULE STATES
  // ============================================================

  Future<List<ModuleStateModel>> getModuleStates() async {
    final response = await _client.rpc(
      'compute_module_states',
      params: {
        'p_user': _userId,
      },
    );

    return (response as List)
        .map(
          (item) => ModuleStateModel.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<ModuleStateModel?> getModuleState(
    String materialId,
  ) async {
    final states = await getModuleStates();

    for (final state in states) {
      if (state.materialId == materialId) {
        return state;
      }
    }

    return null;
  }

  // ============================================================
  // LEARNING PROGRESS
  // ============================================================

  Future<LearningProgressModel?> getLearningProgress(
    String materialId,
  ) async {
    try {
      final mpRow = await _client
          .from('material_progress')
          .select('''
            id,
            student_id,
            material_id,
            reading_completed,
            video_completed,
            completed_at,
            updated_at
          ''')
          .eq('student_id', _userId)
          .eq('material_id', materialId)
          .maybeSingle();

      if (mpRow != null) {
        final map = Map<String, dynamic>.from(mpRow);
        return LearningProgressModel.fromMap({
          ...map,
          'user_id': map['student_id'],
          'ar_used': false,
          'quiz_passed': false,
        });
      }

      final matRow = await _client
          .from('materials')
          .select('class_id')
          .eq('id', materialId)
          .maybeSingle();
      if (matRow != null && matRow['class_id'] != null) {
        return null;
      }
    } catch (_) {}

    final response = await _client
        .from('learning_progress')
        .select('''
          id,
          user_id,
          material_id,
          reading_completed,
          video_completed,
          ar_used,
          quiz_passed,
          completed_at,
          updated_at
        ''')
        .eq('user_id', _userId)
        .eq('material_id', materialId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return LearningProgressModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  Future<List<LearningProgressModel>> getAllLearningProgress({
    String? classId,
  }) async {
    final validClass = classId != null &&
        classId.isNotEmpty &&
        classId != '__legacy_fallback_class__';

    final byMaterialId = <String, LearningProgressModel>{};

    if (validClass) {
      try {
        final mpRows = await _client
            .from('material_progress')
            .select('''
              id,
              student_id,
              material_id,
              reading_completed,
              video_completed,
              completed_at,
              updated_at
            ''')
            .eq('student_id', _userId)
            .eq('class_id', classId);

        for (final item in mpRows as List) {
          final map = Map<String, dynamic>.from(item);
          final model = LearningProgressModel.fromMap({
            ...map,
            'user_id': map['student_id'],
            'ar_used': false,
            'quiz_passed': false,
          });
          byMaterialId[model.materialId] = model;
        }
      } catch (_) {}

      return byMaterialId.values.toList();
    }

    final response = await _client
        .from('learning_progress')
        .select('''
          id,
          user_id,
          material_id,
          reading_completed,
          video_completed,
          ar_used,
          quiz_passed,
          completed_at,
          updated_at
        ''')
        .eq('user_id', _userId);

    for (final item in response as List) {
      final model = LearningProgressModel.fromMap(
        Map<String, dynamic>.from(item),
      );
      byMaterialId[model.materialId] = model;
    }

    try {
      final mpRows = await _client
          .from('material_progress')
          .select('''
            id,
            student_id,
            material_id,
            reading_completed,
            video_completed,
            completed_at,
            updated_at
          ''')
          .eq('student_id', _userId);

      for (final item in mpRows as List) {
        final map = Map<String, dynamic>.from(item);
        final model = LearningProgressModel.fromMap({
          ...map,
          'user_id': map['student_id'],
          'ar_used': false,
          'quiz_passed': false,
        });
        byMaterialId[model.materialId] = model;
      }
    } catch (_) {}

    return byMaterialId.values.toList();
  }

  // ============================================================
  // READING
  // ============================================================

  Future<void> markReadingCompleted(
    String materialId, {
    String? classId,
  }) async {
    String? effectiveClassId = classId;
    if (effectiveClassId == null ||
        effectiveClassId.isEmpty ||
        effectiveClassId == '__legacy_fallback_class__') {
      try {
        final matRow = await _client
            .from('materials')
            .select('class_id')
            .eq('id', materialId)
            .maybeSingle();
        effectiveClassId = matRow?['class_id']?.toString();
      } catch (_) {}
    }

    final hasClass = effectiveClassId != null &&
        effectiveClassId.isNotEmpty &&
        effectiveClassId != '__legacy_fallback_class__';

    if (hasClass) {
      try {
        await _client.rpc(
          'mark_class_reading_completed',
          params: {
            'p_class': effectiveClassId,
            'p_material': materialId,
          },
        );
      } catch (e) {
        debugPrint('mark_class_reading_completed RPC failed, attempting direct upsert: $e');
        try {
          final matInfo = await _client
              .from('materials')
              .select('content_version, video_id')
              .eq('id', materialId)
              .maybeSingle();
          final version = (matInfo?['content_version'] as num?)?.toInt() ?? 1;
          final videoId = matInfo?['video_id']?.toString().trim();
          final hasVideo = videoId != null && videoId.isNotEmpty;

          await _client.from('material_progress').upsert({
            'class_id': effectiveClassId,
            'material_id': materialId,
            'student_id': _userId,
            'content_version': version,
            'reading_completed': true,
            'video_completed': !hasVideo,
            'completed_at': !hasVideo ? DateTime.now().toIso8601String() : null,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'class_id,material_id,student_id');
        } catch (upsertError) {
          debugPrint('material_progress direct upsert fallback error: $upsertError');
        }
      }

      // Also sync to global learning_progress if this material matches a core module
      try {
        final matRow = await _client
            .from('materials')
            .select('module_number')
            .eq('id', materialId)
            .maybeSingle();
        final modNum = (matRow?['module_number'] as num?)?.toInt();
        if (modNum != null) {
          final globalMap = await _client
              .from('materials')
              .select('id')
              .isFilter('class_id', null)
              .eq('module_number', modNum)
              .maybeSingle();
          final globalMatId = globalMap?['id']?.toString();
          if (globalMatId != null) {
            await _client.from('learning_progress').upsert({
              'user_id': _userId,
              'material_id': globalMatId,
              'reading_completed': true,
              'updated_at': DateTime.now().toIso8601String(),
            }, onConflict: 'user_id,material_id');
          }
        }
      } catch (_) {}
      return;
    }

    try {
      await _client.rpc(
        'mark_reading_completed',
        params: {
          'p_material': materialId,
        },
      );
    } catch (e) {
      debugPrint('mark_reading_completed RPC failed, attempting direct upsert: $e');
      try {
        await _client.from('learning_progress').upsert({
          'user_id': _userId,
          'material_id': materialId,
          'reading_completed': true,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,material_id');
      } catch (upsertErr) {
        debugPrint('learning_progress direct upsert fallback error: $upsertErr');
      }
    }
  }

  // ============================================================
  // VIDEO
  // ============================================================

  Future<void> markVideoCompleted(
    String materialId, {
    String? classId,
  }) async {
    String? effectiveClassId = classId;
    if (effectiveClassId == null ||
        effectiveClassId.isEmpty ||
        effectiveClassId == '__legacy_fallback_class__') {
      try {
        final matRow = await _client
            .from('materials')
            .select('class_id')
            .eq('id', materialId)
            .maybeSingle();
        effectiveClassId = matRow?['class_id']?.toString();
      } catch (_) {}
    }

    final hasClass = effectiveClassId != null &&
        effectiveClassId.isNotEmpty &&
        effectiveClassId != '__legacy_fallback_class__';

    if (hasClass) {
      try {
        await _client.rpc(
          'mark_class_video_completed',
          params: {
            'p_class': effectiveClassId,
            'p_material': materialId,
          },
        );
      } catch (e) {
        debugPrint('mark_class_video_completed RPC failed, attempting direct upsert: $e');
        try {
          final matInfo = await _client
              .from('materials')
              .select('content_version')
              .eq('id', materialId)
              .maybeSingle();
          final version = (matInfo?['content_version'] as num?)?.toInt() ?? 1;

          final existing = await _client
              .from('material_progress')
              .select('reading_completed')
              .eq('class_id', effectiveClassId)
              .eq('material_id', materialId)
              .eq('student_id', _userId)
              .maybeSingle();
          final readDone = existing?['reading_completed'] == true;

          await _client.from('material_progress').upsert({
            'class_id': effectiveClassId,
            'material_id': materialId,
            'student_id': _userId,
            'content_version': version,
            'video_completed': true,
            'completed_at': readDone ? DateTime.now().toIso8601String() : null,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'class_id,material_id,student_id');
        } catch (upsertError) {
          debugPrint('material_progress direct video upsert error: $upsertError');
        }
      }

      // Also sync to global learning_progress
      try {
        final matRow = await _client
            .from('materials')
            .select('module_number')
            .eq('id', materialId)
            .maybeSingle();
        final modNum = (matRow?['module_number'] as num?)?.toInt();
        if (modNum != null) {
          final globalMap = await _client
              .from('materials')
              .select('id')
              .isFilter('class_id', null)
              .eq('module_number', modNum)
              .maybeSingle();
          final globalMatId = globalMap?['id']?.toString();
          if (globalMatId != null) {
            await _client.from('learning_progress').upsert({
              'user_id': _userId,
              'material_id': globalMatId,
              'video_completed': true,
              'updated_at': DateTime.now().toIso8601String(),
            }, onConflict: 'user_id,material_id');
          }
        }
      } catch (_) {}
      return;
    }

    try {
      await _client.rpc(
        'mark_video_completed',
        params: {
          'p_material': materialId,
        },
      );
    } catch (e) {
      debugPrint('mark_video_completed RPC failed, attempting direct upsert: $e');
      try {
        await _client.from('learning_progress').upsert({
          'user_id': _userId,
          'material_id': materialId,
          'video_completed': true,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,material_id');
      } catch (upsertErr) {
        debugPrint('learning_progress direct video upsert error: $upsertErr');
      }
    }
  }

  // ============================================================
  // MATERIAL UNLOCK
  // ============================================================

  Future<bool> isMaterialUnlocked(
    String materialId,
  ) async {
    final matRow = await _client
        .from('materials')
        .select('class_id')
        .eq('id', materialId)
        .maybeSingle();
    final classId = matRow?['class_id']?.toString();

    if (classId != null && classId.isNotEmpty) {
      final response = await _client.rpc(
        'is_class_material_unlocked',
        params: {
          'p_class': classId,
          'p_material': materialId,
        },
      );
      return response == true;
    }

    final response = await _client.rpc(
      'is_material_unlocked',
      params: {
        'p_material': materialId,
      },
    );

    return response == true;
  }
}
