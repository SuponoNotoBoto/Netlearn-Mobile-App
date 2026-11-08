import '../../shared/models/announcement_model.dart';

/// Pengumuman dihitung "baru" bila sudah dipublikasikan dan id-nya belum
/// tercatat di penyimpanan baca akun ini.
///
/// Draf tidak pernah dihitung: draf belum diumumkan ke siapa pun, dan dulu
/// ia ikut dihitung sehingga dot dosen menyala terus sampai draf dibuka.
/// Penyebabnya `userAnnouncementsProvider` mengembalikan baris milik dosen
/// tanpa menyaring `published` (baris mahasiswa sudah disaring di query),
/// jadi penyaringan ini diulang di satu tempat yang dipakai semua role.
///
/// Fungsi ini murni (tanpa Flutter/Supabase) supaya bisa diuji offline.
bool hasUnreadAnnouncement(
  List<AnnouncementModel> announcements,
  Set<String> readIds,
) {
  return announcements.any(
    (announcement) => announcement.published && !readIds.contains(announcement.id),
  );
}
