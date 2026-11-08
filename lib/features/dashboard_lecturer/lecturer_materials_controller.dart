import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../shared/models/material_model.dart';
import '../classes/class_controller.dart';
import '../classes/class_models.dart';
import '../materials/student_materials_controller.dart';
import 'lecturer_dashboard_controller.dart';

// ============================================================
// WRITE FAILURES
//
// The database rejects several material writes on its own, and the raw
// Postgres error means nothing to a lecturer. `materials_before_write` raises
// INVALID_VIDEO_URL for an unparseable YouTube link, and both
// `materials_before_write` and `materials_before_delete` raise
// CORE_MODULE_PROTECTED for the system modules. Those are translated into the
// cases below so the form can say what actually went wrong instead of printing
// "42501 permission denied".
// ============================================================

enum LecturerWriteFailure {
  coreProtected,
  invalidVideoUrl,
  notPermitted,
  unknown,
}

class LecturerWriteException implements Exception {
  final LecturerWriteFailure failure;

  /// The raw message, kept for the log. Never shown to the user: Postgres text
  /// leaks table and policy names.
  final String? detail;

  const LecturerWriteException(this.failure, [this.detail]);

  @override
  String toString() => 'LecturerWriteException($failure)';
}

LecturerWriteException mapLecturerWriteError(Object error) {
  if (error is! PostgrestException) {
    return LecturerWriteException(
      LecturerWriteFailure.unknown,
      error.toString(),
    );
  }

  final code = error.code ?? '';

  // `message` is non-nullable on PostgrestException, and the trigger messages
  // such as CORE_MODULE_PROTECTED arrive inside it.
  final message = error.message;

  if (message.contains('CORE_MODULE_PROTECTED')) {
    return LecturerWriteException(
      LecturerWriteFailure.coreProtected,
      message,
    );
  }

  if (message.contains('INVALID_VIDEO_URL') || code == '22023') {
    return LecturerWriteException(
      LecturerWriteFailure.invalidVideoUrl,
      message,
    );
  }

  // 42501 with no recognisable message is the generic RLS refusal, which for a
  // lecturer is almost always "no INSERT policy" or "not a lecturer".
  if (code == '42501') {
    return LecturerWriteException(
      LecturerWriteFailure.notPermitted,
      message,
    );
  }

  return LecturerWriteException(
    LecturerWriteFailure.unknown,
    message.isEmpty ? error.toString() : message,
  );
}

// ============================================================
// MATERIAL LIST
// ============================================================

/// Every material the lecturer can see, published or not.
///
/// Unlike the student list this does not filter on `published`: the lecturer is
/// the one who decides what is published, so a draft that is filtered out here
/// could never be published from the app. The RLS policy
/// (`materials_select` with `is_lecturer()`) is what keeps the two roles apart.
final lecturerMaterialsProvider =
    FutureProvider.autoDispose<List<MaterialModel>>((ref) async {
      final activeClass = await resolveActiveLecturerClass(ref);
      final validClass = activeClass != null &&
          activeClass.id.isNotEmpty &&
          activeClass.id != kLegacyFallbackClassId;
      final response = await supabase.from('materials').select('''
            class_id,
            id,
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
          ''')
          .order('module_number')
          .order('order_index')
          .order('id');

      final allRows = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final classRows = validClass
          ? allRows
              .where((r) => r['class_id']?.toString() == activeClass.id)
              .toList()
          : const <Map<String, dynamic>>[];
      final filteredRows = classRows.isNotEmpty
          ? classRows
          : allRows.where((r) => r['class_id'] == null).toList();
      return filteredRows
          .map(
            (item) => MaterialModel.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    });

/// Refreshes every view derived from the material table.
///
/// The write methods below call this instead of leaving it to the caller: the
/// dashboard counts, the list, and the form's own source row all read from the
/// same table, and invalidating only the screen that performed the write leaves
/// the others showing a figure that no longer exists.
void _invalidateMaterialReads(WidgetRef ref) {
  ref.invalidate(lecturerMaterialsProvider);
  ref.invalidate(lecturerDashboardStatsProvider);
  ref.invalidate(classModulesProvider);
  ref.invalidate(classModuleMaterialsProvider);
  ref.invalidate(studentMaterialsProvider);
  ref.invalidate(studentModulesProvider);
}

// ============================================================
// WRITES
// ============================================================

/// The columns a lecturer is allowed to write.
///
/// `MaterialModel.toMap()` cannot be reused here: it also carries `id`,
/// `created_at`, `updated_at`, `video_id`, `is_core`, `module_number` and
/// `created_by`. Sending `id` on an insert sends an empty string where the
/// column wants a uuid, and the row is rejected before RLS is even consulted.
/// `video_id` is derived from `video_url` by `materials_before_write`, so
/// writing it would just be overwritten.
///
/// `lock_status` TIDAK lagi dikecualikan (20261101130000): dosen memilihnya
/// lewat bagian "Akses materi" di form, dan server menegakkan nilainya di
/// `is_material_unlocked` / `get_learning_flow_status` /
/// `has_completed_all_modules`. Sebelum UI itu ada, kolom ini memang sengaja
/// tidak ditulis karena tidak ada sumber nilai manusia untuknya — alasan lama
/// itu sudah tidak berlaku.
Map<String, dynamic> _lecturerWritableColumns(
  MaterialModel material,
) {
  return {
    'title': material.title,
    'description': material.description,
    'content': material.content,
    'summary': material.summary,

    'title_en': material.titleEn,
    'title_id': material.titleId,
    'description_en': material.descriptionEn,
    'description_id': material.descriptionId,
    'content_en': material.contentEn,
    'content_id': material.contentId,
    'summary_en': material.summaryEn,
    'summary_id': material.summaryId,

    'video_url': material.videoUrl,
    'duration_minutes': material.durationMinutes,

    // Path of the uploaded PDF inside the `material-files` bucket. Null clears
    // the association. The object itself is uploaded separately (see
    // [uploadMaterialPdf]) because the path is decided before the row exists.
    'pdf_url': material.pdfUrl,

    'published': material.published,

    // Pilihan "Akses materi" di form (20261101130000 override). Tidak ada
    // trigger yang menolak/mengubahnya; yang mengonsumsinya adalah gate baca
    // `is_material_unlocked`, snapshot modul `get_learning_flow_status` dan
    // gerbang posttest `has_completed_all_modules`.
    'lock_status': material.lockStatus,
  };
}

// ============================================================
// PDF STORAGE
//
// The `material-files` bucket is private and its storage policies already exist
// remotely (see the material-files migration). The column `materials.pdf_url`
// stores the *object path* inside the bucket, not a public URL, so it stays
// valid when the object is replaced and can be turned into a time-limited
// signed URL only when a lecturer actually opens the file.
// ============================================================

const _materialPdfBucket = 'material-files';

const materialPdfMaxBytes = 20 * 1024 * 1024;

/// Uploads [bytes] as a PDF under the signed-in lecturer's folder and returns
/// the stored object path.
///
/// [upsert] is enabled so replacing a PDF at the same path cannot fail with a
/// duplicate-object error; the caller still names each upload uniquely so a
/// replace never overwrites the version another row might reference.
Future<String> uploadMaterialPdf(
  WidgetRef ref, {
  required Uint8List bytes,
  required String fileName,
}) async {
  final user = supabase.auth.currentUser;

  if (user == null) {
    throw const LecturerWriteException(LecturerWriteFailure.notPermitted);
  }

  final sanitized = fileName.replaceAll(
    RegExp(r'[^A-Za-z0-9._-]'),
    '_',
  );

  final path =
      '${user.id}/${DateTime.now().millisecondsSinceEpoch}_$sanitized';

  try {
    await supabase.storage.from(_materialPdfBucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ),
        );
  } catch (error) {
    throw LecturerWriteException(LecturerWriteFailure.unknown, error.toString());
  }

  return path;
}

/// Best-effort delete of a previously uploaded PDF.
///
/// Failure is swallowed: an orphaned object costs storage but must never block
/// the save that removed its reference, and the storage policy already scopes
/// deletion to lecturers.
Future<void> deleteMaterialPdf(WidgetRef ref, String path) async {
  try {
    await supabase.storage.from(_materialPdfBucket).remove([path]);
  } catch (_) {
    // Intentionally ignored — see doc comment.
  }
}

/// Time-limited signed URL for a stored PDF path.
Future<String> signedMaterialPdfUrl(
  WidgetRef ref,
  String path,
) {
  return supabase.storage
      .from(_materialPdfBucket)
      .createSignedUrl(path, 60 * 60);
}

/// Creates a material and returns its id.
///
/// The base `title` column is NOT NULL and holds the Indonesian copy, which is
/// what every reader falls back to when `title_id` is missing. Writing only the
/// bilingual columns would therefore produce a row that renders as an empty
/// title the first time the Indonesian text is cleared, so the base columns are
/// always filled from whichever language the lecturer supplied.
Future<String?> createMaterial(
  WidgetRef ref,
  MaterialModel draft,
) async {
  final user = supabase.auth.currentUser;

  if (user == null) {
    throw const LecturerWriteException(
      LecturerWriteFailure.notPermitted,
    );
  }

  try {
    final response = await supabase
        .from('materials')
        .insert({
          ..._lecturerWritableColumns(draft),

          'module_number': draft.moduleNumber,
          'order_index': draft.orderIndex,

          // The INSERT policy requires created_by = auth.uid(), so this is what
          // makes a lecturer-authored row distinguishable from a seeded one.
          'created_by': user.id,

          // A material created from the app is never a system module. Core
          // materials are protected by trigger on update and by policy on
          // delete, and must stay an admin/seed concern.
          'is_core': false,
        })
        .select('id')
        .single();

    _invalidateMaterialReads(ref);

    return response['id']?.toString();
  } catch (error) {
    throw mapLecturerWriteError(error);
  }
}

/// Updates an existing material.
///
/// `module_number` is only written for a material the lecturer owns. The trigger
/// `materials_before_write` rejects a change to `module_number` or `is_core` on a
/// core material, and re-sending the same value is still a write to that
/// protected column, so the field is dropped entirely for those rows. The form
/// disables the control to match, so the two agree on what is editable.
///
/// `order_index` is never protected by the trigger and stays writable for every
/// material, which is what lets a lecturer resequence the system modules without
/// being able to move them between modules.
Future<void> updateMaterial(
  WidgetRef ref,
  MaterialModel material,
) async {
  final columns = _lecturerWritableColumns(material);

  columns['order_index'] = material.orderIndex;

  if (!material.isCore) {
    columns['module_number'] = material.moduleNumber;
  }

  try {
    await supabase
        .from('materials')
        .update(columns)
        .eq('id', material.id);

    _invalidateMaterialReads(ref);
  } catch (error) {
    throw mapLecturerWriteError(error);
  }
}

/// Flips a material between published and draft.
///
/// Split from [updateMaterial] because it is the one write a lecturer performs
/// from the list, and because it must not drag the whole edited draft along: an
/// accidental reorder on the detail form should not be saved by tapping publish.
Future<void> setMaterialPublished(
  WidgetRef ref,
  String materialId,
  bool published,
) async {
  try {
    await supabase
        .from('materials')
        .update({'published': published})
        .eq('id', materialId);

    _invalidateMaterialReads(ref);
  } catch (error) {
    throw mapLecturerWriteError(error);
  }
}

/// Deletes a material.
///
/// Refuses core materials before the request is sent. The database refuses them
/// too -- `materials_delete` requires `not is_core` and
/// `materials_before_delete` raises CORE_MODULE_PROTECTED -- but letting the tap
/// through would produce an error dialog for an action the UI already knows is
/// not allowed.
Future<void> deleteMaterial(
  WidgetRef ref,
  MaterialModel material,
) async {
  if (material.isCore) {
    throw const LecturerWriteException(
      LecturerWriteFailure.coreProtected,
      'refused client-side: is_core',
    );
  }

  try {
    await supabase
        .from('materials')
        .delete()
        .eq('id', material.id);

    _invalidateMaterialReads(ref);
  } catch (error) {
    throw mapLecturerWriteError(error);
  }
}