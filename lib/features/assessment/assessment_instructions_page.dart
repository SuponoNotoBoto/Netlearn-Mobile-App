import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_skeleton.dart';
import '../../shared/widgets/nl_topbar.dart';
import '../../shared/widgets/student_bottom_navbar.dart';
import 'assessment_completed_dialog.dart';
import 'assessment_controller.dart';

/// Layar instruksi Pretest dan Posttest (desain Figma `screen === 'pretest'`).
///
/// Halaman ini hanya menampilkan aturan sebelum soal dimulai; ia tidak membuat
/// attempt apa pun. Attempt baru dibuat ketika tombol "Mulai ... Sekarang"
/// membuka [AssessmentPage], yang berarti aturan "kapan attempt dimulai"
/// (dan batas satu kali percobaan) tetap dijaga oleh controller yang sama.
///
/// Setiap jenis tes membawa salinannya sendiri (`_InstructionsCopy`), jadi
/// tombol "View Pretest Instructions" dan "View Posttest Instructions" di
/// daftar assessment tidak pernah mendarat di instruksi jenis yang sama.
class AssessmentInstructionsPage extends ConsumerWidget {
  final String assessmentType;

  const AssessmentInstructionsPage({
    super.key,
    required this.assessmentType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final assessmentAsync =
        ref.watch(assessmentByTypeProvider(assessmentType));

    final isId = Localizations.localeOf(context).languageCode == 'id';
    final isPretestRoute = assessmentType == 'pretest';
    final isPosttestRoute = assessmentType == 'posttest';

    final copy = _copyFor(
      l10n,
      isPretest: isPretestRoute,
      isPosttest: isPosttestRoute,
      isId: isId,
    );

    final displayTitle =
        assessmentAsync.asData?.value?.title ?? copy.topBarTitle;

    return Scaffold(
      backgroundColor: context.background,

      // `.compact` menaruh tombol kembali di kiri. `goBack` pop instruksi bila
      // ditumpuk dari daftar, dan jatuh ke daftar assessment (induk logisnya)
      // ketika halaman ini dibuka langsung lewat deep link.
      appBar: NlTopBar(
        title: displayTitle,
        onBack: () => goBack(context, fallback: '/student/assessment'),
      ),
      body: SafeArea(
        child: assessmentAsync.when(
          loading: () {
            return const NlSkeletonDetail(showBanner: false, paragraphBlocks: 3);
          },
          error: (error, stackTrace) {
            return _errorList(
              ref,
              l10n,
            );
          },
          data: (assessment) {
            if (assessment == null) {
              return _errorList(
                ref,
                l10n,
              );
            }

            final actualCopy = _copyFor(
              l10n,
              assessment: assessment,
              isPretest: assessment.isPretest,
              isId: isId,
            );

            return _InstructionsContent(
              assessment: assessment,
              copy: actualCopy,
            );
          },
        ),
      ),
      bottomNavigationBar: const StudentBottomNavbar(
        currentIndex: 3,
      ),
    );
  }

  /// Daftar yang tetap bisa di-`RefreshIndicator`-kan saat instruksi gagal
  /// dimuat, sama seperti daftar assessment.
  Widget _errorList(
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: NetLearnSpace.s32),
        NlErrorView(
          message: l10n.assessmentLoadFailed,
          onRetry: () {
            ref.invalidate(assessmentListProvider);
          },
        ),
      ],
    );
  }
}

/// Salinan teks satu halaman instruksi, dipilih per jenis tes.
///
/// Label "jumlah soal / waktu / jenis soal" tidak ikut di sini: ketiganya
/// netral dan dipakai bersama dari kunci `pretestInstructions*Label/Value`
/// karena teksnya identik untuk kedua jenis tes.
class _InstructionsCopy {
  final String topBarTitle;
  final String artLabel;
  final String title;
  final String body;
  final String warningPrefix;
  final String warningEmphasis;
  final String warningSuffix;
  final String lockTitle;
  final String lockBody;
  final String startLabel;

  const _InstructionsCopy({
    required this.topBarTitle,
    required this.artLabel,
    required this.title,
    required this.body,
    required this.warningPrefix,
    required this.warningEmphasis,
    required this.warningSuffix,
    required this.lockTitle,
    required this.lockBody,
    required this.startLabel,
  });
}

_InstructionsCopy _copyFor(
  AppLocalizations l10n, {
  AssessmentListItem? assessment,
  bool isPretest = false,
  bool isPosttest = false,
  bool isId = true,
}) {
  if (assessment != null && assessment.isTask) {
    final title = assessment.title;
    final attempts = assessment.attemptsAllowed;
    final attemptsDesc = attempts == 0
        ? (isId ? 'Percobaan: Bebas (Latihan Mandiri)' : 'Attempts: Unlimited Practice')
        : (attempts == 1
            ? (isId ? 'Perhatian: Ujian resmi 1x kesempatan pengerjaan.' : 'Note: Official exam, single attempt only.')
            : (isId ? 'Perhatian: Anda memiliki maksimal $attempts kali kesempatan.' : 'Note: You have a maximum of $attempts attempts.'));

    final lockInfo = assessment.module != null
        ? (isId
            ? 'Kuis Modul ${assessment.module}'
            : 'Module ${assessment.module} Quiz')
        : (isId ? 'Tugas / Kuis Dosen' : 'Assignment / Quiz');

    final lockDesc = assessment.required
        ? (isId
            ? 'Asesmen ini wajib diselesaikan untuk membuka modul materi berikutnya.'
            : 'This assessment is required to unlock the next module.')
        : (isId
            ? 'Asesmen mandiri untuk memperdalam pemahaman materi jaringan komputer.'
            : 'Self-paced assessment to deepen your understanding of networking concepts.');

    return _InstructionsCopy(
      topBarTitle: title,
      artLabel: lockInfo,
      title: title,
      body: assessment.description ??
          assessment.instructions ??
          (isId
              ? 'Kerjakan soal-soal asesmen ini dengan teliti sesuai instruksi.'
              : 'Complete this assessment carefully according to instructions.'),
      warningPrefix: attemptsDesc,
      warningEmphasis: '',
      warningSuffix: '',
      lockTitle: lockInfo,
      lockBody: lockDesc,
      startLabel: isId ? 'Mulai Asesmen' : 'Start Assessment',
    );
  }

  if (isPretest) {
    return _InstructionsCopy(
      topBarTitle: l10n.pretestInstructionsTopBar,
      artLabel: l10n.pretestInstructionsArtLabel,
      title: l10n.pretestInstructionsTitle,
      body: l10n.pretestInstructionsBody,
      warningPrefix: l10n.pretestInstructionsWarningPrefix,
      warningEmphasis: l10n.pretestInstructionsWarningEmphasis,
      warningSuffix: l10n.pretestInstructionsWarningSuffix,
      lockTitle: l10n.pretestInstructionsLockTitle,
      lockBody: l10n.pretestInstructionsLockBody,
      startLabel: l10n.startPretestNow,
    );
  }

  if (isPosttest) {
    return _InstructionsCopy(
      topBarTitle: l10n.posttestInstructionsTopBar,
      artLabel: l10n.posttestInstructionsArtLabel,
      title: l10n.posttestInstructionsTitle,
      body: l10n.posttestInstructionsBody,
      warningPrefix: l10n.posttestInstructionsWarningPrefix,
      // Penekanan "satu kali" dan penutup kalimat koneksinya adalah aturan yang
      // sama untuk kedua tes (dijaga `start_assessment_attempt`), jadi kuncinya
      // dipakai bersama, bukan diduplikasi.
      warningEmphasis: l10n.pretestInstructionsWarningEmphasis,
      warningSuffix: l10n.pretestInstructionsWarningSuffix,
      lockTitle: l10n.posttestInstructionsLockTitle,
      lockBody: l10n.posttestInstructionsLockBody,
      startLabel: l10n.startPosttestNow,
    );
  }

  return _InstructionsCopy(
    topBarTitle: isId ? 'Instruksi Kuis' : 'Quiz Instructions',
    artLabel: isId ? 'Kuis Dosen' : 'Lecturer Quiz',
    title: isId ? 'Petunjuk Pengerjaan' : 'Instructions',
    body: isId
        ? 'Kerjakan soal-soal asesmen ini dengan teliti sesuai instruksi.'
        : 'Complete this assessment carefully according to instructions.',
    warningPrefix: '',
    warningEmphasis: '',
    warningSuffix: '',
    lockTitle: isId ? 'Kuis Dosen' : 'Lecturer Quiz',
    lockBody: isId
        ? 'Asesmen ini disiapkan oleh dosen pengampu.'
        : 'This assessment is prepared by your lecturer.',
    startLabel: isId ? 'Mulai Kuis' : 'Start Quiz',
  );
}

/// Isi halaman setelah data assessment tersedia.
///
/// Dipisah dari [AssessmentInstructionsPage] supaya bisa diuji tanpa Riverpod:
/// widget ini hanya menerima [AssessmentListItem] yang sudah terbaca.
class _InstructionsContent extends StatelessWidget {
  final AssessmentListItem assessment;
  final _InstructionsCopy copy;

  const _InstructionsContent({
    required this.assessment,
    required this.copy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final theme = Theme.of(context);

    final String questionCount = assessment.questionCount > 0
        ? assessment.questionCount.toString()
        : '25';

    final statusColors = theme.extension<NetLearnStatusColors>();

    final Color warningBg =
        statusColors?.pendingBg ?? NetLearnColors.warningBg;
    final Color warningText =
        statusColors?.pendingText ?? NetLearnColors.warningText;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        NetLearnSpace.s20,
        NetLearnSpace.s20,
        NetLearnSpace.s20,
        NetLearnSpace.s32,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: NetLearnSpace.formMeasure,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // `.assessment-art` — panel lavender 160px dengan ikon dan label.
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.accentTint,
                    borderRadius: BorderRadius.circular(
                      NetLearnRadius.cardLg,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 55,
                        color: context.accent,
                      ),
                      const SizedBox(height: NetLearnSpace.s17),
                      Text(
                        copy.artLabel,
                        style:
                            theme.textTheme.bodySmall?.copyWith(
                          color: context.accent,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: NetLearnSpace.s16),

                Semantics(
                  header: true,
                  child: Text(
                    copy.title,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),

                const SizedBox(height: NetLearnSpace.s8),

                Text(
                  copy.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.mutedText,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: NetLearnSpace.s16),

                // `.card.instruction` — tiga baris aturan.
                _Card(
                  child: Column(
                    children: [
                      _InstructionRow(
                        icon: Icons.assignment_outlined,
                        label: l10n.pretestInstructionsQuestionsLabel,
                        value: l10n.pretestInstructionsQuestionsValue(
                          questionCount,
                        ),
                      ),
                      const SizedBox(height: NetLearnSpace.s20),
                      _InstructionRow(
                        icon: Icons.schedule,
                        label: l10n.pretestInstructionsDurationLabel,
                        value: l10n.durationMinutes(
                          assessment.durationMinutes.toString(),
                        ),
                      ),
                      const SizedBox(height: NetLearnSpace.s20),
                      _InstructionRow(
                        icon: Icons.check,
                        label: l10n.pretestInstructionsTypeLabel,
                        value: l10n.pretestInstructionsTypeValue,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: NetLearnSpace.s16),

                // `.warning` — peringatan satu kali percobaan.
                Container(
                  padding: const EdgeInsets.all(
                    NetLearnSpace.s15,
                  ),
                  decoration: BoxDecoration(
                    color: warningBg,
                    borderRadius: BorderRadius.circular(
                      NetLearnRadius.button,
                    ),
                    border: Border.all(
                      color: warningText.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.help_outline,
                        size: 20,
                        color: warningText,
                      ),
                      const SizedBox(width: NetLearnSpace.s12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: warningText,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: copy.warningPrefix,
                              ),
                              // `<b>satu kali</b>` di desain: penekanan di
                              // tengah kalimat, jadi tidak bisa satu `Text`.
                              TextSpan(
                                text: copy.warningEmphasis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: copy.warningSuffix,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: NetLearnSpace.s16),

                // `.card` — kunci untuk mulai belajar.
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 20,
                        color: context.accent,
                      ),
                      const SizedBox(height: NetLearnSpace.s10),
                      Text(
                        copy.lockTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: NetLearnSpace.s6),
                      Text(
                        copy.lockBody,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: context.mutedText,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: NetLearnSpace.s20),

                NlButton(
                  label: copy.startLabel,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    // Gerbang assessment bersama yang sama dengan kartu
                    // daftar: instruksi boleh dibaca siapa pun (halaman ini
                    // tidak pernah menolak saat dibuka), tetapi tombol
                    // mulainya menghormati status — sudah selesai menampilkan
                    // dialog hasil, belum terbuka menampilkan dialog terkunci,
                    // dan hanya jalur normal yang melanjutkan ke soal
                    // percobaan sungguhan tetap dijaga server lewat
                    // `start_assessment_attempt`.
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
                        break;
                    }

                    // Membuka layar soal yang sudah ada. Attempt baru dibuat di
                    // sana, bukan di sini.
                    final routeParam = assessment.isPretest
                        ? 'pretest'
                        : (assessment.isPosttest
                            ? 'posttest'
                            : assessment.id);
                    context.push(
                      '/student/assessment/$routeParam',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// `.card` dari index.css: permukaan putih, garis rambut, radius 16.
class _Card extends StatelessWidget {
  final Widget child;

  const _Card({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NetLearnSpace.s17),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: child,
    );
  }
}

/// Satu baris `.instruction>div`: ikon di kiri, label kecil di atas nilai tebal.
class _InstructionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InstructionRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: context.accent,
        ),
        const SizedBox(width: NetLearnSpace.s14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.mutedText,
                ),
              ),
              const SizedBox(height: NetLearnSpace.s4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
