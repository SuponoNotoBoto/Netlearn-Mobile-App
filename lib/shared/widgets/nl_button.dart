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
    late final Color bg, fg;
    late final BorderSide border;

    switch (variant) {
      case NlButtonVariant.primary:
        bg = NetLearnColors.primary;
        fg = Colors.white;
        border = BorderSide.none;
        break;

      case NlButtonVariant.secondary:
        bg = NetLearnColors.primaryTint;
        fg = NetLearnColors.primary;
        border = BorderSide.none;
        break;

      case NlButtonVariant.outline:
        bg = Colors.transparent;
        fg = NetLearnColors.primary;
        border = const BorderSide(color: NetLearnColors.primary);
        break;

      case NlButtonVariant.danger:
        bg = Colors.transparent;
        fg = NetLearnColors.danger;
        border = const BorderSide(color: NetLearnColors.danger);
        break;

      case NlButtonVariant.ghost:
        bg = Colors.transparent;
        fg = NetLearnColors.primary;
        border = BorderSide.none;
        break;
    }

    return SizedBox(
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
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: loading
            ? SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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

