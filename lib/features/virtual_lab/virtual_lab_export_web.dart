// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

import 'virtual_lab_export.dart';

Future<VirtualLabExportResult> saveTopologyImage(
  Uint8List bytes,
  String fileName,
) async {
  final blob = html.Blob(<Object>[bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..download = fileName
    ..click();

  html.Url.revokeObjectUrl(url);

  return VirtualLabExportResult(
    filePath: fileName,
    fileName: fileName,
  );
}

Future<bool> openTopologyImage(String filePath) async {
  return true;
}

