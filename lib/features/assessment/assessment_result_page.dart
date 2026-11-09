import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/language_controller.dart';
import '../../core/router/safe_back.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_score_ring.dart';
import '../../shared/widgets/nl_section_heading.dart';
import '../../shared/widgets/nl_stats_strip.dart';
import '../../shared/widgets/nl_topbar.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/student_bottom_navbar.dart';
import '../achievements/achievement_service.dart';

/// Hasil assessment yang sudah dikumpulkan.
///
/// Halaman ini sengaja tidak memakai `AssessmentController`: ia membaca
/// attempt yang sudah selesai langsung dari `quiz_attempts`, sehingga mahasiswa
/// bisa membuka hasil lama tanpa memulai sesi baru.
///
/// Yang dipisah menjadi [AssessmentResultView] hanya tampilannya. Tiga query,
/// pemetaan field, dan arti `score`/`passed` tetap sama persis seperti
/// sebelumnya.
///
/// Ringkasan jawaban per soal **tidak** ditampilkan. `get_attempt_review` hanya
/// mengembalikan `question_id`, `order_index`, `selected_option`, dan
/// `is_correct` -- tidak ada jawaban benar, dan tabel `questions` juga tidak
/// punya kolom untuk itu, jadi "Jawaban benar: Router" di desain Figma tidak
/// bisa dijawab dengan data yang ada sekarang.
class AssessmentResultPage extends ConsumerStatefulWidget {
  final String attemptId;

  const AssessmentResultPage({
    super.key,
    required this.attemptId,
  });

  @override
  ConsumerState<AssessmentResultPage> createState() =>
      _AssessmentResultPageState();
}

class _AssessmentResultPageState
    extends ConsumerState<AssessmentResultPage> {
  bool _isLoading = true;
  String? _errorMessage;

  String _title = '';
  String _assessmentType = '';

  double _score = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  int _totalQuestions = 0;

  bool _passed = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await _loadResult();
    });
  }

  Future<void> _loadResult() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final attempt = await supabase
          .from('quiz_attempts')
          .select(
        'id, quiz_id, user_id, status, score, '
            'correct_count, wrong_count, passed',
      )
          .eq('id', widget.attemptId)
          .maybeSingle();

      if (attempt == null) {
        throw Exception('Hasil asesmen tidak ditemukan.');
      }

      final quizId = attempt['quiz_id']?.toString();

      if (quizId == null || quizId.isEmpty) {
        throw Exception(
          'Asesmen pada hasil ini tidak ditemukan.',
        );
      }

      final quiz = await supabase
          .from('quizzes')
          .select(
            'id, title, title_en, title_id, assessment_type',
      )
          .eq('id', quizId)
          .maybeSingle();

      if (quiz == null) {
        throw Exception(
          'Data asesmen tidak ditemukan.',
        );
      }

      final questions = await supabase
          .from('questions')
          .select('id')
          .eq('quiz_id', quizId);

      final language = ref.read(languageProvider);

      final String title;

      if (language.languageCode == 'id') {
        title =
        quiz['title_id']?.toString().trim().isNotEmpty == true
            ? quiz['title_id'].toString()
            : quiz['title']?.toString() ?? 'Asesmen';
      } else {
        title =
        quiz['title_en']?.toString().trim().isNotEmpty == true
            ? quiz['title_en'].toString()
            : quiz['title']?.toString() ?? 'Asesmen';
      }

      final dynamic rawScore = attempt['score'];
      final dynamic rawCorrect = attempt['correct_count'];
      final dynamic rawWrong = attempt['wrong_count'];
      final dynamic rawPassed = attempt['passed'];

      final double score =
      rawScore is num ? rawScore.toDouble() : 0;

      final int correctCount =
      rawCorrect is num ? rawCorrect.toInt() : 0;

      final int wrongCount =
      rawWrong is num ? rawWrong.toInt() : 0;

      final int totalQuestions = questions.length;

      final bool passed = rawPassed == true;

      if (!mounted) {
        return;
      }

      setState(() {
        _title = title;
        _assessmentType =
            quiz['assessment_type']?.toString() ?? '';

        _score = score;
        _correctCount = correctCount;
        _wrongCount = wrongCount;
        _totalQuestions = totalQuestions;
        _passed = passed;

        _isLoading = false;
      });

      final statusStr = attempt['status']?.toString() ?? '';
      if (mounted &&
          (statusStr == 'submitted' || statusStr == 'completed')) {
        AchievementService.unlockBadge(context, 'fast_learner');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.background,

      // `.compact` di Figma menaruh tombol kembali di kiri, dan laporan meminta
      // hasil assessment punya jalan keluar selain dua tombol di bawah. `goBack`
      // pop hasil yang ditumpuk dari layar soal, atau jatuh ke daftar assessment
      // (fallback) ketika halaman ini dibuka langsung lewat deep link.
      appBar: NlTopBar(
        title: l10n.assessmentResult,
        onBack: () => goBack(context, fallback: '/student/assessment'),
      ),
      body: AssessmentResultView(
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        title: _title,
        assessmentType: _assessmentType,
        score: _score,
        correctCount: _correctCount,
        wrongCount: _wrongCount,
        totalQuestions: _totalQuestions,
        passed: _passed,
        onRetry: _loadResult,
      ),
      bottomNavigationBar: const StudentBottomNavbar(
        currentIndex: 3,
      ),
    );
  }
}

/// Tampilan murni hasil assessment.
///
/// Dipisah dari [AssessmentResultPage] supaya bisa diuji tanpa Supabase:
/// widget ini hanya menerima angka yang sudah dibaca, tidak melakukan query
/// apa pun. Pola yang sama dipakai [_QuestionContent] di layar soal -- dan
/// bukan kebetulan, karena keduanya adalah bagian yang paling sering berubah
/// secara visual tetapi paling sering salah karena warna dan ukuran.
class AssessmentResultView extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final String title;
  final String assessmentType;
  final double score;
  final int correctCount;
  final int wrongCount;
  final int totalQuestions;
  final bool passed;
  final VoidCallback onRetry;

  const AssessmentResultView({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.title,
    required this.assessmentType,
    required this.score,
    required this.correctCount,
    required this.wrongCount,
    required this.totalQuestions,
    required this.passed,
    required this.onRetry,
  });

  String _typeLabel(AppLocalizations l10n) {
    if (assessmentType == 'pretest') {
      return l10n.pretest;
    }

    if (assessmentType == 'posttest') {
      return l10n.posttest;
    }

    return l10n.assessment;
  }

  String _completedMessage(AppLocalizations l10n) {
    if (assessmentType == 'pretest') {
      return l10n.pretestCompletedMessage;
    }

    return l10n.posttestCompletedMessage;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return NlErrorView(
        message: errorMessage!,
        onRetry: onRetry,
      );
    }

    final statusColors =
        Theme.of(context).extension<NetLearnStatusColors>();

    // `passed` tetap sumber kebenarannya; yang diganti hanya warnanya.
    // `Colors.green`/`Colors.orange` yang dipakai sebelumnya tidak punya
    // pasangan gelap, jadi di mode gelap ikon hijau berada di atas hijau
    // transparan di atas permukaan gelap.
    final Color positiveColor = statusColors?.positiveText ??
        Theme.of(context).colorScheme.primary;
    final Color positiveBackground = statusColors?.positiveBg ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.12);
    final Color pendingColor =
        statusColors?.pendingText ?? NetLearnColors.warningText;
    final Color pendingBackground =
        statusColors?.pendingBg ?? NetLearnColors.warningBg;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          NetLearnSpace.s20,
          NetLearnSpace.s24,
          NetLearnSpace.s20,
          NetLearnSpace.s32,
        ),
        // Batas lebar kolom: di tablet seluruh kartu hasil akan selebar layar
        // penuh. `maxWidth` hanya menahan, jadi 360dp dan 430dp tidak berubah.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: NetLearnSpace.readingMeasure,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ResultHeader(
                  title: title,
                  typeLabel: _typeLabel(l10n),
                  passed: passed,
                  passedLabel: l10n.passed,
                  failedLabel: l10n.failed,
                  iconColor: positiveColor,
                  iconBackground: positiveBackground,
                ),

                const SizedBox(height: NetLearnSpace.s24),

                NlSectionHeading(
                  title: l10n.score,
                  leadingIcon: Icons.emoji_events_outlined,
                ),

                _ScoreCard(
                  score: score,
                  scoreLabel: l10n.score,
                ),

                const SizedBox(height: NetLearnSpace.s16),

                NlStatsStrip(
                  items: [
                    NlStatsStripItem(
                      value: '$correctCount',
                      label: l10n.correct,
                    ),
                    NlStatsStripItem(
                      value: '$wrongCount',
                      label: l10n.wrong,
                    ),
                    NlStatsStripItem(
                      value: '$totalQuestions',
                      label: l10n.assessmentTotalQuestions,
                    ),
                  ],
                ),

                const SizedBox(height: NetLearnSpace.s16),

                _CompletionMessage(
                  message: _completedMessage(l10n),
                  passed: passed,
                  passedColor: positiveColor,
                  passedBackground: positiveBackground,
                  pendingColor: pendingColor,
                  pendingBackground: pendingBackground,
                ),

                const SizedBox(height: NetLearnSpace.s24),

                NlButton(
                  label: l10n.backToAssessment,
                  icon: Icons.assignment_outlined,
                  onPressed: () {
                    context.go('/student/assessment');
                  },
                ),

                const SizedBox(height: NetLearnSpace.s8),

                NlButton(
                  label: l10n.backToDashboard,
                  icon: Icons.home_outlined,
                  variant: NlButtonVariant.outline,
                  onPressed: () {
                    context.go('/student');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.result-top` dari desain: lingkaran ikon, judul, dan label jenis.
class _ResultHeader extends StatelessWidget {
  final String title;
  final String typeLabel;
  final bool passed;
  final String passedLabel;
  final String failedLabel;
  final Color iconColor;
  final Color iconBackground;

  const _ResultHeader({
    required this.title,
    required this.typeLabel,
    required this.passed,
    required this.passedLabel,
    required this.failedLabel,
    required this.iconColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // `.result-top .circle` = 58px.
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: iconBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_outline_rounded,
            size: 30,
            color: iconColor,
          ),
        ),

        const SizedBox(height: NetLearnSpace.s15),

        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
        ),

        const SizedBox(height: NetLearnSpace.s8),

        Text(
          typeLabel,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.mutedText,
          ),
        ),

        const SizedBox(height: NetLearnSpace.s12),

        // `StatusBadge` selalu ikon + teks + warna, jadi "lulus" dan "tidak
        // lulus" tidak pernah dibedakan oleh warna saja. Enum-nya hanya punya
        // tiga keadaan dan `down` memakai ikon gembok, yang untuk nilai tidak
        // lulus kurang tepat -- sudah dicatat untuk ditinjau.
        StatusBadge(
          status: passed ? NetLearnStatus.linked : NetLearnStatus.down,
          label: passed ? passedLabel : failedLabel,
        ),
      ],
    );
  }
}

/// `.card.score-card` dengan cincin `.score` di dalamnya.
class _ScoreCard extends StatelessWidget {
  final double score;
  final String scoreLabel;

  const _ScoreCard({
    required this.score,
    required this.scoreLabel,
  });

  @override
  Widget build(BuildContext context) {
    final rounded = score.round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: NetLearnSpace.s24,
        horizontal: NetLearnSpace.s16,
      ),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      // `NlScoreRing` dibangun pada tahap fondasi token justru untuk `.score`
      // di desain, dan sebelum halaman ini belum dipakai di mana pun.
      // `/ 100` jadi caption-nya, persis `.score>span`.
      child: NlScoreRing(
        value: rounded,
        caption: '/ 100',
        semanticLabel: '$scoreLabel $rounded / 100',
      ),
    );
  }
}

/// Pesan penutup, dengan warna yang mengikuti `passed`.
class _CompletionMessage extends StatelessWidget {
  final String message;
  final bool passed;
  final Color passedColor;
  final Color passedBackground;
  final Color pendingColor;
  final Color pendingBackground;

  const _CompletionMessage({
    required this.message,
    required this.passed,
    required this.passedColor,
    required this.passedBackground,
    required this.pendingColor,
    required this.pendingBackground,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = passed ? passedColor : pendingColor;
    final background = passed ? passedBackground : pendingBackground;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NetLearnSpace.s16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            passed
                ? Icons.info_outline_rounded
                : Icons.warning_amber_outlined,
            color: color,
            size: 20,
          ),

          const SizedBox(width: NetLearnSpace.s12),

          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}