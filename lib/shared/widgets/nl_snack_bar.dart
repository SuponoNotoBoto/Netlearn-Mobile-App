import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Empat nada pesan feedback. Pemetaan nama → warna ada di [NlSnackBar.build]
/// dan mengambil pasangannya dari [NetLearnFeedbackColors] (`context.feedback`),
/// jadi mode gelap tidak perlu cabang manual di sini.
enum NlSnackTone { success, error, warning, info }

/// Komponen feedback bersama: snackbar ber-ton dengan ikon, border, dan tombol
/// tutup, menggantikan SnackBar Material polos yang dulunya dipakai tersebar
/// di 23 file (latar inverseSurface hitam, tanpa ikon, hilang 4 detik semua).
///
/// Tetap berupa `SnackBar` sungguhan — bukan overlay/`MaterialBanner` buatan —
/// supaya widget test yang sudah memakai `find.byType(SnackBar)` dan
/// `find.text(...)` tetap lulus tanpa interpreted ulang.
///
/// `show` menyembunyikan snackbar yang sedang tampil sebelum menampilkan yang
/// baru: tanpa ini empat kegagalan berurutan membuat pengguna menonton antrean
/// toast satu per satu, padahal yang bermakna cuma yang terakhir.
///
/// Durasi dibedakan per tone — error butuh waktu baca lebih lama daripada
/// konfirmasi berhasil — bukan 4 detik seragam seperti sebelumnya.
abstract final class NlSnackBar {
  static void show(
    BuildContext context,
    String message, {
    NlSnackTone tone = NlSnackTone.info,
    IconData? icon,
    Duration? duration,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (messenger == null) {
      return;
    }

    messenger..hideCurrentSnackBar()..showSnackBar(
      build(context, message, tone: tone, icon: icon, duration: duration),
    );
  }

  static SnackBar build(
    BuildContext context,
    String message, {
    NlSnackTone tone = NlSnackTone.info,
    IconData? icon,
    Duration? duration,
  }) {
    final feedback = context.feedback;

    final Color bg;
    final Color fg;
    final Color border;
    final IconData toneIcon;
    final Duration toneDuration;

    switch (tone) {
      case NlSnackTone.success:
        bg = feedback.successBg;
        fg = feedback.successFg;
        border = feedback.successBorder;
        toneIcon = Icons.check_circle_rounded;
        toneDuration = const Duration(seconds: 3);
      case NlSnackTone.error:
        bg = feedback.errorBg;
        fg = feedback.errorFg;
        border = feedback.errorBorder;
        toneIcon = Icons.error_outline_rounded;
        toneDuration = const Duration(seconds: 6);
      case NlSnackTone.warning:
        bg = feedback.warningBg;
        fg = feedback.warningFg;
        border = feedback.warningBorder;
        toneIcon = Icons.warning_amber_rounded;
        toneDuration = const Duration(seconds: 5);
      case NlSnackTone.info:
        bg = feedback.infoBg;
        fg = feedback.infoFg;
        border = feedback.infoBorder;
        toneIcon = Icons.info_outline_rounded;
        toneDuration = const Duration(seconds: 4);
    }

    // Nilai khusus call site menimpa kontrak tone; null berarti ikon dan
    // durasi tone standar dipakai apa adanya.
    final IconData resolvedIcon = icon ?? toneIcon;
    final Duration resolvedDuration = duration ?? toneDuration;

    return SnackBar(
      behavior: SnackBarBehavior.floating,
      // Scaffolds mengangkat snackbar floating di atas bottomNavigationBar dan
      // inset sistem, jadi margin bawah konstan 16 aman di layar ber-navbar
      // maupun tidak.
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      backgroundColor: bg,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: border),
      ),
      showCloseIcon: true,
      closeIconColor: fg,
      dismissDirection: DismissDirection.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      duration: resolvedDuration,
      // Teks tanpa maxLines/ellipsis: pesan error harus terbaca utuh. Pada
      // text scale 1.3 teks hanya membungkus dan tinggi snackbar mengikuti,
      // bukan terpotong.
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(resolvedIcon, size: 20, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
