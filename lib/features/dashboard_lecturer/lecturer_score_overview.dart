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
import 'widgets/lecturer_score_chart_card.dart';
import '../classes/class_controller.dart';

/// Tab Rekap Nilai — tabel nilai seluruh mahasiswa beserta tombol ekspor
/// CSV-nya.
///
/// Widget ini dipakai di dua tempat: tab kedua halaman Daftar Mahasiswa
/// (`lecturer_student_list_page.dart`) dan tab kedua halaman Assessment
/// (`lecturer_assessments_page.dart`). Ekstraksinya yang membuat kedua
/// tempat menampilkan tabel yang persis sama tanpa salin-tempel; dulu
/// metode-metodenya privat pada satu halaman, dan menautkannya dari halaman
/// lain berarti menduplikasi seluruh tabel.
///
/// Data dinonton sendiri ([lecturerStudentsProvider(null)]) supaya widget
/// ini bisa dipasang di mana pun tanpa parameter tambahan — halaman Daftar
/// Mahasiswa juga menonton provider yang sama untuk tab Data-nya.
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
            // Sama dengan tab Data: 8 di tepi kiri membuat tabel menempel ke
            // layar — 20 memberi napas yang sama seperti tab Data.
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
              LecturerScoreChartCard(students: students),
              const SizedBox(height: NetLearnSpace.s16),
              Text(
                l10n.scoreScaleHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.mutedText,
                    ),
              ),
              const SizedBox(height: NetLearnSpace.s12),

              // Tabel nilai versi compact — setara <table class="w-full
              // text-xs"> di desain. DataTable bawaan membuat baris 56px dan
              // divider Material; Table custom di sini memakai sel padding 8
              // dan garis antarbaris saja. Tanpa scroll horizontal: kolom
              // nama fleksibel (boleh wrap), NIM nowrap, dan kedua kolom
              // nilai berbagi sisa lebar — scroll horizontal justru
              // menyembunyikan kolom Posttest di layar 360dp.
              Semantics(
                label: l10n.scoreTableSemantics,
                container: true,
                child: Container(
                  key: const ValueKey('score-table-card'),
                  // `radius: 18` — `.card` di index.css desain. Padding kartu
                  // dihapus: band header harus selebar kartu dan menempel ke
                  // tepi atasnya (clipBehavior memotong band di radius 18),
                  // jadi 12/10 dipindah ke dalam sel header dan sel data.
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Table(
                    defaultVerticalAlignment:
                        TableCellVerticalAlignment.top,
                    // border-collapse: nama boleh wrap; NIM nowrap
                    // (intrinsic); kedua kolom nilai berbagi sisa lebar.
                    // Bobot 1.7 : 1.35 : 1.35, bukan 2.4 : 1 : 1 — dengan
                    // porsi 1:1 kata "Posttest" sempit di kolomnya dan
                    // terpotong ellipsis, padahal nama cukup wrap 2 baris;
                    // desain Figma menampilkan header nilai dua baris penuh.
                    columnWidths: const {
                      0: FlexColumnWidth(1.7),
                      1: IntrinsicColumnWidth(),
                      2: FlexColumnWidth(1.35),
                      3: FlexColumnWidth(1.35),
                    },
                    border: TableBorder(
                      horizontalInside:
                          BorderSide(color: context.border),
                      // border-b juga pada sel terakhir, sesuai Figma.
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
    // Band header: latar raisedSurface dengan sudut atas membulat — berbeda
    // jelas dari baris data yang di atas surface kartu, dan sel padding 12/10
    // membuat bandnya selebar kartu (padding kartu dipindah ke sel).
    // Label uppercase 11px w700 + letterSpacing: kontras tegas dari data
    // 12px reguler, setara thead di desain.
    // Perataan mengikuti kolom datanya: nama & NIM rata kiri, kedua nilai
    // di tengah.
    Widget headerCell(String label, TextAlign textAlign) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            label.toUpperCase(),
            textAlign: textAlign,
            softWrap: true,
            // "PRETEST SCORE"/"POSTTEST SCORE" boleh dua baris — jangan
            // dipaksa satu baris, itu yang membuat kolom Posttest perlu
            // scroll.
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
    // Sel nama: boleh wrap dan baris boleh tumbuh (break-words di desain).
    Widget nameCell(String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(value, style: const TextStyle(fontSize: 12)),
      );
    }

    // Sel NIM/nilai: satu baris, jangan wrap. Tinggi tetap 18 + FittedBox
    // scale-down mencegah exception overflow saat text scale 1.3 — teksnya
    // yang menyesuaikan, bukan lebar kolom yang memaksa scroll horizontal.
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

    // Sel nilai: — adalah "belum tersedia" (bukan 0), diberi semantics.
    // Nilai yang ada cukup Text: memberi Semantics tanpa label justru
    // menghapus teksnya dari pembaca layar.
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

      if (!context.mounted) {
        return;
      }

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
      if (!context.mounted) {
        return;
      }

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
    final activeClass = ref.read(activeLecturerClassProvider).value;
    final isId = ref.read(languageProvider).languageCode == 'id';

    // Resolve lecturer's name
    final user = supabase.auth.currentUser;
    String? lecturerName = user?.userMetadata?['name']?.toString() ?? user?.userMetadata?['full_name']?.toString();
    if (lecturerName == null && user != null) {
      try {
        final profile = await supabase.from('profiles').select('full_name, name').eq('id', user.id).maybeSingle();
        lecturerName = profile?['full_name']?.toString() ?? profile?['name']?.toString();
      } catch (_) {}
    }

    final path = await LecturerStudentsPdfExporter.generateAndOpenPdf(
      students: students,
      activeClass: activeClass,
      lecturerName: lecturerName,
    );

    if (!context.mounted) return;

    if (path != null) {
      final fileName = path.contains('/') ? path.split('/').last : path.split(r'\').last;
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
        isId
            ? 'Gagal mencetak dokumen PDF'
            : 'Failed to generate PDF document',
        tone: NlSnackTone.error,
      );
    }
  }
}
