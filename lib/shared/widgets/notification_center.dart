import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/announcement_read_store.dart';
import '../../core/theme/app_theme.dart';
import '../../features/dashboard_lecturer/announcement_controller.dart';
import '../../features/dashboard_lecturer/notification_controller.dart';
import '../../features/notifications/notification_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'nl_skeleton.dart';
import 'nl_snack_bar.dart';
import '../../shared/models/announcement_model.dart';
import '../../shared/models/reminder_model.dart';

/// A notification center panel that shows announcements and reminders in tabs.
///
/// Used by both lecturer and student dashboards when the bell icon is tapped.
class NotificationCenter extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final String userId;
  final bool isLecturer;

  const NotificationCenter({
    super.key,
    required this.onClose,
    required this.userId,
    this.isLecturer = false,
  });

  @override
  ConsumerState<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends ConsumerState<NotificationCenter>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLecturer = widget.isLecturer;
    final userId = widget.userId;

    final announcementsProvider = isLecturer
        ? lecturerAnnouncementsProvider(userId)
        : userAnnouncementsProvider(userId);

    final announcementsAsync = ref.watch(announcementsProvider);

    // Tab Pengingat mahasiswa memakai provider per-user; tab dosen melihat
    // provider pengingat "belum dikerjakan" masing-masing di widget tab-nya —
    // memanggil `studentDeadlineRemindersProvider` dengan userId dosen sudah
    // tidak terjadi di sini (dulu selalu kosong).
    final remindersAsync = isLecturer
        ? null
        : ref.watch(studentDeadlineRemindersProvider(userId));

    return Material(
      color: Colors.black.withValues(alpha: 0.3),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 100,
                right: 16,
              ),
              child: Material(
                color: context.surface,
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  // Batas atas, bukan lebar tetap: pada layar 360dp, panel
                  // selebar 360px masih harus menyisakan padding kanan 16px.
                  constraints: const BoxConstraints(
                    maxWidth: 360,
                    maxHeight: 500,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                        decoration: BoxDecoration(
                          color: context.surface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          border: Border(
                            bottom: BorderSide(color: context.border),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.notificationsTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: context.mutedText,
                                  ),
                                  onPressed: widget.onClose,
                                  tooltip: l10n.close,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TabBar(
                              controller: _tabController,
                              tabs: [
                                Tab(text: l10n.announcements),
                                Tab(text: l10n.reminders),
                              ],
                              labelColor: context.accent,
                              unselectedLabelColor: context.mutedText,
                              indicatorColor: context.accent,
                              indicatorWeight: 3,
                              labelStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              unselectedLabelStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              dividerColor: Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _AnnouncementsTab(
                              announcementsAsync: announcementsAsync,
                              isLecturer: widget.isLecturer,
                              userId: widget.userId,
                              onClose: widget.onClose,
                            ),
                            widget.isLecturer
                                ? const _LecturerRemindersTab()
                                : _RemindersTab(
                                    remindersAsync: remindersAsync!,
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementsTab extends ConsumerWidget {
  final AsyncValue<List<AnnouncementModel>> announcementsAsync;
  final bool isLecturer;
  final String userId;
  final VoidCallback onClose;

  const _AnnouncementsTab({
    required this.announcementsAsync,
    required this.isLecturer,
    required this.userId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return announcementsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: NlNotificationsPreviewSkeleton(count: 2),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 46, color: NetLearnColors.danger),
              const SizedBox(height: 12),
              Text(l10n.failedToLoad, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(
                  isLecturer
                      ? lecturerAnnouncementsProvider(userId)
                      : userAnnouncementsProvider(userId),
                ),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
      data: (announcements) {
        if (announcements.isEmpty) {
          return _EmptyState(
            icon: Icons.campaign_outlined,
            title: l10n.noAnnouncements,
            message: isLecturer
                ? 'Create your first announcement to notify students.'
                : 'Published announcements will appear here.',
          );
        }

        // Mahasiswa melihat kartu yang sama dengan halaman Notifikasi; dosen
        // tetap melihat lencana Draf/Dipublikasikan pada barisnya.
        if (!isLecturer) {
          final readIds = ref.watch(announcementReadIdsProvider(userId)).value ??
              const <String>{};

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            shrinkWrap: true,
            itemCount: announcements.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: NetLearnSpace.s8),
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              final unread = !readIds.contains(announcement.id);

              return AnnouncementCard(
                announcement: announcement,
                unread: unread,
                onTap: () => _openStudentAnnouncement(
                  ref,
                  context,
                  announcement,
                  unread: unread,
                ),
              );
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          shrinkWrap: true,
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            return _AnnouncementTile(
              announcement: announcement,
              isLecturer: true,
              onTap: () {
                // Close the overlay first so the dashboard is not still
                // covered when the edit route is popped.
                onClose();
                context.push('/lecturer/announcements/${announcement.id}/edit');
              },
            );
          },
        );
      },
    );
  }

  /// Membuka detail pengumuman untuk mahasiswa.
  ///
  /// Status baca disimpan lebih dulu; kalau penyimpanannya gagal, dot-nya tidak
  /// dihapus dan pengguna diberi tahu. Detailnya sendiri tetap dibuka — isinya
  /// yang dicari, bukan dot-nya.
  ///
  /// [ref] diteruskan sebagai parameter karena `ref` hanya tersedia di dalam
  /// `build`, sedangkan penyimpanan status baca terjadi di callback tap.
  Future<void> _openStudentAnnouncement(
    WidgetRef ref,
    BuildContext context,
    AnnouncementModel announcement, {
    required bool unread,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    if (unread) {
      final saved = await persistAnnouncementRead(
        ref,
        userId: userId,
        announcementId: announcement.id,
      );

      if (!saved) {
        if (!context.mounted) {
          return;
        }

        NlSnackBar.show(
          context,
          l10n.notificationReadSaveFailed,
          tone: NlSnackTone.error,
        );
      }
    }

    if (!context.mounted) {
      return;
    }

    showAnnouncementDetail(context, announcement);
  }
}

/// Tab Pengingat panel lonceng DOSEN: mahasiswa mana yang belum mengerjakan
/// Pretest/Posttest. Mengganti placeholder Inggris yang teksnya hardcode —
/// datanya sama dengan halaman Notifikasi dosen karena tarik provider yang
/// sama ([lecturerMissingAssessmentRemindersProvider]).
class _LecturerRemindersTab extends ConsumerWidget {
  const _LecturerRemindersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return ref.watch(lecturerMissingAssessmentRemindersProvider).when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: NlNotificationsPreviewSkeleton(count: 2),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 46, color: NetLearnColors.danger),
              const SizedBox(height: 12),
              Text(l10n.failedToLoad, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(
                  lecturerMissingAssessmentRemindersProvider,
                ),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
      data: (reminders) {
        if (reminders.isEmpty) {
          return _EmptyState(
            icon: Icons.schedule_outlined,
            title: l10n.noReminders,
            message: l10n.lecturerNoRemindersMessage,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          shrinkWrap: true,
          itemCount: reminders.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: NetLearnSpace.s8),
          itemBuilder: (context, index) => ReminderCard(
            reminder: reminders[index],
            // Kartu menuju rekap nilai mahasiswa yang bersangkutan — tujuan
            // assessment dulu malah membawa dosen ke halaman yang berisi
            // kuis, bukan daftar mahasiswanya. Fallback ke list bila kartu
            // tidak membawa studentId.
            onTap: () => context.push(
              reminders[index].studentId == null
                  ? '/lecturer/students'
                  : '/lecturer/students/${reminders[index].studentId}',
            ),
          ),
        );
      },
    );
  }
}

class _RemindersTab extends ConsumerWidget {
  final AsyncValue<List<ReminderItem>> remindersAsync;

  const _RemindersTab({required this.remindersAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return remindersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: NlNotificationsPreviewSkeleton(count: 2),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 46, color: NetLearnColors.danger),
              const SizedBox(height: 12),
              Text(l10n.failedToLoad, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      data: (reminders) {
        if (reminders.isEmpty) {
          return _EmptyState(
            icon: Icons.schedule_outlined,
            title: l10n.noReminders,
            // Key noRemindersMessage — sekaligus handle jalur "belum
            // dikerjakan"; bukan kalimat deadline hardcode.
            message: l10n.noRemindersMessage,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          shrinkWrap: true,
          itemCount: reminders.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: NetLearnSpace.s8),
          itemBuilder: (context, index) => ReminderCard(
            reminder: reminders[index],
            // Pengingat adalah deadline assessment; tidak ada halaman detail
            // pengingat, jadi tujuan yang benar adalah tab Assessment. Dulu
            // baris ini bisa ditekan tetapi `onTap`-nya kosong.
            onTap: () => context.go('/student/assessment'),
          ),
        );
      },
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final AnnouncementModel announcement;
  final bool isLecturer;
  final VoidCallback onTap;

  const _AnnouncementTile({
    required this.announcement,
    required this.isLecturer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: NetLearnColors.primaryTint,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.campaign_rounded,
                      color: NetLearnColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (isLecturer)
                          Row(
                            children: [
                              _StatusBadge(
                                published: announcement.published,
                                label: announcement.published
                                    ? l10n.announcementPublished
                                    : l10n.announcementDraft,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(announcement.createdAt),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: context.mutedText,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (announcement.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  announcement.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: context.mutedText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final bool published;
  final String label;

  const _StatusBadge({required this.published, required this.label});

  @override
  Widget build(BuildContext context) {
    final toneColors = Theme.of(context).extension<NetLearnStatusColors>();

    final color = published
        ? (toneColors?.positiveText ?? context.accent)
        : (toneColors?.pendingText ?? context.mutedText);

    final background = published
        ? (toneColors?.positiveBg ?? context.accentTint)
        : (toneColors?.pendingBg ?? context.raisedSurface);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: context.mutedText),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.mutedText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}