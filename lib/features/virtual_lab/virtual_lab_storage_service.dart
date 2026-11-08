import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/supabase/supabase_client.dart';
import 'virtual_lab_export.dart';
import 'virtual_lab_model.dart';
import 'virtual_lab_repository.dart';
import 'virtual_lab_saved_topology.dart';

/// Layanan untuk mengelola penyimpanan skenario topologi kustom
/// (Multi-slot save/load) serta ekspor dan impor berkas JSON.
///
/// Menggunakan strategi sinkronisasi ganda (Hybrid Cloud & Local Cache):
/// 1. Cloud (Supabase): Data tersimpan permanen di akun pengguna sehingga tidak hilang
///    saat Chrome ditutup atau flutter run dimulai ulang.
/// 2. Local (SharedPreferences): Cache instan untuk akses cepat dan mode luring (offline).
class VirtualLabStorageService {
  final SharedPreferences? _prefs;
  final String? _customUserId;
  final VirtualLabRepository? _repository;

  const VirtualLabStorageService([
    this._prefs,
    this._customUserId,
    this._repository,
  ]);

  /// Mendapatkan user ID akun yang sedang aktif untuk mengisolasi data per akun.
  String get _currentUserId {
    if (_customUserId != null && _customUserId.isNotEmpty) {
      return _customUserId;
    }
    try {
      return supabase.auth.currentUser?.id ?? 'guest_default';
    } catch (_) {
      return 'guest_default';
    }
  }

  String get _storageKey => 'vlab_saved_topologies_$_currentUserId';

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// Mengambil semua topologi yang tersimpan untuk akun saat ini,
  /// menyinkronkan dengan Cloud Supabase jika tersedia, lalu mengurutkan
  /// berdasarkan waktu pembaruan terbaru.
  Future<List<VirtualLabSavedTopology>> getSavedTopologies() async {
    List<VirtualLabSavedTopology> localList = [];
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.trim().isNotEmpty) {
        localList = VirtualLabSavedTopology.decodeList(raw);
      }
    } catch (_) {}

    // Sinkronisasi dengan cloud Supabase jika pengguna sedang masuk (login)
    final userId = _currentUserId;
    if (userId != 'guest_default') {
      try {
        final repo = _repository ?? const VirtualLabRepository();
        final cloudRawList = await repo.loadSavedTopologies();
        if (cloudRawList.isNotEmpty) {
          final cloudList = cloudRawList
              .map((m) => VirtualLabSavedTopology.fromJson(m))
              .toList();

          // Merge local dan cloud berdasarkan ID (prioritaskan updatedAt terbaru)
          final map = <String, VirtualLabSavedTopology>{};
          for (final item in cloudList) {
            map[item.id] = item;
          }
          for (final item in localList) {
            final existing = map[item.id];
            if (existing == null || item.updatedAt.isAfter(existing.updatedAt)) {
              map[item.id] = item;
            }
          }

          final mergedList = map.values.toList();
          mergedList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          // Perbarui cache local jika ada data dari cloud
          final prefs = await _getPrefs();
          await prefs.setString(
              _storageKey, VirtualLabSavedTopology.encodeList(mergedList));

          // Jika lokal memiliki data yang belum tersimpan di cloud, sinkronkan balik
          if (mergedList.length > cloudList.length) {
            unawaited(repo.saveSavedTopologies(
              mergedList.map((t) => t.toJson()).toList(),
              forUserId: userId,
            ));
          }

          return mergedList;
        } else if (localList.isNotEmpty) {
          // Cloud masih kosong tetapi lokal ada data -> cadangkan lokal ke cloud
          final repo = _repository ?? const VirtualLabRepository();
          unawaited(repo.saveSavedTopologies(
            localList.map((t) => t.toJson()).toList(),
            forUserId: userId,
          ));
        }
      } catch (_) {
        // Fallback aman ke data lokal jika koneksi Supabase terputus atau mode tes
      }
    }

    localList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return localList;
  }

  /// Menyimpan topologi baru atau memperbarui topologi lama jika [existingId] disertakan.
  Future<VirtualLabSavedTopology> saveTopology({
    required String name,
    String? description,
    required VirtualLabSession session,
    String? existingId,
  }) async {
    final prefs = await _getPrefs();
    final list = (await getSavedTopologies()).toList();

    final now = DateTime.now();
    final id = existingId ?? 'topo_${now.millisecondsSinceEpoch}';

    final existingIdx = list.indexWhere((t) => t.id == id);
    DateTime createdAt = now;
    if (existingIdx >= 0) {
      createdAt = list[existingIdx].createdAt;
    }

    final entry = VirtualLabSavedTopology.fromSession(
      id: id,
      name: name.trim().isNotEmpty ? name.trim() : 'Topologi Tanpa Judul',
      description: description,
      session: session,
      createdAt: createdAt,
      updatedAt: now,
    );

    if (existingIdx >= 0) {
      list[existingIdx] = entry;
    } else {
      list.insert(0, entry);
    }

    // 1. Simpan ke cache lokal
    await prefs.setString(_storageKey, VirtualLabSavedTopology.encodeList(list));

    // 2. Simpan juga ke Supabase Cloud jika akun aktif
    final userId = _currentUserId;
    if (userId != 'guest_default') {
      try {
        final repo = _repository ?? const VirtualLabRepository();
        await repo.saveSavedTopologies(
          list.map((t) => t.toJson()).toList(),
          forUserId: userId,
        );
      } catch (_) {}
    }

    return entry;
  }

  /// Menghapus topologi berdasarkan [id].
  Future<bool> deleteTopology(String id) async {
    final prefs = await _getPrefs();
    final list = (await getSavedTopologies()).toList();
    final initialLen = list.length;
    list.removeWhere((t) => t.id == id);
    if (list.length == initialLen) return false;

    // 1. Perbarui cache lokal
    await prefs.setString(_storageKey, VirtualLabSavedTopology.encodeList(list));

    // 2. Sinkronkan penghapusan ke cloud Supabase
    final userId = _currentUserId;
    if (userId != 'guest_default') {
      try {
        final repo = _repository ?? const VirtualLabRepository();
        await repo.saveSavedTopologies(
          list.map((t) => t.toJson()).toList(),
          forUserId: userId,
        );
      } catch (_) {}
    }

    return true;
  }

  /// Mengekspor sesi topologi saat ini menjadi berkas fisik JSON di perangkat.
  Future<VirtualLabExportResult> exportTopologyToJsonFile({
    required VirtualLabSession session,
    required String name,
    String? description,
  }) async {
    final now = DateTime.now();
    final timeStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

    final safeName = name
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final fileName = 'NetLearn_Topology_${safeName}_$timeStr.json';

    final payload = {
      'format': 'NetLearn_VirtualLab',
      'version': 1,
      'name': name.trim().isNotEmpty ? name.trim() : 'Topologi NetLearn',
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      'exportedAt': now.toIso8601String(),
      'deviceCount': session.devices.length,
      'cableCount': session.cables.length,
      'session': session.toJson(),
    };

    final jsonContent = const JsonEncoder.withIndent('  ').convert(payload);
    return await saveTopologyJson(jsonContent, fileName);
  }

  /// Mem-parse dan memvalidasi konten teks JSON menjadi objek `VirtualLabSession`.
  ///
  /// Mampu membaca berkas ekspor NetLearn (`payload.session`),
  /// snapshot storage (`payload.sessionData`), maupun raw session (`payload.devices`).
  VirtualLabSession? parseTopologyJson(String rawJsonContent) {
    try {
      final decoded = jsonDecode(rawJsonContent);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);

      if (map['session'] is Map) {
        return VirtualLabSession.fromJson(
            Map<String, dynamic>.from(map['session'] as Map));
      }

      if (map['sessionData'] is Map) {
        return VirtualLabSession.fromJson(
            Map<String, dynamic>.from(map['sessionData'] as Map));
      }

      if (map['devices'] is List) {
        return VirtualLabSession.fromJson(map);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Membaca teks string dari file hasil pilihan pengguna (`PlatformFile`).
  Future<String?> readPickedFile(PlatformFile file) async {
    try {
      return await file.xFile.readAsString();
    } catch (_) {
      try {
        final bytes = await file.readAsBytes();
        return utf8.decode(bytes);
      } catch (_) {
        return null;
      }
    }
  }
}

final virtualLabStorageServiceProvider = Provider<VirtualLabStorageService>(
  (ref) {
    final repo = ref.watch(virtualLabRepositoryProvider);
    return VirtualLabStorageService(null, null, repo);
  },
);
