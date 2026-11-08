import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Penanda sebaris untuk konten yang memang belum ada (bukan kegagalan).
///
/// Memakai pasangan warna `pending` (amber) dari [NetLearnStatusColors] supaya
/// jelas berbeda dari teks deskripsi abu-abu di sekitarnya, tetapi tetap bukan
/// `danger`/merah: "belum tersedia" bukan error, jadi tidak boleh terbaca
/// sebagai kegagalan muat. Paletnya ikut tema terang/gelap lewat `statusColors`,
/// dan lookup-nya memakai fallback yang sama dengan akses status lain — widget
/// test yang pump di dalam `MaterialApp` polos tidak membawa ekstensi tema.
///
/// Tanpa `maxLines`/ellipsis: pada text scale tinggi teks membungkus dan kotak
/// tumbuh, bukan terpotong.
class NlUnavailableNotice extends StatelessWidget {
  final String message;

  /// Ikon konteks: jam pasir secara default (belum tersedia), PDF untuk kartu
  /// sumber daya materi.
  final IconData icon;

  const NlUnavailableNotice({
    super.key,
    required this.message,
    this.icon = Icons.hourglass_top_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final statusColors = Theme.of(context).statusColors;
    final color = statusColors.pendingText;

    // Pola Semantics persis [StatusBadge]: satu label utuh untuk pembaca
    // layar, isi visual dikecualikan supaya tidak dobel dibacakan.
    return Semantics(
      container: true,
      label: message,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: statusColors.pendingBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.30)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
