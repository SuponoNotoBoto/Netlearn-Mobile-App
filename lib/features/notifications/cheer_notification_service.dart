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
    final rawSenderName = map['sender_name']?.toString().trim() ?? '';
    return CheerNotificationItem(
      id: map['id']?.toString() ?? '',
      senderId: map['sender_id']?.toString() ?? '',
      senderName: rawSenderName.isNotEmpty ? rawSenderName : 'Mahasiswa',
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

  /// Mengembalikan `true` jika [name] kosong, label generik, atau fallback kode
  /// `Mahasiswa (...)` sehingga perlu dicari nama aslinya.
  static bool isGenericSenderName(String? name) {
    if (name == null) return true;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return true;
    final lower = trimmed.toLowerCase();
    return lower == 'teman sekelas' ||
        lower == 'mahasiswa' ||
        trimmed.startsWith('Mahasiswa (');
  }

  /// Mencari nama asli daftar [senderIds] secara berlapis:
  /// 1. Tabel `profiles` (`name`, `email`) — tanpa kolom non-eksisten `full_name`.
  /// 2. RPC `class_roster` pada kelas terkait.
  /// 3. RPC `get_public_member_profile` (bypass RLS jika query langsung dibatasi).
  static Future<Map<String, String>> _resolveSenderNames(
    Set<String> senderIds, {
    String? classId,
    Iterable<String> extraClassIds = const [],
  }) async {
    final names = <String, String>{};
    if (senderIds.isEmpty) return names;

    try {
      final pRows = await supabase
          .from('profiles')
          .select('id, name, email')
          .inFilter('id', senderIds.toList());
      for (final pr in pRows) {
        final pm = Map<String, dynamic>.from(pr as Map);
        final pId = pm['id']?.toString() ?? '';
        if (pId.isEmpty) continue;
        final n = pm['name']?.toString().trim();
        if (n != null && n.isNotEmpty) {
          names[pId] = n;
        } else {
          final email = pm['email']?.toString().trim();
          if (email != null && email.isNotEmpty) {
            names[pId] = email.split('@').first;
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to query profiles for sender names: $e');
    }

    // Fallback kedua: RPC class_roster jika masih ada ID yang belum ter-resolve.
    var stillMissing = senderIds
        .where((id) => !names.containsKey(id) || names[id]!.trim().isEmpty)
        .toList();
    if (stillMissing.isNotEmpty) {
      final candidateClassIds = <String>{
        if (classId != null && classId.isNotEmpty) classId,
        ...extraClassIds.where((c) => c.isNotEmpty),
      };
      for (final cId in candidateClassIds) {
        if (stillMissing.isEmpty) break;
        try {
          final roster =
              await supabase.rpc('class_roster', params: {'p_class': cId});
          if (roster is List) {
            for (final item in roster) {
              final map = Map<String, dynamic>.from(item as Map);
              final stId = map['student_id']?.toString();
              final stName = map['name']?.toString().trim();
              if (stId != null && stName != null && stName.isNotEmpty) {
                names[stId] = stName;
              }
            }
          }
        } catch (_) {}
        stillMissing = senderIds
            .where((id) => !names.containsKey(id) || names[id]!.trim().isEmpty)
            .toList();
      }
    }

    // Fallback ketiga: RPC get_public_member_profile per user yang masih kosong.
    if (stillMissing.isNotEmpty) {
      final validClassUuid = (classId != null &&
              RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(classId))
          ? classId
          : null;
      for (final sId in stillMissing) {
        try {
          final res = await supabase.rpc(
            'get_public_member_profile',
            params: {
              'p_user': sId,
              'p_class': validClassUuid,
            },
          );
          Map<String, dynamic>? row;
          if (res is List && res.isNotEmpty) {
            row = Map<String, dynamic>.from(res.first as Map);
          } else if (res is Map) {
            row = Map<String, dynamic>.from(res);
          }
          final disp =
              (row?['display_name'] ?? row?['name'])?.toString().trim();
          if (disp != null &&
              disp.isNotEmpty &&
              !isGenericSenderName(disp)) {
            names[sId] = disp;
          }
        } catch (_) {}
      }
    }

    return names;
  }

  /// Mencatat saat seorang user mengirim semangat ke [receiverId].
  static Future<void> recordCheer({
    required String receiverId,
    String? classId,
    String? senderName,
  }) async {
    final sender = supabase.auth.currentUser;
    if (sender == null || receiverId.isEmpty || receiverId == sender.id) return;

    String resolvedSenderName = senderName?.trim() ?? '';
    if (isGenericSenderName(resolvedSenderName)) {
      resolvedSenderName = '';
      try {
        final profile = await supabase
            .from('profiles')
            .select('name, email')
            .eq('id', sender.id)
            .maybeSingle();
        final pName = profile?['name']?.toString().trim();
        if (pName != null && pName.isNotEmpty) {
          resolvedSenderName = pName;
        } else {
          final meta = sender.userMetadata;
          final metaName = (meta?['name'] ??
                  meta?['full_name'] ??
                  meta?['display_name'])
              ?.toString()
              .trim();
          if (metaName != null && metaName.isNotEmpty) {
            resolvedSenderName = metaName;
          } else {
            final pEmail = profile?['email']?.toString().trim() ?? sender.email;
            if (pEmail != null && pEmail.isNotEmpty) {
              resolvedSenderName = pEmail.split('@').first;
            }
          }
        }
      } catch (_) {}
    }

    if (resolvedSenderName.isEmpty) {
      resolvedSenderName = 'Mahasiswa';
    }

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
      senderName: resolvedSenderName,
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
        'sender_name': resolvedSenderName,
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
        query = query.or('class_id.eq.$classId,class_id.is.null');
      }
      final dynamic rawRows = await query.order('created_at', ascending: false).limit(35);
      final List rows = (rawRows is List) ? rawRows : [];

      if (rows.isNotEmpty) {
        final missingSenderNameIds = <String>{};
        final extraClassIds = <String>{};
        for (final r in rows) {
          final m = Map<String, dynamic>.from(r as Map);
          final sName = m['sender_name']?.toString();
          final sId = m['sender_id']?.toString() ?? '';
          final rowClassId = m['class_id']?.toString() ?? '';
          if (isGenericSenderName(sName) && sId.isNotEmpty) {
            missingSenderNameIds.add(sId);
            if (rowClassId.isNotEmpty) extraClassIds.add(rowClassId);
          }
        }

        final senderNamesMap = await _resolveSenderNames(
          missingSenderNameIds,
          classId: classId,
          extraClassIds: extraClassIds,
        );

        for (final r in rows) {
          final m = Map<String, dynamic>.from(r as Map);
          final sId = m['sender_id']?.toString() ?? '';
          final currentSenderName = m['sender_name']?.toString();

          if (isGenericSenderName(currentSenderName)) {
            if (senderNamesMap.containsKey(sId) &&
                senderNamesMap[sId]!.isNotEmpty) {
              m['sender_name'] = senderNamesMap[sId]!;
            } else if (sId.isNotEmpty) {
              m['sender_name'] =
                  'Mahasiswa (${sId.length > 5 ? sId.substring(0, 5) : sId})';
            } else {
              m['sender_name'] = 'Mahasiswa';
            }
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

      // Perbaiki nama generic / "Mahasiswa (kode)" pada cache lokal jika ada.
      final genericLocalItems = result
          .where((it) =>
              it.senderId.isNotEmpty && isGenericSenderName(it.senderName))
          .toList();
      if (genericLocalItems.isNotEmpty) {
        final localMissingIds =
            genericLocalItems.map((e) => e.senderId).toSet();
        final extraClassIds = genericLocalItems
            .map((e) => e.classId ?? '')
            .where((c) => c.isNotEmpty)
            .toSet();
        final localNames = await _resolveSenderNames(
          localMissingIds,
          classId: classId,
          extraClassIds: extraClassIds,
        );
        if (localNames.isNotEmpty) {
          var updated = false;
          for (int i = 0; i < result.length; i++) {
            final it = result[i];
            final resolved = localNames[it.senderId];
            if (resolved != null && resolved.isNotEmpty) {
              result[i] = CheerNotificationItem(
                id: it.id,
                senderId: it.senderId,
                senderName: resolved,
                classId: it.classId,
                className: it.className,
                createdAt: it.createdAt,
              );
              updated = true;
            }
          }
          if (updated) {
            await prefs.setString(
              key,
              jsonEncode(result.take(30).map((e) => e.toMap()).toList()),
            );
          }
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
  var history = await CheerNotificationService.getReceivedCheers(
    userId,
    classId: validClassUuid,
  );

  // Jika riwayat kelas kosong tapi dbCount > 0, periksa juga riwayat umum (tanpa filter kelas)
  if (history.isEmpty && dbCount > 0 && validClassUuid != null) {
    history = await CheerNotificationService.getReceivedCheers(userId);
  }

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


