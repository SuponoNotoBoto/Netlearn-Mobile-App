import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Status baca pengumuman mahasiswa, disimpan lokal di SharedPreferences per akun.
///
/// Logika dan struktur kunci mengikuti standar repositori NetLearn:
/// `netlearn.announcement_reads.<userId>`
class AnnouncementReadStore {
  AnnouncementReadStore._();

  static const _keyPrefix = 'netlearn.announcement_reads';

  /// Kunci penyimpanan milik [userId]
  static String keyFor(String userId) => '$_keyPrefix.$userId';

  /// Membaca daftar ID dari nilai JSON mentah
  static Set<String> decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <String>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <String>{};
      }

      return decoded
          .map((item) => item.toString())
          .where((id) => id.isNotEmpty)
          .toSet();
    } on FormatException {
      return <String>{};
    }
  }

  /// Mengubah daftar ID menjadi JSON string stabil
  static String encode(Set<String> ids) {
    final sorted = ids.toList()..sort();
    return jsonEncode(sorted);
  }

  /// Memuat set announcement ID yang telah dibaca untuk user tertentu
  static Future<Set<String>> load(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    return decode(preferences.getString(keyFor(userId)));
  }

  /// Menandai satu [announcementId] sebagai sudah dibaca
  static Future<bool> markRead({
    required String userId,
    required String announcementId,
  }) async {
    if (announcementId.isEmpty) {
      return true;
    }

    final current = await load(userId);
    if (!current.add(announcementId)) {
      // Sudah tercatat dibaca; tidak perlu menulis ulang
      return true;
    }

    return _write(userId, current);
  }

  /// Menandai semua [announcementIds] sebagai sudah dibaca
  static Future<bool> markAllRead({
    required String userId,
    required Iterable<String> announcementIds,
  }) async {
    final current = await load(userId);
    final before = current.length;

    for (final id in announcementIds) {
      if (id.isNotEmpty) {
        current.add(id);
      }
    }

    if (current.length == before) {
      return true;
    }

    return _write(userId, current);
  }

  static Future<bool> _write(String userId, Set<String> ids) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.setString(keyFor(userId), encode(ids));
    } catch (_) {
      return false;
    }
  }
}

