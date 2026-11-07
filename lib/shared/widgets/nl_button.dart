import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum NlButtonVariant { primary, secondary, outline, danger, ghost }

class NlButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final NlButtonVariant variant;
  final bool loading;
  final IconData? icon;
  final IconData? trailingIcon;

  const NlButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = NlButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    late final Color bg, fg;
    late final BorderSide border;

    switch (variant) {
      case NlButtonVariant.primary:
        // `.button` — ungu solid, teks putih, radius 12px.
        bg = scheme.primary;
        fg = scheme.onPrimary;
        border = BorderSide.none;

      case NlButtonVariant.secondary:
        // `.button.secondary` — latar ungu muda, teks ungu, tanpa garis.
        // Gaya: `#f0ecfb` / `#543cd1` (terang), `#242035` / `#d0c2ff` (gelap).
        bg = isDark ? NetLearnColors.primaryDarkTint : NetLearnColors.primaryTint;
        fg = isDark ? NetLearnColors.primaryDarkSoft : NetLearnColors.primary;
        border = BorderSide.none;

      case NlButtonVariant.outline:
        bg = Colors.transparent;
        fg = scheme.primary;
        border = BorderSide(color: scheme.primary);

      case NlButtonVariant.danger:
        // `.unified-logout` — garis merah di atas permukaan, isi transparan.
        bg = Colors.transparent;
        fg = isDark ? NetLearnColors.darkCoralText : NetLearnColors.danger;
        border = BorderSide(
          color: isDark ? NetLearnColors.darkCoralBorder : NetLearnColors.danger,
        );

      case NlButtonVariant.ghost:
        // `.text-button` — tanpa latar dan tanpa garis.
        bg = Colors.transparent;
        fg = scheme.primary;
        border = BorderSide.none;
    }

    return SizedBox(
      // `.button` padding 15px + label 12px ≈ 48px.
      height: 48,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: border,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NetLearnRadius.button),
          ),
          textStyle: theme.textTheme.labelLarge,
        ),
        child: loading
            ? SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: fg),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            // `Flexible`, bukan `Text` telanjang: label Bahasa Indonesia lebih
            // panjang dari Bahasa Inggris untuk kalimat yang sama -- "Tandai
            // sebagai Dibaca" (21 karakter) melebar 8px melewati tombol pada
            // lebar minimum 360dp, dan `Row(mainAxisSize.min)` dengan `Text`
            // telanjang tidak punya cara untuk menyusut, jadi hanya meluber.
            //
            // Bungkus, bukan ellipsis: label yang muat dalam satu baris tetap
            // satu baris, dan yang tidak muat turun satu baris -- dua baris
            // 12px masih muat di dalam tinggi 48px, jadi tidak ada tinggi
            // tombol yang berubah dan tidak ada teks yang terpotong.
            Flexible(child: Text(label)),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}