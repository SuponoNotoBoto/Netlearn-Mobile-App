import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'nl_tap_scale.dart';

/// `.compact` dari index.css: bar putih setinggi 53px, garis bawah rambut,
/// tombol kembali di kiri, judul rata kiri, dan area aksi di kanan.
class NlTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  /// Null membuat bar tanpa tombol kembali.
  ///
  /// Dipakai untuk halaman yang punya navigasi bawah: tab tersebut mengganti
  /// stack, jadi tidak ada halaman sebelumnya untuk kembali. `.compact` di
  /// index.css sendiri tidak menempelkan tombol kembali ke markup-nya, jadi
  /// bentuk yang sama berlaku untuk tab maupun subpage; yang membedakan hanya
  /// ada atau tidaknya tombol.
  final VoidCallback? onBack;
  final Widget? actions;

  const NlTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(53);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 53,
      centerTitle: false,
      // `padding:20px` pada `.compact`. Tanpa tombol kembali judulnya mulai
      // dari padding yang sama, bukan dari `titleSpacing:0` yang hanya berlaku
      // ketika leading tombol kembali memakan 52px.
      leading: onBack == null
          ? null
          : NlTapScale(
              scaleDown: 0.9,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 21),
                onPressed: onBack,
              ),
            ),
      leadingWidth: onBack == null ? 0 : 52,
      titleSpacing: onBack == null ? NetLearnSpace.s20 : 0,
      actions: actions == null ? null : <Widget>[actions!],
      // `.compact h1` — 15px weight 800.
      title: Text(
        title,
        style: theme.textTheme.titleLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}