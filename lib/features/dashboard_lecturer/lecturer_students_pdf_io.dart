import 'dart:io';
import 'dart:typed_data';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Saves the PDF document to the device's application documents directory
/// and attempts to open it with the default system viewer.
Future<String?> saveAndOpenPdf(Uint8List bytes, String fileName) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);

    try {
      await OpenFilex.open(file.path);
    } catch (_) {
      // Viewer open failure does not negate the generated file
    }

    return file.path;
  } catch (_) {
    return null;
  }
}

