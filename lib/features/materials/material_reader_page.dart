import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/language_controller.dart';
import '../../core/progress/posttest_prompt.dart';
import '../../core/progress/progress_refresh.dart';
import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/learning_flow_status_model.dart';
import '../../shared/models/material_model.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/nl_topbar.dart';
import '../../shared/widgets/nl_unavailable_notice.dart';
import '../classes/class_controller.dart';
import 'material_body_parser.dart';
import 'pdf_download.dart';
import 'pdf_service.dart';
import 'student_materials_controller.dart';
import 'material_lab_binding.dart';
import 'widgets/material_lab_card.dart';

/// Full-screen reading view for a material.
///
/// The detail page only offers a way in; all of the body copy lives here so
/// long material is never truncated behind a "read more" toggle.
///
/// One continuous `ListView` from the title to the last paragraph -- there is no
/// page turn, no section index and no pagination. The Figma source agrees:
/// `.reader-phone` only hides the bottom nav, and the reading screen is a single
/// `.scroll-area` with one `.reader-sticky` footer, not a pager.
class MaterialReaderPage extends ConsumerWidget {
  final String materialId;

  /// Dosen membaca materi untuk meninjau kontennya, bukan untuk menyelesaikan
  /// progres belajar: footer "Mark as Read", section "Mark All as Read", dan
  /// chip "Read" dipangkas, dan fallback kembali/PDF mengikuti cabang
  /// `/lecturer/**`. Default `false` = jalur mahasiswa penuh.
  final bool fromLecturer;

  const MaterialReaderPage({
    super.key,
    required this.materialId,
    this.fromLecturer = false,
  });

  /// Fallback navigasi kembali mengikuti cabang route: aksi dosen yang
  /// didorong ke `/student/**` dipantulkan role guard, jadi mahasiswa dan
  /// dosen tidak bisa berbagi satu string fallback.
  String get _materialsFallback =>
      fromLecturer ? '/lecturer/materials' : '/student/materials';

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = ref.watch(languageProvider).languageCode;

    final materialAsync = ref.watch(
      studentMaterialProvider(materialId),
    );

    final progressAsync = ref.watch(
      studentMaterialProgressProvider(materialId),
    );

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          goBack(context, fallback: _materialsFallback);
        }
      },
      child: Scaffold(
        backgroundColor: context.background,
        appBar: NlTopBar(
          title: l10n.readMaterialTitle,
          onBack: () => goBack(context, fallback: _materialsFallback),
        ),
        body: materialAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => NlErrorView(
            message: l10n.failedToLoad,
            onRetry: () {
              ref.invalidate(
                studentMaterialProvider(materialId),
              );
            },
          ),
          data: (material) {
            if (material == null) {
              return NlErrorView(
                message: l10n.materialNotFound,
              );
            }

            return _ReaderBody(
              material: material,
              languageCode: languageCode,
              completed: progressAsync.value?.readingCompleted ?? false,
              fromLecturer: fromLecturer,
            );
          },
        ),
      ),
    );
  }
}

class _ReaderBody extends ConsumerStatefulWidget {
  final MaterialModel material;
  final String languageCode;
  final bool completed;

  /// Mirror of [MaterialReaderPage.fromLecturer] — see its doc.
  final bool fromLecturer;

  const _ReaderBody({
    required this.material,
    required this.languageCode,
    required this.completed,
    required this.fromLecturer,
  });

  @override
  ConsumerState<_ReaderBody> createState() => _ReaderBodyState();
}

class _ReaderBodyState extends ConsumerState<_ReaderBody> {
  final ScrollController _scrollController = ScrollController();

  bool _isSaving = false;
  bool _isMarkingAllAsRead = false;
  bool _isDownloadingPdf = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int get _progressPercent {
    if (widget.completed) {
      return 100;
    }
    // If not completed but has video watched, show 75%
    // For simplicity, we'll use 25% as base for unlocked but not read
    return 25;
  }

  Future<void> _markAsRead() async {
    if (_isSaving || widget.completed) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isSaving = true;
    });

    try {
      // Snapshot the flow before the write so the post-test prompt fires on
      // the completion that unlocked it, not on a later revisit. A failed
      // snapshot only costs the prompt -- it must never block the write.
      final flowBefore = await _readFlowSnapshot();

      final activeClass = await resolveActiveStudentClass(ref);

      await ref
          .read(studentServiceProvider)
          .markReadingCompleted(
            widget.material.id,
            classId: activeClass?.id,
          );

      if (!mounted) {
        return;
      }

      // The row is written at this point, so this action succeeded whatever
      // the refresh below does. Announcing the failure here is what produced
      // "error muncul padahal progres tersimpan": the write had already
      // committed and only a post-write read had thrown.
      NlSnackBar.show(
        context,
        l10n.readingMarked,
        tone: NlSnackTone.success,
      );

      // The next module unlocks once this material is marked read, and the
      // dashboard percentage moves with it -- but that refresh is derived
      // state, so its failure is logged, never surfaced as a failed save.
      try {
        await _refreshAndPromptPosttest(flowBefore);
      } catch (refreshErr) {
        debugPrint('post-write flow refresh failed: $refreshErr');
      }
    } catch (error) {
      // Pesan mentah dari exception (PostgREST memasukkan nama tabel/policy
      // ke dalam message) tidak boleh mendongak ke UI; detailnya hanya ke
      // log. Gilirannya yang ditampilkan adalah kalimat netral.
      debugPrint('markReadingCompleted failed: $error');

      if (!mounted) {
        return;
      }

      NlSnackBar.show(
        context,
        l10n.bannerUnknownError,
        tone: NlSnackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Marks all materials in the current module as read.
  Future<void> _markAllAsRead() async {
    if (_isMarkingAllAsRead || widget.material.moduleNumber == null) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final moduleNumber = widget.material.moduleNumber!;

    setState(() {
      _isMarkingAllAsRead = true;
    });

    try {
      // Get all materials in this module
      final materials = await ref.read(moduleMaterialsProvider(moduleNumber).future);

      // Snapshot flow before
      final flowBefore = await _readFlowSnapshot();

      final activeClass = await resolveActiveStudentClass(ref);

      // Mark each material as read. One row failing must not hide the rows
      // that did commit, so failures are collected instead of aborting the
      // loop: a partial batch is still progress the student can see.
      var marked = 0;
      var attempted = 0;
      for (final material in materials) {
        if (material.id.isEmpty) {
          continue;
        }

        attempted++;
        try {
          await ref.read(studentServiceProvider).markReadingCompleted(
            material.id,
            classId: activeClass?.id,
          );
          marked++;
        } catch (error) {
          debugPrint('markAllAsRead item failed (${material.id}): $error');
        }
      }

      if (!mounted) return;

      // Tidak satu pun baris tersimpan: jangan menampilkan "sudah ditandai"
      // untuk nol baris. Ini yang dulu terjadi saat RPC penandaan belum ada --
      // snackbar sukses padahal tidak ada progres yang berubah.
      if (attempted > 0 && marked == 0) {
        NlSnackBar.show(
          context,
          l10n.bannerUnknownError,
          tone: NlSnackTone.error,
        );
        return;
      }

      NlSnackBar.show(
        context,
        l10n.readingMarked,
        tone: NlSnackTone.success,
      );

      try {
        await _refreshAndPromptPosttest(flowBefore);
      } catch (refreshErr) {
        debugPrint('post-batch flow refresh failed: $refreshErr');
      }
    } catch (error) {
      // Sama dengan alur satu materi: pesan mentah not ke UI, detail ke log.
      debugPrint('markAllAsRead failed: $error');

      if (!mounted) return;

      NlSnackBar.show(
        context,
        l10n.bannerUnknownError,
        tone: NlSnackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAllAsRead = false;
        });
      }
    }
  }

  /// Learning-flow snapshot taken *before* a completion write.
  ///
  /// Returns `null` instead of throwing: the snapshot only feeds the post-test
  /// prompt, so a flow that cannot be read must not turn a successful write
  /// into a failed one.
  Future<LearningFlowStatusModel?> _readFlowSnapshot() async {
    try {
      return await ref.read(studentLearningFlowStatusProvider.future);
    } catch (error) {
      debugPrint('learning flow snapshot failed: $error');
      return null;
    }
  }

  /// Refreshes the flow after a completion write and offers the post-test on
  /// the locked-to-unlocked edge.
  ///
  /// Runs *after* the success snackbar and swallows its own failures: the
  /// progress row is already stored, so a refresh problem (`invalidate` raises
  /// if the container is already gone, a flow read can time out) may cost the
  /// prompt but must never be reported as a failed save.
  Future<void> _refreshAndPromptPosttest(
    LearningFlowStatusModel? flowBefore,
  ) async {
    if (flowBefore == null || !mounted) {
      return;
    }

    try {
      invalidateStudentProgress(ref);

      final flowAfter = await ref.read(studentLearningFlowStatusProvider.future);

      if (!mounted) {
        return;
      }

      await maybePromptPosttest(
        context,
        ref,
        wasUnlocked: flowBefore.posttestUnlocked,
        flow: flowAfter,
      );
    } catch (error) {
      debugPrint('post-write flow refresh failed: $error');
    }
  }

  void _viewPdf() {
    // The resources section only renders this action when the material has a
    // PDF, so there is nothing to check here -- the viewer page owns the load
    // state and its top bar owns the back navigation.
    //
    // Basis route mengikuti cabang pembuka reader: route PDF mahasiswa
    // tidak dipantulkan role guard untuk dosen.
    final pdfBase = widget.fromLecturer ? '/lecturer' : '/student';

    context.push('$pdfBase/material/${widget.material.id}/pdf');
  }

  Future<void> _downloadPdf() async {
    if (_isDownloadingPdf) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isDownloadingPdf = true;
    });

    // The download must surface its result through `context` with guard —
    // the state widget may be gone by the time it finishes, and a snackbar
    // from a dead page would just leak into nobody's screen.
    try {
      final signedUrl = await resolveMaterialPdfUrl(
        widget.material.pdfUrl,
      );

      if (signedUrl == null) {
        throw Exception('Could not resolve the PDF URL');
      }

      final bytes = await downloadMaterialPdfBytes(signedUrl);

      await saveAndOpenPdf(
        bytes,
        'NetLearn_${widget.material.id}.pdf',
      );

      if (!mounted) {
        return;
      }

      NlSnackBar.show(
        context,
        l10n.pdfDownloadSuccess,
        tone: NlSnackTone.success,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      // Detail mentah hanya ke log, sama seperti alur mark-as-read: pesannya
      // bisa memuat nama bucket/policy/url. Tanpa log ini kegagalan PDF tidak
      // bisa ditelusuri dari perangkat.
      debugPrint('PDF download failed (${widget.material.id}): $error');

      NlSnackBar.show(
        context,
        l10n.pdfDownloadFailed,
        tone: NlSnackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingPdf = false;
        });
      }
    }
  }

  void _goToVideo() {
    // `push`, bukan `pushReplacement`: stack masih memegang halaman baca, jadi
    // tombol kembali di halaman video mendarat kembali di materi ini — bukan
    // lompat ke daftar materi/dashboard.
    //
    // Basis route mengikuti cabang yang membuka reader (`/student/**` hari
    // ini; dosen punya cabang sendiri bila kelak dibuka), supaya dosen tidak
    // pernah didorong ke `/student/video/...` yang dipantulkan role guard.
    final location = GoRouter.of(context).state.matchedLocation;
    final videoBase = location.startsWith('/lecturer') ? '/lecturer' : '/student';

    context.push('$videoBase/video/${widget.material.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final title = widget.material.localizedTitle(
      widget.languageCode,
    );

    // Kotak SUMMARY ungu dihapus dari reader (approval revi desain): judul,
    // durasi, progres, dan langsung isi bacaan. `summary` materi tetap hidup
    // di halaman detail; kalau ternyata dipakai lagi di sini, anggap keputusan
    // produk baru — jangan dibangun ulang diam-diam.

    final rawContent = widget.material.localizedContent(
      widget.languageCode,
    )?.trim();

    final content = rawContent != null
        ? MaterialLabBinding.stripLabTag(rawContent)
        : null;

    final hasContent = content != null && content.isNotEmpty;

    final labBinding = MaterialLabBinding.fromMaterial(widget.material);

    final hasVideo = _hasVideo(widget.material);

    final bottomInset = MediaQuery.of(context).padding.bottom;
    final double netBotBottom;
    if (widget.fromLecturer) {
      netBotBottom = bottomInset + 16;
    } else {
      final footerHeight = (widget.completed && hasVideo) ? 128.0 : 72.0;
      netBotBottom = bottomInset + footerHeight + 16;
    }

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SelectionArea(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                NetLearnSpace.s20,
                NetLearnSpace.s20,
                NetLearnSpace.s20,
                NetLearnSpace.s32,
              ),
              children: [
                // Batas lebar kolom bacaan. Di tablet tanpa ini satu paragraf
                // bisa selebar layar penuh; di 360dp dan 430dp tidak ada
                // efeknya karena `maxWidth` hanya menahan, tidak memaksa.
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: NetLearnSpace.readingMeasure,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ReaderHeader(
                          title: title,
                          moduleNumber: widget.material.moduleNumber,
                          durationMinutes: widget.material.durationMinutes,
                          progressPercent: _progressPercent,
                        ),
                        const SizedBox(
                          height: NetLearnSpace.s24,
                        ),
                        if (hasContent)
                          _BodyText(
                            text: content,
                          )
                        else
                          _InlineMessage(
                            message: l10n.noReadingContent,
                          ),
                        if (labBinding != null) ...[
                          const SizedBox(
                            height: NetLearnSpace.s20,
                          ),
                          MaterialLabCard(
                            binding: labBinding,
                            fromLecturer: widget.fromLecturer,
                          ),
                        ],
                        const SizedBox(
                          height: NetLearnSpace.s20,
                        ),
                        // Material Resources section
                        _MaterialResources(
                          material: widget.material,
                          languageCode: widget.languageCode,
                          onViewPdf: _viewPdf,
                          onDownloadPdf: _downloadPdf,
                          isDownloadingPdf: _isDownloadingPdf,
                        ),
                        const SizedBox(
                          height: NetLearnSpace.s16,
                        ),
                        _ModuleDiscussionCard(
                          material: widget.material,
                          languageCode: widget.languageCode,
                          fromLecturer: widget.fromLecturer,
                        ),
                        const SizedBox(
                          height: NetLearnSpace.s20,
                        ),
                        // Mark All as Read button (mahasiswa saja — dosen
                        // tidak menulis progres belajar; only show if module
                        // has multiple materials).
                        if (!widget.fromLecturer &&
                            widget.material.moduleNumber != null)
                          _MarkAllAsReadSection(
                            moduleNumber: widget.material.moduleNumber!,
                            completed: widget.completed,
                            isLoading: _isMarkingAllAsRead,
                            onMarkAllAsRead: _markAllAsRead,
                          ),
                        const SizedBox(
                          height: NetLearnSpace.s20,
                        ),
                        // Video Learning section
                        if (hasVideo)
                          _VideoLearningSection(
                            material: widget.material,
                            languageCode: widget.languageCode,
                            onGoToVideo: _goToVideo,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Footer aksi ini milik mahasiswa: tombol "Mark as Read"/chip "Read"
        // menulis `learning_progress`, dan dosen tidak punya progres untuk
        // ditandai. Tanpa footer, dosen tetap dapat video dari section di atas.
        if (!widget.fromLecturer)
          _ReaderFooter(
            completed: widget.completed,
            isSaving: _isSaving,
            hasContent: hasContent,
            hasVideo: hasVideo,
            onMarkAsRead: _markAsRead,
            onGoToVideo: _goToVideo,
          ),
      ],
    ),
    Positioned(
      bottom: netBotBottom,
      right: 16,
      child: _NetBotFloatingPill(
        material: widget.material,
        languageCode: widget.languageCode,
      ),
    ),
  ],
);
  }

  bool _hasVideo(MaterialModel material) {
    final videoId = material.videoId?.trim();
    final videoUrl = material.videoUrl?.trim();

    return (videoId != null && videoId.isNotEmpty) ||
        (videoUrl != null && videoUrl.isNotEmpty);
  }
}

/// `.reading-header` dari desain Figma: eyebrow modul, judul, progress label + persentase, progress track.
class _ReaderHeader extends StatelessWidget {
  final String title;
  final int? moduleNumber;
  final int? durationMinutes;
  final int progressPercent;

  const _ReaderHeader({
    required this.title,
    required this.moduleNumber,
    required this.durationMinutes,
    required this.progressPercent,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (moduleNumber != null)
          Text(
            l10n.moduleEyebrow(
              moduleNumber.toString().padLeft(2, '0'),
            ).toUpperCase(),
            style: theme.textTheme.labelSmall,
          ),

        // `Semantics(header: true)` -- judul materi adalah heading pertama di
        // halaman ini, dan pembaca layar harus bisa melompat ke sana.
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.headlineSmall,
          ),
        ),

        if (durationMinutes != null && durationMinutes! > 0) ...[
          const SizedBox(
            height: NetLearnSpace.s8,
          ),
          Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 15,
                color: context.mutedText,
              ),
              const SizedBox(
                width: NetLearnSpace.s5,
              ),
              Text(
                l10n.durationMinutes(durationMinutes!),
                style: theme.textTheme.bodySmall?.copyWith(
                      color: context.mutedText,
                    ),
              ),
            ],
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

class _BodyText extends StatelessWidget {
  final String text;

  const _BodyText({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final blocks = parseMaterialBody(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0)
            SizedBox(
              height: blocks[i - 1].kind == MaterialBlockKind.heading
                  ? NetLearnSpace.s8
                  : NetLearnSpace.s16,
            ),
          _BodyBlock(
            block: blocks[i],
          ),
        ],
      ],
    );
  }
}

class _BodyBlock extends StatelessWidget {
  final MaterialBlock block;

  const _BodyBlock({
    required this.block,
  });

  @override
  Widget build(BuildContext context) {
    switch (block.kind) {
      case MaterialBlockKind.heading:
        return _BodyHeading(
          text: block.lines.first,
        );

      case MaterialBlockKind.bullets:
        return _BodyBullets(
          items: block.lines,
        );

      case MaterialBlockKind.preformatted:
        return _BodyPreformatted(
          lines: block.lines,
        );

      case MaterialBlockKind.paragraph:
        return _Paragraph(
          text: block.lines.join('\n'),
        );
    }
  }
}

class _BodyHeading extends StatelessWidget {
  final String text;

  const _BodyHeading({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    // `onSurface` menggantikan `NetLearnColors.ink` yang sebelumnya ditulis
    // langsung: `ink` = `#1a1d26` tidak pernah berubah, jadi setiap heading
    // materi nyaris hitam di atas `#161820` di mode gelap.
    //
    // `Semantics(header: true)` karena baris `1. Judul` di body materi adalah
    // heading sejati -- tanpa ini, pembaca layar hanya melihat paragraf biasa
    // dan tidak bisa melompat antar bagian.
    return Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.onSurface,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
      ),
    );
  }
}

class _BodyBullets extends StatelessWidget {
  final List<String> items;

  const _BodyBullets({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: context.onSurface,
          height: 1.7,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 11, right: 10),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: context.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: style,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BodyPreformatted extends StatelessWidget {
  final List<String> lines;

  const _BodyPreformatted({
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    // Warna teks mengikuti tema: versi sebelumnya memakai `NetLearnColors.ink`
    // yang selalu gelap, jadi blok kode di mode gelap berubah menjadi blok
    // hitam di atas kartu hampir hitam. Latar juga bukan `surface` polos --
    // `raisedSurface` accentuates the code against the page without needing a
    // second border.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NetLearnSpace.s16),
      decoration: BoxDecoration(
        color: context.raisedSurface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          lines.join('\n'),
          softWrap: false,
          style: TextStyle(
            fontFamily: 'monospace',
            fontFamilyFallback: const [
              'Courier New',
              'monospace',
            ],
            fontSize: 13,
            height: 1.5,
            color: context.onSurface,
          ),
        ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;

  const _Paragraph({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0)
            const SizedBox(height: 6),
          Text(
            lines[i],
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.onSurface,
                  height: 1.7,
                ),
          ),
        ],
      ],
    );
  }
}

/// `.reader-sticky` dari index.css: bar putih di bawah area baca, dengan garis
/// atas rambut.
///
/// Aksi utama tetap di footer, bukan jadi Prev/Next di dalam konten: navigasi
/// antar materi bukan bagian dari mekanisme membaca di PRD.
class _ReaderFooter extends StatelessWidget {
  final bool completed;
  final bool isSaving;
  final bool hasContent;
  final bool hasVideo;
  final VoidCallback onMarkAsRead;
  final VoidCallback onGoToVideo;

  const _ReaderFooter({
    required this.completed,
    required this.isSaving,
    required this.hasContent,
    required this.hasVideo,
    required this.onMarkAsRead,
    required this.onGoToVideo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            NetLearnSpace.s20,
            NetLearnSpace.s12,
            NetLearnSpace.s20,
            NetLearnSpace.s12,
          ),
          child: Center(
            child: ConstrainedBox(
              // Footer memakai lebar baca yang sama dengan isi supaya di tablet
              // tombol tidak melebar ke seluruh layar.
              constraints: const BoxConstraints(
                maxWidth: NetLearnSpace.readingMeasure,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Setelah selesai, footer menampilkan status -- bukan tombol
                  // yang tidak melakukan apa-apa dan bukan tombol nonaktif.
                  //
                  // `onPressed: null` yang dipakai sebelumnya membuat Material
                  // meredupkan tombol: pembaca layar announce "dimatikan", dan
                  // mahasiswa tidak bisa membedakannya dari materi yang memang
                  // belum punya konten (keduanya sama-sama tidak bisa ditekan).
                  // Status sekarang punya ikon, label, dan `Semantics(label:)`,
                  // jadi selesai terbaca sebagai kondisi, bukan sebagai aksi
                  // yang gagal.
                  if (completed)
                    _ReadStatusChip(label: l10n.readLabel)
                  else
                    NlButton(
                      label: l10n.markAsRead,
                      icon: Icons.check_rounded,
                      loading: isSaving,
                      onPressed: hasContent ? onMarkAsRead : null,
                    ),
                  if (completed && hasVideo) ...[
                    const SizedBox(height: NetLearnSpace.s8),
                    // Tombol nyata (ungu penuh + ikon play), bukan `.text-button`
                    // ghost yang terbaca seperti tautan. "(Optional)" tetap ada di
                    // label sebagai keterangan sekunder.
                    NlButton(
                      label: l10n.videoOptional,
                      icon: Icons.play_circle_outline_rounded,
                      variant: NlButtonVariant.primary,
                      onPressed: onGoToVideo,
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

/// Status "sudah dibaca" di footer reader.
///
/// Bentuknya tombol outline `.button` supaya sejajar tinggi dan lebar dengan
/// [NlButton] di sebelahnya, tapi bukan tombol: begitu selesai, Marks as Read
/// sudah tidak berlaku lagi, jadi tidak ada aksi untuk diaktifkan.
class _ReadStatusChip extends StatelessWidget {
  final String label;

  const _ReadStatusChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      // Bukan `button: true` dan bukan `enabled: false`: ini laporan kondisi,
      // bukan kontrol. Membaca "Read" sebagai tombol yang tidak bisa ditekan
      // menyesatkan.
      child: ExcludeSemantics(
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NetLearnRadius.button),
            border: Border.all(color: context.accent),
            color: context.accentTint,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: context.onAccentTint,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: context.onAccentTint,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pesan tanpa isi di dalam area baca -- dipakai saat materi tidak punya konten.
///
/// Beda dari [NlErrorView]: ini bukan kegagalan, jadi tidak ada tombol retry dan
/// tidak memakai ikon error.
class _InlineMessage extends StatelessWidget {
  final String message;

  const _InlineMessage({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: NetLearnSpace.s16,
      ),
      child: Column(
        children: [
          Icon(
            Icons.article_outlined,
            size: 34,
            color: context.mutedText,
          ),
          const SizedBox(
            height: NetLearnSpace.s12,
          ),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
  final VoidCallback onViewPdf;
  final VoidCallback onDownloadPdf;
  final bool isDownloadingPdf;

  const _MaterialResources({
    required this.material,
    required this.languageCode,
    required this.onViewPdf,
    required this.onDownloadPdf,
    required this.isDownloadingPdf,
  });

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
          const SizedBox(height: NetLearnSpace.s16),
          if (hasPdf) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewPdf,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: context.accent,
                      side: BorderSide(color: context.accent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(NetLearnRadius.button),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.picture_as_pdf_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.viewPdf),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: NetLearnSpace.s12),
                Expanded(
                  child: NlButton(
                    label: l10n.downloadPdf,
                    icon: Icons.download_outlined,
                    variant: NlButtonVariant.primary,
                    loading: isDownloadingPdf,
                    onPressed: isDownloadingPdf ? null : onDownloadPdf,
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

/// Section for "Mark All as Read" button for the current module.
class _MarkAllAsReadSection extends StatelessWidget {
  final int moduleNumber;
  final bool completed;
  final bool isLoading;
  final VoidCallback onMarkAllAsRead;

  const _MarkAllAsReadSection({
    required this.moduleNumber,
    required this.completed,
    required this.isLoading,
    required this.onMarkAllAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
            l10n.markAllAsRead,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: NetLearnSpace.s8),
          Text(
            l10n.markAllAsReadDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.mutedText,
            ),
          ),
          const SizedBox(height: NetLearnSpace.s16),
          // The section's own button keeps the "Mark All as Read" label even
          // after this material is finished -- "Read" is already reported by the
          // footer status chip, so stamping it everywhere duplicates the state
          // and hides what the section is actually for.
          NlButton(
            label: l10n.markAllAsRead,
            icon: Icons.check_rounded,
            variant: completed ? NlButtonVariant.outline : NlButtonVariant.primary,
            loading: isLoading,
            onPressed: completed ? null : onMarkAllAsRead,
          ),
        ],
      ),
    );
  }
}

/// Video Learning section for the material reader.
class _VideoLearningSection extends StatelessWidget {
  final MaterialModel material;
  final String languageCode;
  final VoidCallback onGoToVideo;

  const _VideoLearningSection({
    required this.material,
    required this.languageCode,
    required this.onGoToVideo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final videoId = material.videoId?.trim();
    final videoUrl = material.videoUrl?.trim();
    final hasVideo = (videoId != null && videoId.isNotEmpty) ||
        (videoUrl != null && videoUrl.isNotEmpty);

    if (!hasVideo) return const SizedBox.shrink();

    final videoTitle = material.localizedTitle(languageCode);

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
            l10n.videoLearningSection,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: NetLearnSpace.s8),
          Text(
            videoTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: NetLearnSpace.s16),
          // Tombol utama, bukan tautan ghost: laporan meminta video pendukung
          // terbaca sebagai tombol. Label tetap memuat "(Optional)" sekunder.
          NlButton(
            label: l10n.videoOptional,
            icon: Icons.play_circle_outline_rounded,
            variant: NlButtonVariant.primary,
            onPressed: onGoToVideo,
          ),
        ],
      ),
    );
  }
}


/// Floating action pill that launches the NetBot AI Tutor sheet
/// primed with the current material's context.
class _NetBotFloatingPill extends StatelessWidget {
  final MaterialModel material;
  final String languageCode;

  const _NetBotFloatingPill({
    required this.material,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final isId = languageCode == 'id';

    return Material(
      color: Colors.transparent,
      elevation: 6,
      shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: () {
          NlSnackBar.show(
            context,
            isId
                ? 'Fitur NetBot AI masih dalam tahap pengembangan.'
                : 'NetBot AI feature is currently under development.',
          );
        },
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF4F46E5), // Indigo
                Color(0xFF7C3AED), // Violet
              ],
            ),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                isId ? 'Tanya NetBot' : 'Ask NetBot',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleDiscussionCard extends StatelessWidget {
  final MaterialModel material;
  final String languageCode;
  final bool fromLecturer;

  const _ModuleDiscussionCard({
    required this.material,
    required this.languageCode,
    required this.fromLecturer,
  });

  @override
  Widget build(BuildContext context) {
    final isId = languageCode == 'id';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modNum = material.moduleNumber;
    final title = modNum != null
        ? (isId
            ? 'Forum Tanya-Jawab Modul $modNum'
            : 'Module $modNum Q&A Discussion')
        : (isId ? 'Forum Tanya-Jawab Kelas' : 'Class Q&A Discussion');
    final subtitle = isId
        ? 'Diskusikan materi ini bersama dosen & teman sekelas'
        : 'Ask questions & discuss this material with your lecturer & classmates';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('material_open_discussion_btn'),
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final router = GoRouter.maybeOf(context);
          if (router == null) return;
          final loc = router.state.matchedLocation;
          final base =
              (fromLecturer || loc.startsWith('/lecturer')) ? '/lecturer' : '/student';
          final query = <String>[
            if (modNum != null) 'module=$modNum',
            if (material.id.isNotEmpty) 'materialId=${material.id}',
          ].join('&');
          router.push(query.isEmpty ? '$base/discussions' : '$base/discussions?$query');
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? NetLearnColors.darkSurface : const Color(0xFFFAF8FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? NetLearnColors.darkLine : const Color(0xFFE5DEFA),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C2CE2).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  color: Color(0xFF6C2CE2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1E1B2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? NetLearnColors.darkMuted
                            : const Color(0xFF68647B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF6C2CE2),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
