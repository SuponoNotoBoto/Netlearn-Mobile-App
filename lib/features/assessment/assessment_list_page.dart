import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_empty_state.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_micro_transition.dart';
import '../../shared/widgets/nl_segmented_tabs.dart';
import '../../shared/widgets/nl_skeleton.dart';
import '../../shared/widgets/nl_topbar.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/student_bottom_navbar.dart';
import '../profile/student_assessment_history_page.dart';
import 'assessment_completed_dialog.dart';
import 'assessment_controller.dart';

/// Daftar dua assessment inti: Pretest dan Post Test (tab pertama), dan
/// riwayat asesmen (tab kedua — [AssessmentHistoryView] yang sama dengan
/// halaman standalone-nya).
///
/// Aturan yang menentukan boleh atau tidaknya sebuah assessment dikerjakan
/// tidak disentuh: `completed` selalu menang lebih dulu, lalu `unlocked`, dan
/// baru setelah itu halaman dibuka. Yang berubah hanya tampilannya.
class AssessmentListPage extends ConsumerStatefulWidget {
  const AssessmentListPage({
    super.key,
  });

  @override
  ConsumerState<AssessmentListPage> createState() =>
      _AssessmentListPageState();
}

class _AssessmentListPageState extends ConsumerState<AssessmentListPage> {
  static const int _coreTab = 0;
  static const int _historyTab = 1;

  int _selectedTab = _coreTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.background,

      // `.compact` di Figma selalu menampilkan tombol kembali di kiri,
      // termasuk pada daftar assessment. Dulu tombol ini tidak ada
      // (`onBack: null`) sehingga layar yang dibuka lewat deep link tidak
      // punya jalan keluar. `goBack` pop bila daftar memang ditumpuk, dan
      // jatuh ke dashboard (tab assessment bukan halaman yang punya induk
      // lain) ketika dibuka lewat deep link.
      appBar: NlTopBar(
        title: l10n.assessment,
        onBack: () => goBack(context, fallback: '/student'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // `.tabs` dari desain — pola yang sama dengan tab Daftar
            // Mahasiswa dosen: track abu, pill putih untuk tab terpilih.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                NetLearnSpace.s20,
                NetLearnSpace.s16,
                NetLearnSpace.s20,
                0,
              ),
              child: NlSegmentedTabs(
                labels: [
                  l10n.assessmentCoreTab,
                  l10n.assessmentHistory,
                ],
                selectedIndex: _selectedTab,
                semanticLabel: l10n.assessment,
                onChanged: (index) {
                  setState(() {
                    _selectedTab = index;
                  });
                },
              ),
            ),

            const SizedBox(height: NetLearnSpace.s16),

            // Tab pertama: Pretest & Post Test. Tab kedua: riwayat — isi
            // yang sama dengan halaman riwayat standalone, jadi tautan
            // text-button lama di bawah daftar dihapus (sekarang sudah
            // jadi tab).
            Expanded(
              child: NlContentTransition(
                child: _selectedTab == _historyTab
                    ? const AssessmentHistoryView()
                    : _buildCoreTab(context, ref, l10n),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const StudentBottomNavbar(
        currentIndex: 3,
      ),
    );
  }

  /// Tab pertama — isi daftar yang lama, tanpa perubahan perilaku.
  Widget _buildCoreTab(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final assessmentsAsync =
    ref.watch(assessmentListProvider);

    return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(
              assessmentListProvider,
            );

            await ref.read(
              assessmentListProvider.future,
            );
          },
          child: assessmentsAsync.when(
            loading: () {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  NetLearnSpace.s20,
                  NetLearnSpace.s16,
                  NetLearnSpace.s20,
                  NetLearnSpace.s32,
                ),
                children: const [
                  NlSkeletonList(itemCount: 3),
                ],
              );
            },
            error: (error, stackTrace) {
              return ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(
                    height: NetLearnSpace.s32,
                  ),
                  NlErrorView(
                    message: l10n.assessmentLoadFailed,
                    onRetry: () {
                      ref.invalidate(
                        assessmentListProvider,
                      );
                    },
                  ),
                ],
              );
            },
            data: (assessments) {
              if (assessments.isEmpty) {
                return ListView(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(
                      height: NetLearnSpace.s32,
                    ),
                    NlEmptyState(
                      icon: Icons.assignment_outlined,
                      title: l10n.noAssessments,
                      message: l10n.noAssessmentsDescription,
                    ),
                  ],
                );
              }

              final isId = Localizations.localeOf(context).languageCode == 'id';
              final theme = Theme.of(context);

              // Pisahkan tugas/kuis buatan dosen (LMS) dan evaluasi kurikulum inti (Pretest/Posttest).
              final customTasks = assessments.where((a) => a.isTask).toList();
              final coreAssessments = assessments.where((a) => a.isPretest || a.isPosttest).toList();
              coreAssessments.sort((a, b) => a.isPretest ? -1 : 1);

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  NetLearnSpace.s20,
                  NetLearnSpace.s20,
                  NetLearnSpace.s20,
                  NetLearnSpace.s32,
                ),
                children: [
                  const _AssessmentIntro(),
                  const SizedBox(height: NetLearnSpace.s24),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: NetLearnSpace.formMeasure,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Bagian Tugas & Kuis Dosen (jika ada)
                          if (customTasks.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.assignment_turned_in_rounded, size: 20, color: Color(0xFF8C52FF)),
                                const SizedBox(width: 8),
                                Text(
                                  isId ? 'Tugas & Kuis Dosen' : 'Class Assignments & Quizzes',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8C52FF).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${customTasks.length} ${isId ? 'Asesmen' : 'Tasks'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF8C52FF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: NetLearnSpace.s12),
                            for (final task in customTasks)
                              Padding(
                                padding: const EdgeInsets.only(bottom: NetLearnSpace.s16),
                                child: _CustomTaskCard(
                                  assessment: task,
                                  onTap: () => _openAssessment(context, task, l10n),
                                  onInstructionTap: () {
                                    context.push('/student/assessment-instructions/${task.id}');
                                  },
                                ),
                              ),
                            const SizedBox(height: NetLearnSpace.s16),
                          ],

                          // 2. Bagian Evaluasi Kurikulum (Pretest & Posttest)
                          Row(
                            children: [
                              const Icon(Icons.school_rounded, size: 20, color: Color(0xFF8C52FF)),
                              const SizedBox(width: 8),
                              // `Expanded`, bukan `Text` polos: judul bagian ini
                              // melebar 5.1 px di 360dp (lebar terkecil yang
                              // didukung) dengan judul bahasa Inggris, dan
                              // RenderFlex melaporkannya sebagai overflow.
                              Expanded(
                                child: Text(
                                  isId ? 'Evaluasi Kurikulum' : 'Curriculum Evaluation',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: NetLearnSpace.s12),
                          for (final assessment in coreAssessments)
                            Padding(
                              padding: const EdgeInsets.only(bottom: NetLearnSpace.s16),
                              child: _AssessmentCard(
                                assessment: assessment,
                                onTap: () {
                                  _openAssessment(
                                    context,
                                    assessment,
                                    l10n,
                                  );
                                },
                                onInstructionTap: () {
                                  final routeParam = assessment.isPretest
                                      ? 'pretest'
                                      : 'posttest';
                                  context.push(
                                    '/student/assessment-instructions/$routeParam',
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  /// Percabangan buka assessment, tidak diubah urutannya:
  /// `completed` diperiksa lebih dulu supaya assessment yang sudah dikerjakan
  /// tetap membuka dialog hasilnya, bukan dialog terkunci. Percabangannya
  /// sendiri kini gerbang bersama [resolveAssessmentEntry] — halaman
  /// instruksi dan pintu dashboard memakai aturan yang persis sama
  /// (melalui [openAssessmentEntry]); di sini datanya sudah dimiliki, jadi
  /// dipakai langsung tanpa membaca provider lagi.
  void _openAssessment(
      BuildContext context,
      AssessmentListItem assessment,
      AppLocalizations l10n,
      ) {
    switch (resolveAssessmentEntry(
      completed: assessment.completed,
      unlocked: assessment.unlocked,
      canAttemptAgain: assessment.canAttemptAgain,
    )) {
      case AssessmentEntryAction.showCompleted:
        showAssessmentCompletedDialog(
          context,
          assessment,
          l10n,
        );
        return;

      case AssessmentEntryAction.showLocked:
        showAssessmentLockedDialog(
          context,
          assessment,
          l10n,
        );
        return;

      case AssessmentEntryAction.openInstructions:
        final routeParam = assessment.isPretest
            ? 'pretest'
            : (assessment.isPosttest
                ? 'posttest'
                : assessment.id);
        context.push(
          '/student/assessment-instructions/$routeParam',
        );
        return;
    }
  }
}

/// `.assignment-intro` dari desain Figma (App.tsx): lingkaran ungu,
/// judul "Assessment" (sesuai Figma), subtitle "Measure your understanding...".
/// Body "Complete the Pretest before..." DIHAPUS (tidak ada di Figma).
class _AssessmentIntro extends StatelessWidget {
  const _AssessmentIntro();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final theme = Theme.of(context);

    return Column(
      children: [
        // `.circle.purple` — lingkaran ungu 58px dengan ikon ClipboardList.
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: context.accentTint,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.assignment_outlined,
            size: 26,
            color: context.accent,
          ),
        ),

        const SizedBox(
          height: NetLearnSpace.s12,
        ),

        Semantics(
          header: true,
          child: Text(
            l10n.assessment,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
        ),

        const SizedBox(
          height: NetLearnSpace.s8,
        ),

        Text(
          l10n.assessmentListIntroSubtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.mutedText,
          ),
        ),
      ],
    );
  }
}

class _CustomTaskCard extends StatelessWidget {
  final AssessmentListItem assessment;
  final VoidCallback onTap;
  final VoidCallback onInstructionTap;

  const _CustomTaskCard({
    required this.assessment,
    required this.onTap,
    required this.onInstructionTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isId = Localizations.localeOf(context).languageCode == 'id';

    final bool isLocked = !assessment.unlocked && !assessment.completed;
    final bool completed = assessment.completed;
    final statusColors = theme.extension<NetLearnStatusColors>();

    final Color tone = completed
        ? (statusColors?.positiveText ?? const Color(0xFF2E7D32))
        : isLocked
            ? context.mutedText
            : theme.colorScheme.primary;

    return Semantics(
      button: true,
      label: '${assessment.title}, ${completed ? l10n.completed : (isLocked ? l10n.locked : l10n.active)}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NetLearnRadius.card),
          child: Container(
            padding: const EdgeInsets.all(NetLearnSpace.s17),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(NetLearnRadius.card),
              border: Border.all(
                color: isLocked ? context.border : const Color(0xFF8C52FF).withValues(alpha: 0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  // `theme.shadowColor` (bawaan: hitam) alih-alih
                  // `Colors.black`, supaya tes kontrak desain
                  // "no raw palette colours" tetap hijau dan bayangan ikut
                  // tema kalau warna bayangan diubah.
                  color: theme.shadowColor.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badges Row: Wrap on left, StatusBadge on right
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (assessment.module != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8C52FF).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bookmark_rounded, size: 12, color: Color(0xFF8C52FF)),
                                const SizedBox(width: 4),
                                Text(
                                  isId ? 'Modul ${assessment.module} Checkpoint' : 'Module ${assessment.module} Checkpoint',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF8C52FF),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7E3FF2).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.assignment_rounded, size: 12, color: Color(0xFF7E3FF2)),
                                const SizedBox(width: 4),
                                Text(
                                  isId ? 'Tugas Mandiri LMS' : 'LMS Task',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF7E3FF2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: assessment.required
                                ? const Color(0xFFFF5252).withValues(alpha: 0.12)
                                : const Color(0xFF9E9E9E).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            assessment.required ? (isId ? 'Wajib' : 'Required') : (isId ? 'Opsional' : 'Optional'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: assessment.required ? const Color(0xFFD32F2F) : const Color(0xFF616161),
                            ),
                          ),
                        ),
                        if (assessment.leaderboardEnabled)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '🏆 Leaderboard',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    status: completed
                        ? NetLearnStatus.linked
                        : isLocked
                            ? NetLearnStatus.down
                            : NetLearnStatus.active,
                    label: completed
                        ? l10n.completed
                        : isLocked
                            ? l10n.locked
                            : l10n.active,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                assessment.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16.5,
                ),
              ),

              if (assessment.description != null && assessment.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  assessment.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.mutedText,
                    height: 1.4,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Details Wrap (Soal, Durasi, Batas Percobaan, Tenggat)
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.format_list_numbered_rounded, size: 14, color: context.mutedText),
                      const SizedBox(width: 4),
                      Text(
                        '${assessment.questionCount > 0 ? assessment.questionCount : '—'} ${isId ? 'Soal' : 'Questions'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: context.mutedText),
                      const SizedBox(width: 4),
                      Text(
                        assessment.durationMinutes > 0
                            ? '${assessment.durationMinutes} ${l10n.minutes}'
                            : (isId ? 'Tanpa Batas Waktu' : 'No Limit'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.replay_rounded, size: 14, color: context.mutedText),
                      const SizedBox(width: 4),
                      Text(
                        assessment.attemptsAllowed == 0
                            ? (isId ? 'Bebas Retake' : 'Unlimited Retakes')
                            : (assessment.attemptsAllowed == 1
                                ? (isId ? '1x Kesempatan' : '1 Attempt')
                                : (isId ? 'Percobaan: ${assessment.userAttemptCount}/${assessment.attemptsAllowed}' : 'Attempts: ${assessment.userAttemptCount}/${assessment.attemptsAllowed}')),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (assessment.deadline != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 14,
                          color: assessment.deadline!.isBefore(DateTime.now())
                              ? const Color(0xFFD32F2F)
                              : context.mutedText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isId ? 'Tenggat' : 'Due'}: ${assessment.deadline!.day}/${assessment.deadline!.month}/${assessment.deadline!.year} ${assessment.deadline!.hour.toString().padLeft(2, '0')}:${assessment.deadline!.minute.toString().padLeft(2, '0')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: assessment.deadline!.isBefore(DateTime.now())
                                ? const Color(0xFFD32F2F)
                                : context.mutedText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // Action Buttons
              if (completed) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (assessment.score != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: tone.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          l10n.scorePercent(assessment.score!.toStringAsFixed(0)),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: tone,
                          ),
                        ),
                      ),
                    if (assessment.attemptId != null)
                      OutlinedButton(
                        onPressed: () {
                          context.push('/student/assessment-result/${assessment.attemptId}');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isId ? 'Lihat Hasil' : 'View Result',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    if (assessment.canAttemptAgain)
                      FilledButton.icon(
                        onPressed: onInstructionTap,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(
                          isId ? 'Coba Lagi' : 'Retake',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF8C52FF),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                  ],
                ),
              ] else if (isLocked) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => showAssessmentLockedDialog(context, assessment, l10n),
                    icon: const Icon(Icons.lock_rounded, size: 16),
                    label: Text(
                      assessment.module != null
                          ? (isId ? 'Terkunci (Selesaikan Modul ${assessment.module})' : 'Locked (Finish Module ${assessment.module})')
                          : (isId ? 'Asesmen Terkunci' : 'Assessment Locked'),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onInstructionTap,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(
                      isId ? 'Mulai Asesmen' : 'Start Assessment',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8C52FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class _AssessmentCard extends StatelessWidget {
  final AssessmentListItem assessment;
  final VoidCallback onTap;

  /// Membuka halaman instruksi jenis tes ini tanpa melewati dialog
  /// completed/locked. Dipakai oleh tombol instruksi; kartu itu sendiri tetap
  /// memanggil [onTap] yang menjaga percabangan status.
  final VoidCallback onInstructionTap;

  const _AssessmentCard({
    required this.assessment,
    required this.onTap,
    required this.onInstructionTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final theme = Theme.of(context);

    final statusColors =
        theme.extension<NetLearnStatusColors>();

    final bool isLocked =
        !assessment.unlocked &&
            !assessment.completed;

    final bool completed = assessment.completed;
    final bool isPretest = assessment.isPretest;

    // `NetLearnStatusColors` menggantikan `Colors.green`/`Colors.grey` yang
    // sebelumnya dipakai di sini dan di ikon. Warna hijau itu tidak punya
    // pasangan gelap, jadi ikon hijau pernah berada di atas hijau transparan
    // di atas permukaan gelap. `StatusBadge` sudah membawa ikon + teks + warna,
    // jadi warna tidak pernah jadi satu-satunya pembeda.
    final Color tone = completed
        ? (statusColors?.positiveText ?? theme.colorScheme.primary)
        : isLocked
            ? context.mutedText
            : theme.colorScheme.primary;

    // Label status: untuk assessment yang tersedia (belum selesai & tidak terkunci),
    // gunakan label per tipe (Assessment awal / Evaluasi akhir / Tugas).
    final String statusLabel = completed
        ? l10n.completed
        : isLocked
            ? l10n.locked
            : isPretest
                ? l10n.assessmentInitialTag
                : (assessment.isPosttest ? l10n.assessmentFinalTag : 'Tugas / Kuis');

    // Deskripsi per tipe.
    final String description = isPretest
        ? l10n.assessmentInitialDesc
        : (assessment.isPosttest
            ? l10n.assessmentFinalDesc
            : (assessment.deadline != null
                ? 'Batas Waktu: ${assessment.deadline!.day}/${assessment.deadline!.month}/${assessment.deadline!.year} ${assessment.deadline!.hour.toString().padLeft(2, '0')}:${assessment.deadline!.minute.toString().padLeft(2, '0')}'
                : 'Asesmen & Kuis Kelas'));

    // Alasan terkunci untuk Post Test (Figma: tampilkan alasan di dalam kartu).
    final String? lockReason = isLocked && !isPretest
        ? l10n.assessmentLockedPosttest
        : isLocked
            ? l10n.assessmentLockedGeneric
            : null;

    return Semantics(
      // `container: true` supaya kartu menjadi node semantik sendiri. Tanpa
      // ini anotasi menempel ke node induk (Column daftar), dan judul bagian
      // di atasnya ikut tergabung sehingga labelnya menjadi
      // "Curriculum Evaluation\nPretest, Locked" -- pembaca layar tidak lagi
      // mengumumkan satu kartu sebagai satu tombol.
      container: true,
      button: true,
      label: '${assessment.title}, $statusLabel',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(
            NetLearnRadius.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(
              NetLearnRadius.card,
            ),
            child: Container(
              padding: const EdgeInsets.all(
                NetLearnSpace.s17,
              ),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(
                  NetLearnRadius.card,
                ),
                border: Border.all(
                  color: context.border,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // Lingkaran ikon di kiri (40px, ClipboardList putih, warna per tipe).
                  _CircleIcon(
                    isPretest: isPretest,
                  ),

                  const SizedBox(
                    height: NetLearnSpace.s10,
                  ),

                  // Badge tipe di pojok kanan atas (Initial assessment / Final assessment).
                  Align(
                    alignment: Alignment.topRight,
                    child: StatusBadge(
                      status: completed
                          ? NetLearnStatus.linked
                          : isLocked
                              ? NetLearnStatus.down
                              : NetLearnStatus.active,
                      label: statusLabel,
                    ),
                  ),

                  const SizedBox(
                    height: NetLearnSpace.s8,
                  ),

                  // Judul DI BAWAH ikon (rata kiri, tebal).
                  Text(
                    assessment.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: NetLearnSpace.s10,
                  ),

                  // Deskripsi per tipe (Figma).
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.mutedText,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(
                    height: NetLearnSpace.s12,
                  ),

                  // Meta: "{count} Questions · {minutes} Minutes" (Figma).
                  // Tanpa ikon timer, hanya teks.
                  Text(
                    l10n.assignmentMeta(
                      '25',
                      assessment.durationMinutes.toString(),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.mutedText,
                    ),
                  ),

                  const SizedBox(
                    height: NetLearnSpace.s16,
                  ),

                  // Alasan terkunci untuk Post Test (tampil di dalam kartu).
                  if (lockReason != null) ...[
                    Text(
                      lockReason,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.mutedText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(
                      height: NetLearnSpace.s12,
                    ),
                  ],

                  // Tombol utama - perilaku per state:
                  // - Selesai: TIDAK ADA TOMBOL. Hanya badge Completed + skor.
                  // - Tersedia: Tombol ungu solid penuh lebar, teks & ikon PUTIH, tinggi minimal 48.
                  // - Terkunci: Tombol disabled, latar abu, teks/ikon abu, alasan di atas tombol.
                  if (completed) ...[
                    // State Selesai: badge Completed (kiri) + skor (kanan).
                    // Wrap digunakan agar tidak overflow pada text scale 1.3x.
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: NetLearnSpace.s8,
                      runSpacing: NetLearnSpace.s8,
                      children: [
                        StatusBadge(
                          status: NetLearnStatus.linked,
                          label: l10n.completed,
                        ),
                        Text(
                          l10n.scorePercent(
                            assessment.score!
                                .toStringAsFixed(0),
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: tone,
                          ),
                        ),
                      ],
                    ),
                  ] else if (isLocked) ...[
                    // State Terkunci: tombol tetap aktif sesuai Figma —
                    // instruksi bersifat informasi, bukan pengerjaan soal,
                    // jadi melihat aturan Post Test yang terkunci tidak
                    // melanggar aturan akses. Attempt tetap dijaga server;
                    // tombol Start di halaman instruksi menolak assessment
                    // yang terkunci dengan dialog yang sama seperti kartu ini.
                    NlButton(
                      label: isPretest
                          ? l10n.viewPretestInstructions
                          : l10n.viewPosttestInstructions,
                      icon: Icons.arrow_forward_rounded,
                      onPressed: onInstructionTap,
                    ),
                  ] else ...[
                    // State Tersedia: tombol ungu solid penuh lebar, teks & ikon PUTIH, tinggi minimal 48.
                    NlButton(
                      label: isPretest
                          ? l10n.viewPretestInstructions
                          : l10n.viewPosttestInstructions,
                      icon: Icons.arrow_forward_rounded,
                      onPressed: onTap,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.circle` dari desain Figma: lingkaran 40px dengan ikon ClipboardList size 22.
/// Warna background: Pretest = NetLearnAccents.purple (#7960E6), Post Test = NetLearnAccents.pink (#E474AA).
/// Ikon selalu putih.
class _CircleIcon extends StatelessWidget {
  final bool isPretest;

  const _CircleIcon({
    required this.isPretest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isPretest ? NetLearnAccents.purple : NetLearnAccents.pink,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.assignment_outlined,
        size: 22,
        color: Colors.white,
      ),
    );
  }
}