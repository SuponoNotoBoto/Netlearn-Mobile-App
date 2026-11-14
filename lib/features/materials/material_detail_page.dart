import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/language_controller.dart';
import '../../core/progress/progress_refresh.dart';
import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/material_model.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_section_heading.dart';
import '../../shared/widgets/nl_skeleton.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/nl_topbar.dart';
import '../../shared/widgets/nl_unavailable_notice.dart';
import 'pdf_download.dart';
import 'pdf_service.dart';
import 'student_materials_controller.dart';
import 'material_lab_binding.dart';
import 'widgets/material_lab_card.dart';

class MaterialDetailPage extends ConsumerWidget {
  final String materialId;

  /// Whether the lecturer opened this page from the lecturer materials list.
  ///
  /// When true, back navigation returns to `/lecturer/materials` instead of
  /// `/student/materials`. The student route leaves the default false.
  final bool fromLecturer;

  const MaterialDetailPage({
    super.key,
    required this.materialId,
    this.fromLecturer = false,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final language = ref.watch(languageProvider);

    final materialAsync = ref.watch(
      studentMaterialProvider(materialId),
    );

    final isUnlockedAsync = ref.watch(
      isMaterialUnlockedProvider(materialId),
    );

    final progressAsync = ref.watch(
      studentMaterialProgressProvider(materialId),
    );

    final languageCode = language.languageCode;

    final backFallback =
        fromLecturer ? '/lecturer/materials' : '/student/materials';

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          goBack(context, fallback: backFallback);
        }
      },
      child: Scaffold(
        backgroundColor: context.background,
        appBar: NlTopBar(
          title: l10n.materials,
          onBack: () => goBack(context, fallback: backFallback),
        ),
        body: materialAsync.when(
          loading: () => const NlSkeletonDetail(),
          error: (error, stackTrace) => NlErrorView(
            message: l10n.failedToLoad,
            onRetry: () {
              ref.invalidate(
                studentMaterialProvider(materialId),
              );
              ref.invalidate(
                isMaterialUnlockedProvider(materialId),
              );
            },
          ),
          data: (material) {
            if (material == null) {
              return NlErrorView(
                message: l10n.materialNotFound,
                onRetry: () => goBack(context, fallback: '/student/materials'),
              );
            }

            // Only hide the material when the server positively reports it as
            // locked. A failed or still-pending unlock check must not block
            // reading and watching the video.
            final isUnlocked = isUnlockedAsync.hasError
                ? true
                : (isUnlockedAsync.value ?? true);

            return _MaterialContent(
              material: material,
              languageCode: languageCode,
              isUnlocked: isUnlocked,
              progressAsync: progressAsync,
              fromLecturer: fromLecturer,
            );
          },
        ),
      ),
    );
  }
}

class _MaterialContent extends ConsumerWidget {
  final MaterialModel material;
  final String languageCode;
  final bool isUnlocked;
  final AsyncValue progressAsync;

  /// Diteruskan dari [MaterialDetailPage.fromLecturer]: Video page yang sama
  /// dipakai dua role, tetapi route pemutar harus mengikuti cabang yang
  /// membuka halaman ini (`/lecturer/video/...` vs `/student/video/...`).
  /// Mendorong dosen ke `/student/video/...` membuat role guard memantulkannya
  /// kembali ke dashboard, bukan ke pemutar.
  final bool fromLecturer;

  const _MaterialContent({
    required this.material,
    required this.languageCode,
    required this.isUnlocked,
    required this.progressAsync,
    required this.fromLecturer,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final progress = progressAsync.value;

    // Calculate progress percentage for this material
    int progressPercent = 0;
    if (progress?.readingCompleted == true) {
      progressPercent = 100;
    } else if (progress?.videoCompleted == true) {
      progressPercent = 75;
    } else if (isUnlocked) {
      progressPercent = 25;
    }

    final title = material.localizedTitle(
      languageCode,
    );

    final description = material.localizedDescription(
      languageCode,
    );

    final content = material.localizedContent(
      languageCode,
    );

    final summary = material.localizedSummary(
      languageCode,
    );

    final labBinding = MaterialLabBinding.fromMaterial(material);

    // Batas lebar kolom: di tablet satu paragraf 900px tidak terbaca, dan
    // kartu selebar layar membuat hierarki judul hilang. 360dp dan 430dp tidak
    // tersentuh karena `maxWidth` hanya menahan, tidak memaksa.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        NetLearnSpace.s20,
        NetLearnSpace.s20,
        NetLearnSpace.s20,
        NetLearnSpace.s32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: NetLearnSpace.readingMeasure,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReadingHeader(
                title: title,
                description: description,
                moduleNumber: material.moduleNumber,
                progressPercent: progressPercent,
              ),
              const SizedBox(
                height: NetLearnSpace.s20,
              ),
              _MaterialMeta(
                durationMinutes: material.durationMinutes,
                isCore: material.isCore,
              ),
              const SizedBox(
                height: NetLearnSpace.s20,
              ),
              if (!isUnlocked)
                const _LockedCard()
              else ...[
                NlSectionHeading(
                  title: l10n.learningMaterial,
                  leadingIcon: Icons.menu_book_outlined,
                ),
                _ReadingActionCard(
                  materialId: material.id,
                  hasContent: (content != null && content.trim().isNotEmpty) ||
                      (summary != null && summary.trim().isNotEmpty),
                  completed: progress?.readingCompleted ?? false,
                ),
                const SizedBox(
                  height: NetLearnSpace.s16,
                ),
                NlSectionHeading(
                  title: l10n.video,
                  leadingIcon: Icons.play_circle_outline_rounded,
                ),
                _VideoCard(
                  materialId: material.id,
                  videoId: material.videoId,
                  videoUrl: material.videoUrl,
                  completed: progress?.videoCompleted ?? false,
                  fromLecturer: fromLecturer,
                  // Watched the video on this detail page, so the module list
                  // and dashboard may have advanced by the time we come back.
                  onWatched: () {
                    invalidateStudentProgress(ref);
                  },
                ),
                const SizedBox(
                  height: NetLearnSpace.s20,
                ),
                if (summary != null && summary.trim().isNotEmpty) ...[
                  _SummaryCard(
                    summary: summary,
                  ),
                  const SizedBox(
                    height: NetLearnSpace.s20,
                  ),
                ],
                if (labBinding != null) ...[
                  const NlSectionHeading(
                    title: 'Praktikum & Simulasi',
                    leadingIcon: Icons.science_outlined,
                  ),
                  MaterialLabCard(
                    binding: labBinding,
                    fromLecturer: fromLecturer,
                  ),
                  const SizedBox(
                    height: NetLearnSpace.s20,
                  ),
                ],
                _MaterialResources(
                  material: material,
                  languageCode: languageCode,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// `.reading-header` dari desain Figma: eyebrow modul, judul, progress label + persentase, progress track.
class _ReadingHeader extends StatelessWidget {
  final String title;
  final String? description;
  final int? moduleNumber;
  final int progressPercent;

  const _ReadingHeader({
    required this.title,
    required this.description,
    required this.moduleNumber,
    required this.progressPercent,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final trimmedDescription = description?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (moduleNumber != null) ...[
          Text(
            l10n.moduleEyebrow(
              moduleNumber.toString().padLeft(2, '0'),
            ).toUpperCase(),
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(
            height: NetLearnSpace.s6,
          ),
        ],

        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.headlineSmall,
          ),
        ),

        if (trimmedDescription.isNotEmpty) ...[
          const SizedBox(
            height: NetLearnSpace.s8,
          ),
          Text(
            trimmedDescription,
            style: theme.textTheme.bodyLarge?.copyWith(
                  color: context.mutedText,
                  height: 1.65,
                ),
          ),
        ],

        const SizedBox(height: NetLearnSpace.s16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.readingProgress,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.mutedText,
                fontSize: 10,
              ),
            ),
            Text(
              '$progressPercent%',
              style: NetLearnDisplay.progress.copyWith(
                fontSize: 17,
                color: context.accent,
              ),
            ),
          ],
        ),

        const SizedBox(height: NetLearnSpace.s8),

        ClipRRect(
          borderRadius: BorderRadius.circular(NetLearnRadius.pill / 2),
          child: Container(
            height: NetLearnSpace.s5,
            color: isDark
                ? NetLearnColors.darkProgressTrackBg
                : NetLearnColors.progressTrackBg,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressPercent / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: NetLearnGradients.progress,
                  borderRadius: BorderRadius.circular(NetLearnRadius.pill / 2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MaterialMeta extends StatelessWidget {
  final int? durationMinutes;
  final bool isCore;

  const _MaterialMeta({
    required this.durationMinutes,
    required this.isCore,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: NetLearnSpace.s8,
      runSpacing: NetLearnSpace.s8,
      children: [
        if (durationMinutes != null)
          _MetaPill(
            icon: Icons.schedule_outlined,
            text: '$durationMinutes ${l10n.minutes}',
          ),
        if (isCore)
          _MetaPill(
            icon: Icons.star_outline_rounded,
            text: l10n.coreMaterial,
          ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NetLearnSpace.s12,
        vertical: NetLearnSpace.s8,
      ),
      decoration: BoxDecoration(
        color: context.accentTint,
        borderRadius: BorderRadius.circular(
          NetLearnRadius.pill,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: context.onAccentTint,
          ),
          const SizedBox(
            width: NetLearnSpace.s4,
          ),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.onAccentTint,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String summary;

  const _SummaryCard({
    required this.summary,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    // `accentTint` bukan `NetLearnColors.mint`: alias mint adalah nilai tetap
    // `#e9e3fb` yang tidak pernah berubah di mode gelap, jadi teks ungu gelap
    // pernah hilang di atas latar ungu gelap.
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 16,
                color: context.mutedText,
              ),
              const SizedBox(width: 8),
              Text(
                'RINGKASAN MATERI',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.mutedText,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
              ),
            ],
          ),
          const SizedBox(
            height: NetLearnSpace.s8,
          ),
          Text(
            summary,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.onSurface,
                  fontWeight: FontWeight.w400,
                  height: 1.7,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReadingActionCard extends StatelessWidget {
  final String materialId;
  final bool hasContent;
  final bool completed;

  const _ReadingActionCard({
    required this.materialId,
    required this.hasContent,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _ContentActionCard(
      icon: Icons.menu_book_outlined,
      title: l10n.readMaterial,
      description: hasContent
          ? l10n.readMaterialDescription
          : l10n.materialContentUnavailable,
      completed: completed,
      enabled: true,
      buttonText: completed
          ? l10n.continueReading
          : l10n.markAsRead,
      onPressed: () {
        context.push('/student/material/$materialId/read');
      },
    );
  }
}

class _VideoCard extends StatelessWidget {
  final String materialId;
  final String? videoId;
  final String? videoUrl;
  final bool completed;

  /// Benar bila halaman ini dibuka dari daftar materi dosen
  /// (`/lecturer/materials/:id/view`). Pemutar video yang sama dipakai dua
  /// role, tetapi route-nya harus mengikuti cabang pembuka: dosen yang
  /// didorong ke `/student/video/...` dipantulkan role guard kembali ke
  /// dashboard, bukan ke pemutar video.
  final bool fromLecturer;

  /// Dipanggil setelah halaman video ditutup.
  ///
  /// Callback, bukan `WidgetRef` yang diteruskan ke widget stateless:
  /// invalidasi progres tetap milik [_MaterialContent] yang memiliki `ref`, jadi
  /// kartu ini tidak ikut dibangun ulang hanya karena pemanggilnya berubah state.
  /// Tidak ada perubahan perilaku -- pemanggilan yang sama seperti sebelumnya.
  final VoidCallback? onWatched;

  const _VideoCard({
    required this.materialId,
    required this.videoId,
    required this.videoUrl,
    required this.completed,
    this.fromLecturer = false,
    this.onWatched,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;

    final available = (videoId != null && videoId!.trim().isNotEmpty) ||
        (videoUrl != null && videoUrl!.trim().isNotEmpty);

    return _ContentActionCard(
      icon: Icons.play_circle_outline_rounded,
      title: l10n.learningVideo,
      description: available
          ? l10n.learningVideoDescription
          : l10n.videoUnavailable,
      completed: completed,
      enabled: available,
      buttonText: completed ? l10n.watched : l10n.videoOptional,
      // "Supporting Video" langsung ke pemutar video milik materi ini —
      // materialId yang sama menentukan video yang dimainkan (ID YouTube dari
      // baris tabel `materials`), jadi video Modul 4 selalu ikut Modul 4.
      // Bukan halaman daftar video.
      onPressed: available
          ? () async {
              final videoBase = fromLecturer ? '/lecturer' : '/student';

              await context.push('$videoBase/video/$materialId');

              // Watched the video on this detail page, so the module list and
              // dashboard may have advanced by the time we come back.
              onWatched?.call();
            }
          : null,
    );
  }
}

class _ContentActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool completed;
  final bool enabled;
  final String buttonText;
  final VoidCallback? onPressed;

  const _ContentActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.completed,
    required this.enabled,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  // `accentTint` is `primaryContainer`, which follows the
                  // theme; the previous `NetLearnColors.mint` was a fixed
                  // light-only lavender that kept a white-ish tile in dark mode.
                  color: completed
                      ? context.accentTint
                      : context.raisedSurface,
                  borderRadius: BorderRadius.circular(
                    NetLearnRadius.card,
                  ),
                ),
                child: Icon(
                  completed ? Icons.check_rounded : icon,
                  color: context.accent,
                  size: 22,
                ),
              ),
              const SizedBox(
                width: NetLearnSpace.s12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(
                      height: NetLearnSpace.s4,
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.5,
                            color: context.mutedText,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: NetLearnSpace.s12,
          ),

          // `NlButton` sekarang, bukan `OutlinedButton` setinggi 36px. Targets
          // sentuh Material minimal 48px, dan `.button` di desain memang
          // setinggi itu, jadi tombol 36px ini menyimpang dari keduanya.
          NlButton(
            label: buttonText,
            icon: enabled ? icon : null,
            variant: completed
                ? NlButtonVariant.outline
                : NlButtonVariant.primary,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class _LockedCard extends StatelessWidget {
  const _LockedCard();

  @override
  Widget build(
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        NetLearnSpace.s20,
      ),
      decoration: BoxDecoration(
        color: context.raisedSurface,
        borderRadius: BorderRadius.circular(
          NetLearnRadius.card,
        ),
        border: Border.all(
          color: context.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: context.mutedText,
            size: 30,
          ),
          const SizedBox(
            height: NetLearnSpace.s8,
          ),
          Text(
            l10n.materialLocked,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(
            height: NetLearnSpace.s4,
          ),
          Text(
            l10n.completePreviousModule,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.mutedText,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

/// `.material-resources` dari Figma: section untuk PDF view/download.
class _MaterialResources extends StatelessWidget {
  final MaterialModel material;
  final String languageCode;

  const _MaterialResources({
    required this.material,
    required this.languageCode,
  });

  Future<void> _downloadPdf(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final signedUrl = await resolveMaterialPdfUrl(material.pdfUrl);

      if (signedUrl == null) {
        throw Exception('Could not resolve the PDF URL');
      }

      final bytes = await downloadMaterialPdfBytes(signedUrl);

      await saveAndOpenPdf(bytes, 'NetLearn_${material.id}.pdf');

      if (!context.mounted) {
        return;
      }

      NlSnackBar.show(
        context,
        l10n.pdfDownloadSuccess,
        tone: NlSnackTone.success,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      // The user only sees a neutral line; the raw cause (bucket/policy name,
      // HTTP status, timeout) stays in the log so a failure report is
      // diagnosable instead of vanishing into a silent `catch (_)`.
      debugPrint('PDF download failed (${material.id}): $error');

      NlSnackBar.show(
        context,
        l10n.pdfDownloadFailed,
        tone: NlSnackTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final hasPdf = material.pdfUrl != null && material.pdfUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NetLearnSpace.s16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.materialResources,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: NetLearnSpace.s8),
          if (hasPdf)
            Text(
              l10n.materialResourcesDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.mutedText,
              ),
            )
          else
            NlUnavailableNotice(
              message: l10n.noPdfAvailable,
              icon: Icons.picture_as_pdf_outlined,
            ),
          if (hasPdf) ...[
            const SizedBox(height: NetLearnSpace.s16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push(
                        '/student/material/${material.id}/pdf',
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: Text(l10n.viewPdf),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: context.accent,
                      side: BorderSide(color: context.accent),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(NetLearnRadius.button),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: NetLearnSpace.s12),
                Expanded(
                  child: NlButton(
                    label: l10n.downloadPdf,
                    icon: Icons.download_outlined,
                    variant: NlButtonVariant.primary,
                    onPressed: () => _downloadPdf(context),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
