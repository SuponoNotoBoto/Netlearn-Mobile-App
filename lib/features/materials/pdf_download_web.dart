// dart:html is discouraged in favour of package:web, but pulling in package:web
// (plus dart:js_interop interop boilerplate) for one anchor-click download is
// not worth a new dependency. This file only compiles for the web target.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

/// Triggers a browser download of the PDF bytes.
Future<void> saveAndOpenPdf(Uint8List bytes, String fileName) async {
  final blob = html.Blob(<Object>[bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..download = fileName
    ..click();

  html.Url.revokeObjectUrl(url);
}