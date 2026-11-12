import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_netlearn_logo.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import 'about_downloads.dart';

/// Redesigned "About NetLearn" body, shared by the student and lecturer
/// wrappers (`student_about_page.dart` / `lecturer_about_page.dart`) so the
/// content lives exactly once.
///
/// Structure follows the approved Figma Make frames (`About Application`):
/// a hero card (app identity, release status, version), a "Key Features"
/// list — only the six features that actually exist in this app — and a
/// "Download Resources" section with two cards (AR Markers & Material Book).
/// Both download the bundled PDF files (`assets/downloads/`, see
/// [AboutDownloadResource]), handing the bytes to the same `saveAndOpenPdf`
/// helper as the material-reader PDFs.
///
/// [openDownload] injects the download action so widget tests can pump the
/// content without touching real assets or the filesystem.
///
/// All colors come from the existing theme tokens, so light and dark modes
/// both resolve without their own palette here.
class AboutNetLearnContent extends ConsumerWidget {
  const AboutNetLearnContent({
    super.key,
    this.openDownload = openAboutDownload,
  });

  /// Bisa diganti di widget test dengan fake; default membaca aset PDF asli.
  final Future<void> Function(AboutDownloadResource resource) openDownload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final mutedBody = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 12,
      height: 1.75,
      color: context.mutedText,
    );

    return ListView(
      // `.content` = `padding:22px 22px 28px`, sesuai halaman-halaman lain.
      padding: const EdgeInsets.fromLTRB(
        NetLearnSpace.s22,
        NetLearnSpace.s22,
        NetLearnSpace.s22,
        28,
      ),
      children: [
        _AboutHeroCard(l10n: l10n, theme: theme, mutedBody: mutedBody),

        const SizedBox(height: NetLearnSpace.s20),

        _AboutSectionTitle(l10n.keyFeaturesTitle),
        const SizedBox(height: NetLearnSpace.s12),

        _AboutFeatureList(theme: theme),

        const SizedBox(height: NetLearnSpace.s20),

        _AboutSectionTitle(l10n.downloadResourcesTitle),
        const SizedBox(height: NetLearnSpace.s12),

        _DownloadResourceCards(
          theme: theme,
          openDownload: openDownload,
        ),
      ],
    );
  }
}

/// Judul bagian ("Key Features", "Download Resources") — hitam tebal, bukan
/// heading ungu bagian dashboard; di frame About keduanya tetap warna teks
/// biasa di luar kartu.
class _AboutSectionTitle extends StatelessWidget {
  final String title;

  const _AboutSectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: context.onSurface,
            ),
      ),
    );
  }
}

/// Kartu identitas di paling atas: logo + nama + lencana rilis, judul
/// platform, dua paragraf deskripsi, garis pemisah, lalu blok versi.
class _AboutHeroCard extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  final TextStyle? mutedBody;

  const _AboutHeroCard({
    required this.l10n,
    required this.theme,
    required this.mutedBody,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const NlNetLearnLogo(size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.appName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.accent,
                  ),
                ),
              ),
              _AboutPill(
                label: l10n.aboutReleaseBadge,
                accent: true,
              ),
            ],
          ),

          const SizedBox(height: NetLearnSpace.s14),

          Text(
            l10n.aboutNetLearnHeadline,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.45,
              color: context.onSurface,
            ),
          ),

          const SizedBox(height: NetLearnSpace.s10),

          Text(l10n.aboutNetLearnBody, style: mutedBody),
          const SizedBox(height: 10),
          Text(l10n.aboutNetLearnBodyLecturers, style: mutedBody),

          const SizedBox(height: NetLearnSpace.s16),

          // Garis pemisah tipis atas blok versi, seperti di frame.
          Container(height: 1, color: context.border),

          const SizedBox(height: NetLearnSpace.s14),

          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.aboutVersion,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: NetLearnSpace.s8),
              _AboutPill(label: l10n.aboutUnderDevelopmentBadge),
            ],
          ),

          const SizedBox(height: NetLearnSpace.s8),

          Text(
            l10n.aboutPreReleaseNote,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.6,
              color: context.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lencana kecil milik kartu hero ("Release"/"Rilis", "Under Development") dan
/// kartu sumber daya ("Coming Soon"). [accent] memilih lencana ungu muda di
/// atas lencana netral abu-abu.
class _AboutPill extends StatelessWidget {
  final String label;
  final bool accent;

  const _AboutPill({
    required this.label,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    // Token status punya varian gelap; ambil lewat extension, bukan warna
    // konstan, supaya lencana "Coming Soon"/"Under Development" terbaca di
    // kedua tema.
    final statusColors = Theme.of(context).extension<NetLearnStatusColors>();

    final background = accent
        ? context.accentTint
        : statusColors?.neutralBg ?? NetLearnColors.neutralBg;
    final foreground = accent
        ? context.accent
        : statusColors?.neutralText ?? NetLearnColors.neutralText;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: foreground,
        ),
      ),
    );
  }
}

/// Daftar enam fitur utama di dalam satu kartu. Enam barisnya keduanya
/// (mahasiswa dan dosen) benar-benar ada di aplikasi, sesuai daftar fitur
/// frame desain — tidak ada fitur yang direncanakan ikut ditampilkan.
class _AboutFeatureList extends StatelessWidget {
  const _AboutFeatureList({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final features = <(IconData, String, String)>[
      (
        Icons.menu_book_outlined,
        l10n.aboutFeatureMaterialsTitle,
        l10n.aboutFeatureMaterialsDescription,
      ),
      (
        Icons.description_outlined,
        l10n.aboutFeatureReadingTitle,
        l10n.aboutFeatureReadingDescription,
      ),
      (
        Icons.videocam_outlined,
        l10n.aboutFeatureVideosTitle,
        l10n.aboutFeatureVideosDescription,
      ),
      (
        Icons.assignment_outlined,
        l10n.aboutFeatureAssessmentTitle,
        l10n.aboutFeatureAssessmentDescription,
      ),
      (
        Icons.trending_up_rounded,
        l10n.aboutFeatureProgressTitle,
        l10n.aboutFeatureProgressDescription,
      ),
      (
        Icons.school_outlined,
        l10n.aboutFeatureLecturerTitle,
        l10n.aboutFeatureLecturerDescription,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: Column(
        children: [
          for (final (index, feature) in features.indexed) ...[
            if (index > 0) const SizedBox(height: 14),
            _FeatureRow(
              theme: theme,
              icon: feature.$1,
              title: feature.$2,
              description: feature.$3,
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String title;
  final String description;

  const _FeatureRow({
    required this.theme,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.accentTint,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: context.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.5,
                  color: context.mutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dua kartu sumber daya unduhan (AR Markers & Buku Materi). Kolomnya mengikuti
/// lebar: dua di ukuran tablet/lebar (>= 560), dan disusun vertikal pada lebar
/// ponsel.
class _DownloadResourceCards extends StatelessWidget {
  const _DownloadResourceCards({
    required this.theme,
    required this.openDownload,
  });

  final ThemeData theme;
  final Future<void> Function(AboutDownloadResource resource) openDownload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final cards = <(IconData, String, String, AboutDownloadResource)>[
      (
        // Marker: ikon bingkai pemindaian AR, sesuai frame "Download Marker".
        Icons.center_focus_weak,
        l10n.downloadMarkerTitle,
        l10n.downloadMarkerDescription,
        AboutDownloadResource.arMarkers,
      ),
      (
        // Buku materi: dokumen, kini PDF materi jaringan komputer yang
        // dibundel — bukan daftar materi mahasiswa.
        Icons.description_outlined,
        l10n.downloadMaterialsTitle,
        l10n.downloadMaterialsDescription,
        AboutDownloadResource.materialBook,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 560 ? 2 : 1;

        final rows = <List<(IconData, String, String, AboutDownloadResource)>>[];

        for (var index = 0; index < cards.length; index += columnCount) {
          rows.add(
            cards.sublist(
              index,
              (index + columnCount).clamp(0, cards.length),
            ),
          );
        }

        return Column(
          children: [
            for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
              if (rowIndex > 0) const SizedBox(height: NetLearnSpace.s16),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var column = 0; column < columnCount; column++) ...[
                      if (column > 0) const SizedBox(width: NetLearnSpace.s16),
                      Expanded(
                        child: column < rows[rowIndex].length
                            ? _DownloadResourceCard(
                                key: switch (rows[rowIndex][column].$4) {
                                  AboutDownloadResource.arMarkers =>
                                    const ValueKey(
                                      'about-download-markers',
                                    ),
                                  AboutDownloadResource.materialBook =>
                                    const ValueKey(
                                      'about-download-materials',
                                    ),
                                  // Kedua varian bahasa manual berbagi kartu
                                  // dengan key yang sama: hanya satu kartu
                                  // Manual Books yang pernah tampil.
                                  AboutDownloadResource.manualBookEn ||
                                  AboutDownloadResource.manualBookId =>
                                    const ValueKey(
                                      'about-download-manuals',
                                    ),
                                },
                                theme: theme,
                                icon: rows[rowIndex][column].$1,
                                title: rows[rowIndex][column].$2,
                                description: rows[rowIndex][column].$3,
                                resource: rows[rowIndex][column].$4,
                                onDownload: openDownload,
                                pdfBadgeLabel: l10n.downloadPdfBadge,
                                downloadPdfLabel: l10n.downloadPdf,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Satu kartu unduhan: tile ikon + lencana status, judul, deskripsi, dan
/// tombol Unduh.
///
/// Ketiga kartu benar-benar mengunduh: PDF dibundel di `assets/downloads/` dan
/// byte-nya diserahkan ke `saveAndOpenPdf` milik helper unduhan PDF materi.
class _DownloadResourceCard extends StatefulWidget {
  final ThemeData theme;
  final IconData icon;
  final String title;
  final String description;

  final AboutDownloadResource resource;
  final Future<void> Function(AboutDownloadResource) onDownload;

  final String pdfBadgeLabel;
  final String downloadPdfLabel;

  const _DownloadResourceCard({
    super.key,
    required this.theme,
    required this.icon,
    required this.title,
    required this.description,
    required this.resource,
    required this.onDownload,
    required this.pdfBadgeLabel,
    required this.downloadPdfLabel,
  });

  @override
  State<_DownloadResourceCard> createState() => _DownloadResourceCardState();
}

class _DownloadResourceCardState extends State<_DownloadResourceCard> {
  /// True selaman unduhan berjalan — ikonnya jadi spinner (ukuran sama,
  /// supaya tidak menggeser layout di 360dp) dan tap lanjutan diblokir.
  bool _busy = false;

  Future<void> _download() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      await widget.onDownload(widget.resource);
      if (!mounted) return;
      NlSnackBar.show(
        context,
        AppLocalizations.of(context)!.downloadSucceeded,
        tone: NlSnackTone.success,
        icon: Icons.check_circle_outline_rounded,
      );
    } catch (_) {
      // Pesan mentah tidak pernah ditampilkan: bisa membocorkan path aset.
      if (!mounted) return;
      NlSnackBar.show(
        context,
        AppLocalizations.of(context)!.downloadFailed,
        tone: NlSnackTone.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.accentTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(widget.icon, size: 20, color: context.accent),
              ),
              const Spacer(),
              // Semua kartu yang PDF-nya dibundel menampilkan badge "PDF".
              _AboutPill(label: widget.pdfBadgeLabel),
            ],
          ),

          const SizedBox(height: NetLearnSpace.s12),

          Text(
            widget.title,
            style: widget.theme.textTheme.titleMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.onSurface,
            ),
          ),

          const SizedBox(height: NetLearnSpace.s6),

          Text(
            widget.description,
            style: widget.theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.6,
              color: context.mutedText,
            ),
          ),

          const SizedBox(height: 10),

          Material(
            color: context.accentTint,
            borderRadius: BorderRadius.circular(NetLearnRadius.button),
            child: InkWell(
              onTap: _busy ? null : _download,
              borderRadius: BorderRadius.circular(NetLearnRadius.button),
              child: _buttonBody(context, widget.downloadPdfLabel),
            ),
          ),
        ],
      ),
    );
  }

  /// Isi tombol (padding s13, ikon 17, teks 12 w700).
  Widget _buttonBody(BuildContext context, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NetLearnSpace.s13),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Saat mengunduh ikon diganti spinner dengan ukuran ikon yang sama
          // (17) supaya baris tombol tidak berubah tinggi/lebar.
          if (_busy)
            const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.download_rounded, size: 17, color: context.accent),
          const SizedBox(width: NetLearnSpace.s10),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
