import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/supabase/supabase_client.dart';

/// Bucket that holds uploaded PDF material files.
///
/// It is private (`public = false`, see the storage settings migration), so the
/// object path stored in `materials.pdf_url` must be exchanged for a short-lived
/// signed URL before the client can fetch it. Storage RLS policy
/// `netlearn_storage_read` already lets any authenticated user sign.
const String materialFilesBucket = 'material-files';

/// How long a signed URL stays valid. One hour is generous for reading a PDF.
const int signedUrlLifetimeSeconds = 3600;

/// How long a signed-URL request or the PDF download may take before it counts
/// as a failure.
///
/// Neither the storage client nor `http.get` times out on its own: a request
/// that never completes (dead connection, DNS stuck behind a captive portal,
/// proxy that accepts and then stalls) left the viewer in its loading state
/// with no error and no retry button — the "view PDF loading terus" report.
/// An explicit timeout turns that hang into a normal, retryable failure.
const Duration pdfRequestTimeout = Duration(seconds: 30);

/// Turns the value stored in `materials.pdf_url` into a URL the client can
/// actually fetch.
///
/// - `null` / empty → `null` (this material has no PDF);
/// - an `http(s)://` value is a public link already hosted elsewhere and is
///   returned unchanged;
/// - anything else is treated as an object path inside [materialFilesBucket]
///   and exchanged for a signed URL via the storage API.
///
/// The lecturer form stores both kinds, so the app-facing helpers here work on
/// whatever the form wrote instead of assuming one shape. See
/// `youtube_link.dart` for the sibling split for video URLs.
Future<String?> resolveMaterialPdfUrl(String? pdfUrl) async {
  final raw = pdfUrl?.trim();

  if (raw == null || raw.isEmpty) {
    return null;
  }

  final lower = raw.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return raw;
  }

  return supabase.storage
      .from(materialFilesBucket)
      .createSignedUrl(raw, signedUrlLifetimeSeconds)
      .timeout(pdfRequestTimeout);
}

/// Downloads the PDF bytes behind [url] with a plain GET.
///
/// A signed URL is fetchable without an auth header, so the same code path works
/// on web and on devices — no `dart:io` and no conditional import needed here.
Future<Uint8List> downloadMaterialPdfBytes(String url) async {
  final response = await http.get(Uri.parse(url)).timeout(pdfRequestTimeout);

  if (response.statusCode != 200) {
    throw Exception('Failed to download PDF: ${response.statusCode}');
  }

  return response.bodyBytes;
}