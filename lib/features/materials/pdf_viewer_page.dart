import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfx/pdfx.dart';

import '../../core/localization/language_controller.dart';
import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_skeleton.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/nl_topbar.dart';
import '../../shared/widgets/nl_unavailable_notice.dart';
import 'pdf_download.dart';
import 'pdf_service.dart';
import 'student_materials_controller.dart';

/// Maps any PDF load failure onto one friendly, localised message.
///
/// pdfx membungkus kegagalan di balik `Future` jadi teks generik seperti
/// "Exception: Unknown error", dan detail exception mentah bisa membocorkan
/// nama table/policy/url. Pesan asli hanya dipakai di `debugPrint`
/// (`kDebugMode`); tombol unduh di app bar tetap jadi jalan keluarnya.
String pdfErrorMessage(Object error, AppLocalizations l10n) {
  return l10n.pdfOpenFailed;
}

/// Full-screen view of a material's PDF, opened from the detail page or the
/// reader's Material Resources section.
///
/// The old page lived inside the reader, was pushed through `Navigator` and
/// popped through GoRouter — two stacks pretending to be one, so the back
/// button tore the reader out from under it. This page is a normal GoRouter
/// route (`/student/material/:materialId/pdf`), so back navigation and the
/// reader's own stack agree again.
class PdfViewerPage extends ConsumerStatefulWidget {
  final String materialId;

  /// Mirror of [MaterialReaderPage.fromLecturer]: fallback kembali mengikuti
  /// cabang route — `/lecturer/materials` untuk dosen, `/student/materials`
  /// untuk mahasiswa. Default `false` = jalur mahasiswa.
  final bool fromLecturer;

  const PdfViewerPage({
    super.key,
    required this.materialId,
    this.fromLecturer = false,
  });

  @override
  ConsumerState<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends ConsumerState<PdfViewerPage> {
  PdfControllerPinch? _controller;
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _error;

  /// "Materi ini tidak punya PDF" bukan kegagalan muat: tampil sebagai
  /// pemberitahuan amber tanpa tombol Coba Lagi — retry tidak akan pernah
  /// berhasil untuk materi yang memang tanpa PDF. Hanya kegagalan muat
  /// sungguhan yang masuk [NlErrorView] merah.
  bool _missingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void dispose() {
    // `_controller` is nullable because a failed load never creates one — the
    // old code kept a `late` field and its `dispose` threw a
    // LateInitializationError every time the download step failed.
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    final previous = _controller;
    _controller = null;

    // First build already starts in the loading state, so only reset when this
    // is a retry or a re-load: setState synchronously inside initState would be
    // a gamble on the framework's mount phase.
    if (previous != null || _error != null || !_isLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
        _missingPdf = false;
      });
    }

    try {
      // The document can outlive this session if the controller was disposed in
      // the meanwhile (retry), so close it instead of leaking it. This await
      // belongs inside the try: a throwing `document` future (a closed or
      // disposed controller) would otherwise escape before the catch and leave
      // `_isLoading` true with no error and no retry button — a dead spinner.
      final previousDocument = await previous?.document;
      await previousDocument?.close();

      final material = await ref.read(
        studentMaterialProvider(widget.materialId).future,
      );

      final pdfUrl = material?.pdfUrl;
      if (material == null || pdfUrl == null || pdfUrl.trim().isEmpty) {
        // Bukan error: tidak ada PDF-nya, jadi tanpa `_error` dan tanpa
        // tombol Coba Lagi.
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
          _missingPdf = true;
        });
        return;
      }

      final signedUrl = await resolveMaterialPdfUrl(pdfUrl);

      if (signedUrl == null) {
        throw Exception('Could not resolve the PDF URL');
      }

      final bytes = await downloadMaterialPdfBytes(signedUrl);

      // Await the document here instead of handing its Future to the
      // controller: pdfx turns a failed `openData` Future into a generic
      // "Unknown error" once it sits behind PdfControllerPinch, so the real
      // cause (truncated download, corrupt PDF) both disappears from the UI
      // and from our own debugPrint.
      final document = await PdfDocument.openData(bytes);

      if (document.pagesCount < 1) {
        await document.close();
        throw Exception('PDF has no pages');
      }

      if (!mounted) {
        await document.close();
        return;
      }

      setState(() {
        // Already-resolved Future, so the view never re-runs a load that
        // could fail outside this try/catch.
        _controller = PdfControllerPinch(
          document: Future.value(document),
        );
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      // Raw cause stays in the log; the user only ever sees the friendly
      // message (and the download button in the app bar).
      if (kDebugMode) {
        debugPrint('PDF open failed (${widget.materialId}): $error');
      }
      setState(() {
        _isLoading = false;
        _error = pdfErrorMessage(error, AppLocalizations.of(context)!);
      });
    }
  }

  Future<void> _download() async {
    if (_isDownloading) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isDownloading = true;
    });

    try {
      final material = await ref.read(
        studentMaterialProvider(widget.materialId).future,
      );

      final signedUrl = await resolveMaterialPdfUrl(material?.pdfUrl);

      if (signedUrl == null) {
        throw Exception('Could not resolve the PDF URL');
      }

      final bytes = await downloadMaterialPdfBytes(signedUrl);

      await saveAndOpenPdf(
        bytes,
        'NetLearn_${widget.materialId}.pdf',
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

      // Same rule as `_loadPdf`: the raw cause stays in the log (a storage
      // error names bucket/policy, a timeout names the stalled step) while the
      // user sees one neutral line. Without this the download failed silently
      // and the device report could not be traced back to a cause.
      if (kDebugMode) {
        debugPrint('PDF download failed (${widget.materialId}): $error');
      }

      NlSnackBar.show(
        context,
        l10n.pdfDownloadFailed,
        tone: NlSnackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  /// Fallback kembali mengikuti cabang pembuka: aksi dosen yang didorong ke
  /// `/student/**` dipantulkan role guard, jadi bukan "kembali" yang
  /// pengguna rasakan.
  String get _materialsFallback =>
      widget.fromLecturer ? '/lecturer/materials' : '/student/materials';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = ref.watch(languageProvider).languageCode;

    final material = ref.watch(
      studentMaterialProvider(widget.materialId),
    ).value;

    final String title;
    final pdfUrl = material?.pdfUrl;
    if (pdfUrl != null && pdfUrl.trim().isNotEmpty) {
      final localized = material!.localizedTitle(languageCode);
      title = localized.trim().isEmpty ? l10n.viewPdf : localized;
    } else {
      title = l10n.viewPdf;
    }

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
          title: title,
          onBack: () => goBack(context, fallback: _materialsFallback),
          actions: IconButton(
            tooltip: l10n.downloadPdf,
            onPressed: _isDownloading ? null : _download,
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
          ),
        ),
        body: _buildBody(l10n),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const NlSkeletonDetail(showBanner: false, paragraphBlocks: 4);
    }

    if (_missingPdf) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(NetLearnSpace.s24),
          child: NlUnavailableNotice(
            message: l10n.noPdfAvailable,
            icon: Icons.picture_as_pdf_outlined,
          ),
        ),
      );
    }

    if (_error != null) {
      return NlErrorView(
        message: _error!,
        onRetry: _loadPdf,
      );
    }

    return PdfViewPinch(
      controller: _controller!,
      onDocumentError: (error) {
        // The errorBuilder below owns the UI; the log keeps the raw cause.
        if (kDebugMode) {
          debugPrint('PDF view error: $error');
        }
      },
      builders:
          // Argumen tipe ini wajib. Field `builders` di PdfViewPinch tersimpan
          // sebagai generic mentah, jadi tanpa tipe eksplisit
          // PdfViewPinchBuilders diinferensi sebagai <dynamic>, dan pdfx
          // melakukan cast keras ke PdfViewPinchBuilders<DefaultBuilderOptions>
          // (pdf_view_pinch.dart:569) → TypeError "PdfViewPinchBuilders<dynamic>
          // is not a subtype of PdfViewPinchBuilders<DefaultBuilderOptions>"
          // SAAT BUILD, membenturkan seluruh halaman (layar merah), tidak
          // tertangkap errorBuilder karena lemparnya terjadi di tengah build.
          PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        errorBuilder: (context, error) => NlErrorView(
          message: pdfErrorMessage(error, l10n),
          onRetry: _loadPdf,
        ),
      ),
    );
  }
}