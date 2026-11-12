import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/supabase/supabase_client.dart';

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
  static String _storageKey(String receiverId) => 'v2_received_cheers_$receiverId';

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

    // 1. Simpan di SharedPreferences penerima (cache lokal/instan)
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _storageKey(receiverId);
      final raw = prefs.getString(key);
      final list = <CheerNotificationItem>[item];
      if (raw != null && raw.isNotEmpty) {
        try {
          final List decoded = jsonDecode(raw) as List;
          list.addAll(decoded.map((m) =>
              CheerNotificationItem.fromMap(Map<String, dynamic>.from(m as Map))));
        } catch (_) {}
      }
      await prefs.setString(
        key,
        jsonEncode(list.take(30).map((e) => e.toMap()).toList()),
      );
    } catch (_) {}

    // 2. Best-effort mirror ke Supabase jika tabel user_notifications / profile_cheers ada
    try {
      await supabase.from('profile_cheers').insert({
        'sender_id': sender.id,
        'receiver_id': receiverId,
        'class_id': classId,
        'sender_name': senderName,
        'created_at': now.toIso8601String(),
      });
    } catch (_) {}
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
          .select('id, sender_id, sender_name, class_id, created_at')
          .eq('receiver_id', receiverId);
      if (classId != null && classId.isNotEmpty) {
        query = query.eq('class_id', classId);
      }
      final rows = await query.order('created_at', ascending: false).limit(25);
      if ((rows as List).isNotEmpty) {
        for (final r in rows) {
          result.add(
            CheerNotificationItem.fromMap(Map<String, dynamic>.from(r as Map)),
          );
        }
        return result;
      }
    } catch (_) {}

    // 2. Fallback baca dari SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey(receiverId));
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

/// Provider reaktif untuk riwayat dan total semangat (cheers) yang diterima mahasiswa.
final studentReceivedCheersProvider =
    FutureProvider.family.autoDispose<List<CheerNotificationItem>, String>(
        (ref, userId) async {
  if (userId.isEmpty) return const [];
  return CheerNotificationService.getReceivedCheers(userId);
});


