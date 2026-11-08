import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/supabase/supabase_client.dart';
import 'virtual_lab_mission.dart';
import 'virtual_lab_repository.dart';

/// Layanan untuk mengelola penyimpanan & penilaian misi praktikum Virtual Lab.
///
/// Menerapkan strategi Hybrid Cloud & Local Cache:
/// 1. Cloud (Supabase): Data tersimpan di `virtual_lab_canvases.state['lab_submissions']`
///    sehingga nilai dan bukti praktikum mahasiswa tersimpan permanen dan dapat
///    diverifikasi oleh dosen.
/// 2. Local (SharedPreferences): Cache instan untuk performa cepat dan mode luring.
class VirtualLabMissionService {
  final SharedPreferences? _prefs;
  final String? _customUserId;
  final VirtualLabRepository? _repository;

  const VirtualLabMissionService([
    this._prefs,
    this._customUserId,
    this._repository,
  ]);

  String get currentUserId {
    if (_customUserId != null && _customUserId.isNotEmpty) {
      return _customUserId;
    }
    try {
      return supabase.auth.currentUser?.id ?? 'guest_default';
    } catch (_) {
      return 'guest_default';
    }
  }

  String get _storageKey => 'vlab_submissions_$currentUserId';

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// Membaca seluruh data pengumpulan misi praktikum akun saat ini.
  Future<Map<String, VirtualLabMissionSubmission>> getSubmissions() async {
    final result = <String, VirtualLabMissionSubmission>{};

    // 1. Baca cache lokal
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (value is Map) {
              result[key.toString()] = VirtualLabMissionSubmission.fromJson(
                Map<String, dynamic>.from(value),
              );
            }
          });
        }
      }
    } catch (_) {}

    // 2. Sinkronisasi dengan Cloud Supabase
    final userId = currentUserId;
    if (userId != 'guest_default') {
      try {
        final repo = _repository ?? const VirtualLabRepository();
        final cloudData = await repo.loadLabSubmissions();
        if (cloudData.isNotEmpty) {
          bool updatedFromCloud = false;
          cloudData.forEach((key, value) {
            if (value is Map) {
              final sub = VirtualLabMissionSubmission.fromJson(
                Map<String, dynamic>.from(value),
              );
              final existing = result[key];
              if (existing == null ||
                  sub.submittedAt.isAfter(existing.submittedAt)) {
                result[key] = sub;
                updatedFromCloud = true;
              }
            }
          });

          // Perbarui cache lokal jika data cloud lebih baru
          if (updatedFromCloud) {
            final prefs = await _getPrefs();
            final jsonMap = {
              for (final e in result.entries) e.key: e.value.toJson(),
            };
            await prefs.setString(_storageKey, jsonEncode(jsonMap));
          }

          // Jika ada entri lokal yang belum ada di cloud, sinkronkan balik
          if (result.length > cloudData.length) {
            unawaited(repo.saveLabSubmissions(
              {for (final e in result.entries) e.key: e.value.toJson()},
              forUserId: userId,
            ));
          }
        }
      } catch (_) {}
    }

    return result;
  }

  /// Membaca satu riwayat pengumpulan berdasarkan [materialId].
  Future<VirtualLabMissionSubmission?> getSubmission(String materialId) async {
    final all = await getSubmissions();
    return all[materialId];
  }

  /// Menyimpan hasil pengumpulan misi praktikum (Submission) baru.
  Future<void> saveSubmission(VirtualLabMissionSubmission submission) async {
    final all = await getSubmissions();
    final updated = Map<String, VirtualLabMissionSubmission>.from(all);
    updated[submission.materialId] = submission;

    // Simpan ke Cache Lokal
    final prefs = await _getPrefs();
    final jsonMap = {
      for (final e in updated.entries) e.key: e.value.toJson(),
    };
    await prefs.setString(_storageKey, jsonEncode(jsonMap));

    // Simpan ke Cloud Supabase
    final userId = currentUserId;
    if (userId != 'guest_default') {
      try {
        final repo = _repository ?? const VirtualLabRepository();
        await repo.saveLabSubmissions(jsonMap, forUserId: userId);
      } catch (_) {}
    }
  }
}

final virtualLabMissionServiceProvider = Provider<VirtualLabMissionService>(
  (ref) => const VirtualLabMissionService(),
);

/// Notifier untuk memantau status pengumpulan misi praktikum di seluruh aplikasi.
class LabSubmissionsNotifier
    extends Notifier<AsyncValue<Map<String, VirtualLabMissionSubmission>>> {
  @override
  AsyncValue<Map<String, VirtualLabMissionSubmission>> build() {
    _load();
    return const AsyncValue.loading();
  }

  Future<void> _load() async {
    final service = ref.read(virtualLabMissionServiceProvider);
    try {
      final data = await service.getSubmissions();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reload() => _load();

  Future<void> recordSubmission(VirtualLabMissionSubmission submission) async {
    final service = ref.read(virtualLabMissionServiceProvider);
    await service.saveSubmission(submission);
    final current = state.value ?? {};
    final updated = Map<String, VirtualLabMissionSubmission>.from(current);
    updated[submission.materialId] = submission;
    state = AsyncValue.data(updated);
  }
}

final labSubmissionsProvider = NotifierProvider<LabSubmissionsNotifier,
    AsyncValue<Map<String, VirtualLabMissionSubmission>>>(
  () => LabSubmissionsNotifier(),
);

