import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_mcq_option.dart';
import '../../shared/widgets/nl_section_heading.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/nl_topbar.dart';
import 'assessment_controller.dart';

/// Layar pengerjaan assessment: satu soal pada satu waktu, dengan navigasi
/// nomor soal di bawahnya.
///
/// Yang berubah pada tahap ini hanya tampilannya. Aturan yang tidak disentuh:
/// kapan attempt dimulai, irama timer satu detik, peringatan sekali pada sisa
/// 60 detik, pengumpulan otomatis di detik nol, konfirmasi sebelum keluar,
/// `PopScope`, dan penulisan jawaban lewat `selectAnswer`.
class AssessmentPage extends ConsumerStatefulWidget {
  final String assessmentType;

  const AssessmentPage({
    super.key,
    required this.assessmentType,
  });

  @override
  ConsumerState<AssessmentPage> createState() =>
      _AssessmentPageState();
}

class _AssessmentPageState extends ConsumerState<AssessmentPage> {
  Timer? _timer;

  bool _hasStarted = false;
  bool _isSubmitting = false;
  bool _hasShownTimeWarning = false;

  /// Sisa waktu dalam detik, dihitung [_startTimer].
  ///
  /// Notifier ini ada supaya lonceng waktu tidak ikut membangun ulang seluruh
  /// halaman setiap detik. [_startTimer] tetap satu-satunya tempat waktu
  /// dihitung dan tetap membaca sumber yang sama seperti sebelumnya:
  /// `startedAt + durationMinutes` dibandingkan `DateTime.now()`. Yang berubah
  /// hanya空了 lingkup rebuild-nya, bukan sumber kebenarannya.
  final ValueNotifier<int> _remainingSeconds = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAssessment();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _remainingSeconds.dispose();
    super.dispose();
  }

  Future<void> _startAssessment() async {
    if (_hasStarted) {
      return;
    }

    _hasStarted = true;

    final controller = ref.read(
      assessmentControllerProvider.notifier,
    );

    try {
      await controller.startAssessmentByType(
        widget.assessmentType,
      );

      if (!mounted) {
        return;
      }

      _startTimer();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        _friendlyErrorMessage(error),
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();

    final state = ref.read(
      assessmentControllerProvider,
    );

    if (state.startedAt == null ||
        state.durationMinutes <= 0) {
      return;
    }

    // Nilai awal ditulis sekali di sini, bukan di dalam `build`. Menulis
    // notifier sambil membangun akan menandai pendengarnya dirty di tengah
    // build dan bisa membuat Flutter melempar exception.
    _remainingSeconds.value = _secondsLeft(state);

    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (!mounted) {
          return;
        }

        final currentState = ref.read(
          assessmentControllerProvider,
        );

        final startedAt = currentState.startedAt;

        if (startedAt == null) {
          return;
        }

        if (_secondsLeft(currentState) <= 0) {
          _timer?.cancel();

          _submitAssessment(
            automatic: true,
          );

          return;
        }

        if (_secondsLeft(currentState) <= 60 &&
            !_hasShownTimeWarning) {
          _hasShownTimeWarning = true;

          _showTimeWarning();
        }

        // Sebelumnya `setState(() {})` di titik ini membangun ulang teks soal,
        // gambar soal, dan seluruh kotak navigasi sekali per detik.
        _remainingSeconds.value = _secondsLeft(currentState);
      },
    );
  }

  /// Sisa waktu dalam detik, atau nol bila sudah lewat atau belum dimulai.
  int _secondsLeft(
      AssessmentSessionState state,
      ) {
    final startedAt = state.startedAt;

    if (startedAt == null ||
        state.durationMinutes <= 0) {
      return 0;
    }

    final deadline = startedAt.add(
      Duration(
        minutes: state.durationMinutes,
      ),
    );

    final seconds =
        deadline.difference(DateTime.now()).inSeconds;

    return seconds < 0 ? 0 : seconds;
  }

  Future<void> _selectAnswer(
      String questionId,
      String option,
      ) async {
    HapticFeedback.lightImpact();
    final controller = ref.read(
      assessmentControllerProvider.notifier,
    );

    try {
      await controller.selectAnswer(
        questionId,
        option,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        _friendlyErrorMessage(error),
      );
    }
  }

  Future<void> _submitAssessment({
    bool automatic = false,
  }) async {
    if (_isSubmitting) {
      return;
    }

    if (!automatic) {
      final shouldSubmit =
      await _showSubmitConfirmation();

      if (!mounted) {
        return;
      }

      if (!shouldSubmit) {
        return;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    _timer?.cancel();

    final controller = ref.read(
      assessmentControllerProvider.notifier,
    );

    try {
      final attempt =
      await controller.submitAssessment();

      HapticFeedback.heavyImpact();

      if (!mounted) {
        return;
      }

      context.go(
        '/student/assessment-result/${attempt.id}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      _showError(
        _friendlyErrorMessage(error),
      );
    }
  }

  Future<bool> _showSubmitConfirmation() async {
    final state = ref.read(
      assessmentControllerProvider,
    );

    final l10n = AppLocalizations.of(context)!;

    final int answered =
        state.answeredQuestions;

    final int total =
        state.totalQuestions;

    final int unanswered =
        total - answered;

    if (!mounted) {
      return false;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            l10n.assessmentSubmitTitle,
          ),
          content: Text(
            unanswered > 0
                ? l10n.assessmentSubmitWithUnanswered(unanswered)
                : l10n.assessmentSubmitAllAnswered,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: Text(
                l10n.back,
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: Text(
                l10n.assessmentSubmit,
              ),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<bool> _showExitConfirmation() async {
    final l10n = AppLocalizations.of(context)!;

    if (!mounted) {
      return false;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            l10n.assessmentLeaveTitle,
          ),
          content: Text(
            l10n.assessmentLeaveBody,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: Text(
                l10n.stay,
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: Text(
                l10n.leave,
              ),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  void _showTimeWarning() {
    final l10n = AppLocalizations.of(context)!;

    if (!mounted) {
      return;
    }

    // Durasi dan behavior tidak lagi diatur di sini — semuanya milik helper
    // per tone (warning = 5 detik).
    NlSnackBar.show(
      context,
      l10n.assessmentTimeWarning,
      tone: NlSnackTone.warning,
    );
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    NlSnackBar.show(
      context,
      message,
      tone: NlSnackTone.error,
    );
  }

  /// Memetakan kode error dari server ke kalimat yang bisa dibaca.
  ///
  /// Percabangan dan urutannya tidak berubah sama sekali; hanya teksnya yang
  /// pindah ke ARB supaya tidak ada lagi `isIndonesian ? ... : ...` di file ini.
  String _friendlyErrorMessage(
      Object error,
      ) {
    final l10n = AppLocalizations.of(context)!;

    final raw = error.toString();

    if (raw.contains('ASSESSMENT_NOT_FOUND')) {
      return l10n.assessmentErrorNotFound;
    }

    if (raw.contains('ASSESSMENT_NOT_PUBLISHED')) {
      return l10n.assessmentErrorNotPublished;
    }

    if (raw.contains('ASSESSMENT_NO_QUESTIONS')) {
      return l10n.assessmentErrorNoQuestions;
    }

    if (raw.contains('ATTEMPT_NOT_FOUND')) {
      return l10n.assessmentErrorAttemptNotFound;
    }

    // Kode spesifik dari assessment_access(). Semuanya dikirim sebagai
    // `ASSESSMENT_LOCKED:<KODE>`, jadi harus diperiksa SEBELUM cabang generik
    // ASSESSMENT_LOCKED di bawah -- kalau tidak, semuanya jatuh ke kalimat
    // "sudah dikerjakan atau belum terbuka" dan mahasiswa tidak tahu mana
    // yang sebenarnya terjadi.
    if (raw.contains('DEADLINE_PASSED')) {
      return l10n.assessmentErrorDeadlinePassed;
    }

    if (raw.contains('ATTEMPTS_EXHAUSTED')) {
      return l10n.assessmentErrorAttemptsExhausted;
    }

    if (raw.contains('NOT_ENROLLED') || raw.contains('CLASS_NOT_PUBLISHED')) {
      return l10n.assessmentErrorNotEnrolled;
    }

    if (raw.contains('PRETEST_DONE') || raw.contains('POSTTEST_DONE')) {
      return l10n.assessmentErrorAlreadyCompleted;
    }

    if (raw.contains('MODULES_INCOMPLETE') || raw.contains('MODULE_LOCKED')) {
      return l10n.assessmentErrorModulesIncomplete;
    }

    final isId = Localizations.localeOf(context).languageCode == 'id';

    if (raw.contains('PRETEST_DISABLED')) {
      return isId ? 'Pretest dinonaktifkan untuk kelas ini.' : 'Pretest is disabled for this class.';
    }

    if (raw.contains('POSTTEST_DISABLED')) {
      return isId ? 'Posttest dinonaktifkan untuk kelas ini.' : 'Posttest is disabled for this class.';
    }

    if (raw.contains('ASSESSMENT_LOCKED')) {
      // "Assessment is still locked." dulu menyesatkan untuk kasus paling
      // umum di sini: soal ditembak dari pintu yang tidak memeriksa status
      // selesai, dan server menolaknya karena tes sudah dikerjakan. Pesannya
      // kini menyebut keduanya, dan layar errornya tidak menawarkan Retry
      // (lihat `_ErrorPage` di build) karena Retry hanya mengulang kegagalan
      // yang sama.
      return l10n.assessmentErrorLockedOrCompleted;
    }

    if (raw.contains('PRETEST_REQUIRED')) {
      return l10n.assessmentErrorPretestRequired;
    }

    if (raw.contains('MODULES_NOT_COMPLETED')) {
      return l10n.assessmentErrorModulesIncomplete;
    }

    if (raw.contains('ASSESSMENT_ALREADY_COMPLETED')) {
      return l10n.assessmentErrorAlreadyCompleted;
    }

    if (raw.contains('USER_NOT_AUTHENTICATED')) {
      return l10n.assessmentErrorNoSession;
    }

    if (raw.contains('42501') || raw.contains('row-level security') || raw.contains('permission denied')) {
      return isId
          ? 'Izin database ditolak (RLS). Pastikan migrasi SQL telah dijalankan di Supabase SQL Editor.'
          : 'Database permission denied (RLS). Please ensure the SQL migration was executed in Supabase SQL Editor.';
    }

    return l10n.assessmentErrorGeneric;
  }

  /// Judul sebelum attempt termuat. Posttest dipisah dari Pretest karena
  /// keduanya adalah dua assessment yang berbeda dan keduanya sudah punya
  /// string sendiri di ARB.
  String _fallbackTitle(AppLocalizations l10n) {
    if (widget.assessmentType == 'pretest') {
      return l10n.pretest;
    }
    if (widget.assessmentType == 'posttest') {
      return l10n.posttest;
    }
    return l10n.assessment;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final state = ref.watch(
      assessmentControllerProvider,
    );

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: context.background,
        appBar: NlTopBar(
          title: _fallbackTitle(l10n),
          onBack: () => goBack(context, fallback: '/student/assessment'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.errorMessage != null &&
        !state.hasQuestions) {
      // ASSESSMENT_LOCKED tidak boleh menawarkan Retry: percobaan baru akan
      // ditolak lagi dengan cara yang sama (server `start_assessment_attempt`
      // memang begitu), jadi tombolnya tidak dirender sama sekali.
      final bool locked =
          state.errorMessage!.contains('ASSESSMENT_LOCKED');

      return _ErrorPage(
        message: _friendlyErrorMessage(
          state.errorMessage!,
        ),
        title: _fallbackTitle(l10n),
        onRetry: locked
            ? null
            : () {
                _hasStarted = false;
                _startAssessment();
              },
      );
    }

    if (!state.hasQuestions) {
      return Scaffold(
        backgroundColor: context.background,
        appBar: NlTopBar(
          title: _fallbackTitle(l10n),
          onBack: () => goBack(context, fallback: '/student/assessment'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult:
          (didPop, result) async {
        if (didPop) {
          return;
        }

        final shouldLeave =
        await _showExitConfirmation();

        if (!mounted) {
          return;
        }

        if (!shouldLeave) {
          return;
        }

        goBack(context, fallback: '/student/assessment');
      },
      child: Scaffold(
        backgroundColor: context.background,
        appBar: NlTopBar(
          title: state.assessmentTitle ??
              _fallbackTitle(l10n),
          onBack: () async {
            final shouldLeave =
            await _showExitConfirmation();

            if (!mounted) {
              return;
            }

            if (!shouldLeave) {
              return;
            }

            goBack(context, fallback: '/student/assessment');
          },
        ),
        body: SafeArea(
          child: Column(
            children: [
              _ProgressHeader(
                state: state,
                remainingSeconds: _remainingSeconds,
                timeRemainingLabel: l10n.timeRemaining,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    NetLearnSpace.s20,
                    NetLearnSpace.s16,
                    NetLearnSpace.s20,
                    NetLearnSpace.s24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: NetLearnSpace.formMeasure,
                      ),
                      child: _QuestionContent(
                        state: state,
                        yourAnswerLabel: l10n.assessmentYourAnswer,
                        onAnswer: _selectAnswer,
                        onQuestionSelected: (index) {
                          ref
                              .read(
                            assessmentControllerProvider
                                .notifier,
                          )
                              .goToQuestion(index);
                        },
                      ),
                    ),
                  ),
                ),
              ),
              _BottomControls(
                state: state,
                isSubmitting: _isSubmitting,
                onPrevious: () {
                  ref
                      .read(
                    assessmentControllerProvider
                        .notifier,
                  )
                      .previousQuestion();
                },
                onNext: () {
                  ref
                      .read(
                    assessmentControllerProvider
                        .notifier,
                  )
                      .nextQuestion();
                },
                onSubmit: () {
                  _submitAssessment();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris progres dan lonceng waktu, mengikuti `.section-heading` dan `.timer`
/// di desain: label soal di kiri, waktu di kanan, track penuh di bawahnya.
///
/// [remainingSeconds] diganti oleh [_AssessmentPageState._startTimer] setiap
/// detik, jadi hanya lonceng waktunya yang dibangun ulang -- bukan teks soal,
/// gambar soal, dan seluruh kotak navigasi.
class _ProgressHeader extends StatelessWidget {
  final AssessmentSessionState state;
  final ValueListenable<int> remainingSeconds;
  final String timeRemainingLabel;

  const _ProgressHeader({
    required this.state,
    required this.remainingSeconds,
    required this.timeRemainingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final int current =
        state.currentQuestionIndex + 1;

    final int total =
        state.totalQuestions;

    final double progress =
    total == 0 ? 0 : current / total;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NetLearnSpace.s20,
        NetLearnSpace.s14,
        NetLearnSpace.s20,
        NetLearnSpace.s4,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: NetLearnSpace.formMeasure,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.assessmentQuestionProgress(current, total),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: NetLearnSpace.s10,
                  ),

                  ValueListenableBuilder<int>(
                    valueListenable: remainingSeconds,
                    builder: (context, seconds, _) {
                      return _TimerBadge(
                        seconds: seconds,
                        critical: seconds <= 60,
                        label: timeRemainingLabel,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(
                height: NetLearnSpace.s9,
              ),

              // `.progress-track` = 5px dengan `border-radius:10px` dan isian
              // gradien, sama persis seperti yang dipakai `NlProgressSummary`.
              // Track-nya ditulis di sini karena panel itu menampilkan angka
              // persentase besar, sedangkan assessment tidak punya persentase:
              // yang ada hanya "soal ke-N dari N".
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  NetLearnRadius.pill / 2,
                ),
                child: SizedBox(
                  height: NetLearnSpace.s5,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark
                        ? NetLearnColors.darkProgressTrackBg
                        : NetLearnColors.progressTrackBg,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      NetLearnColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: NetLearnSpace.s7,
              ),

              Text(
                l10n.assessmentAnsweredCount(state.answeredQuestions),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                  color: context.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.timer` dari desain: ikon jam dan sisa waktu.
///
/// Warnanya mengikuti tema: aksen ungu selama masih longgar, pasangan
/// `pending` dari `NetLearnStatusColors` pada sisa 60 detik terakhir. `index.css`
/// memberi `.timer` warna merah muda `#aa477c` di atas `#fbeaf3`, tapi warna itu
/// tidak punya pasangan gelap dan tidak ada di token manapun, jadi tidak
/// diambil; bentuknya yang dipakai.
class _TimerBadge extends StatelessWidget {
  final int seconds;
  final bool critical;
  final String label;

  const _TimerBadge({
    required this.seconds,
    required this.critical,
    required this.label,
  });

  String _format() {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final hours = seconds ~/ 3600;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColors =
        Theme.of(context).extension<NetLearnStatusColors>();

    final color = critical
        ? (statusColors?.pendingText ?? NetLearnColors.warningText)
        : context.accent;

    final background = critical
        ? (statusColors?.pendingBg ?? NetLearnColors.warningBg)
        : context.accentTint;

    return Semantics(
      // Angka jam tidak berarti apa-apa tanpa konteks, jadi label-nya menyebut
      // sisa waktu sebelum angkanya.
      label: '$label ${_format()}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: NetLearnSpace.s10,
          vertical: NetLearnSpace.s8,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(NetLearnRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 15,
              color: color,
            ),
            const SizedBox(width: NetLearnSpace.s6),
            Text(
              _format(),
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                // Angka jam harus lebarnya tetap; tanpa ini digit melompat
                // setiap detik karena `1` lebih sempit dari `0`.
                fontFeatures: const [
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionContent extends StatelessWidget {
  final AssessmentSessionState state;
  final String yourAnswerLabel;
  final Future<void> Function(
      String,
      String,
      ) onAnswer;
  final ValueChanged<int> onQuestionSelected;

  const _QuestionContent({
    required this.state,
    required this.yourAnswerLabel,
    required this.onAnswer,
    required this.onQuestionSelected,
  });

  /// A-D ditulis eksplisit, bukan lewat `AssessmentQuestion.options`, supaya
  /// tiap pilihan bisa membawa callback dan state `selected`-nya sendiri.
  static const List<String> _optionLetters = ['A', 'B', 'C', 'D'];

  String _optionText(
      AssessmentQuestion question,
      String letter,
      ) {
    switch (letter) {
      case 'A':
        return question.optionA;

      case 'B':
        return question.optionB;

      case 'C':
        return question.optionC;

      default:
        return question.optionD;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final question = state.currentQuestion;

    if (question == null) {
      return const SizedBox.shrink();
    }

    final selected = state.answers[question.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.imageUrl != null &&
            question.imageUrl!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              bottom: NetLearnSpace.s16,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                NetLearnRadius.card,
              ),
              child: Image.network(
                question.imageUrl!,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder:
                    (
                    context,
                    error,
                    stackTrace,
                    ) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),

        // `.card.question`: teks soal di dalam kartu putih. Sebelumnya teksnya
        // berdiri langsung di atas background halaman tanpa kartu.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(
            NetLearnSpace.s16,
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
          child: Semantics(
            header: true,
            child: Text(
              question.questionText,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                height: 1.4,
              ),
            ),
          ),
        ),

        const SizedBox(
          height: NetLearnSpace.s20,
        ),

        for (final letter in _optionLetters)
          Padding(
            padding: const EdgeInsets.only(
              bottom: NetLearnSpace.s10,
            ),
            child: NlMcqOption(
              label: letter,
              text: _optionText(question, letter),
              selected: selected == letter,
              selectedLabel: yourAnswerLabel,
              onTap: () {
                onAnswer(
                  question.id,
                  letter,
                );
              },
            ),
          ),

        const SizedBox(
          height: NetLearnSpace.s12,
        ),

        NlSectionHeading(
          title: l10n.assessmentQuestionNavigation,
          leadingIcon: Icons.grid_view_rounded,
        ),

        _QuestionNavigator(
          state: state,
          onQuestionSelected: onQuestionSelected,
        ),
      ],
    );
  }
}

class _QuestionNavigator
    extends StatelessWidget {
  final AssessmentSessionState state;
  final ValueChanged<int> onQuestionSelected;

  const _QuestionNavigator({
    required this.state,
    required this.onQuestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: NetLearnSpace.s4,
      runSpacing: NetLearnSpace.s4,
      children: List.generate(
        state.questions.length,
            (index) {
          final question =
          state.questions[index];

          final bool isCurrent =
          index ==
              state.currentQuestionIndex;

          final bool isAnswered =
          state.answers.containsKey(
            question.id,
          );

          return _QuestionNumber(
            number: index + 1,
            current: isCurrent,
            answered: isAnswered,
            // Dibaca sebagai satu kalimat. Tanpa ini pembaca layar
            // announcing empat fragmen terpisah dan tidak tahu nomor berapa
            // yang sedang dikerjakan.
            semanticsLabel: [
              l10n.questionNumber(index + 1),
              if (isCurrent) l10n.assessmentCurrentQuestion,
              if (isAnswered)
                l10n.assessmentAnsweredQuestion
              else
                l10n.assessmentUnansweredQuestion,
            ].join(', '),
            onTap: () {
              onQuestionSelected(index);
            },
          );
        },
      ),
    );
  }
}

class _QuestionNumber extends StatelessWidget {
  final int number;
  final bool current;
  final bool answered;
  final String semanticsLabel;
  final VoidCallback onTap;

  const _QuestionNumber({
    required this.number,
    required this.current,
    required this.answered,
    required this.semanticsLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color backgroundColor;
    final Color foregroundColor;

    if (current) {
      backgroundColor =
          context.accent;
      foregroundColor =
          theme.colorScheme.onPrimary;
    } else if (answered) {
      backgroundColor =
          context.accentTint;
      foregroundColor =
          context.accent;
    } else {
      backgroundColor =
          context.raisedSurface;
      foregroundColor =
          context.onSurface;
    }

    // Kotak yang digambar tetap 42px seperti sebelumnya, area sentuhnya 48px.
    // `Material` dan `InkWell` membungkus seluruh 48px, jadi klik di sela
    // antar kotak juga masuk. Kotak digambar 48px akan terlihat jauh lebih
    // besar dari baris jawaban tepat di atasnya.
    return Semantics(
      button: true,
      selected: current,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(
                NetLearnRadius.sm,
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(
                  NetLearnRadius.sm,
                ),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(
                      NetLearnRadius.sm,
                    ),
                  ),
                  child: Text(
                    '$number',
                    maxLines: 1,
                    style: theme.textTheme
                        .labelLarge
                        ?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final AssessmentSessionState state;
  final bool isSubmitting;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const _BottomControls({
    required this.state,
    required this.isSubmitting,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final bool isFirst =
        state.currentQuestionIndex == 0;

    final bool isLast =
        state.currentQuestionIndex ==
            state.questions.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        NetLearnSpace.s20,
        NetLearnSpace.s12,
        NetLearnSpace.s20,
        NetLearnSpace.s12,
      ),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(
          top: BorderSide(
            color: context.border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: NetLearnSpace.formMeasure,
            ),
            child: Row(
              children: [
                _ArrowButton(
                  icon: Icons.arrow_back_rounded,
                  label: l10n.assessmentPreviousQuestion,
                  onPressed: isFirst ? null : onPrevious,
                ),
                const SizedBox(
                  width: NetLearnSpace.s12,
                ),
                Expanded(
                  child: NlButton(
                    label: isLast
                        ? l10n.assessmentSubmitAction
                        : l10n.assessmentNextAction,
                    icon: isLast
                        ? Icons.check_rounded
                        : null,
                    loading: isSubmitting,
                    onPressed: isSubmitting
                        ? null
                        : (isLast ? onSubmit : onNext),
                  ),
                ),
                const SizedBox(
                  width: NetLearnSpace.s12,
                ),

                // Selalu ada, hanya dinonaktifkan di soal terakhir.
                // Sebelumnya tombol kanan ini hilang di soal terakhir sehingga
                // baris bawah melompat lebarnya setiap kali mahasiswa berpindah
                // ke soal terakhir lalu kembali. Menonaktifkannya menjaga
                // callback `onNext` persis seperti sebelumnya: di soal terakhir
                // tombol itu memang sudah tidak bisa ditekan.
                _ArrowButton(
                  icon: Icons.arrow_forward_rounded,
                  label: l10n.assessmentNextQuestion,
                  onPressed: isLast ? null : onNext,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol panah tanpa teks di bar bawah soal.
///
/// `OutlinedButton` dengan isi `Icon` saja tidak punya nama yang bisa dibaca
/// pembaca layar, jadi tanpa [Tooltip] dan [Semantics] kontrol ini
/// announces sebagai "button" tanpa tujuan. `minimumSize` 48px memenuhi target
/// sentuh Material.
class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ArrowButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: context.accent,
        side: BorderSide(
          color: context.accent,
        ),
        padding: EdgeInsets.zero,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            NetLearnRadius.button,
          ),
        ),
      ),
      child: Icon(
        icon,
        size: 18,
      ),
    );

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: ExcludeSemantics(
        child: Tooltip(
          message: label,
          excludeFromSemantics: true,
          child: button,
        ),
      ),
    );
  }
}

class _ErrorPage extends StatelessWidget {
  final String message;
  final String title;

  /// Nullable supaya kegagalan yang pasti diulang lagi (ASSESSMENT_LOCKED)
  /// tidak menampilkan tombol Retry. [NlErrorView.onRetry] memang sudah bisa
  /// menerima null dan menyembunyikan tombolnya.
  final VoidCallback? onRetry;

  const _ErrorPage({
    required this.message,
    required this.title,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: NlTopBar(
        title: title,
        onBack: () => goBack(context, fallback: '/student/assessment'),
      ),
      body: NlErrorView(
        message: message,
        onRetry: onRetry,
      ),
    );
  }
}