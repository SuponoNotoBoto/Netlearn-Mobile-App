import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../supabase/supabase_client.dart';

/// Status baca pengumuman mahasiswa, disimpan lokal per akun.
///
/// Supabase tidak punya tempat untuk status ini: tabel `notifications` tidak
/// ada di skema remote, dan `NotificationModel` hanya model Dart yang belum
/// dipakai query mana pun. Menambah tabel berarti perubahan skema yang butuh
/// persetujuan, jadi status baca disimpan di SharedPreferences.
///
/// Kuncinya dipisah per `user id` supaya dua akun di satu perangkat tidak
/// saling mewarisi status baca — masalah yang sama dengan cache provider lama
/// di `session_reset.dart`, tetapi di sini tidak perlu di-reset saat login
/// karena kuncinya memang milik akun yang sedang masuk.
///
/// Yang disimpan hanya tambahan, tidak pernah `clear()`: SharedPreferences juga
/// menyimpan pilihan bahasa dan tema.
class AnnouncementReadStore {
  AnnouncementReadStore._();

  static const _keyPrefix = 'netlearn.announcement_reads';

  /// Kunci penyimpanan milik [userId].
  static String keyFor(String userId) => '$_keyPrefix.$userId';

  /// Membaca daftar id dari nilai JSON mentah.
  ///
  /// Nilai yang rusak atau bukan daftar dianggap kosong: status baca yang gagal
  /// dibaca tidak boleh membuat halaman notifikasi gagal dibuka, dan menampilkan
  /// semua pengumuman sebagai belum dibaca adalah kegagalan yang lebih ringan
  /// daripada layar kosong.
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

  /// Mengubah daftar id menjadi JSON. Diurutkan supaya isi penyimpanan stabil
  /// dan mudah dibandingkan saat menelusuri masalah.
  static String encode(Set<String> ids) {
    final sorted = ids.toList()..sort();
    return jsonEncode(sorted);
  }

  static Future<Set<String>> load(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    return decode(preferences.getString(keyFor(userId)));
  }

  /// Menandai [announcementId] sebagai sudah dibaca.
  ///
  /// Mengembalikan `false` kalau penulisan gagal, supaya pemanggil hanya
  /// menghapus indikator belum dibaca setelah status baca benar-benar
  /// tersimpan — dot yang hilang padahal tidak tersimpan akan kembali muncul
  /// saat aplikasi dibuka lagi.
  static Future<bool> markRead({
    required String userId,
    required String announcementId,
  }) async {
    if (announcementId.isEmpty) {
      return true;
    }

    final current = await load(userId);
    if (!current.add(announcementId)) {
      // Sudah tercatat dibaca; tidak perlu menulis ulang.
      return true;
    }

    return _write(userId, current);
  }

  /// Menandai semua [announcementIds] sebagai sudah dibaca.
  ///
  /// Dipakai tombol "Mark All as Read", yang hanya menandai pengumuman yang
  /// sedang tampil di daftar — bukan seluruh isi tabel.
  static Future<bool> markAllRead({
    required String userId,
    required Iterable<String> announcementIds,
  }) async {
    final current = await load(userId);
    final before = current.length;

    current.addAll(announcementIds.where((id) => id.isNotEmpty));
    if (current.length == before) {
      return true;
    }

    return _write(userId, current);
  }

  static Future<bool> _write(String userId, Set<String> ids) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.setString(keyFor(userId), encode(ids));
  }
}

/// Id pengguna yang sedang masuk untuk halaman notifikasi.
///
/// Dibaca lewat provider, bukan langsung dari `supabase.auth` di dalam halaman,
/// supaya halaman bisa diuji tanpa `Supabase.initialize` (yang tidak ada di
/// `flutter test`).
final notificationUserIdProvider = Provider<String?>(
  (ref) => supabase.auth.currentUser?.id,
);

/// Daftar id pengumuman yang sudah dibaca oleh [userId].
final announcementReadIdsProvider = FutureProvider.autoDispose
    .family<Set<String>, String>((ref, userId) => AnnouncementReadStore.load(userId));

/// Menandai satu pengumuman sudah dibaca, lalu menyegarkan [announcementReadIdsProvider].
///
/// Urutannya disengaja: provider baru di-invalidate setelah penyimpanan
/// berhasil. Kalau tidak, dot-nya hilang dulu dan muncul lagi.
///
/// Mengembalikan `false` kalau penyimpanan gagal.
Future<bool> persistAnnouncementRead(
  WidgetRef ref, {
  required String userId,
  required String announcementId,
}) async {
  final saved = await AnnouncementReadStore.markRead(
    userId: userId,
    announcementId: announcementId,
  );

  if (saved) {
    ref.invalidate(announcementReadIdsProvider(userId));
  }

  return saved;
}

/// Menandai seluruh [announcementIds] sudah dibaca, lalu menyegarkan provider.
Future<bool> persistAllAnnouncementsRead(
  WidgetRef ref, {
  required String userId,
  required Iterable<String> announcementIds,
}) async {
  final saved = await AnnouncementReadStore.markAllRead(
    userId: userId,
    announcementIds: announcementIds,
  );

  if (saved) {
    ref.invalidate(announcementReadIdsProvider(userId));
  }

  return saved;
}
