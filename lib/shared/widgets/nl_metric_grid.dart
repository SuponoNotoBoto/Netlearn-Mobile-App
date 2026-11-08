import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Wadah untuk beberapa metrik dashboard: `.metrics` dari index.css.
///
/// ```css
/// .metrics{display:grid;grid-template-columns:1fr 1fr;gap:15px;background:white;
///          padding:17px;border-radius:16px;margin-bottom:17px;
///          border:1px solid #eceef2}
/// ```
///
/// Widget ini hanya menggambar wadah itu. Isinya adalah [child] apa pun, biasanya
/// [NlStatCard] yang sudah ada, jadi metrik tidak diduplikasi di sini.
///
/// [bordered] bernilai false membuat satu [child] mengisi seluruh wadah tanpa
/// kartu di dalamnya -- untuk satu angka besar seperti "Rata-rata kelas" di header
/// profil, bukan untuk deretan metrik.
class NlMetricGrid extends StatelessWidget {
  final List<Widget> children;

  /// `1fr 1fr`.
  final int columns;

  /// `gap:15px`.
  final double gap;

  /// `padding:17px`.
  final EdgeInsetsGeometry? padding;

  /// `margin-bottom:17px`, ikut dibuang kalau [bottomGap] nol.
  final double bottomGap;

  final bool bordered;

  const NlMetricGrid({
    super.key,
    required this.children,
    this.columns = 2,
    this.gap = NetLearnSpace.s15,
    this.padding = const EdgeInsets.all(NetLearnSpace.s17),
    this.bottomGap = NetLearnSpace.s17,
    this.bordered = true,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    if (children.length == 1) {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomGap),
        child: children.first,
      );
    }

    // `columns` dipakai sebagai langkah pada loop di bawah dan sebagai lebar
    // kolom pada loop kedua. Nilai nol atau negatif akan membuat
    // `index += columns` tidak pernah maju sehingga build tidak pernah selesai,
    // jadi nilainya dipaksa minimal satu di sini. Nilai 1 ke atas -- termasuk
    // semua nilai yang sekarang dipakai -- tidak tersentuh, sehingga layoutnya
    // tetap sama.
    final columnCount = columns < 1 ? 1 : columns;

    final rows = <List<Widget>>[];

    for (var index = 0; index < children.length; index += columnCount) {
      rows.add(
        children.sublist(
          index,
          (index + columnCount).clamp(0, children.length),
        ),
      );
    }

    // Setiap baris dibungkus `IntrinsicHeight` supaya sel di dalamnya bisa
    // memakai `stretch`: tanpa itu `stretch` akan meminta tinggi tak berujung
    // dari `Column` yang sedang di dalam `SingleChildScrollView`.
    return Padding(
      padding: EdgeInsets.only(bottom: bottomGap),
      child: Container(
        padding: padding,
        decoration: bordered
            ? BoxDecoration(
                color: context.surface,
                border: Border.all(color: context.border),
                borderRadius: BorderRadius.circular(NetLearnRadius.card),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0) SizedBox(height: gap),

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var column = 0; column < columnCount; column++) ...[
                      if (column > 0) SizedBox(width: gap),

                      Expanded(
                        child: column < rows[index].length
                            ? rows[index][column]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
