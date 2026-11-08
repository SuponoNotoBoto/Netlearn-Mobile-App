import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/localization/language_controller.dart';
import '../../core/router/safe_back.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_stats_strip.dart';
import '../../shared/widgets/nl_topbar.dart';
import '../../shared/widgets/status_badge.dart';
import 'student_profile_controller.dart';

/// One submitted attempt listed on the assessment history page.
class AssessmentHistoryRecord {
  final String attemptId;
  final String quizId;
  final String title;
  final String assessmentType;
  final double? score;
  final bool? passed;
  final DateTime? submittedAt;

  const AssessmentHistoryRecord({
    required this.attemptId,
    required this.quizId,
    required this.title,
    required this.assessmentType,
    required this.score,
    required this.passed,
    required this.submittedAt,
  });

  bool get isPretest => assessmentType == 'pretest';
}

// The history relies on the same `quiz_attempts` read the assessment
// controller performs for the list, so RLS already lets the student fetch
// their own attempts. The quiz titles keep the same locale preference order
// used everywhere else on the student side (_en for English, then the base
// Indonesian column).
final assessmentHistoryProvider =
    FutureProvider.autoDispose<List<AssessmentHistoryRecord>>((ref) async {
  final user = supabase.auth.currentUser;

  if (user == null) {
    return const [];
  }

  final languageCode = ref.watch(languageProvider).languageCode;

  final attempts = await supabase
      .from('quiz_attempts')
      .select('id, quiz_id, status, submitted_at, score, passed')
      .eq('user_id', user.id)
      .eq('status', 'submitted')
      .order('submitted_at', ascending: false);

  if (attempts.isEmpty) {
    return const [];
  }

  final quizIds = <String>{};
  for (final raw in attempts) {
    quizIds.add((raw as Map)['quiz_id'].toString());
  }

  final quizzes = await supabase
      .from('quizzes')
      .select('id, title, title_en, title_id, assessment_type')
      .inFilter('id', quizIds.toList());

  final quizById = <String, Map<String, dynamic>>{};
  for (final raw in quizzes) {
    final quiz = Map<String, dynamic>.from(raw as Map);
    quizById[quiz['id'].toString()] = quiz;
  }

  String localizedTitle(Map<String, dynamic> quiz) {
    final String? localized = languageCode == 'id'
        ? quiz['title_id']?.toString()
        : quiz['title_en']?.toString();

    if (localized != null && localized.trim().isNotEmpty) {
      return localized.trim();
    }

    return quiz['title']?.toString().trim() ?? '';
  }

  return [
    for (final raw in attempts)
      () {
        final attempt = Map<String, dynamic>.from(raw as Map);
        final quiz = quizById[attempt['quiz_id'].toString()] ?? const {};

        return AssessmentHistoryRecord(
          attemptId: attempt['id'].toString(),
          quizId: attempt['quiz_id'].toString(),
          title: localizedTitle(quiz),
          assessmentType: quiz['assessment_type']?.toString() ?? 'pretest',
          score: (attempt['score'] as num?)?.toDouble(),
          passed: attempt['passed'] as bool?,
          submittedAt: attempt['submitted_at'] == null
              ? null
              : DateTime.tryParse(attempt['submitted_at'].toString()),
        );
      }(),
  ];
});

/// Status dua assessment inti (Pretest & Post Test) untuk halaman riwayat,
/// dihitung dari attempt yang benar-benar diserahkan mahasiswa yang sama.
///
/// Fungsi murni supaya bisa diuji tanpa Supabase: [records] sudah berurutan
/// dari yang terbaru (urutan yang [assessmentHistoryProvider] berikan), jadi
/// attempt pertama per jenis tes adalah skornya yang terbaru.
class CoreAssessmentHistory {
  final AssessmentHistoryRecord? pretest;
  final AssessmentHistoryRecord? posttest;

  const CoreAssessmentHistory({
    required this.pretest,
    required this.posttest,
  });

  /// Pretest dan Post Test adalah dua assessment inti — jumlah "x/2" yang
  /// dirujuk Figma. Attempt untuk kuis jenis lain (misal tugas) tidak menghitung.
  int get completedCount => [
        pretest,
        posttest,
      ].where((record) => record != null).length;

  /// Rata-rata skor terbaru per assessment inti; `null` ketika belum ada
  /// satu pun skor, sehingga pemanggil bisa menampilkan "—".
  double? get averageScore {
    final scores = [
      pretest?.score,
      posttest?.score,
    ].whereType<double>().toList();

    if (scores.isEmpty) {
      return null;
    }

    return scores.reduce((a, b) => a + b) / scores.length;
  }
}

CoreAssessmentHistory summarizeCoreAssessments(
  List<AssessmentHistoryRecord> records,
) {
  AssessmentHistoryRecord? pretest;
  AssessmentHistoryRecord? posttest;

  // Records sudah termuda-dahulu, jadi attempt pertama per jenis tes
  // otomatis yang terbaru.
  for (final record in records) {
    if (record.assessmentType == 'pretest') {
      pretest ??= record;
    } else if (record.assessmentType == 'posttest') {
      posttest ??= record;
    }
  }

  return CoreAssessmentHistory(pretest: pretest, posttest: posttest);
}

/// Transkrip pretest & post test milik mahasiswa yang sedang login.
///
/// Daftar ini hanya berisi attempt berstatus `submitted` milik user itu sendiri,
/// diurutkan dari yang terbaru. Layout mengikuti Figma `Assessment History
/// (96-967)`: heading, kartu identitas, dua metrik ringkasan, lalu baris
/// status per assessment inti — dan di bawahnya daftar attempt nyata yang
/// bisa dibuka halaman hasilnya ([AssessmentResultPage]) seperti sebelumnya.
/// Isi riwayat asesmen tanpa top bar — dipakai dua kali:
/// jalan pintu [StudentAssessmentHistoryPage] (halaman standalone yang
/// di-push dari dashboard/profil) dan tab kedua halaman daftar assessment
/// (`assessment_list_page.dart`). Ekstraksi ini yang membuat kedua tempat
/// menampilkan isi yang persis sama tanpa salin-tempel.
///
/// Riwayat gagal dimuat tetap harus bisa dibuka: bagian identitas
/// dan status inti diringkas dengan placeholder, dan bagian
/// attempt memakai view error dengan tombol coba lagi.
class AssessmentHistoryView extends ConsumerWidget {
  const AssessmentHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(assessmentHistoryProvider);

    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => NlErrorView(
        message: AppLocalizations.of(context)!.failedToLoad,
        onRetry: () {
          ref.invalidate(assessmentHistoryProvider);
        },
      ),
      data: (records) {
        final core = summarizeCoreAssessments(records);

        return _HistoryContent(
          records: records,
          core: core,
        );
      },
    );
  }
}

class StudentAssessmentHistoryPage extends ConsumerWidget {
  const StudentAssessmentHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          goBack(context);
        }
      },
      child: Scaffold(
        backgroundColor: context.background,
        appBar: NlTopBar(
          title: AppLocalizations.of(context)!.assessmentHistory,
          onBack: () => goBack(context),
        ),
        body: const AssessmentHistoryView(),
      ),
    );
  }
}

class _HistoryContent extends ConsumerWidget {
  final List<AssessmentHistoryRecord> records;
  final CoreAssessmentHistory core;

  const _HistoryContent({
    required this.records,
    required this.core,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final profileAsync = ref.watch(studentProfileProvider);

    final String name;
    final String studentId;
    // Identitas mengikuti provider yang sama dengan halaman Profile, jadi
    // kalau profiles gagal dibaca, kartu tidak mengarang nama atau NIM.
    final bool identityLoaded = profileAsync.value != null;

    if (identityLoaded) {
      name = profileAsync.value!['name']?.toString() ?? '—';
      studentId = profileAsync.value!['identity_number']?.toString() ?? '—';
    } else {
      name = '—';
      studentId = '—';
    }

    final average = core.averageScore;

    final averageValue = average == null ? '—' : average.round().toString();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        NetLearnSpace.s20,
        NetLearnSpace.s20,
        NetLearnSpace.s20,
        NetLearnSpace.s32,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.assessmentHistory,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),

        const SizedBox(height: NetLearnSpace.s16),

        // Kartu identitas (Figma: nama, Student ID, satu baris penjelasan).
        _IdentityCard(
          name: name,
          studentIdLabel: l10n.historyStudentId,
          studentId: studentId,
          subtitle: l10n.assessmentHistorySubtitle,
        ),

        const SizedBox(height: NetLearnSpace.s12),

        // Dua metrik ringkasan (Figma: jumlah assessment selesai dan rata-rata
        // skor yang tersedia) — dihitung dari attempt yang sama dengan daftar
        // di bawah, bukan dari sumber baru.
        NlStatsStrip(
          items: [
            NlStatsStripItem(
              value: core.completedCount.toString(),
              label: l10n.historyCompletedLabel,
              semanticLabel: '${l10n.historyCompletedLabel} ${core.completedCount}',
            ),
            NlStatsStripItem(
              value: averageValue,
              label: l10n.historyAverageLabel,
              semanticLabel: '${l10n.historyAverageLabel} $averageValue',
            ),
          ],
        ),

        const SizedBox(height: NetLearnSpace.s12),

        // Caption "0/2 · Assessments not complete" (Figma). Ketika keduanya
        // sudah selesai, strip metrik di atas sudah menyatakan 2, jadi caption
        // tidak perlu mengulanginya.
        if (core.completedCount < 2)
          Text(
            l10n.historyCoreIncomplete(core.completedCount.toString()),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.mutedText,
            ),
          ),

        if (records.isEmpty) ...[
          const SizedBox(height: NetLearnSpace.s12),
          // Ajakan saat belum ada attempt (Figma).
          _NoticeCard(message: l10n.assessmentHistoryEmpty),
        ],

        const SizedBox(height: NetLearnSpace.s12),

        _AssessmentStatusCard(
          title: l10n.historyPretestTitle,
          record: core.pretest,
          notStartedLabel: l10n.notStarted,
          completedLabel: l10n.completed,
          scoreLabel: l10n.historyScoreLabel,
        ),

        const SizedBox(height: NetLearnSpace.s12),

        _AssessmentStatusCard(
          title: l10n.historyPosttestTitle,
          record: core.posttest,
          notStartedLabel: l10n.notStarted,
          completedLabel: l10n.completed,
          scoreLabel: l10n.historyScoreLabel,
        ),

        // Daftar attempt nyata di bawah ringkasan: satu kartu per attempt,
        // bisa dibuka halaman hasilnya — perilaku yang sudah ada dipertahankan.
        for (final record in records) ...[
          const SizedBox(height: NetLearnSpace.s12),
          _HistoryCard(record: record),
        ],
      ],
    );
  }
}

/// Kartu identitas di atas halaman (Figma `96-967`).
class _IdentityCard extends StatelessWidget {
  final String name;
  final String studentIdLabel;
  final String studentId;
  final String subtitle;

  const _IdentityCard({
    required this.name,
    required this.studentIdLabel,
    required this.studentId,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NetLearnSpace.s14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: NetLearnSpace.s6),
          Text(
            '$studentIdLabel: $studentId',
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.mutedText,
            ),
          ),
          const SizedBox(height: NetLearnSpace.s4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Papan pemberitahuan putih ketika belum ada riwayat (Figma).
class _NoticeCard extends StatelessWidget {
  final String message;

  const _NoticeCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NetLearnSpace.s14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: context.mutedText,
          height: 1.5,
        ),
      ),
    );
  }
}

/// Baris status satu assessment inti (Figma: judul tebal, badge di kanan,
/// baris "Score: —").
class _AssessmentStatusCard extends StatelessWidget {
  final String title;
  final AssessmentHistoryRecord? record;
  final String notStartedLabel;
  final String completedLabel;
  final String scoreLabel;

  const _AssessmentStatusCard({
    required this.title,
    required this.record,
    required this.notStartedLabel,
    required this.completedLabel,
    required this.scoreLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final submitted = record != null;
    final score = submitted ? record!.score : null;
    final scoreText = score == null ? '—' : score.round().toString();

    return Semantics(
      label: '$title, ${submitted ? completedLabel : notStartedLabel}, '
          '$scoreLabel $scoreText',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(NetLearnSpace.s14),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: NetLearnSpace.s8),
                if (submitted)
                  StatusBadge(
                    status: NetLearnStatus.linked,
                    label: completedLabel,
                  )
                else
                  _NeutralBadge(label: notStartedLabel),
              ],
            ),
            const SizedBox(height: NetLearnSpace.s6),
            Text(
              '$scoreLabel $scoreText',
              style: theme.textTheme.bodySmall?.copyWith(
                color: submitted ? context.onSurface : context.mutedText,
                fontWeight: score == null ? null : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge netral abu untuk status belum mulai — StatusBadge tidak punya
/// varian abu, dan `active` (titik ungu) akan berarti status lain.
class _NeutralBadge extends StatelessWidget {
  final String label;

  const _NeutralBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: context.mutedText.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(NetLearnRadius.badge),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: context.mutedText,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Kartu satu attempt yang bisa dibuka halaman hasil + pembahasannya.
class _HistoryCard extends StatelessWidget {
  final AssessmentHistoryRecord record;

  const _HistoryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final typeLabel = record.isPretest ? l10n.pretest : l10n.posttest;
    final typeIcon = record.isPretest
        ? Icons.play_circle_outline_rounded
        : Icons.flag_outlined;
    final submittedAt = record.submittedAt;
    final dateText = submittedAt == null
        ? '—'
        : DateFormat('d MMM yyyy').format(submittedAt);
    final scoreText = record.score?.round().toString() ?? '—';

    return Semantics(
      button: true,
      label: '${record.title}, $typeLabel, $dateText, $scoreText',
      child: InkWell(
        onTap: () {
          context.push('/student/assessment-result/${record.attemptId}');
        },
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(NetLearnSpace.s14),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(NetLearnRadius.card),
            border: Border.all(color: context.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.accentTint,
                  borderRadius: BorderRadius.circular(NetLearnRadius.card),
                ),
                child: Icon(typeIcon, size: 20, color: context.accent),
              ),
              const SizedBox(width: NetLearnSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: NetLearnSpace.s4),
                    Text(
                      '$typeLabel · $dateText',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: NetLearnSpace.s8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    scoreText,
                    style: NetLearnDisplay.stat.copyWith(
                      fontSize: 18,
                      color: _scoreColor(context),
                    ),
                  ),
                  if (record.passed != null) ...[
                    const SizedBox(height: NetLearnSpace.s4),
                    Text(
                      record.passed! ? l10n.passed : l10n.failed,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _scoreColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _scoreColor(BuildContext context) {
    if (record.passed == null) {
      return context.onSurface;
    }

    return record.passed!
        ? NetLearnColors.success
        : NetLearnColors.danger;
  }
}
