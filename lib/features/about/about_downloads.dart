import 'package:flutter/services.dart';

import '../materials/pdf_download.dart';

/// PDF yang dibundel dan bisa diunduh dari About NetLearn.
///
/// Buku panduan punya dua varian karena bahasanya terpasang di berkas, bukan
/// dirender perangkat: `manualBookEn` / `manualBookId`. Yang mana yang
/// diunduh dipilih [AboutNetLearnContent] dari bahasa aktif pada saat tap.
/// Nama file di `assets/downloads/` harus sama persis dengan yang
/// di [`pubspec.yaml`] — folder `assets/downloads/` TIDAK direkursif, jadi
/// berkas baru di dalamnya ikut terbundel hanya karena folder itu sudah
/// dideklarasikan begitu berkasnya ada.
enum AboutDownloadResource { arMarkers, materialBook, manualBookEn, manualBookId }

extension AboutDownloadResourceFiles on AboutDownloadResource {
  /// Lokasi aset — harus sama dengan isi `pubspec.yaml` dan nama file di
  /// `assets/downloads/`.
  String get assetPath => switch (this) {
        AboutDownloadResource.arMarkers =>
          'assets/downloads/netlearn_ar_markers.pdf',
        AboutDownloadResource.materialBook =>
          'assets/downloads/netlearn_material_book.pdf',
        AboutDownloadResource.manualBookEn =>
          'assets/downloads/Manual_Book_Netlearn_en.pdf',
        AboutDownloadResource.manualBookId =>
          'assets/downloads/Manual_Book_Netlearn_id.pdf',
      };

  /// Nama file saat disimpan/dibuka di perangkat, mengikuti konvensi
  /// `NetLearn_<...>.pdf` milik unduhan PDF materi. Buku panduan membawa
  /// tandanya bahasa dalam nama, supaya dua versi tidak saling menimpa di
  /// perangkat pengguna yang sering berganti bahasa.
  String get fileName => switch (this) {
        AboutDownloadResource.arMarkers => 'NetLearn_Marker_AR.pdf',
        AboutDownloadResource.materialBook => 'NetLearn_Buku_Materi.pdf',
        AboutDownloadResource.manualBookEn => 'NetLearn_Manual_Book_EN.pdf',
        AboutDownloadResource.manualBookId => 'NetLearn_Manual_Book_ID.pdf',
      };
}

/// Membaca PDF yang dibundel lalu menyerahkannya ke [saveAndOpenPdf].
///
/// [bundle] dan [saveAndOpen] bisa diganti di test supaya tidak menyentuh
/// aset nyata atau filesystem.
Future<void> openAboutDownload(
  AboutDownloadResource resource, {
  AssetBundle? bundle,
  Future<void> Function(Uint8List bytes, String fileName)? saveAndOpen,
}) async {
  final data = await (bundle ?? rootBundle).load(resource.assetPath);
  final bytes = data.buffer.asUint8List(
    data.offsetInBytes,
    data.lengthInBytes,
  );

  await (saveAndOpen ?? saveAndOpenPdf)(bytes, resource.fileName);
}
