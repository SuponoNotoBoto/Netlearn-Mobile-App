import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/language_controller.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/student_model.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_empty_state.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import 'lecturer_students_controller.dart';
import 'lecturer_students_csv.dart';
import 'lecturer_students_pdf.dart';

/// Tab Rekap Nilai — tabel nilai seluruh mahasiswa beserta tombol ekspor CSV dan PDF.
class LecturerScoreOverviewTab extends ConsumerWidget {
  const LecturerScoreOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final studentsAsync = ref.watch(lecturerStudentsProvider(null));

    return studentsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(NetLearnSpace.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 46,
                color: NetLearnColors.danger,
              ),
              const SizedBox(height: NetLearnSpace.s12),
              Text(
                mapStudentsError(error).message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NetLearnSpace.s12),
              OutlinedButton(
                onPressed: () {
                  ref.invalidate(lecturerStudentsProvider(null));
                },
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
      data: (students) {
        if (students.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(NetLearnSpace.s24),
              child: NlEmptyState(
                icon: Icons.assessment_outlined,
                title: l10n.scoreOverview,
                message: l10n.scoreTabEmpty,
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: context.accent,
          onRefresh: () async {
            ref.invalidate(lecturerStudentsProvider(null));
            await ref.read(lecturerStudentsProvider(null).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              NetLearnSpace.s20,
              NetLearnSpace.s8,
              NetLearnSpace.s20,
              NetLearnSpace.s32,
            ),
            children: [
              Text(
                l10n.scoreOverview,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: NetLearnSpace.s12),
              Row(
                children: [
                  Expanded(
                    child: NlButton(
                      label: l10n.downloadCsv,
                      icon: Icons.download_rounded,
                      variant: NlButtonVariant.secondary,
                      onPressed: () => _downloadCsv(context, l10n, students),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NlButton(
                      label: ref.watch(languageProvider).languageCode == 'id'
                          ? 'Cetak Laporan PDF'
                          : 'Print PDF Report',
                      icon: Icons.picture_as_pdf_rounded,
                      variant: NlButtonVariant.primary,
                      onPressed: () => _exportPdf(context, ref, students),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NetLearnSpace.s12),
              Text(
                l10n.scoreScaleHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.mutedText,
                    ),
              ),
              const SizedBox(height: NetLearnSpace.s16),

              Semantics(
                label: l10n.scoreTableSemantics,
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
                      _scoreHeaderRow(context, l10n),
                      for (final student in students)
                        _scoreRow(context, l10n, student),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  TableRow _scoreHeaderRow(BuildContext context, AppLocalizations l10n) {
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
        headerCell(l10n.studentName, TextAlign.left),
        headerCell(l10n.nim, TextAlign.left),
        headerCell(l10n.pretestScore, TextAlign.center),
        headerCell(l10n.posttestScore, TextAlign.center),
      ],
    );
  }

  TableRow _scoreRow(
    BuildContext context,
    AppLocalizations l10n,
    StudentModel student,
  ) {
    Widget nameCell(String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(value, style: const TextStyle(fontSize: 12)),
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
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ),
      );
    }

    Widget scoreCell(double? score) {
      if (score == null) {
        return Semantics(
          label: l10n.scoreNotAvailable,
          excludeSemantics: true,
          child: flatCell(
            '—',
            alignment: Alignment.center,
            color: context.mutedText,
          ),
        );
      }

      return flatCell(formatScoreValue(score), alignment: Alignment.center);
    }

    return TableRow(
      children: [
        nameCell(student.name),
        flatCell(
          student.identityNumber ?? '',
          alignment: Alignment.centerLeft,
        ),
        scoreCell(student.pretestScore),
        scoreCell(student.posttestScore),
      ],
    );
  }

  Future<void> _downloadCsv(
    BuildContext context,
    AppLocalizations l10n,
    List<StudentModel> students,
  ) async {
    try {
      final path = await exportScoresToCsv(students);
      if (!context.mounted) return;

      if (path != null) {
        NlSnackBar.show(
          context,
          l10n.csvExported,
          tone: NlSnackTone.success,
        );
      } else {
        NlSnackBar.show(
          context,
          l10n.csvFailed,
          tone: NlSnackTone.error,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      NlSnackBar.show(
        context,
        l10n.csvFailed,
        tone: NlSnackTone.error,
      );
    }
  }

  Future<void> _exportPdf(
    BuildContext context,
    WidgetRef ref,
    List<StudentModel> students,
  ) async {
    final isId = ref.read(languageProvider).languageCode == 'id';

    final user = supabase.auth.currentUser;
    final lecturerName = user?.userMetadata?['name']?.toString() ??
        user?.userMetadata?['full_name']?.toString() ??
        'Rafi Ahmad Fauzan';

    try {
      final path = await LecturerStudentsPdfExporter.generateAndOpenPdf(
        students: students,
        activeClass: null,
        lecturerName: lecturerName,
      );

      if (!context.mounted) return;

      if (path != null) {
        final fileName = path.contains('/')
            ? path.split('/').last
            : path.split(r'\').last;
        NlSnackBar.show(
          context,
          isId
              ? 'Laporan PDF berhasil dicetak: $fileName'
              : 'PDF report generated: $fileName',
          tone: NlSnackTone.success,
        );
      } else {
        NlSnackBar.show(
          context,
          isId ? 'Gagal mencetak dokumen PDF' : 'Failed to generate PDF document',
          tone: NlSnackTone.error,
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      NlSnackBar.show(
        context,
        isId ? 'Gagal mencetak dokumen PDF' : 'Failed to generate PDF document',
        tone: NlSnackTone.error,
      );
    }
  }
}
