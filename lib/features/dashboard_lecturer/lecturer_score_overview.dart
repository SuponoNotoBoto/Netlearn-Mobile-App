import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import 'assessment_models.dart';

/// Tab Rekap Nilai — tabel nilai seluruh mahasiswa beserta tombol aksi ekspor CSV & PDF.
/// Mereplika persis visual dan struktur tabel dari NetLearn 2.0.
class LecturerScoreOverviewTab extends StatefulWidget {
  final List<StudentScoreModel>? students;

  const LecturerScoreOverviewTab({
    super.key,
    this.students,
  });

  @override
  State<LecturerScoreOverviewTab> createState() => _LecturerScoreOverviewTabState();
}

class _LecturerScoreOverviewTabState extends State<LecturerScoreOverviewTab> {
  late List<StudentScoreModel> _students;

  @override
  void initState() {
    super.initState();
    _students = widget.students ?? getInitialStudents();
  }

  void _downloadCsv() {
    NlSnackBar.show(
      context,
      'Rekap nilai berhasil diekspor ke CSV: rekap_nilai_mahasiswa.csv',
      tone: NlSnackTone.success,
    );
  }

  void _exportPdf() {
    NlSnackBar.show(
      context,
      'Laporan PDF nilai berhasil dicetak: laporan_rekap_nilai_TI-3A.pdf',
      tone: NlSnackTone.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        NetLearnSpace.s20,
        NetLearnSpace.s8,
        NetLearnSpace.s20,
        NetLearnSpace.s32,
      ),
      children: [
        Text(
          'Rekap Nilai Mahasiswa',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: NetLearnColors.neutral900,
              ),
        ),
        const SizedBox(height: NetLearnSpace.s12),
        Row(
          children: [
            Expanded(
              child: NlButton(
                label: 'Unduh CSV',
                icon: Icons.download_rounded,
                variant: NlButtonVariant.secondary,
                onPressed: _downloadCsv,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NlButton(
                label: 'Cetak Laporan PDF',
                icon: Icons.picture_as_pdf_rounded,
                variant: NlButtonVariant.primary,
                onPressed: _exportPdf,
              ),
            ),
          ],
        ),
        const SizedBox(height: NetLearnSpace.s12),
        Text(
          'Skala nilai 0–100. Tanda strip (—) menunjukkan mahasiswa belum mengerjakan asesmen.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.mutedText,
                fontSize: 12,
              ),
        ),
        const SizedBox(height: NetLearnSpace.s16),

        // Tabel nilai versi compact persis NetLearn 2.0
        Semantics(
          label: 'Tabel Rekap Nilai Mahasiswa',
          container: true,
          child: Container(
            key: const ValueKey('score-table-card'),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.top,
              columnWidths: const {
                0: FlexColumnWidth(1.7),
                1: IntrinsicColumnWidth(),
                2: FlexColumnWidth(1.35),
                3: FlexColumnWidth(1.35),
              },
              border: TableBorder(
                horizontalInside: BorderSide(color: context.border),
                bottom: BorderSide(color: context.border),
              ),
              children: [
                _scoreHeaderRow(context),
                for (final student in _students)
                  _scoreRow(context, student),
              ],
            ),
          ),
        ),
      ],
    );
  }

  TableRow _scoreHeaderRow(BuildContext context) {
    Widget headerCell(String label, TextAlign textAlign) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            label.toUpperCase(),
            textAlign: textAlign,
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: context.mutedText,
            ),
          ),
        ),
      );
    }

    return TableRow(
      decoration: BoxDecoration(
        color: context.raisedSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      children: [
        headerCell('Nama Mahasiswa', TextAlign.left),
        headerCell('NIM', TextAlign.left),
        headerCell('Pretest', TextAlign.center),
        headerCell('Posttest', TextAlign.center),
      ],
    );
  }

  TableRow _scoreRow(BuildContext context, StudentScoreModel student) {
    Widget nameCell(String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: NetLearnColors.neutral900,
          ),
        ),
      );
    }

    Widget flatCell(
      String value, {
      required Alignment alignment,
      Color? color,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: SizedBox(
          height: 18,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignment,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 12,
                color: color ?? NetLearnColors.neutral700,
              ),
            ),
          ),
        ),
      );
    }

    Widget scoreCell(double? score) {
      if (score == null) {
        return flatCell(
          '—',
          alignment: Alignment.center,
          color: context.mutedText,
        );
      }

      return flatCell(
        formatScoreValue(score),
        alignment: Alignment.center,
        color: score >= 75 ? NetLearnColors.forest : NetLearnColors.danger,
      );
    }

    return TableRow(
      children: [
        nameCell(student.name),
        flatCell(
          student.identityNumber,
          alignment: Alignment.centerLeft,
        ),
        scoreCell(student.pretestScore),
        scoreCell(student.posttestScore),
      ],
    );
  }
}

