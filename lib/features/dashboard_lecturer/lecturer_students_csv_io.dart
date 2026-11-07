import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Writes [csv] into the app documents directory and opens it with the
/// system viewer.
///
/// Like `pdf_download_io.dart`, the app documents directory is user-scoped,
/// so no storage permission is needed on Android. This file is only compiled
/// for native targets — the web target uses `lecturer_students_csv_web.dart`
/// through the conditional import in `lecturer_students_csv.dart`.
///
/// Returns the written path, or null when the viewer could not open the file.
Future<String?> saveAndOpenStudentsCsv(String csv, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  await file.writeAsString(csv);

  // Open the file with the default application.
  final result = await OpenFilex.open(file.path);
  if (result.type != ResultType.done) {
    return null;
  }

  return file.path;
}
