import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/announcement_read_store.dart';
import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/announcement_model.dart';
import '../../shared/models/reminder_model.dart';
import '../../shared/widgets/nl_empty_state.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_segmented_tabs.dart';
import '../../shared/widgets/nl_skeleton.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/nl_topbar.dart';
import '../../shared/widgets/student_bottom_navbar.dart';
import '../dashboard_lecturer/notification_controller.dart';
import 'notification_widgets.dart';

/// Halaman Notifikasi mahasiswa, frame `16:1063` ("Notifikasi Announcement").
///
/// Struktur dari Figma (revisi terbaru): bar atas hanya tombol kembali dan
/// judul — lonceng di bar atas halaman ini dihapus karena redundan (panel
/// lonceng tetap hidup di dasbor). Tersisa segmented tab
/// Pengumuman/Pengingat; tombol "Mark All as Read"; lalu daftar kartu. Bar
/// navigasi mahasiswa tetap di bawah, dengan tidak ada tab yang aktif —
/// halaman ini bukan salah satu dari lima tab itu.
class StudentNotificationsPage extends ConsumerStatefulWidget {
  const StudentNotificationsPage({super.key});

  @override
  ConsumerState<StudentNotificationsPage> createState() =>
      _StudentNotificationsPageState();
}

class _StudentNotificationsPageState
    extends ConsumerState<StudentNotificationsPage> {
  static const _announcementsTab = 0;

  int _tabIndex = _announcementsTab;

  /// Mencegah dua kali tap pada "Mark All as Read" saat penyimpanan berjalan.
  bool _savingReadState = false;

  Future<void> _openAnnouncement(
    AnnouncementModel announcement, {
    required bool unread,
  }) async {
    final userId = ref.read(notificationUserIdProvider);
    final l10n = AppLocalizations.of(context)!;

    // Urutannya: simpan dulu, baru buka detail. Kalau penyimpanan gagal, dot-nya
    // tetap ada dan pengguna diberi tahu — status baca tidak pernah diklaim
    // padahal tidak tersimpan.
    if (unread && userId != null) {
      final saved = await persistAnnouncementRead(
        ref,
        userId: userId,
        announcementId: announcement.id,
      );

      if (!saved) {
        if (!mounted) {
          return;
        }

        NlSnackBar.show(
          context,
          l10n.notificationReadSaveFailed,
          tone: NlSnackTone.error,
        );
      }
    }

    if (!mounted) {
      return;
    }

    showAnnouncementDetail(context, announcement);
  }

  Future<void> _markAllRead(List<AnnouncementModel> announcements) async {
    final userId = ref.read(notificationUserIdProvider);
    final l10n = AppLocalizations.of(context)!;

    if (userId == null || announcements.isEmpty || _savingReadState) {
      return;
    }

    setState(() {
      _savingReadState = true;
    });

    final saved = await persistAllAnnouncementsRead(
      ref,
      userId: userId,
      announcementIds: announcements.map((announcement) => announcement.id),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _savingReadState = false;
    });

    if (!saved) {
      NlSnackBar.show(
        context,
        l10n.notificationReadSaveFailed,
        tone: NlSnackTone.error,
      );
    }
  }

  Future<void> _refresh() async {
    final userId = ref.read(notificationUserIdProvider);
    if (userId == null) {
      return;
    }

    ref.invalidate(userAnnouncementsProvider(userId));
    ref.invalidate(studentDeadlineRemindersProvider(userId));
    ref.invalidate(announcementReadIdsProvider(userId));

    await ref.read(userAnnouncementsProvider(userId).future);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = ref.watch(notificationUserIdProvider);

    // Daftar pengumuman dibaca di build, bukan di dalam tab, karena hitungan
    // "belum dibaca" milik halaman menentukan tombol "Mark All as Read"
    // tampil atau tidak. Satu sumber data untuk tombol dan isi.
    final announcementsAsync =
        userId == null ? null : ref.watch(userAnnouncementsProvider(userId));
    final readIdsAsync =
        userId == null ? null : ref.watch(announcementReadIdsProvider(userId));

    final announcements =
        announcementsAsync?.value ?? const <AnnouncementModel>[];

    // Status baca yang belum termuat dianggap kosong: kartu tampil belum dibaca
    // sampai penyimpanan lokal selesai dibaca, bukan sebaliknya.
    final readIds = readIdsAsync?.value ?? const <String>{};

    final unreadCount = announcements
        .where((announcement) => !readIds.contains(announcement.id))
        .length;

    return Scaffold(
      backgroundColor: context.background,
      // Bar atas di sini adalah `appBar`, bukan anak dari sebuah `Column`:
      // `NlTopBar` membungkus `AppBar`, yang butuh tinggi terbatas dan akan
      // gagal diukur di dalam kolom tanpa batas tinggi.
      appBar: NlTopBar(
        title: l10n.notificationsTitle,
        onBack: () => goBack(context, fallback: '/student'),
      ),
      // Tidak ada tab yang aktif: halaman ini bukan salah satu dari lima tab
      // mahasiswa, jadi tidak ada tujuan yang bisa disorot di bar bawah.
      bottomNavigationBar: const StudentBottomNavbar(currentIndex: -1),
      body: userId == null
          ? NlEmptyState(
              icon: Icons.notifications_off_outlined,
              title: l10n.noNotifications,
            )
          : _buildContent(
              l10n,
              userId: userId,
              announcementsAsync: announcementsAsync!,
              readIdsAsync: readIdsAsync!,
              announcements: announcements,
              unreadCount: unreadCount,
            ),
    );
  }

  Widget _buildContent(
    AppLocalizations l10n, {
    required String userId,
    required AsyncValue<List<AnnouncementModel>> announcementsAsync,
    required AsyncValue<Set<String>> readIdsAsync,
    required List<AnnouncementModel> announcements,
    required int unreadCount,
  }) {
    return RefreshIndicator(
      color: context.accent,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // `.content` = `padding:22px 22px 28px`.
        padding: const EdgeInsets.fromLTRB(
          NetLearnSpace.s22,
          NetLearnSpace.s22,
          NetLearnSpace.s22,
          28,
        ),
        children: [
          NlSegmentedTabs(
            labels: [
              l10n.announcements,
              l10n.reminders,
            ],
            selectedIndex: _tabIndex,
            semanticLabel: l10n.notificationsTitle,
            onChanged: (index) => setState(() => _tabIndex = index),
          ),
          const SizedBox(height: NetLearnSpace.s16),
          if (_tabIndex == _announcementsTab)
            ..._announcementsChildren(
              l10n,
              announcementsAsync: announcementsAsync,
              readIdsAsync: readIdsAsync,
              announcements: announcements,
              unreadCount: unreadCount,
            )
          else
            ..._remindersChildren(l10n, userId: userId),
        ],
      ),
    );
  }

  List<Widget> _announcementsChildren(
    AppLocalizations l10n, {
    required AsyncValue<List<AnnouncementModel>> announcementsAsync,
    required AsyncValue<Set<String>> readIdsAsync,
    required List<AnnouncementModel> announcements,
    required int unreadCount,
  }) {
    // Hanya daftar pengumumannya yang menahan tab ini. Status baca lokal
    // (`announcementReadIdsProvider`) sengaja tidak ikut ditunggu: kalau
    // penyimpanan lokal lambat atau gagal, daftarnya tetap tampil — kartu
    // sementara dibaca sebagai belum dibaca — alih-alih berputar selamanya.
    if (announcementsAsync.isLoading) {
      return const [_NotificationLoading()];
    }

    if (announcementsAsync.hasError) {
      return [
        NlErrorView(
          message: l10n.failedToLoad,
          onRetry: () {
            final userId = ref.read(notificationUserIdProvider);
            if (userId != null) {
              ref.invalidate(userAnnouncementsProvider(userId));
            }
          },
        ),
      ];
    }

    if (announcements.isEmpty) {
      return [
        NlEmptyState(
          icon: Icons.campaign_outlined,
          title: l10n.noAnnouncements,
          message: l10n.noAnnouncementsMessage,
        ),
      ];
    }

    final readIds = readIdsAsync.value ?? const <String>{};

    final children = <Widget>[];

    // Tombol hanya muncul kalau masih ada yang belum dibaca: menandai semua
    // sebagai dibaca saat semuanya sudah dibaca tidak melakukan apa pun.
    if (unreadCount > 0) {
      children.add(
        _MarkAllAsReadButton(
          label: l10n.markAllAsRead,
          busy: _savingReadState,
          onPressed: () => _markAllRead(announcements),
        ),
      );
    }

    for (final announcement in announcements) {
      children.add(
        AnnouncementCard(
          announcement: announcement,
          unread: !readIds.contains(announcement.id),
          onTap: () => _openAnnouncement(
            announcement,
            unread: !readIds.contains(announcement.id),
          ),
        ),
      );
    }

    return _withGaps(children);
  }

  List<Widget> _remindersChildren(AppLocalizations l10n, {required String userId}) {
    final remindersAsync = ref.watch(studentDeadlineRemindersProvider(userId));

    if (remindersAsync.isLoading) {
      return const [_NotificationLoading()];
    }

    if (remindersAsync.hasError) {
      return [
        NlErrorView(
          message: l10n.failedToLoad,
          onRetry: () => ref.invalidate(studentDeadlineRemindersProvider(userId)),
        ),
      ];
    }

    final reminders = remindersAsync.value ?? const <ReminderItem>[];

    if (reminders.isEmpty) {
      return [
        NlEmptyState(
          icon: Icons.schedule_outlined,
          title: l10n.noReminders,
          message: l10n.noRemindersMessage,
        ),
      ];
    }

    // Setiap pengingat adalah deadline assessment, jadi tujuannya tab
    // Assessment — bukan detail yang tidak ada. `go` dipakai supaya tab
    // menggantikan stack, sama seperti bar bawah.
    return _withGaps([
      for (final reminder in reminders)
        ReminderCard(
          reminder: reminder,
          onTap: () => context.go('/student/assessment'),
        ),
    ]);
  }

  /// Jarak antar anak `.content` di Figma adalah `gap:16px`.
  List<Widget> _withGaps(List<Widget> children) {
    final spaced = <Widget>[];

    for (var index = 0; index < children.length; index++) {
      if (index > 0) {
        spaced.add(const SizedBox(height: NetLearnSpace.s16));
      }

      spaced.add(children[index]);
    }

    return spaced;
  }
}

/// Tombol "Mark All as Read" — teks aksen dengan ikon centang, di tengah.
class _MarkAllAsReadButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onPressed;

  const _MarkAllAsReadButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // Tombol mati saat penyimpanan berjalan, bukan menghilang, supaya
          // letaknya tidak melompat.
          onTap: busy ? null : onPressed,
          borderRadius: BorderRadius.circular(NetLearnRadius.sm),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              NetLearnSpace.s8,
              NetLearnSpace.s15,
              NetLearnSpace.s8,
              NetLearnSpace.s8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.done_all_rounded,
                  size: 14,
                  color: context.accent,
                ),
                const SizedBox(width: NetLearnSpace.s6),
                Text(
                  label,
                  style: context.linkSmallStyle?.copyWith(
                    fontSize: 11,
                    color: context.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationLoading extends StatelessWidget {
  const _NotificationLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: NetLearnSpace.s8),
      child: NlNotificationsPreviewSkeleton(count: 3),
    );
  }
}

