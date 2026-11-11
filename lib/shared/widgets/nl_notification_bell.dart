import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/announcement_read_store.dart';
import '../../core/notifications/announcement_unread.dart';
import '../../core/theme/app_theme.dart';
import '../../features/dashboard_lecturer/notification_controller.dart';
import '../models/announcement_model.dart';
import 'nl_tap_scale.dart';

final _bellUserIdProvider = Provider<String?>((ref) {
  try {
    return ref.watch(notificationUserIdProvider);
  } catch (_) {
    return null;
  }
});

/// `.header-icon-btn` dari `design_figma/scr_figma_new/index.css`:
/// tombol lingkaran 40x40 putih (`#fff` di light mode, `#161820` di dark mode)
/// dengan border `#f1edfc` dan dot merah belum dibaca (`#FF7979`).
class NlNotificationBell extends ConsumerWidget {
  final VoidCallback onTap;

  final String tooltip;

  const NlNotificationBell({
    super.key,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(_bellUserIdProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    var showDot = false;

    if (userId != null) {
      final announcements =
          ref.watch(userAnnouncementsProvider(userId)).value ??
              const <AnnouncementModel>[];
      final readIds = ref.watch(announcementReadIdsProvider(userId)).value ??
          const <String>{};

      showDot = hasUnreadAnnouncement(announcements, readIds);
    }

    return Tooltip(
      message: tooltip,
      child: NlTapScale(
        scaleDown: 0.92,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? NetLearnColors.darkSurface : NetLearnColors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? NetLearnColors.darkLine
                    : const Color(0xFFF1EDFC),
              ),
              boxShadow: isDark
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x0F1D1C21),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 19,
                    color: isDark
                        ? NetLearnColors.darkText
                        : NetLearnColors.ink,
                  ),
                ),
                if (showDot)
                  Positioned(
                    top: 7,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7979),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isDark
                              ? NetLearnColors.darkSurface
                              : NetLearnColors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
