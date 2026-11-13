import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/supabase/supabase_client.dart';
import '../classes/class_controller.dart';

/// Catatan notifikasi semangat / cheer yang diterima seorang mahasiswa.
@immutable
class CheerNotificationItem {
  final String id;
  final String senderId;
  final String senderName;
  final String? classId;
  final String? className;
  final DateTime createdAt;

  const CheerNotificationItem({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.classId,
    this.className,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'sender_id': senderId,
        'sender_name': senderName,
        'class_id': classId,
        'class_name': className,
        'created_at': createdAt.toIso8601String(),
      };

  factory CheerNotificationItem.fromMap(Map<String, dynamic> map) {
    return CheerNotificationItem(
      id: map['id']?.toString() ?? '',
      senderId: map['sender_id']?.toString() ?? '',
      senderName: map['sender_name']?.toString() ?? 'Teman Sekelas',
      classId: map['class_id']?.toString(),
      className: map['class_name']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Layanan untuk mencatat dan menyajikan notifikasi semangat (cheer) antar mahasiswa.
class CheerNotificationService {
  static String _storageKey(String receiverId, [String? classId]) =>
      classId != null && classId.isNotEmpty
          ? 'v2_received_cheers_${receiverId}_$classId'
          : 'v2_received_cheers_$receiverId';

  /// Mencatat saat seorang user mengirim semangat ke [receiverId].
  static Future<void> recordCheer({
    required String receiverId,
    String? classId,
  }) async {
    final sender = supabase.auth.currentUser;
    if (sender == null || receiverId.isEmpty || receiverId == sender.id) return;

    String senderName = 'Teman Sekelas';
    try {
      final profile = await supabase
          .from('profiles')
          .select('name')
          .eq('id', sender.id)
          .maybeSingle();
      final pName = profile?['name']?.toString().trim();
      if (pName != null && pName.isNotEmpty) {
        senderName = pName;
      }
    } catch (_) {}

    String? className;
    if (classId != null && classId.isNotEmpty) {
      try {
        final c = await supabase
            .from('classes')
            .select('name')
            .eq('id', classId)
            .maybeSingle();
        className = c?['name']?.toString().trim();
      } catch (_) {}
    }

    final now = DateTime.now();
    final item = CheerNotificationItem(
      id: 'cheer_${now.millisecondsSinceEpoch}_${sender.id.hashCode}',
      senderId: sender.id,
      senderName: senderName,
      classId: classId,
      className: className,
      createdAt: now,
    );

    // 1. Simpan di SharedPreferences penerima (cache lokal/instan), baik per-kelas maupun global
    try {
      final prefs = await SharedPreferences.getInstance();
      final keysToUpdate = [
        _storageKey(receiverId),
        if (classId != null && classId.isNotEmpty)
          _storageKey(receiverId, classId),
      ];

      for (final key in keysToUpdate) {
        final raw = prefs.getString(key);
        final list = <CheerNotificationItem>[item];
        if (raw != null && raw.isNotEmpty) {
          try {
            final List decoded = jsonDecode(raw) as List;
            list.addAll(decoded.map((m) => CheerNotificationItem.fromMap(
                Map<String, dynamic>.from(m as Map))));
          } catch (_) {}
        }
        await prefs.setString(
          key,
          jsonEncode(list.take(30).map((e) => e.toMap()).toList()),
        );
      }
    } catch (_) {}

    // 2. Mirror ke Supabase tabel profile_cheers (dengan fallback toleransi skema)
    final basePayload = <String, dynamic>{
      'sender_id': sender.id,
      'receiver_id': receiverId,
      'created_at': now.toIso8601String(),
    };
    if (classId != null && classId.isNotEmpty) {
      basePayload['class_id'] = classId;
    }

    try {
      // Coba insert dengan sender_name
      await supabase.from('profile_cheers').insert({
        ...basePayload,
        'sender_name': senderName,
      });
    } catch (_) {
      try {
        // Fallback jika skema profile_cheers tidak memiliki kolom sender_name
        await supabase.from('profile_cheers').insert(basePayload);
      } catch (err) {
        debugPrint('profile_cheers insert note: $err');
      }
    }
  }

  /// Membaca daftar semangat yang diterima oleh user aktif.
  static Future<List<CheerNotificationItem>> getReceivedCheers(
    String receiverId, {
    String? classId,
  }) async {
    final result = <CheerNotificationItem>[];

    // 1. Coba baca dari Supabase jika tabel profile_cheers tersedia
    try {
      var query = supabase
          .from('profile_cheers')
          .select()
          .eq('receiver_id', receiverId);
      if (classId != null && classId.isNotEmpty) {
        query = query.eq('class_id', classId);
      }
      final rows = await query.order('created_at', ascending: false).limit(35);
      if ((rows as List).isNotEmpty) {
        final missingSenderNameIds = <String>{};
        for (final r in rows) {
          final m = Map<String, dynamic>.from(r as Map);
          final sName = m['sender_name']?.toString().trim();
          if (sName == null || sName.isEmpty) {
            final sId = m['sender_id']?.toString();
            if (sId != null && sId.isNotEmpty) {
              missingSenderNameIds.add(sId);
            }
          }
        }

        final senderNamesMap = <String, String>{};
        if (missingSenderNameIds.isNotEmpty) {
          try {
            final pRows = await supabase
                .from('profiles')
                .select('id, name')
                .filter('id', 'in', missingSenderNameIds.toList());
            for (final pr in pRows as List) {
              final pm = Map<String, dynamic>.from(pr as Map);
              senderNamesMap[pm['id'].toString()] =
                  pm['name']?.toString().trim() ?? 'Teman Sekelas';
            }
          } catch (_) {}
        }

        for (final r in rows) {
          final m = Map<String, dynamic>.from(r as Map);
          if (m['sender_name'] == null || m['sender_name'].toString().trim().isEmpty) {
            final sId = m['sender_id']?.toString() ?? '';
            m['sender_name'] = senderNamesMap[sId] ?? 'Teman Sekelas';
          }
          result.add(CheerNotificationItem.fromMap(m));
        }
        return result;
      }
    } catch (e) {
      debugPrint('getReceivedCheers Supabase notice: $e');
    }

    // 2. Fallback baca dari SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = (classId != null && classId.isNotEmpty)
          ? _storageKey(receiverId, classId)
          : _storageKey(receiverId);

      var raw = prefs.getString(key);
      if ((raw == null || raw.isEmpty) && classId != null && classId.isNotEmpty) {
        raw = prefs.getString(_storageKey(receiverId));
      }

      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw) as List;
        for (final m in decoded) {
          final parsed =
              CheerNotificationItem.fromMap(Map<String, dynamic>.from(m as Map));
          if (classId != null &&
              classId.isNotEmpty &&
              parsed.classId != null &&
              parsed.classId != classId) {
            continue;
          }
          result.add(parsed);
        }
      }
    } catch (_) {}

    return result;
  }
}

/// Status cheers yang diterima mahasiswa yang terikat pada kelas aktif.
class StudentClassCheersState {
  final int count;
  final List<CheerNotificationItem> history;
  final String? classId;
  final String? className;

  const StudentClassCheersState({
    required this.count,
    required this.history,
    this.classId,
    this.className,
  });
}

/// Provider reaktif untuk total dan riwayat semangat (cheers) mahasiswa per kelas aktif.
final studentClassCheersProvider = FutureProvider.autoDispose
    .family<StudentClassCheersState, String>((ref, userId) async {
  if (userId.isEmpty) {
    return const StudentClassCheersState(count: 0, history: []);
  }

  // Ambil kelas aktif saat ini
  final activeClassAsync = ref.watch(activeStudentClassProvider);
  final activeClass = activeClassAsync.value;
  final classId = (activeClass != null && !activeClass.isLegacyFallback)
      ? activeClass.id
      : ref.watch(activeStudentClassIdProvider);

  final validClassUuid = (classId != null &&
          RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(classId))
      ? classId
      : null;

  int dbCount = 0;
  // 1. Baca hitungan resmi cheers dari get_public_member_profile di kelas aktif
  try {
    final dynamic res = await supabase.rpc(
      'get_public_member_profile',
      params: {
        'p_user': userId,
        'p_class': validClassUuid,
      },
    );
    if (res is List && res.isNotEmpty) {
      final m = Map<String, dynamic>.from(res.first as Map);
      dbCount = (m['cheers_count'] as num?)?.toInt() ?? 0;
    } else if (res is Map) {
      dbCount = (res['cheers_count'] as num?)?.toInt() ?? 0;
    }
  } catch (e) {
    debugPrint('get_public_member_profile error in studentClassCheersProvider: $e');
  }

  // 2. Ambil riwayat detail pengirim cheers untuk kelas ini
  final history = await CheerNotificationService.getReceivedCheers(
    userId,
    classId: validClassUuid,
  );

  final finalCount = dbCount > history.length ? dbCount : history.length;

  return StudentClassCheersState(
    count: finalCount,
    history: history,
    classId: validClassUuid,
    className: activeClass?.name,
  );
});

/// Provider kompatibilitas lama
final studentReceivedCheersProvider =
    FutureProvider.family.autoDispose<List<CheerNotificationItem>, String>(
        (ref, userId) async {
  if (userId.isEmpty) return const [];
  return CheerNotificationService.getReceivedCheers(userId);
});


