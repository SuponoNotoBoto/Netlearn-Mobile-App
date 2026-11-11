import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'nl_tap_scale.dart';

/// `.document-actions` dari index.css: sepasang tombol aksi yang lebarnya sama.
///
/// ```css
/// .document-actions{display:flex;gap:10px}
/// .document-actions button,.document-actions a{flex:1;display:flex;
///                  align-items:center;justify-content:center;gap:7px;
///                  padding:12px 8px;border-radius:25px;font-size:10px;
///                  font-weight:700;text-decoration:none}
/// .document-actions button{border:1px solid #543cd1;color:#543cd1;background:white}
/// .document-actions a{background:#543cd1;color:white}
/// ```
///
/// Bentuk ini muncul di empat tempat -- detail materi, reader, halaman video, dan
/// aksi PDF -- dan belum ada satu pun yang memakai geometri yang sama, sehingga
/// setiap halaman memakai bentuk tombol yang berbeda.
///
/// Bentuknya sengaja BUKAN [NlButton]: `.button` di index.css memakai radius
/// `12px` dan label `12px`, sedangkan `.document-actions` memakai radius `25px`
/// dan label `10px`. Menyatukan keduanya justru membuat salah satunya meleset.
class NlDocumentActions extends StatelessWidget {
  final List<NlDocumentAction> actions;

  /// `gap:10px`.
  final double gap;

  const NlDocumentActions({
    super.key,
    required this.actions,
    this.gap = NetLearnSpace.s10,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    // `stretch` memberi kedua tombol tinggi yang sama, jadi teks dua baris di
    // salah satunya tidak membuat tombol terlihat lebih pendek. `IntrinsicHeight`
    // yang memuskinkan `stretch` dipakai di dalam `Column` yang tinggi_bounds-nya
    // tidak berujung, mis. di dalam `SingleChildScrollView`.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            if (index > 0) SizedBox(width: gap),

            Expanded(child: _ActionButton(action: actions[index])),
          ],
        ],
      ),
    );
  }
}

/// Satu tombol pada [NlDocumentActions].
class NlDocumentAction {
  final String label;
  final IconData? icon;

  /// Isi solid `bg:#543cd1`, kosong `border:1px solid #543cd1`. Tombol filled
  /// harus paling banyak satu: dua tombol solid bersebelahan kehilangan jalan
  /// untuk membedakannya.
  final bool filled;

  final VoidCallback? onPressed;

  const NlDocumentAction({
    required this.label,
    this.icon,
    this.filled = false,
    this.onPressed,
  });
}

class _ActionButton extends StatelessWidget {
  final NlDocumentAction action;

  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final background = action.filled ? context.accent : context.surface;

    final foreground = action.filled
        ? Theme.of(context).colorScheme.onPrimary
        : context.accent;

    final button = Container(
      // `padding:12px 8px` + `border-radius:25px` + `gap:7px`
      padding: const EdgeInsets.symmetric(
        vertical: NetLearnSpace.s12,
        horizontal: NetLearnSpace.s8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(NetLearnRadius.action),
        border: action.filled ? null : Border.all(color: context.accent),
        // `.button` = `box-shadow:0 4px 10px #543cd114`. Hanya tombol filled
        // yang berbayang; yang beroutline tidak punya bayangan di desain.
        boxShadow: action.filled ? NetLearnShadows.button : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              action.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              // `.document-actions button` = 10px / weight 700
              style: context.documentActionStyle?.copyWith(color: foreground),
            ),
          ),

          if (action.icon != null) ...[
            const SizedBox(width: NetLearnSpace.s7),

            Icon(action.icon, size: 15, color: foreground),
          ],
        ],
      ),
    );

    if (action.onPressed == null) {
      return Opacity(opacity: 0.5, child: button);
    }

    return Semantics(
      button: true,
      child: NlTapScale(
        scaleDown: 0.96,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(NetLearnRadius.action),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: action.onPressed,
            borderRadius: BorderRadius.circular(NetLearnRadius.action),
            child: button,
          ),
        ),
      ),
    );
  }
}
