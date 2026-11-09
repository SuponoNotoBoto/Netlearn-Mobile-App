import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sfx_service.dart';
import '../../../core/localization/language_controller.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/nl_snack_bar.dart';
import '../../classes/class_controller.dart';
import '../../dashboard_student/student_dashboard_controller.dart';
import '../../materials/material_lab_binding.dart';
import '../virtual_lab_leaderboard_service.dart';
import '../virtual_lab_mission.dart';
import '../virtual_lab_mission_service.dart';
import '../virtual_lab_model.dart';
import '../virtual_lab_network.dart';
import 'virtual_lab_leaderboard_sheet.dart';

/// Bottom sheet interaktif untuk melihat daftar target misi praktikum,
/// mengecek evaluasi otomatis, dan mengumpulkan hasil praktikum ke Cloud.
class VirtualLabMissionSheet extends ConsumerStatefulWidget {
  final MaterialLabBinding binding;
  final VirtualLabSession session;
  final VirtualLabConnectivityResult? lastTest;
  final VoidCallback? onRefreshRequested;

  const VirtualLabMissionSheet({
    super.key,
    required this.binding,
    required this.session,
    this.lastTest,
    this.onRefreshRequested,
  });

  static Future<void> show({
    required BuildContext context,
    required MaterialLabBinding binding,
    required VirtualLabSession session,
    VirtualLabConnectivityResult? lastTest,
    VoidCallback? onRefreshRequested,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VirtualLabMissionSheet(
        binding: binding,
        session: session,
        lastTest: lastTest,
        onRefreshRequested: onRefreshRequested,
      ),
    );
  }

  @override
  ConsumerState<VirtualLabMissionSheet> createState() =>
      _VirtualLabMissionSheetState();
}

class _VirtualLabMissionSheetState
    extends ConsumerState<VirtualLabMissionSheet> {
  VirtualLabMissionReport? _report;
  bool _isSubmitting = false;
  bool _isReevaluatingLive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluate();
    });
  }

  void _evaluate() {
    final languageCode = ref.read(languageProvider).languageCode;
    setState(() {
      _report = VirtualLabMissionEvaluator.evaluate(
        session: widget.session,
        binding: widget.binding,
        lastTest: widget.lastTest,
        languageCode: languageCode,
      );
    });
  }

  Future<void> _submitPractical(VirtualLabMissionReport currentReport, bool isEn) async {
    final l10nScore = currentReport.score;

    if (!currentReport.isPassed) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEn ? 'Submit Current Progress?' : 'Kumpulkan Progres Saat Ini?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Text(
            isEn
                ? 'You have completed ${currentReport.completedTasks} of ${currentReport.totalTasks} objectives (Score: $l10nScore/100).\n\nDo you want to submit this score now, or keep working to improve it?'
                : 'Anda baru menyelesaikan ${currentReport.completedTasks} dari ${currentReport.totalTasks} target objektif (Perolehan Skor: $l10nScore/100).\n\nApakah Anda ingin mengumpulkan nilai ini sekarang, atau mencoba melengkapinya terlebih dahulu?',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(isEn ? 'Keep Practicing' : 'Lanjutkan Praktikum'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(isEn
                  ? 'Submit ($l10nScore Pts)'
                  : 'Kumpulkan ($l10nScore Poin)'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() => _isSubmitting = true);

    try {
      final submission = VirtualLabMissionSubmission(
        id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
        userId: ref.read(virtualLabMissionServiceProvider).currentUserId,
        materialId: currentReport.materialId,
        materialTitle: currentReport.materialTitle,
        preset: currentReport.preset,
        score: currentReport.score,
        isPassed: currentReport.isPassed,
        submittedAt: DateTime.now(),
        completedTaskIds: currentReport.tasks
            .where((t) => t.isCompleted)
            .map((t) => t.id)
            .toList(),
        totalTasks: currentReport.totalTasks,
        topologySnapshot: widget.session.toJson(),
      );

      await ref
          .read(labSubmissionsProvider.notifier)
          .recordSubmission(submission);

      // Catat juga ke Virtual Lab Leaderboard
      try {
        final user = supabase.auth.currentUser;
        String studentName = 'Mahasiswa';
        if (user != null) {
          final cachedDashboard = ref.read(studentDashboardProvider).value;
          if (cachedDashboard != null && cachedDashboard.userName.trim().isNotEmpty) {
            studentName = cachedDashboard.userName.trim();
          } else {
            try {
              final profile = await supabase
                  .from('profiles')
                  .select('name')
                  .eq('id', user.id)
                  .maybeSingle();
              final dbName = profile?['name']?.toString().trim();
              if (dbName != null && dbName.isNotEmpty) {
                studentName = dbName;
              }
            } catch (_) {}
          }
        }

        final activeClass = ref.read(activeStudentClassProvider).value;
        final classId = (activeClass != null && !activeClass.isLegacyFallback) ? activeClass.id : null;

        await VirtualLabLeaderboardService.saveScore(
          classId: classId,
          studentId: submission.userId,
          studentName: studentName,
          materialId: submission.materialId,
          materialTitle: submission.materialTitle,
          preset: submission.preset,
          score: submission.score,
          completedTasks: submission.completedTaskIds.length,
          totalTasks: submission.totalTasks,
          isPassed: submission.isPassed,
        );
      } catch (_) {}

      if (!mounted) return;

      HapticFeedback.heavyImpact();
      SfxService.instance.playSuccess();

      setState(() {
        _isReevaluatingLive = false;
      });

      Navigator.pop(context); // Tutup bottom sheet

      // Tampilkan dialog selebrasi
      _showCelebrationDialog(submission, isEn);
    } catch (e) {
      if (mounted) {
        NlSnackBar.show(
          context,
          isEn
              ? 'Failed to submit practical: $e'
              : 'Gagal mengumpulkan praktikum: $e',
          tone: NlSnackTone.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showCelebrationDialog(VirtualLabMissionSubmission sub, bool isEn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: sub.isPassed
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (sub.isPassed
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6366F1))
                        .withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                sub.isPassed
                    ? Icons.emoji_events_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              sub.isPassed
                  ? (isEn ? 'Practicum Passed!' : 'Praktikum Berhasil!')
                  : (isEn ? 'Practicum Submitted!' : 'Praktikum Dikumpulkan!'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isEn
                  ? 'Final Practicum Score: ${sub.score} / 100'
                  : 'Skor Akhir Praktikum: ${sub.score} / 100',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: sub.isPassed
                    ? const Color(0xFF059669)
                    : const Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              sub.isPassed
                  ? (isEn
                      ? 'Congratulations! All network design criteria have been verified and saved securely to your account.'
                      : 'Selamat! Seluruh kriteria rancangan jaringan Anda telah terverifikasi dengan sempurna dan tersimpan aman di akun Anda.')
                  : (isEn
                      ? 'Your topology design has been saved. You can reopen it anytime to practice and improve your score.'
                      : 'Rancangan topologi Anda berhasil disimpan. Anda dapat membukanya kembali kapan saja untuk menyempurnakan skor praktikum.'),
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(isEn ? 'Close' : 'Tutup',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.emoji_events_rounded, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      VirtualLabLeaderboardSheet.show(
                        context,
                        initialMissionId: sub.preset.isNotEmpty ? sub.preset : sub.materialId,
                      );
                    },
                    label: Text(
                      isEn ? 'Leaderboard' : 'Peringkat',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEn = ref.watch(languageProvider).languageCode == 'en';

    // Cek apakah mahasiswa telah mengumpulkan praktikum modul ini
    final submissionsMap = ref.watch(labSubmissionsProvider).value;
    final key1 = widget.binding.materialId;
    final key2 = widget.binding.referencePreset ?? widget.binding.preset;
    final existingSubmission = submissionsMap?[key1] ?? submissionsMap?[key2];

    final hasSubmitted = existingSubmission != null && !_isReevaluatingLive;

    // Evaluasi dasar
    final baseReport = _report ??
        VirtualLabMissionEvaluator.evaluate(
          session: widget.session,
          binding: widget.binding,
          lastTest: widget.lastTest,
          languageCode: isEn ? 'en' : 'id',
        );

    // Jika sudah dikumpulkan dan tidak sedang live-retest, tampilkan kondisi submission yang sudah tersimpan
    final VirtualLabMissionReport report;
    if (hasSubmitted) {
      final sub = existingSubmission;
      final completedIds = sub.completedTaskIds.toSet();
      final adjustedTasks = baseReport.tasks.map((t) {
        final isDone = sub.isPassed || completedIds.contains(t.id);
        return t.copyWith(
          isCompleted: isDone,
          failureReason: isDone ? null : t.failureReason,
        );
      }).toList();

      report = VirtualLabMissionReport(
        materialId: baseReport.materialId,
        materialTitle: baseReport.materialTitle,
        preset: baseReport.preset,
        tasks: adjustedTasks,
        evaluatedAt: sub.submittedAt,
        languageCode: isEn ? 'en' : 'id',
      );
    } else {
      report = baseReport;
    }

    final displayScore = hasSubmitted ? existingSubmission.score : report.score;
    final displayPassed = hasSubmitted ? existingSubmission.isPassed : report.isPassed;

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (displayPassed
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6366F1))
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    displayPassed
                        ? Icons.emoji_events_rounded
                        : Icons.flag_circle_rounded,
                    color: displayPassed
                        ? const Color(0xFF059669)
                        : const Color(0xFF4F46E5),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? 'Lab Mission Objectives' : 'Target Misi Praktikum',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.binding.localized(isEn ? 'en' : 'id').title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.mutedText,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isEn ? 'Leaderboard' : 'Papan Peringkat',
                  onPressed: () {
                    VirtualLabLeaderboardSheet.show(
                      context,
                      initialMissionId: widget.binding.referencePreset ?? widget.binding.preset,
                    );
                  },
                  icon: const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                ),
                IconButton(
                  tooltip: isEn ? 'Check Again' : 'Periksa Ulang',
                  onPressed: () {
                    widget.onRefreshRequested?.call();
                    setState(() {
                      _isReevaluatingLive = true;
                    });
                    _evaluate();
                    HapticFeedback.lightImpact();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                ),
              ],
            ),
          ),

          // Progress bar strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: displayPassed
                    ? const Color(0xFFECFDF5)
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: displayPassed
                      ? const Color(0xFFA7F3D0)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasSubmitted
                              ? (isEn ? 'Status: Completed' : 'Status Praktikum: Selesai')
                              : (isEn ? 'Objective Progress' : 'Penyelesaian Objektif'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: displayPassed
                                ? const Color(0xFF065F46)
                                : const Color(0xFF475569),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasSubmitted
                            ? (isEn
                                ? 'Score: $displayScore/100'
                                : 'Skor: $displayScore/100')
                            : '${report.completedTasks}/${report.totalTasks} ${isEn ? "Done" : "Selesai"} ($displayScore%)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: displayPassed
                              ? const Color(0xFF059669)
                              : const Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: report.totalTasks == 0
                          ? 0
                          : (hasSubmitted ? 1.0 : report.completedTasks / report.totalTasks),
                      minHeight: 6,
                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        displayPassed
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Daftar Tugas
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              itemCount: report.tasks.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final task = report.tasks[index];
                return _buildTaskItem(task, isDark);
              },
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: context.surface,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                if (hasSubmitted) ...[
                  // Tombol untuk uji ulang kanvas
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isReevaluatingLive = true;
                        });
                        _evaluate();
                        HapticFeedback.lightImpact();
                        NlSnackBar.show(
                          context,
                          isEn
                              ? 'Now evaluating current canvas live.'
                              : 'Sedang mengevaluasi kanvas aktif saat ini.',
                          tone: NlSnackTone.info,
                        );
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(isEn ? 'Re-evaluate Canvas' : 'Uji Ulang Kanvas'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tombol lihat detail nilai
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        _showCelebrationDialog(existingSubmission, isEn);
                      },
                      icon: const Icon(Icons.emoji_events_rounded, size: 16),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isEn
                              ? 'View Score (${existingSubmission.score}/100)'
                              : 'Lihat Nilai (${existingSubmission.score}/100)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        _evaluate();
                        HapticFeedback.lightImpact();
                        NlSnackBar.show(
                          context,
                          report.summary(isEn ? 'en' : 'id'),
                          tone: report.isPassed
                              ? NlSnackTone.success
                              : NlSnackTone.info,
                        );
                      },
                      icon: const Icon(Icons.rule_folder_outlined, size: 16),
                      label: Text(isEn ? 'Check Status' : 'Periksa Status'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: report.isPassed
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : () => _submitPractical(report, isEn),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload_rounded, size: 16),
                      label: Text(
                        _isSubmitting
                            ? (isEn ? 'Saving...' : 'Menyimpan...')
                            : (isEn
                                ? 'Submit (${report.score})'
                                : 'Kumpulkan (${report.score})'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(VirtualLabMissionTask task, bool isDark) {
    final isDone = task.isCompleted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDone
            ? (isDark
                ? const Color(0xFF064E3B).withValues(alpha: 0.25)
                : const Color(0xFFF0FDF4))
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone
              ? const Color(0xFF86EFAC)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isDone ? 1.2 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isDone ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDone
                        ? (isDark
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFF065F46))
                        : (isDark ? Colors.white : const Color(0xFF1E293B)),
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
                if (!isDone && task.failureReason != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 11, color: Color(0xFFDC2626)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            task.failureReason!,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!isDone && task.hint != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded,
                          size: 11, color: Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          task.hint!,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFFB45309),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
