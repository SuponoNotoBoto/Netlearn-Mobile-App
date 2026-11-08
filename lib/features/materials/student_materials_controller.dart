import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/language_controller.dart';
import '../../core/supabase/supabase_client.dart';
import '../../shared/models/learning_flow_status_model.dart';
import '../../shared/models/learning_progress_model.dart';
import '../../shared/models/material_model.dart';
import '../../shared/models/module_state_model.dart';
import '../../shared/services/student_service.dart';
import '../classes/class_controller.dart';
import '../classes/class_models.dart';
import 'material_cache_service.dart';

final studentServiceProvider = Provider<StudentService>((ref) {
  return StudentService.instance;
});

// ============================================================
// MATERIAL LIST
// ============================================================

final studentMaterialsProvider =
    FutureProvider.autoDispose<List<MaterialModel>>((ref) async {
      final service = ref.watch(studentServiceProvider);
      final activeClass = await resolveActiveStudentClass(ref);

      return service.getPublishedMaterials(classId: activeClass?.id);
    });

// ============================================================
// MATERIALS BY MODULE
// ============================================================

/// Semua materi published milik satu modul, dalam urutan baca
/// (`order_index`, `id`).
///
/// Dipakai bersama oleh halaman daftar materi per modul dan reader (bagian
/// "Mark All as Read"): keduanya harus membaca daftar yang sama, supaya itu
/// yang dijumlahkan progresnya sama dengan yang terlihat mahasiswa. Kalau
/// provider-nya diambil dari service di dua tempat berbeda, keduanya bisa
/// terlambat refetch pada waktu berbeda.
final moduleMaterialsProvider = FutureProvider.autoDispose
    .family<List<MaterialModel>, int>((ref, moduleNumber) async {
      final service = ref.watch(studentServiceProvider);
      final activeClass = await resolveActiveStudentClass(ref);

      return service.getMaterialsByModule(
        moduleNumber,
        classId: activeClass?.id,
      );
    });

// ============================================================
// LEARNING FLOW STATUS (PRETEST, MODULE 1-4, POSTTEST)
// ============================================================

final studentLearningFlowStatusProvider =
    FutureProvider.autoDispose<LearningFlowStatusModel>((ref) async {
      final service = ref.watch(studentServiceProvider);
      final activeClass = await resolveActiveStudentClass(ref);

      if (activeClass != null && !activeClass.isLegacyFallback) {
        try {
          final classFlow = await ref.read(
            classLearningFlowStatusProvider(activeClass.id).future,
          );
          if (classFlow != null) {
            final pretestOk =
                !classFlow.pretestEnabled || classFlow.pretestCompleted;
            final completedCount = classFlow.completedModules;
            return LearningFlowStatusModel(
              pretestCompleted: pretestOk,
              module1Completed: completedCount >= 1,
              module2Completed: completedCount >= 2,
              module3Completed: completedCount >= 3,
              module4Completed: classFlow.allModulesCompleted,
              posttestUnlocked: classFlow.posttestUnlocked,
              posttestCompleted: classFlow.posttestCompleted,
            );
          }
        } catch (_) {}
      }

      try {
        return await service.getLearningFlowStatus();
      } catch (_) {
        return const LearningFlowStatusModel(
          pretestCompleted: false,
          module1Completed: false,
          module2Completed: false,
          module3Completed: false,
          module4Completed: false,
          posttestUnlocked: false,
          posttestCompleted: false,
        );
      }
    });

final isMaterialUnlockedProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, materialId) async {
      final service = ref.watch(studentServiceProvider);

      return service.isMaterialUnlocked(materialId);
    });

// ============================================================
// MODULE STATES (LEGACY / COMPATIBILITY)
// ============================================================

final studentModuleStatesProvider =
    FutureProvider.autoDispose<List<ModuleStateModel>>((ref) async {
      final service = ref.watch(studentServiceProvider);

      return service.getModuleStates();
    });

// ============================================================
// ALL PROGRESS
// ============================================================

final studentLearningProgressProvider =
    FutureProvider.autoDispose<List<LearningProgressModel>>((ref) async {
      final service = ref.watch(studentServiceProvider);
      final activeClass = await resolveActiveStudentClass(ref);

      return service.getAllLearningProgress(classId: activeClass?.id);
    });

// ============================================================
// SINGLE MATERIAL
// ============================================================

final studentMaterialProvider = FutureProvider.autoDispose
    .family<MaterialModel?, String>((ref, materialId) async {
      final service = ref.watch(studentServiceProvider);

      try {
        final material = await service.getMaterialById(materialId);
        if (material != null) {
          unawaited(MaterialCacheService.cacheMaterial(material));
        }
        return material;
      } catch (error) {
        // Fallback to offline cache when network fails
        final cached = await MaterialCacheService.getCachedMaterial(materialId);
        if (cached != null) {
          return cached;
        }
        rethrow;
      }
    });

// ============================================================
// SINGLE MATERIAL PROGRESS
// ============================================================

final studentMaterialProgressProvider = FutureProvider.autoDispose
    .family<LearningProgressModel?, String>((ref, materialId) async {
      final service = ref.watch(studentServiceProvider);

      return service.getLearningProgress(materialId);
    });

// ============================================================
// SINGLE MODULE STATE
// ============================================================

final studentMaterialStateProvider = FutureProvider.autoDispose
    .family<ModuleStateModel?, String>((ref, materialId) async {
      final service = ref.watch(studentServiceProvider);

      return service.getModuleState(materialId);
    });

// ============================================================
// MODULE LIST (STUDENT VIEW)
//
// This lives here rather than in the page widget because the unlocked and
// completed flags baked into each StudentModule have to be invalidated from
// every place that changes progress: finishing a reading, finishing a video,
// and submitting the pretest. Keeping it in the page file meant nothing could
// reach it, so the list kept showing stale locks until it happened to be
// disposed and refetched.
// ============================================================

class StudentModule {
  final int moduleNumber;
  final String title;
  final String description;
  final int materialCount;
  final int durationMinutes;
  final bool unlocked;
  final bool completed;

  // True when this module is locked specifically because the pretest has not
  // been submitted yet. The pretest is the root gate for the whole course, so
  // when it is missing every module reports this, not just module 1.
  final bool blockedByPretest;
  final String? firstMaterialId;

  const StudentModule({
    required this.moduleNumber,
    required this.title,
    required this.description,
    required this.materialCount,
    required this.durationMinutes,
    required this.unlocked,
    required this.completed,
    required this.blockedByPretest,
    required this.firstMaterialId,
  });
}

final studentModulesProvider = FutureProvider.autoDispose<List<StudentModule>>((
  ref,
) async {
  final user = supabase.auth.currentUser;

  if (user == null) {
    return [];
  }

  final languageCode = ref.watch(languageProvider).languageCode;
  final studentService = ref.watch(studentServiceProvider);
  final activeClass = await resolveActiveStudentClass(ref);

  // get_learning_flow_status() only knows about the student learning path and
  // reports every module as locked for anyone who has not passed the pretest.
  // is_material_unlocked() already exempts admin and lecturer, so the list is
  // aligned with it here instead of showing non-students a wall of locks.
  final profileResponse = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .maybeSingle();

  final role = profileResponse is Map<String, dynamic>
      ? profileResponse['role']?.toString()
      : null;

  final bypassLearningFlow = role != null && role != 'student';

  if (activeClass != null && !activeClass.isLegacyFallback) {
    final classModRows = await supabase
        .from('class_modules')
        .select(
          'id, class_id, position, title, title_en, title_id, '
          'description, description_en, description_id, status, '
          'template_module_number',
        )
        .eq('class_id', activeClass.id)
        .eq('status', 'published')
        .order('position');

    final publishedClassModules = (classModRows as List)
        .map((r) => ClassModule.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();

    publishedClassModules.sort((a, b) {
      final numA = _resolveClassModuleNumber(a);
      final numB = _resolveClassModuleNumber(b);
      if (numA != numB) return numA.compareTo(numB);
      return a.position.compareTo(b.position);
    });

    if (publishedClassModules.isNotEmpty) {
      final matRows = await supabase
          .from('materials')
          .select(
            'id, module_id, module_number, title, title_en, title_id, '
            'description, description_en, description_id, '
            'duration_minutes, order_index, published, lock_status, video_id',
          )
          .eq('class_id', activeClass.id)
          .eq('published', true)
          .order('order_index')
          .order('id');

      final classMaterials = (matRows as List)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();

      final mpRows = await supabase
          .from('material_progress')
          .select('material_id, reading_completed, video_completed')
          .eq('class_id', activeClass.id)
          .eq('student_id', user.id);

      final mpByMatId = <String, Map<String, dynamic>>{
        for (final r in mpRows as List)
          (r as Map)['material_id'].toString(): Map<String, dynamic>.from(r),
      };

      final classFlow = await ref.watch(
        classLearningFlowStatusProvider(activeClass.id).future,
      );
      final pretestSatisfied = !(classFlow?.pretestEnabled ?? false) ||
          (classFlow?.pretestCompleted ?? false);

      return buildClassStudentModules(
        classModules: publishedClassModules,
        materials: classMaterials,
        materialProgressByMatId: mpByMatId,
        pretestSatisfied: pretestSatisfied,
        bypassLearningFlow: bypassLearningFlow,
        languageCode: languageCode,
      );
    }

    return const <StudentModule>[];
  }

  final materialsResponse = await supabase
      .from('materials')
      .select(
        'id, module_number, title, title_en, title_id, '
        'description, description_en, description_id, '
        'duration_minutes, order_index, published',
      )
      .eq('published', true)
      .isFilter('class_id', null)
      .order('module_number')
      .order('order_index');

  final flowStatus = await studentService.getLearningFlowStatus();

  return buildStudentModules(
    materials: List<Map<String, dynamic>>.from(materialsResponse),
    flowStatus: flowStatus,
    bypassLearningFlow: bypassLearningFlow,
    languageCode: languageCode,
  );
});

/// Turns raw material rows plus the learning flow snapshot into the module
/// cards the student list renders.
///
/// Split out from [studentModulesProvider] so the unlock rules can be tested
/// without a live Supabase session, which is where the "module 2 stays locked
/// after I finished module 1" bug lived.
List<StudentModule> buildStudentModules({
  required List<Map<String, dynamic>> materials,
  required LearningFlowStatusModel flowStatus,
  required bool bypassLearningFlow,
  required String languageCode,
}) {
  final Map<int, List<Map<String, dynamic>>> groupedMaterials = {};

  for (final material in materials) {
    final moduleNumber = _readInt(material['module_number']);

    if (moduleNumber == null) {
      continue;
    }

    groupedMaterials.putIfAbsent(moduleNumber, () => []);
    groupedMaterials[moduleNumber]!.add(material);
  }

  final modules = <StudentModule>[];

  for (final entry in groupedMaterials.entries) {
    final moduleNumber = entry.key;
    final moduleMaterials = entry.value;

    // Bypassing the gate only removes the lock. Completion still reflects what
    // the database actually records, so an admin or lecturer browsing the
    // course is not shown every module as already finished.
    final unlocked =
        bypassLearningFlow || flowStatus.isModuleUnlocked(moduleNumber);
    final completed = flowStatus.isModuleCompleted(moduleNumber);

    final firstMaterial = moduleMaterials.isEmpty
        ? null
        : moduleMaterials.first;

    final title = _localizedValue(
      languageCode,
      firstMaterial?['title_en'],
      firstMaterial?['title_id'],
      firstMaterial?['title'],
    );

    final description = _localizedValue(
      languageCode,
      firstMaterial?['description_en'],
      firstMaterial?['description_id'],
      firstMaterial?['description'],
    );

    final duration = moduleMaterials.fold<int>(0, (total, material) {
      return total + (_readInt(material['duration_minutes']) ?? 0);
    });

    modules.add(
      StudentModule(
        moduleNumber: moduleNumber,
        title: title.isEmpty ? 'Module $moduleNumber' : title,
        description: description,
        materialCount: moduleMaterials.length,
        durationMinutes: duration,
        unlocked: unlocked,
        completed: completed,
        // The pretest is the root gate for the whole course, so while it is
        // missing every module reports this rather than only module 1.
        blockedByPretest: !unlocked && !flowStatus.pretestCompleted,
        firstMaterialId: firstMaterial?['id']?.toString(),
      ),
    );
  }

  modules.sort((a, b) => a.moduleNumber.compareTo(b.moduleNumber));

  return modules;
}

String _localizedValue(
  String languageCode,
  dynamic english,
  dynamic indonesian,
  dynamic fallback,
) {
  final englishText = english?.toString().trim() ?? '';
  final indonesianText = indonesian?.toString().trim() ?? '';
  final fallbackText = fallback?.toString().trim() ?? '';

  if (languageCode == 'id') {
    if (indonesianText.isNotEmpty) {
      return indonesianText;
    }
    // The base column holds the Indonesian copy, so it is the correct fallback
    // here. Preferring _en before it meant that a module with no description_id
    // rendered its English description while the app was set to Indonesian.
    if (fallbackText.isNotEmpty) {
      return fallbackText;
    }
    return englishText;
  }

  if (englishText.isNotEmpty) {
    return englishText;
  }

  if (fallbackText.isNotEmpty) {
    return fallbackText;
  }

  return indonesianText;
}

int? _readInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

int resolveClassModuleNumber(ClassModule cm) => _resolveClassModuleNumber(cm);

int _resolveClassModuleNumber(ClassModule cm) {
  if (cm.templateModuleNumber != null && cm.templateModuleNumber! > 0) {
    return cm.templateModuleNumber!;
  }
  final match = RegExp(
    r'(?:modul|module)\s*(\d+)',
    caseSensitive: false,
  ).firstMatch('${cm.title} ${cm.titleEn ?? ''} ${cm.titleId ?? ''}');
  if (match != null) {
    final parsed = int.tryParse(match.group(1)!);
    if (parsed != null && parsed > 0) return parsed;
  }
  return cm.position > 0 ? cm.position : 1;
}

List<StudentModule> buildClassStudentModules({
  required List<ClassModule> classModules,
  required List<Map<String, dynamic>> materials,
  required Map<String, Map<String, dynamic>> materialProgressByMatId,
  required bool pretestSatisfied,
  required bool bypassLearningFlow,
  required String languageCode,
}) {
  final sortedModules = List<ClassModule>.from(classModules)
    ..sort((a, b) {
      final numA = _resolveClassModuleNumber(a);
      final numB = _resolveClassModuleNumber(b);
      if (numA != numB) return numA.compareTo(numB);
      return a.position.compareTo(b.position);
    });

  final result = <StudentModule>[];
  var allPriorCompleted = true;

  for (final cm in sortedModules) {
    final modNum = _resolveClassModuleNumber(cm);
    final modMats = materials
        .where(
          (m) =>
              m['module_id']?.toString() == cm.id ||
              _readInt(m['module_number']) == modNum ||
              _readInt(m['module_number']) == cm.position,
        )
        .toList();

    var modCompleted = modMats.isNotEmpty;
    for (final m in modMats) {
      final lock = m['lock_status']?.toString() ?? 'default';
      if (lock != 'default') continue;
      final mp = materialProgressByMatId[m['id'].toString()];
      final readDone = mp?['reading_completed'] == true;
      final hasVideo =
          m['video_id'] != null && m['video_id'].toString().isNotEmpty;
      final vidDone = !hasVideo || mp?['video_completed'] == true;
      if (!readDone || !vidDone) {
        modCompleted = false;
        break;
      }
    }

    final unlocked =
        bypassLearningFlow || (pretestSatisfied && allPriorCompleted);
    final firstMat = modMats.isEmpty ? null : modMats.first;

    final modTitle = cm.localizedTitle(languageCode).isNotEmpty
        ? cm.localizedTitle(languageCode)
        : _localizedValue(
            languageCode,
            firstMat?['title_en'],
            firstMat?['title_id'],
            firstMat?['title'],
          );

    final modDesc = cm.localizedDescription(languageCode).isNotEmpty
        ? cm.localizedDescription(languageCode)
        : _localizedValue(
            languageCode,
            firstMat?['description_en'],
            firstMat?['description_id'],
            firstMat?['description'],
          );

    final duration = modMats.fold<int>(0, (total, material) {
      return total + (_readInt(material['duration_minutes']) ?? 0);
    });

    result.add(
      StudentModule(
        moduleNumber: modNum,
        title: modTitle.isEmpty ? 'Module $modNum' : modTitle,
        description: modDesc,
        materialCount: modMats.length,
        durationMinutes: duration,
        unlocked: unlocked,
        completed: modCompleted,
        blockedByPretest: !unlocked && !pretestSatisfied,
        firstMaterialId: firstMat?['id']?.toString(),
      ),
    );

    allPriorCompleted = allPriorCompleted && modCompleted;
  }

  result.sort((a, b) => a.moduleNumber.compareTo(b.moduleNumber));
  return result;
}
