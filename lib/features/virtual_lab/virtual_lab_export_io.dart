import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'virtual_lab_export.dart';

Future<VirtualLabExportResult> saveTopologyImage(
  Uint8List bytes,
  String fileName,
) async {
  Directory directory;
  try {
    directory = await getApplicationDocumentsDirectory();
  } catch (_) {
    directory = await getTemporaryDirectory();
  }

  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);

  return VirtualLabExportResult(
    filePath: file.path,
    fileName: fileName,
  );
}

Future<bool> openTopologyImage(String filePath) async {
  try {
    final result = await OpenFilex.open(filePath);
    return result.type == ResultType.done;
  } catch (_) {
    return false;
  }
}

Future<VirtualLabExportResult> saveTopologyJson(
  String jsonContent,
  String fileName,
) async {
  Directory directory;
  try {
    directory = await getApplicationDocumentsDirectory();
  } catch (_) {
    directory = await getTemporaryDirectory();
  }

  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  await file.writeAsString(jsonContent, flush: true);

  return VirtualLabExportResult(
    filePath: file.path,
    fileName: fileName,
  );
}

