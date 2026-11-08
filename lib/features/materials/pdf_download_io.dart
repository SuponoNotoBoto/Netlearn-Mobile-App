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
  final file = File(
    '${directory.path}${Platform.pathSeparator}$fileName',
  );
  await file.writeAsBytes(bytes);
  await OpenFilex.open(file.path);
}