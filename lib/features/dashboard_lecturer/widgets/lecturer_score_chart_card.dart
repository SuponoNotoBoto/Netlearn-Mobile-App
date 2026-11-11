import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/language_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/student_model.dart';
import '../../../shared/widgets/nl_button.dart';
import '../lecturer_ai_service.dart';

class LecturerScoreChartCard extends ConsumerStatefulWidget {
  final List<StudentModel> students;

  const LecturerScoreChartCard({
    super.key,
    required this.students,
  });

  @override
  ConsumerState<LecturerScoreChartCard> createState() =>
      _LecturerScoreChartCardState();
}

class _LecturerScoreChartCardState
    extends ConsumerState<LecturerScoreChartCard> {
  bool _analyzingAi = false;
  LecturerScoreAnalyticsResult? _aiResult;
  String? _aiError;

  Future<void> _runAiAnalysis(String langCode) async {
    setState(() {
      _analyzingAi = true;
      _aiError = null;
    });

    try {
      final res = await LecturerAiService.analyzeClassScores(
        students: widget.students,
        languageCode: langCode,
      );
      if (!mounted) return;
      setState(() {
        _aiResult = res;
        _analyzingAi = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiError = langCode == 'id'
            ? 'Gagal memuat analisis AI. Silakan coba lagi.'
            : 'Failed to generate AI analysis. Please try again.';
        _analyzingAi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = ref.watch(languageProvider).languageCode;
    final isId = langCode == 'id';
    final theme = Theme.of(context);

    final preScores = widget.students
        .map((s) => s.pretestScore)
        .whereType<double>()
        .toList();
    final postScores = widget.students
        .map((s) => s.posttestScore)
        .whereType<double>()
        .toList();

    final avgPre = preScores.isEmpty
        ? 0.0
        : preScores.reduce((a, b) => a + b) / preScores.length;
    final avgPost = postScores.isEmpty
        ? 0.0
        : postScores.reduce((a, b) => a + b) / postScores.length;
    final gain = avgPost - avgPre;

    final passedCount = postScores.where((s) => s >= 70).length;
    final passRate = postScores.isEmpty
        ? 0.0
        : (passedCount / postScores.length) * 100.0;

    // Distribution buckets (using posttest if available, else pretest)
    int bucketExcellent = 0; // 85 - 100
    int bucketGood = 0; // 70 - 84
    int bucketFair = 0; // 55 - 69
    int bucketRemedial = 0; // < 55
    int bucketUnsubmitted = 0;

    for (final s in widget.students) {
      final effectiveScore = s.posttestScore ?? s.pretestScore;
      if (effectiveScore == null) {
        bucketUnsubmitted++;
      } else if (effectiveScore >= 85) {
        bucketExcellent++;
      } else if (effectiveScore >= 70) {
        bucketGood++;
      } else if (effectiveScore >= 55) {
        bucketFair++;
      } else {
        bucketRemedial++;
      }
    }

    final totalStudents = widget.students.isEmpty ? 1 : widget.students.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Metric Summary Row
        Row(
          children: [
            Expanded(
              child: _StatMiniCard(
                label: isId ? 'Rata-rata Pretest' : 'Avg Pretest',
                value: preScores.isEmpty ? '—' : avgPre.toStringAsFixed(1),
                sublabel: '${preScores.length}/${widget.students.length} mhs',
                icon: Icons.assignment_outlined,
                accentColor: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatMiniCard(
                label: isId ? 'Rata-rata Posttest' : 'Avg Posttest',
                value: postScores.isEmpty ? '—' : avgPost.toStringAsFixed(1),
                sublabel: postScores.isNotEmpty && preScores.isNotEmpty
                    ? '${gain >= 0 ? "+" : ""}${gain.toStringAsFixed(1)} pts'
                    : '${postScores.length}/${widget.students.length} mhs',
                icon: Icons.trending_up_rounded,
                accentColor: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatMiniCard(
                label: isId ? 'Kelulusan (≥70)' : 'Pass Rate (≥70)',
                value: postScores.isEmpty
                    ? '—'
                    : '${passRate.toStringAsFixed(0)}%',
                sublabel: isId
                    ? '$passedCount lulus'
                    : '$passedCount passed',
                icon: Icons.verified_rounded,
                accentColor: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),

        const SizedBox(height: NetLearnSpace.s12),

        // 2. Visual Charts Container (Pre vs Post Comparison + Grade Distribution)
        Container(
          padding: const EdgeInsets.all(NetLearnSpace.s16),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: context.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isId
                          ? 'Visualisasi Distribusi & Peningkatan Nilai'
                          : 'Score Distribution & Learning Gain Chart',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NetLearnSpace.s14),

              // Pretest vs Posttest Progress Comparison
              Text(
                isId
                    ? 'Perbandingan Rata-rata Kelas (Skala 0–100)'
                    : 'Class Average Comparison (0–100 Scale)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _ComparisonBarRow(
                label: 'Pretest',
                score: avgPre,
                color: const Color(0xFF6366F1),
              ),
              const SizedBox(height: 6),
              _ComparisonBarRow(
                label: 'Posttest',
                score: avgPost,
                color: const Color(0xFF10B981),
              ),

              const SizedBox(height: NetLearnSpace.s16),
              const Divider(height: 1),
              const SizedBox(height: NetLearnSpace.s14),

              // Grade Distribution Horizontal Bars
              Text(
                isId
                    ? 'Sebaran Kategori Nilai Mahasiswa'
                    : 'Student Grade Category Breakdown',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _DistributionRow(
                label: isId ? 'Sangat Baik (85–100)' : 'Excellent (85–100)',
                count: bucketExcellent,
                total: totalStudents,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 6),
              _DistributionRow(
                label: isId ? 'Baik / Lulus (70–84)' : 'Good / Pass (70–84)',
                count: bucketGood,
                total: totalStudents,
                color: const Color(0xFF8C52FF),
              ),
              const SizedBox(height: 6),
              _DistributionRow(
                label: isId ? 'Cukup (55–69)' : 'Fair (55–69)',
                count: bucketFair,
                total: totalStudents,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 6),
              _DistributionRow(
                label: isId ? 'Perlu Remedial (<55)' : 'Needs Remedial (<55)',
                count: bucketRemedial,
                total: totalStudents,
                color: const Color(0xFFEF4444),
              ),
              if (bucketUnsubmitted > 0) ...[
                const SizedBox(height: 6),
                _DistributionRow(
                  label: isId ? 'Belum Mengumpulkan' : 'Not Submitted Yet',
                  count: bucketUnsubmitted,
                  total: totalStudents,
                  color: Colors.grey,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: NetLearnSpace.s12),

        // 3. AI Analytics & Pedagogical Insight Card
        Container(
          padding: const EdgeInsets.all(NetLearnSpace.s16),
          decoration: BoxDecoration(
            color: context.accentTint.withAlpha(110),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: context.accent.withAlpha(80),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: context.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isId
                              ? 'Analisis & Kesimpulan AI (Asisten Dosen)'
                              : 'AI Score Analysis & Pedagogical Insight',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          isId
                              ? 'Evaluasi otomatis performa kelas & saran remedial'
                              : 'Automated class performance & remedial recommendations',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.mutedText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NetLearnSpace.s12),
              if (_aiResult != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        _aiResult!.markdownInsight,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.5,
                          color: context.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Powered by ${_aiResult!.providerName}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: context.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (_aiError != null) ...[
                Text(
                  _aiError!,
                  style: TextStyle(
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
                  label: _aiResult == null
                      ? (isId
                          ? 'Buat Analisis & Kesimpulan AI ✨'
                          : 'Generate AI Score Analysis ✨')
                      : (isId ? 'Perbarui Analisis AI' : 'Refresh AI Analysis'),
                  icon: Icons.analytics_outlined,
                  loading: _analyzingAi,
                  onPressed:
                      _analyzingAi ? null : () => _runAiAnalysis(langCode),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final IconData icon;
  final Color accentColor;

  const _StatMiniCard({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: context.mutedText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonBarRow extends StatelessWidget {
  final String label;
  final double score;
  final Color color;

  const _ComparisonBarRow({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clampedRatio = (score / 100.0).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: clampedRatio,
              minHeight: 10,
              backgroundColor: context.border.withAlpha(90),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            score.toStringAsFixed(1),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DistributionRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _DistributionRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
    final pct = (ratio * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$count mhs ($pct%)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: context.border.withAlpha(80),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
