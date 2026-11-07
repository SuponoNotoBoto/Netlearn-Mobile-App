// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// Downloads the PDF document in the web browser using a Blob object URL.
Future<String?> saveAndOpenPdf(Uint8List bytes, String fileName) async {
  try {
    final blob = html.Blob(<Object>[bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..download = fileName
      ..click();

    html.Url.revokeObjectUrl(url);
    return fileName;
  } catch (_) {
    return null;
  }
}

