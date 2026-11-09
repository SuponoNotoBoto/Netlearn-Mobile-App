import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/language_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../virtual_lab/virtual_lab_mission.dart';
import '../../virtual_lab/virtual_lab_mission_service.dart';
import '../../virtual_lab/widgets/virtual_lab_leaderboard_sheet.dart';
import '../material_lab_binding.dart';

/// Kartu interaktif yang menampilkan tautan praktikum Virtual Lab 2D
/// pada halaman detail materi ([MaterialDetailPage]) maupun halaman baca materi ([MaterialReaderPage]).
///
/// Mendukung dwibahasa (ID/EN), status penilaian misi praktikum (Fase 7: Mission Checker),
/// dan memastikan teks cloud bersih tanpa kata "Supabase".
class MaterialLabCard extends ConsumerWidget {
  final MaterialLabBinding binding;
  final bool fromLecturer;
  final VirtualLabMissionSubmission? submission;

  const MaterialLabCard({
    super.key,
    required this.binding,
    this.fromLecturer = false,
    this.submission,
  });

  void _openLab(BuildContext context) {
    final route =
        fromLecturer ? '/lecturer/virtual-lab' : '/student/virtual-lab';
    context.push(route, extra: binding);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEn = ref.watch(languageProvider).languageCode == 'en';
    final effectiveBinding = binding.localized(isEn ? 'en' : 'id');

    // Ambil data submission jika pengguna sedang login
    VirtualLabMissionSubmission? activeSub = submission;
    if (activeSub == null) {
      try {
        final submissionsMap = ref.watch(labSubmissionsProvider).value;
        if (submissionsMap != null) {
          final key1 = binding.materialId;
          final key2 = binding.referencePreset ?? binding.preset;
          activeSub = submissionsMap[key1] ?? submissionsMap[key2];
        }
      } catch (_) {}
    }

    final isCompleted = activeSub != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF10B981).withAlpha(isDark ? 120 : 80)
              : context.accent.withAlpha(isDark ? 80 : 50),
          width: isCompleted ? 1.4 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? const Color(0xFF10B981) : context.accent)
                .withAlpha(isDark ? 25 : 15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header pita gradien
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: NetLearnSpace.s16,
              vertical: NetLearnSpace.s10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCompleted
                    ? [
                        const Color(0xFF10B981).withAlpha(isDark ? 55 : 35),
                        const Color(0xFF059669).withAlpha(isDark ? 30 : 20),
                      ]
                    : [
                        context.accent.withAlpha(isDark ? 45 : 30),
                        context.accentTint.withAlpha(isDark ? 25 : 15),
                      ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(NetLearnRadius.card - 1),
                topRight: Radius.circular(NetLearnRadius.card - 1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCompleted
                      ? Icons.verified_rounded
                      : Icons.science_rounded,
                  size: 18,
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : context.accent,
                ),
                const SizedBox(width: NetLearnSpace.s8),
                Text(
                  isCompleted
                      ? (isEn ? 'PRACTICUM COMPLETED' : 'PRAKTIKUM SELESAI')
                      : (isEn ? 'VIRTUAL LAB PRACTICUM' : 'PRAKTIKUM VIRTUAL LAB'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isCompleted
                        ? const Color(0xFF047857)
                        : context.accent,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF10B981).withAlpha(isDark ? 60 : 35)
                        : context.accent.withAlpha(isDark ? 50 : 30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted
                        ? (isEn
                            ? 'Score: ${activeSub.score}/100'
                            : 'Skor: ${activeSub.score}/100')
                        : _presetLabel(binding.preset, isEn),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isCompleted
                          ? (isDark
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFF065F46))
                          : context.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Konten Utama Kartu
          Padding(
            padding: const EdgeInsets.all(NetLearnSpace.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  effectiveBinding.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (effectiveBinding.description != null &&
                    effectiveBinding.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: NetLearnSpace.s6),
                  Text(
                    effectiveBinding.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.mutedText,
                      height: 1.4,
                    ),
                  ),
                ],

                // Banner jika praktikum telah berhasil diselesaikan
                if (isCompleted) ...[
                  const SizedBox(height: NetLearnSpace.s12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: Color(0xFF059669),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEn
                                    ? 'Evaluation Passed: Score ${activeSub.score}/100'
                                    : 'Evaluasi Lulus: Skor ${activeSub.score}/100',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                              Text(
                                isEn
                                    ? 'Saved to Cloud • ${_formatDate(activeSub.submittedAt)}'
                                    : 'Tersimpan di Cloud • ${_formatDate(activeSub.submittedAt)}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Cuplikan Poin Instruksi
                if (effectiveBinding.instructions.isNotEmpty && !isCompleted) ...[
                  const SizedBox(height: NetLearnSpace.s12),
                  Container(
                    padding: const EdgeInsets.all(NetLearnSpace.s12),
                    decoration: BoxDecoration(
                      color: context.raisedSurface.withAlpha(160),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: context.border.withAlpha(120),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.checklist_rounded,
                              size: 15,
                              color: context.mutedText,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isEn ? 'Lab Task Guide:' : 'Panduan Tugas Lab:',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: context.mutedText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...effectiveBinding.instructions.take(2).map(
                              (inst) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '• ',
                                      style: TextStyle(
                                        color: context.accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        inst,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: context.onSurface,
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        if (effectiveBinding.instructions.length > 2)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              isEn
                                  ? '+ ${effectiveBinding.instructions.length - 2} more steps in the lab'
                                  : '+ ${effectiveBinding.instructions.length - 2} langkah lainnya di dalam lab',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: context.accent,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: NetLearnSpace.s12),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 13,
                      color: context.mutedText,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        isCompleted
                            ? (isEn
                                ? 'This practical is completed. You are free to reopen the lab anytime to experiment.'
                                : 'Praktikum ini telah selesai. Anda tetap bebas membuka kembali lab untuk mencoba eksperimen baru.')
                            : (isEn
                                ? 'Self-directed & optional practical (does not affect reading progress). You may skip this practical to continue to the next material.'
                                : 'Praktikum mandiri & opsional (tidak memengaruhi progres bacaan). Anda dapat melewati praktikum ini untuk langsung lanjut materi berikutnya.'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          color: context.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: NetLearnSpace.s10),

                // Tombol Buka Lab & Leaderboard
                Row(
                  children: [
                    IconButton(
                      tooltip: isEn ? 'Leaderboard' : 'Papan Peringkat Praktikum',
                      icon: const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFFD97706),
                      ),
                      onPressed: () {
                        VirtualLabLeaderboardSheet.show(
                          context,
                          initialMissionId: binding.referencePreset ?? binding.preset,
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openLab(context),
                        icon: Icon(
                          isCompleted ? Icons.open_in_new_rounded : Icons.hub_outlined,
                          size: 18,
                        ),
                        label: Text(isCompleted
                            ? (isEn ? 'Reopen Lab' : 'Buka Kembali Lab')
                            : (isEn ? 'Open in Virtual Lab' : 'Buka di Virtual Lab')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isCompleted ? const Color(0xFF10B981) : context.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  String _presetLabel(String preset, bool isEn) {
    final effective = binding.referencePreset ?? preset;
    switch (effective) {
      case 'p2p':
        return 'Peer-to-Peer';
      case 'star':
        return isEn ? 'Star Topology' : 'Topologi Star';
      case 'dual_subnet':
        return 'Routing L3';
      case 'dhcp_server':
        return 'DHCP & Web';
      case 'custom':
        return isEn ? 'Lecturer Lab' : 'Lab Dosen';
      case 'blank':
      default:
        return isEn ? 'Open Canvas' : 'Lab Terbuka';
    }
  }
}
