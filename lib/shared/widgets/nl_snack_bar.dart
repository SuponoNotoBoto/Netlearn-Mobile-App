import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum NlSnackTone { success, error, warning, info }

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

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
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
        break;
      case NlSnackTone.error:
        bg = feedback.errorBg;
        fg = feedback.errorFg;
        border = feedback.errorBorder;
        toneIcon = Icons.error_outline_rounded;
        toneDuration = const Duration(seconds: 6);
        break;
      case NlSnackTone.warning:
        bg = feedback.warningBg;
        fg = feedback.warningFg;
        border = feedback.warningBorder;
        toneIcon = Icons.warning_amber_rounded;
        toneDuration = const Duration(seconds: 5);
        break;
      case NlSnackTone.info:
        bg = feedback.infoBg;
        fg = feedback.infoFg;
        border = feedback.infoBorder;
        toneIcon = Icons.info_outline_rounded;
        toneDuration = const Duration(seconds: 4);
        break;
    }

    final IconData resolvedIcon = icon ?? toneIcon;
    final Duration resolvedDuration = duration ?? toneDuration;

    return SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      backgroundColor: bg,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: border),
      ),
      duration: resolvedDuration,
      content: Row(
        children: [
          Icon(resolvedIcon, color: fg, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

