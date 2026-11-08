import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../shared/models/student_model.dart';
import '../classes/class_models.dart';
import 'lecturer_students_pdf_io.dart'
    if (dart.library.html) 'lecturer_students_pdf_web.dart' as platform;

class LecturerStudentsPdfExporter {
  static String _sanitize(String text) {
    return text
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('…', '...')
        .replaceAll('•', '-')
        .replaceAll(RegExp(r'[^\x00-\xFF]'), '');
  }

  static pw.Document buildPdfDocument({
    required List<StudentModel> students,
    LecturerClass? activeClass,
    String? lecturerName,
  }) {
    final pdf = pw.Document();

    final className = _sanitize(activeClass?.name ?? 'Kelas Utama Jaringan Komputer');
    final classCode = _sanitize(activeClass?.code ?? 'NL-2026');
    final safeLecturer = _sanitize(lecturerName ?? 'Dosen Jaringan');
    final printDate = DateTime.now();
    final formattedDate =
        '${printDate.day.toString().padLeft(2, '0')}/${printDate.month.toString().padLeft(2, '0')}/${printDate.year}';

    // Calculate aggregates
    int pretestCount = 0;
    double pretestSum = 0;
    int posttestCount = 0;
    double posttestSum = 0;

    for (final s in students) {
      if (s.pretestScore != null) {
        pretestSum += s.pretestScore!;
        pretestCount++;
      }
      if (s.posttestScore != null) {
        posttestSum += s.posttestScore!;
        posttestCount++;
      }
    }

    final avgPretest = pretestCount > 0 ? (pretestSum / pretestCount).toStringAsFixed(1) : '-';
    final avgPosttest = posttestCount > 0 ? (posttestSum / posttestCount).toStringAsFixed(1) : '-';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // Kop Laporan
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'NETLEARN LEARNING MANAGEMENT SYSTEM',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'LAPORAN RESMI REKAPITULASI NILAI & EVALUASI MAHASISWA',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Mata Kuliah: Jaringan Komputer Dasar & Terapan',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Divider(thickness: 1.5, color: PdfColors.indigo900),
                  pw.SizedBox(height: 10),
                ],
              ),
            ),

            // Metadata Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Nama Kelas: $className', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text('Kode Kelas: $classCode', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Tanggal Cetak: $formattedDate', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Text('Dosen Pengampu: $safeLecturer', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // Ringkasan Statistik
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text('Total Mahasiswa: ${students.length}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rata-rata Pretest: $avgPretest', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rata-rata Posttest: $avgPosttest', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Tabel Nilai yang dapat split antar halaman
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headers: ['No', 'NIM', 'Nama Mahasiswa', 'Pretest', 'Posttest', 'Status'],
              headerStyle: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo50),
              headerAlignment: pw.Alignment.center,
              cellStyle: const pw.TextStyle(fontSize: 8),
              columnWidths: {
                0: const pw.FixedColumnWidth(26),
                1: const pw.FixedColumnWidth(70),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FixedColumnWidth(48),
                4: const pw.FixedColumnWidth(48),
                5: const pw.FixedColumnWidth(64),
              },
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
              },
              data: students.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final s = entry.value;
                final pretest = s.pretestScore != null ? s.pretestScore!.toStringAsFixed(0) : '-';
                final posttest = s.posttestScore != null ? s.posttestScore!.toStringAsFixed(0) : '-';
                final passed = s.posttestScore != null && s.posttestScore! >= 70;
                final statusText = s.posttestScore == null ? 'Belum Ujian' : (passed ? 'Lulus' : 'Remidi');

                return [
                  '$idx',
                  _sanitize(s.identityNumber ?? '-'),
                  _sanitize(s.name),
                  pretest,
                  posttest,
                  statusText,
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 36),

            // Tanda Tangan Dosen
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.SizedBox(),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Mengetahui / Mengesahkan,', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Dosen Pengampu Mata Kuliah', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 48),
                    pw.Text('( $safeLecturer )', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('NIP/NIDN. .................................', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static Future<String?> generateAndOpenPdf({
    required List<StudentModel> students,
    LecturerClass? activeClass,
    String? lecturerName,
  }) async {
    try {
      final pdf = buildPdfDocument(
        students: students,
        activeClass: activeClass,
        lecturerName: lecturerName,
      );
      final Uint8List bytes = await pdf.save();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Laporan_Nilai_$timestamp.pdf';
      return await platform.saveAndOpenPdf(bytes, fileName);
    } catch (_) {
      return null;
    }
  }
}

