import '../../shared/models/student_model.dart';

import 'lecturer_students_csv_io.dart'
    if (dart.library.html) 'lecturer_students_csv_web.dart' as platform;

/// Builds the CSV body for the lecturer student list export.
///
/// Kept pure and platform-free so the export format can be unit-tested without
/// touching the file system or the browser.
String buildStudentsCsv(List<StudentModel> students) {
  final buffer = StringBuffer();

  // Header row.
  buffer.writeln('Name,NIM,Program,Status');

  // Data rows.
  for (final student in students) {
    final name = _escapeCsvField(student.name);
    final nim = _escapeCsvField(student.identityNumber ?? '');
    final program = _escapeCsvField(student.program ?? '');
    final status = student.isActive ? 'Active' : 'Inactive';
    buffer.writeln('$name,$nim,$program,$status');
  }

  return buffer.toString();
}

/// Exports the student list to a CSV file and opens it.
///
/// The CSV contains the columns that are actually available in the student
/// list: name, NIM, program, and status. Score data is not included because
/// RLS does not permit lecturers to read `quiz_attempts` or
/// `learning_progress` for other users.
///
/// On device the file is written to the app documents directory and opened
/// with the default app; on web the browser downloads it instead. The
/// conditional import keeps `dart:io` (plus `path_provider` and `open_filex`,
/// which import it themselves) off the web compile and `dart:html` off the
/// native compile.
///
/// Returns the file path on device, the file name on web, or null on failure.
Future<String?> exportStudentsToCsv(List<StudentModel> students) {
  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  return platform.saveAndOpenStudentsCsv(
    buildStudentsCsv(students),
    'netlearn_students_$timestamp.csv',
  );
}

// ---------------------------------------------------------------------------
// Score overview export.
//
// The header contract is the Figma design (StudentProgress.tsx, scoreCsv.ts):
// the columns stay Indonesian even in the English locale, every cell is
// quoted, rows end with \r\n and the file starts with a BOM so Excel opens
// it as UTF-8.
// ---------------------------------------------------------------------------

/// Exact header row of the score overview export. Kept as a constant so the
/// page and the tests agree on the contract.
const scoreCsvHeaders = ['Nama Mahasiswa', 'NIM', 'Nilai Pretest', 'Nilai Posttest'];

/// Builds the score overview CSV body for the Score Overview tab export.
///
/// Kept pure and platform-free like [buildStudentsCsv]. A missing score is an
/// empty cell, not a dash and not 0: a dash would not survive round-tripping
/// in Excel and a 0 would misreport "not taken" as "taken, scored zero".
String buildScoreCsv(List<StudentModel> students) {
  final buffer = StringBuffer();

  // BOM first, so Excel detects UTF-8 for names with diacritics.
  buffer.write('\uFEFF');

  // Header row.
  buffer.write(_toCsvRow(scoreCsvHeaders));

  // Data rows.
  for (final student in students) {
    buffer.write(_toCsvRow([
      student.name,
      student.identityNumber ?? '',
      formatScoreValue(student.pretestScore),
      formatScoreValue(student.posttestScore),
    ]));
  }

  return buffer.toString();
}

/// Encodes one row: every cell quoted, joined with commas, closed by CRLF —
/// including a trailing \r\n on the last row, which Excel expects.
String _toCsvRow(List<String> cells) {
  return '${cells.map(_encodeScoreCsvField).join(',')}\r\n';
}

/// Exports the score overview to a CSV file and opens it.
///
/// Same device/web split as [exportStudentsToCsv]; see there for why the
/// conditional import exists.
///
/// Returns the file path on device, the file name on web, or null on failure.
Future<String?> exportScoresToCsv(List<StudentModel> students) {
  return platform.saveAndOpenStudentsCsv(
    buildScoreCsv(students),
    'netlearn_score_overview_${_fileTimestamp()}.csv',
  );
}

/// yyyyMMdd_HHmmss: sortable, valid in a file name, and unique enough that
/// two exports never overwrite each other (the design used a bare
/// netlearn_score_overview.csv, which did).
String _fileTimestamp() {
  final now = DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${now.year}${two(now.month)}${two(now.day)}'
      '_${two(now.hour)}${two(now.minute)}${two(now.second)}';
}

/// Formats a score for export and display: at most two decimals with trailing
/// zeros stripped, so 85, 66.67 and 100 — not 85.00 or 66.6700.
String formatScoreValue(double? score) {
  if (score == null) return '';

  String text = score.toStringAsFixed(2);

  if (text.contains('.')) {
    text = text.replaceAll(RegExp(r'0+$'), '');
    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
  }

  return text;
}

/// CSV cell rules for the score export.
///
/// Wraps in double quotes unconditionally, doubles any embedded quote, and
/// neutralises spreadsheet-formula injection: a value starting with = + - @
/// TAB or CR becomes '=SUM(A1) etc., so a crafted name cannot execute as a
/// formula in Excel.
///
/// (Unlike `_escapeCsvField` above, which stays conditional-quote for the
/// historical body export format that lecturer_students_csv_test.dart pins,
/// the score export always quotes — the design contract.)
String _encodeScoreCsvField(String value) {
  final isFirstCharRisky = value.isNotEmpty && const {
    '=',
    '+',
    '-',
    '@',
    '\t',
    '\r',
  }.contains(value[0]);

  final safe = isFirstCharRisky ? "'$value" : value;

  return '"${safe.replaceAll('"', '""')}"';
}

/// Escapes a field for CSV: wraps in quotes if it contains a comma, quote,
/// or newline, and doubles any embedded quotes.
String _escapeCsvField(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
