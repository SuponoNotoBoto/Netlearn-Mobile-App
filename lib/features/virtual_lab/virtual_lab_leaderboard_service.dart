import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/avatar/nl_avatar_models.dart';
import '../../core/supabase/supabase_client.dart';
import 'virtual_lab_leaderboard_models.dart';
import 'virtual_lab_mission.dart';

class VirtualLabLeaderboardService {
  static String _storageKey(String? classId) =>
      'vlab_leaderboard_scores_v1_${classId != null && classId.isNotEmpty ? classId : "global"}';

  /// Menormalkan identifier misi/preset ke salah satu tab resmi leaderboard
  /// (`overall`, `p2p`, `star`, `dual_subnet`, `dhcp_server`).
  static String normalizeMissionKey(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v.isEmpty || v == 'overall' || v == 'custom') return 'overall';
    if (v.contains('p2p')) return 'p2p';
    if (v.contains('star')) return 'star';
    if (v.contains('dual_subnet') ||
        v.contains('routing') ||
        v.contains('gateway')) {
      return 'dual_subnet';
    }
    if (v.contains('dhcp') || v.contains('server')) return 'dhcp_server';
    return 'overall';
  }

  /// Menggabungkan dua daftar skor sambil mempertahankan entri skor tertinggi
  /// per kombinasi `(studentId, materialKey)`.
  static List<VirtualLabScore> mergeScoreLists(
    Iterable<VirtualLabScore> primary,
    Iterable<VirtualLabScore> secondary,
  ) {
    final Map<String, VirtualLabScore> merged = {};

    void absorb(VirtualLabScore item) {
      final matKey = item.materialId.isNotEmpty
          ? item.materialId.toLowerCase()
          : item.preset.toLowerCase();
      final key = '${item.studentId}::$matKey';
      final existing = merged[key];
      if (existing == null ||
          item.score > existing.score ||
          (item.score == existing.score &&
              item.completedTasks > existing.completedTasks) ||
          (item.score == existing.score &&
              item.completedTasks == existing.completedTasks &&
              item.date.isAfter(existing.date))) {
        merged[key] = item;
      }
    }

    for (final s in primary) {
      absorb(s);
    }
    for (final s in secondary) {
      absorb(s);
    }

    final result = merged.values.toList();
    result.sort((a, b) {
      final cmpScore = b.score.compareTo(a.score);
      if (cmpScore != 0) return cmpScore;
      final cmpTasks = b.completedTasks.compareTo(a.completedTasks);
      if (cmpTasks != 0) return cmpTasks;
      return a.date.compareTo(b.date);
    });
    return result;
  }

  /// Menyinkronkan riwayat pengumpulan lokal/canvas milik user aktif ke cache
  /// leaderboard jika belum tercatat atau memiliki skor lebih tinggi.
  static Future<void> syncSubmissions({
    required Map<String, VirtualLabMissionSubmission> submissions,
    String? classId,
    required String studentName,
  }) async {
    if (submissions.isEmpty) return;
    for (final sub in submissions.values) {
      await saveScore(
        classId: classId,
        studentId: sub.userId,
        studentName: studentName,
        materialId: sub.materialId,
        materialTitle: sub.materialTitle,
        preset: sub.preset,
        score: sub.score,
        completedTasks: sub.completedTaskIds.length,
        totalTasks: sub.totalTasks,
        isPassed: sub.isPassed,
      );
    }
  }

  /// Menyimpan hasil skor misi praktikum mahasiswa ke cache lokal & sinkronisasi cloud.
  static Future<void> saveScore({
    String? classId,
    required String studentId,
    required String studentName,
    required String materialId,
    required String materialTitle,
    required String preset,
    required int score,
    required int completedTasks,
    required int totalTasks,
    required bool isPassed,
    AvatarConfig? avatarConfig,
  }) async {
    final cleanName = studentName.trim().isEmpty ? 'Mahasiswa' : studentName.trim();
    try {
      final prefs = await SharedPreferences.getInstance();

      final targetKeys = <String>{
        _storageKey(classId),
        _storageKey(null),
      };

      for (final key in targetKeys) {
        final raw = prefs.getString(key);
        final list = <VirtualLabScore>[];
        if (raw != null && raw.isNotEmpty) {
          try {
            final List decoded = jsonDecode(raw) as List;
            list.addAll(decoded.map((item) =>
                VirtualLabScore.fromMap(Map<String, dynamic>.from(item))));
          } catch (_) {}
        }

        // Cari apakah mahasiswa sudah pernah mengumpulkan praktikum untuk materi/preset ini
        final existingIndex = list.indexWhere((e) =>
            e.studentId == studentId &&
            (e.materialId == materialId || (e.preset == preset && preset.isNotEmpty)));

        final now = DateTime.now();
        final newEntry = VirtualLabScore(
          id: existingIndex >= 0 ? list[existingIndex].id : 'vlab_${now.millisecondsSinceEpoch}',
          studentId: studentId,
          studentName: cleanName,
          classId: classId,
          materialId: materialId,
          materialTitle: materialTitle,
          preset: preset,
          score: score,
          completedTasks: completedTasks,
          totalTasks: totalTasks,
          isPassed: isPassed,
          date: now,
          avatarConfig: avatarConfig ?? (existingIndex >= 0 ? list[existingIndex].avatarConfig : null),
        );

        if (existingIndex >= 0) {
          final existing = list[existingIndex];
          // Update jika skor baru lebih tinggi atau menyempurnakan tugas
          if (score > existing.score || (score == existing.score && completedTasks >= existing.completedTasks)) {
            list[existingIndex] = newEntry;
          } else if (cleanName != existing.studentName) {
            list[existingIndex] = VirtualLabScore(
              id: existing.id,
              studentId: existing.studentId,
              studentName: cleanName,
              classId: existing.classId,
              materialId: existing.materialId,
              materialTitle: existing.materialTitle,
              preset: existing.preset,
              score: existing.score,
              completedTasks: existing.completedTasks,
              totalTasks: existing.totalTasks,
              isPassed: existing.isPassed,
              date: existing.date,
              avatarConfig: existing.avatarConfig,
            );
          }
        } else {
          list.add(newEntry);
        }

        await prefs.setString(key, jsonEncode(list.map((e) => e.toMap()).toList()));
      }

      // Best-effort remote sync ke Supabase
      try {
        final user = supabase.auth.currentUser;
        if (user != null) {
          final isRealUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(studentId);
          final validUid = isRealUuid ? studentId : user.id;

          AvatarConfig? myAvatar = avatarConfig ??
              AvatarConfig.fromDynamic(
                prefs.getString('cached_avatar_config_$validUid'),
              );
          if (myAvatar == null) {
            try {
              final prof = await supabase
                  .from('profiles')
                  .select('avatar_config')
                  .eq('id', validUid)
                  .maybeSingle();
              myAvatar = AvatarConfig.fromDynamic(prof?['avatar_config']);
            } catch (_) {}
          }

          // Upsert ke virtual_lab_scores dengan fallback bertingkat bila kolom
          // opsional atau constraint ON CONFLICT belum tersedia di remote.
          await _syncScoreToRemote(
            userId: validUid,
            studentName: cleanName,
            materialId: materialId,
            materialTitle: materialTitle,
            preset: preset,
            score: score,
            completedTasks: completedTasks,
            totalTasks: totalTasks,
            isPassed: isPassed,
            classId: classId,
            avatarConfig: myAvatar,
          );
        }
      } catch (e) {
        debugPrint('VirtualLabLeaderboardService sync remote warning: $e');
      }
    } catch (_) {}
  }

  static Future<void> _syncScoreToRemote({
    required String userId,
    required String studentName,
    required String materialId,
    required String materialTitle,
    required String preset,
    required int score,
    required int completedTasks,
    required int totalTasks,
    required bool isPassed,
    String? classId,
    AvatarConfig? avatarConfig,
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      'student_name': studentName,
      'material_id': materialId,
      'material_title': materialTitle,
      'preset': preset,
      'score': score,
      'completed_tasks': completedTasks,
      'total_tasks': totalTasks,
      'is_passed': isPassed,
      if (classId != null && classId.isNotEmpty) 'class_id': classId,
      if (avatarConfig != null) 'avatar_config': avatarConfig.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    const optionalCols = [
      'avatar_config',
      'class_id',
      'completed_tasks',
      'total_tasks',
      'is_passed',
      'preset',
      'material_title',
    ];

    for (var i = 0; i <= optionalCols.length; i++) {
      try {
        await supabase
            .from('virtual_lab_scores')
            .upsert(payload, onConflict: 'user_id, material_id');
        return;
      } on PostgrestException catch (e) {
        final msg = e.message.toLowerCase();
        // Tidak ada unique constraint (user_id, material_id) -> select + update/insert.
        if (e.code == '42P10' || msg.contains('on conflict')) {
          try {
            final existing = await supabase
                .from('virtual_lab_scores')
                .select('id, score')
                .eq('user_id', userId)
                .eq('material_id', materialId)
                .maybeSingle();
            if (existing != null) {
              final prevScore = (existing['score'] as num?)?.toInt() ?? 0;
              if (score >= prevScore) {
                await supabase
                    .from('virtual_lab_scores')
                    .update(payload)
                    .eq('id', existing['id'].toString());
              }
            } else {
              await supabase.from('virtual_lab_scores').insert(payload);
            }
            return;
          } catch (_) {
            return;
          }
        }

        final isColError = e.code == '42703' ||
            e.code == 'PGRST204' ||
            msg.contains('column');
        if (isColError) {
          String? toDrop;
          for (final col in optionalCols) {
            if (payload.containsKey(col) && msg.contains(col)) {
              toDrop = col;
              break;
            }
          }
          toDrop ??= optionalCols.firstWhere(
            (c) => payload.containsKey(c),
            orElse: () => '',
          );
          if (toDrop.isNotEmpty) {
            payload.remove(toDrop);
            continue;
          }
        }
        return;
      } catch (_) {
        return;
      }
    }
  }

  /// Membaca seluruh skor dari penyimpanan lokal & cloud lalu menggabungkannya
  /// agar skor terbaru selalu tampil meski sinkronisasi remote tertunda.
  static Future<List<VirtualLabScore>> getAllScores({String? classId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final effectiveClassId =
          (classId != null && classId.isNotEmpty) ? classId : null;

      // 1. Baca dari SharedPreferences terlebih dahulu (scoped + global fallback)
      final localScores = <VirtualLabScore>[];
      void loadPrefsKey(String key, {required bool filterByClass}) {
        final raw = prefs.getString(key);
        if (raw == null || raw.isEmpty) return;
        try {
          final List decoded = jsonDecode(raw) as List;
          for (final item in decoded) {
            final parsed =
                VirtualLabScore.fromMap(Map<String, dynamic>.from(item as Map));
            if (filterByClass && effectiveClassId != null) {
              if (parsed.classId != null &&
                  parsed.classId!.isNotEmpty &&
                  parsed.classId != effectiveClassId) {
                continue;
              }
            }
            localScores.add(parsed);
          }
        } catch (_) {}
      }

      loadPrefsKey(_storageKey(effectiveClassId), filterByClass: false);
      if (effectiveClassId != null) {
        loadPrefsKey(_storageKey(null), filterByClass: true);
      }

      // 2. Baca dari remote Supabase jika tersedia dan gabungkan
      List<VirtualLabScore> remoteScores = const [];
      try {
        var query = supabase.from('virtual_lab_scores').select();
        if (effectiveClassId != null) {
          query = query.eq('class_id', effectiveClassId);
        }
        final remoteRows = await query.order('score', ascending: false);
        remoteScores = (remoteRows as List).map((item) {
          return VirtualLabScore.fromMap(
            Map<String, dynamic>.from(item as Map),
          );
        }).toList();
      } catch (_) {}

      final merged = mergeScoreLists(remoteScores, localScores);
      if (merged.isNotEmpty) {
        final key = _storageKey(effectiveClassId);
        await prefs.setString(
          key,
          jsonEncode(merged.map((e) => e.toMap()).toList()),
        );
      }
      return merged;
    } catch (_) {}
    return const [];
  }

  /// Menghitung akumulasi performa keseluruhan praktikum per mahasiswa.
  static Future<List<VirtualLabOverallScore>> getOverallScores({String? classId}) async {
    final allScores = await getAllScores(classId: classId);
    if (allScores.isEmpty) return const [];

    // Kelompokkan per studentId
    final Map<String, List<VirtualLabScore>> studentMap = {};
    for (final s in allScores) {
      studentMap.putIfAbsent(s.studentId, () => []).add(s);
    }

    final overallList = <VirtualLabOverallScore>[];

    studentMap.forEach((studentId, scores) {
      if (scores.isEmpty) return;
      final studentName = scores.first.studentName;
      final avatar = scores.first.avatarConfig;

      // Ambil skor terbaik untuk tiap material unik
      final Map<String, VirtualLabScore> bestPerMaterial = {};
      for (final sc in scores) {
        final matKey = sc.materialId.isNotEmpty ? sc.materialId : sc.preset;
        final existing = bestPerMaterial[matKey];
        if (existing == null || sc.score > existing.score) {
          bestPerMaterial[matKey] = sc;
        }
      }

      int totalScore = 0;
      int completedMissions = 0;
      DateTime latestDate = scores.first.date;

      for (final s in bestPerMaterial.values) {
        totalScore += s.score;
        if (s.score > 0) completedMissions++;
        if (s.date.isAfter(latestDate)) latestDate = s.date;
      }

      final avg = completedMissions > 0 ? (totalScore / completedMissions) : 0.0;

      overallList.add(VirtualLabOverallScore(
        studentId: studentId,
        studentName: studentName,
        classId: classId,
        totalScore: totalScore,
        averageScore: avg,
        completedMissions: completedMissions,
        totalAvailableMissions: 4,
        lastSubmittedAt: latestDate,
        avatarConfig: avatar,
      ));
    });

    // Urutkan peringkat keseluruhan:
    // 1. Total score tertinggi
    // 2. Misi selesai terbanyak
    // 3. Tanggal pengumpulan lebih awal
    overallList.sort((a, b) {
      final cmpTotal = b.totalScore.compareTo(a.totalScore);
      if (cmpTotal != 0) return cmpTotal;
      final cmpCount = b.completedMissions.compareTo(a.completedMissions);
      if (cmpCount != 0) return cmpCount;
      return a.lastSubmittedAt.compareTo(b.lastSubmittedAt);
    });

    return overallList;
  }

  /// Membaca skor peringkat khusus untuk satu misi praktikum tertentu.
  static Future<List<VirtualLabScore>> getScoresByMission({
    required String missionKey,
    String? classId,
  }) async {
    final allScores = await getAllScores(classId: classId);
    if (allScores.isEmpty) return const [];

    final normalizedKey = normalizeMissionKey(missionKey);
    if (normalizedKey == 'overall') {
      return allScores;
    }

    // Filter skor yang cocok dengan materialId atau preset
    final filtered = allScores.where((s) {
      final matId = s.materialId.toLowerCase();
      final preset = s.preset.toLowerCase();
      return matId.contains(normalizedKey) ||
          preset.contains(normalizedKey) ||
          (preset.isNotEmpty && normalizedKey.contains(preset));
    }).toList();

    // Pastikan per mahasiswa hanya muncul skor tertingginya pada misi ini
    final Map<String, VirtualLabScore> bestPerStudent = {};
    for (final s in filtered) {
      final existing = bestPerStudent[s.studentId];
      if (existing == null ||
          s.score > existing.score ||
          (s.score == existing.score && s.completedTasks > existing.completedTasks)) {
        bestPerStudent[s.studentId] = s;
      }
    }

    final result = bestPerStudent.values.toList();
    result.sort((a, b) {
      final cmpScore = b.score.compareTo(a.score);
      if (cmpScore != 0) return cmpScore;
      final cmpTasks = b.completedTasks.compareTo(a.completedTasks);
      if (cmpTasks != 0) return cmpTasks;
      return a.date.compareTo(b.date);
    });

    return result;
  }
}
