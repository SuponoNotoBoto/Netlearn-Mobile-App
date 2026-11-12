import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Writes [bytes] to the app's documents directory and opens it with the
/// system PDF viewer.
///
/// The app documents directory is user-scoped and needs no `Permission.storage`
/// on Android — the old reader implementation requested it and then could still
/// not write on API 33+, where that permission is a no-op unless scoped to
/// media. Writing into our own directory sidesteps storage permissions entirely.
Future<void> saveAndOpenPdf(Uint8List bytes, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final target = File(
    '${directory.path}${Platform.pathSeparator}$fileName',
  );

  File outputFile = target;
  try {
    if (await target.exists()) {
      await target.delete();
    }
    await target.writeAsBytes(bytes, flush: true);
  } on FileSystemException {
    // Jika file lama masih terkunci oleh penampil PDF eksternal, tulis ke nama
    // baru agar dokumen terbaru tetap terbuka tanpa gagal.
    final dotIndex = fileName.lastIndexOf('.');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final fallbackName = dotIndex > 0
        ? '${fileName.substring(0, dotIndex)}_$stamp${fileName.substring(dotIndex)}'
        : '${fileName}_$stamp';
    outputFile = File(
      '${directory.path}${Platform.pathSeparator}$fallbackName',
    );
    await outputFile.writeAsBytes(bytes, flush: true);
  }

  await OpenFilex.open(outputFile.path);
}