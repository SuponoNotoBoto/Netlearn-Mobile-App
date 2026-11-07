import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Top bar setinggi 53px dengan garis bawah hairline, tombol kembali, dan judul
/// sesuai dengan spesifikasi index.css NetLearn 2.0.
class NlTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
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
    return AppBar(
      backgroundColor: context.surface,
      foregroundColor: context.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 53,
      centerTitle: false,
      leading: onBack == null
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back, size: 21),
              onPressed: onBack,
            ),
      leadingWidth: onBack == null ? 0 : 52,
      titleSpacing: onBack == null ? NetLearnSpace.s20 : 0,
      actions: actions == null ? null : <Widget>[actions!],
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: NetLearnColors.neutral900,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: context.border,
        ),
      ),
    );
  }
}

