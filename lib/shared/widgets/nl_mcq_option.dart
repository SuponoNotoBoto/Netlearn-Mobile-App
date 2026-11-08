import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// `.option` dari index.css: satu baris jawaban pilihan ganda.
///
/// ```css
/// .option{padding:15px;display:flex;gap:13px;align-items:center;
///          border:1px solid #e3e4ed;background:white;border-radius:12px;
///          font-size:13px}
/// .option>span{width:29px;height:29px;border:1px solid #e6e6ef;display:grid;
///              place-items:center;border-radius:8px;font-size:11px;
///              font-weight:700}
/// .option>svg{margin-left:auto}
/// .option.chosen{border-color:#7358d8;background:#efebfc;color:#543cd1}
/// .option.chosen>span{background:#543cd1;color:white}
/// ```
///
/// Widget ini ada karena baris jawaban ini diulang di dua tempat -- di layar
/// soal assessment dan sebagai kartu jawaban di dashboard -- dan kedua tempat
/// punya versi private-nya sendiri dengan ukuran berbeda.
///
/// Bentuk publiknya sama dengan versi private yang sebelumnya ada di
/// `assessment_page.dart`: [label], [text], [selected], [onTap]. Perbedaannya
/// hanya presentasi: semua warna dibaca dari tema, baris terpilih memakai
/// pasangan `accentTint`/`accent` yang mengikuti mode gelap, dan baris ini
/// meng-*announce* `selected` sehingga pembaca layar tahu jawaban mana yang
/// sudah dipilih -- sebelumnya hanya terbaca sebagai teks biasa.
class NlMcqOption extends StatelessWidget {
  /// Huruf pilihan, mis. `A`.
  final String label;

  /// Isi pilihan. Boleh panjang dan membungkus; baris ini tidak memotongnya.
  final String text;

  /// Apakah jawaban ini yang sedang dipilih.
  final bool selected;

  final VoidCallback onTap;

  /// Diawali pada baris yang dipilih, mis. "Jawaban Anda".
  ///
  /// Null membiarkan Flutter membacakan label dan teks apa adanya.
  final String? selectedLabel;

  const NlMcqOption({
    super.key,
    required this.label,
    required this.text,
    required this.selected,
    required this.onTap,
    this.selectedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // `accentTint` = `primaryContainer`, jadi baris terpilih tidak memakai
    // ungu terang `#efebfc` apa adanya -- nilai itu tidak punya pasangan gelap
    // di index.css dan akan hilang di atas permukaan gelap.
    final borderColor = selected ? context.accent : context.border;
    final background = selected ? context.accentTint : context.surface;

    // `align-items:center` di CSS. Baris memakai tinggi-isinstead wrap seperti
    // CSS; versi sebelumnya memakai `CrossAxisAlignment.start` sehingga kotak
    // huruf menempel ke baris pertama saja kalau teks pilihan membungkus.
    final content = Container(
      // `padding:15px`
      padding: const EdgeInsets.all(NetLearnSpace.s15),
      decoration: BoxDecoration(
        color: background,
        // `border-radius:12px`. `NetLearnRadius.button` adalah satu-satunya
        // token yang bernilai 12; `field` bernilai 10 dan tidak cocok.
        borderRadius: BorderRadius.circular(NetLearnRadius.button),
        border: Border.all(
          color: borderColor,
          // `1px` normally, `2px` saat dipilih, supaya pilihan aktif tidak
          // hanya dibedakan oleh warna.
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          _LetterTile(
            label: label,
            selected: selected,
          ),

          // `gap:13px`
          const SizedBox(width: NetLearnSpace.s13),

          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.4,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? context.accent : context.onSurface,
              ),
            ),
          ),

          // `>svg{margin-left:auto}`
          if (selected) ...[
            const SizedBox(width: NetLearnSpace.s8),

            Icon(
              Icons.check_circle_rounded,
              color: context.accent,
              size: 22,
            ),
          ],
        ],
      ),
    );

    // `padding:15px` di atas teks yang setinggi minimal 15px membuat baris ini
    // selalu di atas 48px --Material tidak perlu `constraints` tambahan, dan
    // menambahkannya akan membuat kartu terlihat lebih tinggi dari desain
    // tanpa menambah area yang bisa diklik.
    return Semantics(
      button: true,
      selected: selected,
      label: selected && selectedLabel != null
          ? '$selectedLabel: $label. $text'
          : '$label. $text',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(NetLearnRadius.button),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(NetLearnRadius.button),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// `>span` di dalam `.option`: kotak huruf pilihan.
class _LetterTile extends StatelessWidget {
  final String label;
  final bool selected;

  const _LetterTile({
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // `border:1px solid #e6e6ef` hanya ada di desain terang; index.css tidak
    // mendefinisikan pasangan `.dark-theme` untuk `.option>span`, jadi mode
    // gelap memakai garis tema.
    final unselectedBorder =
        isDark ? context.border : NetLearnColors.lineDark;

    return Container(
      // `29px`. Bukan 48px: kotak huruf ini bukan target sentuh -- yang bisa
      // diklik adalah seluruh baris. Memperbesar huruf hanya akan membuat baris
      // terasa tidak seimbang tanpa menambah area yang bisa diklik.
      width: 29,
      height: 29,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? context.accent : context.raisedSurface,
        // `border-radius:8px`
        borderRadius: BorderRadius.circular(NetLearnRadius.sm),
        border: Border.all(
          color: selected ? Colors.transparent : unselectedBorder,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.displayFontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: selected
              ? Theme.of(context).colorScheme.onPrimary
              : context.onSurface,
        ),
      ),
    );
  }
}