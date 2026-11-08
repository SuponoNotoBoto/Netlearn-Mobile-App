import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/language_controller.dart';
import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/material_model.dart';
import '../../shared/models/learning_progress_model.dart';
import '../../shared/widgets/nl_empty_state.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_material_thumbnail.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/nl_topbar.dart';
import '../../shared/widgets/status_badge.dart';
import 'student_materials_controller.dart';

/// Daftar materi dalam satu modul.
///
/// Kartu modul di halaman Materials dulu langsung membuka `firstMaterialId`,
/// ketika satu modul memang hanya berisi satu materi. Setelah dosen dapat
/// menambah materi ke modul yang sudah ada, materi kedua dan seterusnya tidak
/// terjangkau dari daftar itu, jadi kartu modul kini membuka halaman ini dan
/// setiap materi tampil satu per satu.
class ModuleMaterialsPage extends ConsumerWidget {
  final int moduleNumber;

  const ModuleMaterialsPage({super.key, required this.moduleNumber});

  void _retry(WidgetRef ref) {
    // Tiga sumber yang dibaca layar ini di-refresh bersamaan: `StudentModule`
    // (pemegang status kunci), daftar materinya, dan baris progresnya.
    ref.invalidate(studentModulesProvider);
    ref.invalidate(moduleMaterialsProvider(moduleNumber));
    ref.invalidate(studentLearningProgressProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final materialsAsync = ref.watch(moduleMaterialsProvider(moduleNumber));
    final progressAsync = ref.watch(studentLearningProgressProvider);
    final modulesAsync = ref.watch(studentModulesProvider);

    final isLoading =
        materialsAsync.isLoading || progressAsync.isLoading ||
        modulesAsync.isLoading;

    final hasError =
        materialsAsync.hasError || progressAsync.hasError ||
        modulesAsync.hasError;

    return Scaffold(
      backgroundColor: context.background,

      // Halaman second-level: tanpa bottom navbar, cukup tombol kembali ke
      // daftar materi. `moduleNumber` dijamin int oleh router
      // (`app_router.dart`), jadi tidak ada cabang "modul tidak valid" lagi.
      appBar: NlTopBar(
        title: l10n.moduleEyebrow('$moduleNumber'),
        onBack: () => goBack(context, fallback: '/student/materials'),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 90),
                    NlErrorView(
                      message: l10n.failedToLoad,
                      onRetry: () => _retry(ref),
                    ),
                  ],
                )
              : _buildList(
                  context,
                  ref,
                  materials: materialsAsync.value ?? const <MaterialModel>[],
                  progress: progressAsync.value ?? const <LearningProgressModel>[],
                ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref, {
    required List<MaterialModel> materials,
    required List<LearningProgressModel> progress,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final modules = ref.watch(studentModulesProvider).value ?? const [];

    // Kalau modulnya ada dan terkunci, tampilkan pesan tanpa efek samping di
    // build: tidak ada dialog/snackbar yang dipanggil, dan pengguna kembali
    // lewat tombol top bar. Gerbang ini sebenarnya sudah dilewati dari kartu
    // modul di halaman Materials; cabang ini aman terhadap deep link.
    StudentModule? module;
    for (final candidate in modules) {
      if (candidate.moduleNumber == moduleNumber) {
        module = candidate;
        break;
      }
    }

    if (module != null && !module.unlocked) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 40),
          NlEmptyState(
            icon: Icons.lock_outline_rounded,
            title: l10n.lockedModuleMessage,
            message: module.blockedByPretest
                ? l10n.lockedNeedsPretest
                : l10n.completePreviousModule,
          ),
        ],
      );
    }

    if (materials.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 90),
          NlEmptyState(
            icon: Icons.menu_book_outlined,
            title: l10n.noMaterials,
            message: l10n.noMaterialsDescription,
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: context.accent,
      onRefresh: () async {
        _retry(ref);
        await ref.read(moduleMaterialsProvider(moduleNumber).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          NetLearnSpace.s20,
          NetLearnSpace.s20,
          NetLearnSpace.s20,
          NetLearnSpace.s32,
        ),
        children: [
          for (final material in materials)
            Padding(
              padding: const EdgeInsets.only(bottom: NetLearnSpace.s16),
              child: _ModuleMaterialCard(
                material: material,
                progress: progress,
              ),
            ),
        ],
      ),
    );
  }
}

class _ModuleMaterialCard extends ConsumerWidget {
  final MaterialModel material;
  final List<LearningProgressModel> progress;

  const _ModuleMaterialCard({
    required this.material,
    required this.progress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final languageCode = ref.watch(languageProvider).languageCode;

    final title = material.localizedTitle(languageCode);
    final description = material.localizedDescription(languageCode);

    final durationText = material.durationMinutes != null
        ? '${material.durationMinutes} ${l10n.minutes}'
        : null;

    // Aturan selesai yang dipakai di sini sama dengan
    // `get_learning_flow_status()` (bool_and): selesai = dibaca, dan video
    // selesai APABILA materi punya video. Kartu modul di dashboard memakai
    // `readingCompleted && videoCompleted` tanpa syarat video; untuk daftar
    // per materi, materi tanpa video tidak boleh terlihat "belum selesai"
    // harusnya karena tidak ada video yang bisa ditandai selesai.
    LearningProgressModel? row;
    for (final candidate in progress) {
      if (candidate.materialId == material.id) {
        row = candidate;
        break;
      }
    }

    final readingDone = row?.readingCompleted ?? false;
    final videoDone =
        material.videoId == null ? true : (row?.videoCompleted ?? false);
    final started = readingDone || (row?.videoCompleted ?? false);
    final completed = readingDone && videoDone;

    // `linked` = badge centang (selesai). `active` dipakai untuk dua status
    // sisanya: bedanya hanya teks, "In Progress" vs "Not Started".
    final badge = completed
        ? NetLearnStatus.linked
        : NetLearnStatus.active;
    final badgeLabel = completed
        ? l10n.completed
        : started
            ? l10n.inProgress
            : l10n.notStarted;

    // Override dosen (20261101130000). Materi terkunci tidak bisa dibaca dan
    // tidak akan pernah selesai, jadi badge progres semuanya tidak berarti:
    // yang tampil adalah badge "Kunci paksa" + pesan saat di-tap, bukan kartu
    // mati tanpa penjelasan. Materi buka-paksa tetap menunjukkan progresnya,
    // plus badge "Buka paksa" karena tidak menghitung syarat modul.
    final forcedLocked = material.lockStatus == 'locked';
    final forcedOpen = material.lockStatus == 'unlocked';

    return Material(
      color: context.surface,
      borderRadius: BorderRadius.circular(NetLearnRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (forcedLocked) {
            // Server menolak `mark_reading_completed` untuk materi ini
            // (MODULE_LOCKED), jadi lebih jelas memberi tahu di sini daripada
            // membuka reader dan membiarkan tombol "tandai selesai"-nya gagal
            // nanti dengan pesan server.
            NlSnackBar.show(context, l10n.materialAccessLockedItemMessage);

            return;
          }

          context.push('/student/material/${material.id}/read');
        },
        child: Container(
          padding: const EdgeInsets.all(NetLearnSpace.s15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NetLearnRadius.card),
            border: Border.all(color: context.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NlMaterialThumbnail(
                moduleNumber: material.moduleNumber,
                exampleIpLabel: l10n.materialArtExampleIp,
              ),

              const SizedBox(height: NetLearnSpace.s15),

              Text(
                title.isEmpty ? '-' : title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),

              if (description != null &&
                  description.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  description.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.mutedText,
                  ),
                ),
              ],

              const SizedBox(height: NetLearnSpace.s12),

              if (durationText != null) ...[
                Wrap(
                  spacing: NetLearnSpace.s6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 14,
                      color: context.mutedText,
                    ),
                    Text(
                      durationText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: NetLearnSpace.s12),
              ],

              // `.section-heading`: badge di kiri, chevron di kanan. Chevron
              // disembunyikan di materi yang dikunci karena tidak ada halaman
              // yang dibuka — tap-nya hanya memunculkan pesan.
              Wrap(
                spacing: NetLearnSpace.s8,
                runSpacing: NetLearnSpace.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (forcedLocked)
                    StatusBadge(
                      status: NetLearnStatus.down,
                      label: l10n.materialAccessForcedLockedBadge,
                    )
                  else ...[
                    StatusBadge(status: badge, label: badgeLabel),
                    if (forcedOpen)
                      StatusBadge(
                        status: NetLearnStatus.linked,
                        label: l10n.materialAccessForcedOpenBadge,
                      ),
                  ],
                  if (!forcedLocked)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: context.accent,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
