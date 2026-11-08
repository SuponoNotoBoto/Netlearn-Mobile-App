import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// `.theme-switch` dari index.css: sakelar tema yang digambar sendiri.
///
/// ```css
/// .theme-switch{width:40px;height:24px;background:#dcdce7;border-radius:20px;
///               flex-shrink:0;padding:3px;transition:background .2s}
/// .theme-switch span{display:block;width:18px;height:18px;border-radius:50%;
///               background:#fff;box-shadow:0 1px 3px #0002;transition:transform .2s}
/// .theme-switch.enabled{background:#543cd1}
/// .theme-switch.enabled span{transform:translateX(16px)}
/// ```
///
/// Sakelar Material bawaan berukuran sekitar 48x28 dengan track beroutline dan
/// ripple, jadi bentuknya tidak sama dengan desain. Widget ini hanya gambar
/// kontrolnya; baris yang mengelilinginya sudah ada di `NlDarkModeRow` dan tidak
/// diubah pada tahap ini.
///
/// `onChanged` null membuat sakelar non-interaktif dengan gaya dimatikan, dipakai
/// dipakai kalau tema belum siap dibaca.
class NlThemeSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Label untuk pembaca layar, mis. "Mode gelap".
  final String semanticLabel;

  const NlThemeSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel = 'Mode gelap',
  });

  static const double _trackWidth = 40;
  static const double _trackHeight = 24;
  static const double _knobSize = 18;

  /// `padding:3px` + jarak aman untuk [MaterialTapTargetSize.padded] (48px).
  static const double _touchPadding = (48 - _trackHeight) / 2;

  /// `.theme-switch span` = `box-shadow:0 1px 3px #0002`.
  ///
  /// Hitam dengan alpha, bukan bayangan ungu seperti [NetLearnColors.shadowTint]:
  /// bayangan ini menempel pada knob putih yang selalu berada di atas track.
  static const List<BoxShadow> knobShadow = [
    BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final enabled = onChanged != null;

    // not verified: `index.css` tidak punya aturan `.dark-theme .theme-switch`,
    // jadi track saat mati memakai `darkLine` seperti surface lain.
    final offColor = isDark
        ? NetLearnColors.darkLine
        : NetLearnColors.themeSwitchOff;

    final trackColor = value ? context.accent : offColor;

    return Semantics(
      toggled: value,
      label: semanticLabel,
      enabled: enabled,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        radius: _trackWidth / 2,
        // Target sentuh tetap 48px walau track hanya 24px tinggi.
        containedInkWell: true,
        child: Padding(
          padding: const EdgeInsets.all(_touchPadding),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _trackWidth,
            height: _trackHeight,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(NetLearnRadius.pill),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: _knobSize,
                height: _knobSize,
                decoration: BoxDecoration(
                  color: NetLearnColors.white,
                  shape: BoxShape.circle,
                  boxShadow: knobShadow,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
