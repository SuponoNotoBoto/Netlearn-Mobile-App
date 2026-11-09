import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/avatar/nl_avatar_models.dart';
import '../../core/supabase/supabase_client.dart';
import 'virtual_lab_leaderboard_models.dart';

class VirtualLabLeaderboardService {
  static String _storageKey(String? classId) =>
      'vlab_leaderboard_scores_v1_${classId != null && classId.isNotEmpty ? classId : "global"}';

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

          // Upsert ke virtual_lab_scores jika tabel ada
          try {
            await supabase.from('virtual_lab_scores').upsert({
              'user_id': validUid,
              'student_name': cleanName,
              'material_id': materialId,
              'material_title': materialTitle,
              'preset': preset,
              'score': score,
              'completed_tasks': completedTasks,
              'total_tasks': totalTasks,
              'is_passed': isPassed,
              'class_id': classId,
              if (myAvatar != null) 'avatar_config': myAvatar.toMap(),
              'updated_at': DateTime.now().toIso8601String(),
            }, onConflict: 'user_id, material_id');
          } catch (_) {
            // Jika tabel virtual_lab_scores belum dimigrasi di remote, fallback aman
          }
        }
      } catch (e) {
        debugPrint('VirtualLabLeaderboardService sync remote warning: $e');
      }
    } catch (_) {}
  }

  /// Membaca seluruh skor mentah dari penyimpanan lokal/cloud.
  static Future<List<VirtualLabScore>> getAllScores({String? classId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Coba baca dari remote Supabase jika ada koneksi
      try {
        var query = supabase.from('virtual_lab_scores').select();
        if (classId != null && classId.isNotEmpty) {
          query = query.eq('class_id', classId);
        }
        final remoteRows = await query.order('score', ascending: false);
        if (remoteRows.isNotEmpty) {
          final remoteScores = remoteRows.map((item) {
            final m = Map<String, dynamic>.from(item as Map);
            return VirtualLabScore.fromMap(m);
          }).toList();

          final key = _storageKey(classId);
          await prefs.setString(
              key, jsonEncode(remoteScores.map((e) => e.toMap()).toList()));
          return remoteScores;
        }
      } catch (_) {}

      // 2. Baca dari SharedPreferences
      final key = _storageKey(classId);
      final raw = prefs.getString(key) ?? prefs.getString(_storageKey(null));
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw) as List;
        return decoded
            .map((item) =>
                VirtualLabScore.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
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

    final normalizedKey = missionKey.toLowerCase().replaceAll(' ', '_');

    // Filter skor yang cocok dengan materialId atau preset
    final filtered = allScores.where((s) {
      final matId = s.materialId.toLowerCase();
      final preset = s.preset.toLowerCase();
      return matId.contains(normalizedKey) ||
          preset.contains(normalizedKey) ||
          normalizedKey.contains(preset);
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
