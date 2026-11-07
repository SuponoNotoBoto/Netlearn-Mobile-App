// dart:html is discouraged in favour of package:web, but pulling in package:web
// (plus dart:js_interop interop boilerplate) for one anchor-click download is
// not worth a new dependency. This file only compiles for the web target.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

/// Triggers a browser download of [csv] under [fileName].
///
/// There is no system file viewer on web, so the browser download is the
/// equivalent of the device behaviour (`lecturer_students_csv_io.dart`).
/// Returns [fileName] so a non-null result still means "export started".
Future<String?> saveAndOpenStudentsCsv(String csv, String fileName) async {
  final blob = html.Blob(<Object>[utf8.encode(csv)], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..download = fileName
    ..click();

  html.Url.revokeObjectUrl(url);
  return fileName;
}
