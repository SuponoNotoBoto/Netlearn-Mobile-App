import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/student_model.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_empty_state.dart';
import '../../shared/widgets/nl_skeleton.dart';
import '../../shared/widgets/nl_topbar.dart';
import 'lecturer_ai_service.dart';
import 'lecturer_bottom_navbar.dart';
import 'lecturer_students_controller.dart';
import 'lecturer_students_csv.dart';

/// Halaman "Rekap Nilai Mahasiswa": detail nilai Pretest/Posttest satu
/// mahasiswa — pengganti bottom sheet di list lama, mengikuti varian lecturer
/// dari `StudentProgress.tsx`.
///
/// Sengaja TIDAK query ulang ke Supabase: datanya dibaca dari
/// `lecturerStudentsProvider(null)` yang sama dengan Student List, sehingga
/// angka di sini tidak mungkin berbeda dari tabelnya.
///
/// Second-level page: kembali lewat NlTopBar dan tombol
/// "Kembali ke Daftar Mahasiswa". Navbar bawah dipertahankan (tab Profil
/// aktif) karena screenshot juga menampilkannya di halaman detail.
class LecturerStudentScoreDetailPage extends ConsumerWidget {
  final String studentId;

  const LecturerStudentScoreDetailPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final studentsAsync = ref.watch(lecturerStudentsProvider(null));

    return Scaffold(
      backgroundColor: context.background,
      appBar: NlTopBar(
        title: l10n.studentScoreSummary,
        onBack: () => context.pop(),
      ),
      bottomNavigationBar:
          LecturerBottomNavbar(currentIndex: _LecturerStudentListNav.profileNavIndex),
      body: studentsAsync.when(
        loading: () => const NlSkeletonList(
          itemCount: 4,
          padding: EdgeInsets.all(NetLearnSpace.s20),
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
          StudentModel? student;
          for (final candidate in students) {
            if (candidate.id == studentId) {
              student = candidate;
              break;
            }
          }

          if (student == null) {
            return _buildStudentMissing(context, l10n);
          }

          return _buildContent(context, l10n, student);
        },
      ),
    );
  }

  /// StudentId tak dikenal (mis. pull-to-refresh menemukan roster yang sudah
  /// berubah): bukan crash — state kosong + tombol kembali.
  Widget _buildStudentMissing(BuildContext context, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(NetLearnSpace.s24),
      children: [
        NlEmptyState(
          icon: Icons.people_outline,
          title: l10n.studentList,
          message: l10n.noStudentsFound,
        ),
        const SizedBox(height: NetLearnSpace.s16),
        NlButton(
          label: l10n.backToStudentList,
          variant: NlButtonVariant.secondary,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    StudentModel student,
  ) {
    final isIndonesian = Localizations.localeOf(context).languageCode == 'id';
    final theme = Theme.of(context);

    final scores = [
      student.pretestScore,
      student.posttestScore,
    ].whereType<double>().toList();

    final gradedCount = scores.length;
    final average = gradedCount == 0
        ? null
        : scores.reduce((a, b) => a + b) / gradedCount;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        NetLearnSpace.s20,
        NetLearnSpace.s16,
        NetLearnSpace.s20,
        NetLearnSpace.s32,
      ),
      children: [
        // Judul section. Di prototipe ini satu-satunya judul karena frame
        // Figma tidak punya top bar; di sini top bar sudah memuat judul yang
        // sama, tetap dipertahankan agar selaras dengan instruksi layout.
        Text(
          l10n.studentScoreSummary,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: NetLearnSpace.s12),

        // Kartu profil.
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(NetLearnRadius.card),
            border: Border.all(color: context.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (student.identityNumber != null &&
                  student.identityNumber!.isNotEmpty) ...[
                const SizedBox(height: NetLearnSpace.s4),
                Text(
                  'NIM: ${student.identityNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.mutedText,
                  ),
                ),
              ],
              const SizedBox(height: NetLearnSpace.s8),
              Text(
                l10n.studentScoreHistoryIntro,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.mutedText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NetLearnSpace.s12),

        // Kartu metrik `.metrics`: jumlah bernilai + rata-rata nilai tersedia.
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: _Metric(
                  value: gradedCount.toString(),
                  label: l10n.assessmentsCompleted,
                ),
              ),
              const SizedBox(width: NetLearnSpace.s12),
              Expanded(
                child: _Metric(
                  value: average?.toStringAsFixed(1) ?? '—',
                  label: l10n.averageAvailableScore,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NetLearnSpace.s16),

        // Baris status: "x/2 · Selesai" atau "x/2 · Assessment belum selesai".
        Text(
          '$gradedCount/2 · '
          '${gradedCount == 2 ? l10n.completed : l10n.assessmentsIncomplete}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.mutedText,
          ),
        ),
        const SizedBox(height: NetLearnSpace.s16),

        if (gradedCount == 0) ...[
          _HistoryEmptyCard(l10n: l10n),
          const SizedBox(height: NetLearnSpace.s16),
        ],

        _AssessmentCard(
          title: l10n.pretest,
          assessmentType: 'pretest',
          score: student.pretestScore,
          submittedAt: student.pretestSubmittedAt,
          isIndonesian: isIndonesian,
        ),
        const SizedBox(height: NetLearnSpace.s12),
        _AssessmentCard(
          title: l10n.posttest,
          assessmentType: 'posttest',
          score: student.posttestScore,
          submittedAt: student.posttestSubmittedAt,
          isIndonesian: isIndonesian,
        ),
        const SizedBox(height: NetLearnSpace.s16),

        _StudentAiInsightCard(
          student: student,
          isIndonesian: isIndonesian,
        ),
        const SizedBox(height: NetLearnSpace.s16),

        NlButton(
          label: l10n.backToStudentList,
          variant: NlButtonVariant.secondary,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}

/// Satu angka `.metrics`: 17px ungu bold di atas label 9px muted.
class _Metric extends StatelessWidget {
  final String value;
  final String label;

  const _Metric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.accent,
          ),
        ),
        const SizedBox(height: NetLearnSpace.s4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: context.mutedText,
          ),
        ),
      ],
    );
  }
}

/// Kartu informasi saat belum ada nilai sama sekali — latar tint aksen,
/// persis kartu "Belum ada riwayat" di screenshot.
class _HistoryEmptyCard extends StatelessWidget {
  final AppLocalizations l10n;

  const _HistoryEmptyCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NetLearnSpace.s15),
      decoration: BoxDecoration(
        color: context.accentTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: context.accent),
          const SizedBox(width: NetLearnSpace.s12),
          Expanded(
            child: Text(
              l10n.noAssessmentHistory,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.onAccentTint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu satu asesmen: judul + badge status, `Nilai: x/100`, tanggal submit.
class _AssessmentCard extends StatelessWidget {
  final String title;
  final String assessmentType;
  final double? score;
  final DateTime? submittedAt;
  final bool isIndonesian;

  const _AssessmentCard({
    required this.title,
    required this.assessmentType,
    required this.score,
    required this.submittedAt,
    required this.isIndonesian,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDone = score != null;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.onSurface,
                  ),
                ),
              ),
              _StatusBadge(isDone: isDone),
            ],
          ),
          const SizedBox(height: NetLearnSpace.s8),
          Text(
            '${l10n.score}: '
            '${score == null ? '—' : '${formatScoreValue(score!)}/100'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (submittedAt != null) ...[
            const SizedBox(height: NetLearnSpace.s4),
            Text(
              _formatSubmittedAt(submittedAt!, isIndonesian),
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.mutedText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// `20 Okt 2026 • 09.30` — gaya tanggal yang sama dengan pengingat
  /// (bulan disingkat lokal, jam dua digit dipisah titik).
  String _formatSubmittedAt(DateTime date, bool isIndonesian) {
    const monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const monthsId = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final months = isIndonesian ? monthsId : monthsEn;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '${date.day} ${months[date.month - 1]} ${date.year} • $hour.$minute';
  }
}

/// Status pill: Selesai (hijau) / Belum Dimulai (netral) — pasangan warna
/// dari `NetLearnStatusColors`, bukan skema baru.
class _StatusBadge extends StatelessWidget {
  final bool isDone;

  const _StatusBadge({required this.isDone});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).statusColors;
    final bg = isDone ? colors.positiveBg : colors.neutralBg;
    final fg = isDone ? colors.positiveText : colors.neutralText;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NetLearnSpace.s8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(NetLearnRadius.badge),
      ),
      child: Text(
        isDone ? l10n.completed : l10n.notStarted,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

/// Indeks navbar yang disorot di halaman-halaman daftar mahasiswa (Profil).
/// Dipisah supaya halaman detail bisa memakai angka yang sama.
class _LecturerStudentListNav {
  static const profileNavIndex = 4;
}

class _StudentAiInsightCard extends StatefulWidget {
  final StudentModel student;
  final bool isIndonesian;

  const _StudentAiInsightCard({
    required this.student,
    required this.isIndonesian,
  });

  @override
  State<_StudentAiInsightCard> createState() => _StudentAiInsightCardState();
}

class _StudentAiInsightCardState extends State<_StudentAiInsightCard> {
  bool _loading = false;
  LecturerScoreAnalyticsResult? _result;
  String? _error;

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await LecturerAiService.analyzeIndividualStudent(
        student: widget.student,
        languageCode: widget.isIndonesian ? 'id' : 'en',
      );
      if (!mounted) return;
      setState(() {
        _result = res;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = widget.isIndonesian
            ? 'Gagal menganalisis nilai mahasiswa. Silakan coba lagi.'
            : 'Failed to analyze student scores. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isId = widget.isIndonesian;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.accentTint.withAlpha(110),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.accent.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: context.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isId
                      ? 'Evaluasi & Rekomendasi AI Personal'
                      : 'Personal AI Diagnostic & Mentoring',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_result != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border),
              ),
              child: SelectableText(
                _result!.markdownInsight,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_error != null) ...[
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 12,
                color: NetLearnColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: NlButton(
              label: _result == null
                  ? (isId ? 'Analisis Mahasiswa dengan AI ✨' : 'Analyze Student with AI ✨')
                  : (isId ? 'Perbarui Analisis AI' : 'Refresh AI Analysis'),
              icon: Icons.psychology_alt_outlined,
              loading: _loading,
              onPressed: _loading ? null : _analyze,
            ),
          ),
        ],
      ),
    );
  }
}
