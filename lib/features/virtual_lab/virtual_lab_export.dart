import 'dart:typed_data';

import 'virtual_lab_export_io.dart'
    if (dart.library.html) 'virtual_lab_export_web.dart' as platform;

class VirtualLabExportResult {
  final String filePath;
  final String fileName;

  const VirtualLabExportResult({
    required this.filePath,
    required this.fileName,
  });
}

/// Menyimpan data gambar PNG kanvas ke direktori dokumen pengguna.
Future<VirtualLabExportResult> saveTopologyImage(
  Uint8List bytes,
  String fileName,
) {
  return platform.saveTopologyImage(bytes, fileName);
}

/// Membuka file gambar yang sudah disimpan menggunakan penampil foto/galeri bawaan sistem.
Future<bool> openTopologyImage(String filePath) {
  return platform.openTopologyImage(filePath);
}

/// Menyimpan data konfigurasi topologi berformat JSON ke berkas fisik perangkat.
Future<VirtualLabExportResult> saveTopologyJson(
  String jsonContent,
  String fileName,
) {
  return platform.saveTopologyJson(jsonContent, fileName);
}

