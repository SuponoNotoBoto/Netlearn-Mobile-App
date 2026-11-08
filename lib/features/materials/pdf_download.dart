import 'dart:typed_data';

import 'pdf_download_io.dart'
    if (dart.library.html) 'pdf_download_web.dart' as platform;

/// Saves and opens the PDF on devices, or triggers a browser download on web.
///
/// The conditional import keeps `dart:io` (path_provider, `File`, OpenFilex)
/// off the web compile and `dart:html` off the native compile. Both platforms
/// expose the same [saveAndOpenPdf] entry point, so callers only ever see this
/// one function.
Future<void> saveAndOpenPdf(Uint8List bytes, String fileName) {
  return platform.saveAndOpenPdf(bytes, fileName);
}