import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../material_lab_binding.dart';

/// Kartu interaktif yang menampilkan tautan praktikum Virtual Lab 2D
/// pada halaman detail materi ([MaterialDetailPage]) maupun halaman baca materi ([MaterialReaderPage]).
class MaterialLabCard extends StatelessWidget {
  final MaterialLabBinding binding;
  final bool fromLecturer;

  const MaterialLabCard({
    super.key,
    required this.binding,
    this.fromLecturer = false,
  });

  void _openLab(BuildContext context) {
    final route = fromLecturer ? '/lecturer/virtual-lab' : '/student/virtual-lab';
    context.push(route, extra: binding);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(
          color: context.accent.withAlpha(isDark ? 80 : 50),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: context.accent.withAlpha(isDark ? 25 : 15),
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
                colors: [
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
                  Icons.science_rounded,
                  size: 18,
                  color: context.accent,
                ),
                const SizedBox(width: NetLearnSpace.s8),
                Text(
                  'PRAKTIKUM VIRTUAL LAB',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: context.accent,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.accent.withAlpha(isDark ? 50 : 30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _presetLabel(binding.preset),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.accent,
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
                  binding.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (binding.description != null &&
                    binding.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: NetLearnSpace.s6),
                  Text(
                    binding.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.mutedText,
                      height: 1.4,
                    ),
                  ),
                ],

                // Cuplikan Poin Instruksi
                if (binding.instructions.isNotEmpty) ...[
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
                              'Panduan Tugas Lab:',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: context.mutedText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...binding.instructions.take(2).map(
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
                                        style: theme.textTheme.bodySmall?.copyWith(
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
                        if (binding.instructions.length > 2)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '+ ${binding.instructions.length - 2} langkah lainnya di dalam lab',
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
                        'Praktikum mandiri & opsional (tidak memengaruhi progres bacaan).',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          color: context.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: NetLearnSpace.s10),

                // Tombol Buka Lab
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openLab(context),
                    icon: const Icon(Icons.hub_outlined, size: 18),
                    label: const Text('Buka di Virtual Lab'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.accent,
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
          ),
        ],
      ),
    );
  }

  String _presetLabel(String preset) {
    final effective = binding.referencePreset ?? preset;
    switch (effective) {
      case 'p2p':
        return 'Peer-to-Peer';
      case 'star':
        return 'Topologi Star';
      case 'dual_subnet':
        return 'Routing L3';
      case 'dhcp_server':
        return 'DHCP & Web';
      case 'custom':
        return 'Lab Dosen';
      case 'blank':
      default:
        return 'Lab Terbuka';
    }
  }
}
