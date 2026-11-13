import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/avatar/nl_avatar_models.dart';
import '../../core/avatar/nl_avatar_widget.dart';
import '../../core/notifications/announcement_read_store.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_metric_grid.dart';
import '../../shared/widgets/nl_micro_transition.dart';
import '../../shared/widgets/nl_notification_bell.dart';
import '../../shared/widgets/nl_promo_banner.dart';
import '../../shared/widgets/nl_shortcut_tile.dart';
import '../../shared/widgets/nl_skeleton.dart';
// class imports
// class imports
import '../classes/class_controller.dart';
import '../classes/class_models.dart';
import '../classes/class_onboarding_page.dart';
import '../classes/lecturer_manage_class_section.dart';
import 'lecturer_bottom_navbar.dart';
import 'lecturer_dashboard_controller.dart';
import 'notification_controller.dart';

class LecturerDashboardPage extends ConsumerStatefulWidget {
  const LecturerDashboardPage({super.key});

  @override
  ConsumerState<LecturerDashboardPage> createState() =>
      _LecturerDashboardPageState();
}

class _LecturerDashboardPageState extends ConsumerState<LecturerDashboardPage> {
  Future<void> _refresh() async {
    ref.invalidate(lecturerDashboardStatsProvider);
    ref.invalidate(lecturerProfileProvider);
    ref.invalidate(lecturerClassesProvider);

    // Daftar pengumuman dan status bacanya tidak ikut di-invalidate oleh
    // stats di atas: keduanya di-cache terpisah oleh
    // userAnnouncementsProvider / announcementReadIdsProvider, jadi tanpa ini
    // pull-to-refresh menyegarkan metrik tapi dot lonceng bisa basi.
    final userId = ref.read(notificationUserIdProvider);
    if (userId != null) {
      ref.invalidate(userAnnouncementsProvider(userId));
      ref.invalidate(announcementReadIdsProvider(userId));
    }

    await ref.read(lecturerDashboardStatsProvider.future);
  }

  void _openNotifications() {
    context.push('/lecturer/notifications');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final statsAsync = ref.watch(lecturerDashboardStatsProvider);
    final profileAsync = ref.watch(lecturerProfileProvider);
    final classesAsync = ref.watch(lecturerClassesProvider);
    final archivedClasses = ref.watch(lecturerArchivedClassesProvider).value;
    final activeClass = ref.watch(activeLecturerClassProvider).value;
    final classes = classesAsync.value;
    final isAdmin = profileAsync.value?.isAdmin == true;
    if (!isAdmin &&
        classes != null &&
        classes.isEmpty &&
        (archivedClasses?.isEmpty ?? true)) {
      return Scaffold(
        backgroundColor: context.background,
        body: const SafeArea(
          child: ClassOnboardingView(
            role: ClassOnboardingRole.lecturer,
            hasExistingClass: false,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.background,

      body: SafeArea(
        child: RefreshIndicator(
          color: context.accent,
          onRefresh: _refresh,
          child: Stack(
            children: [
              CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // `.hero.dashboard-hero` — gradien 115deg dengan sudut bawah
                  // membulat. Memegang avatar, sapaan, dan kartu identitas sekaligus
                  // supaya bagian atas layar hanya punya satu blok warna.
                  SliverToBoxAdapter(
                    child: profileAsync.when(
                      loading: () => _buildHero(context, null),
                      error: (error, stackTrace) => _buildHero(context, null),
                      data: (profile) => _buildHero(context, profile),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      NetLearnSpace.s20,
                      NetLearnSpace.s20,
                      NetLearnSpace.s20,
                      NetLearnSpace.s32,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (classes != null &&
                            activeClass != null &&
                            activeClass.id != kLegacyFallbackClassId) ...[
                          LecturerActiveClassBar(
                            classes: classes,
                            activeClass: activeClass,
                          ),
                          const SizedBox(height: NetLearnSpace.s16),
                        ],
                        if (isAdmin) ...[
                          _AdminUserManagementCard(
                            onTap: () => context.push('/admin/users'),
                          ),
                          const SizedBox(height: NetLearnSpace.s16),
                        ],
                        NlPromoBanner(
                          title: Localizations.localeOf(context).languageCode == 'id'
                              ? 'Siap Mengajar Hari Ini?'
                              : 'Ready to Teach Today?',
                          subtitle: Localizations.localeOf(context).languageCode == 'id'
                              ? 'Kelola materi, pengumuman, dan pantau progres mahasiswa melalui dashboard Anda.'
                              : 'Manage materials, announcements, and monitor student progress from your dashboard.',
                          ctaLabel: Localizations.localeOf(context).languageCode == 'id'
                              ? 'Kelola Materi'
                              : 'Manage Materials',
                          onPressed: () {
                            context.push('/lecturer/materials');
                          },
                        ),

                        const SizedBox(height: NetLearnSpace.s20),

                        // Learning Space — shortcut grid dipindah ke atas
                        // supaya dosen cepat mencapai halaman kelola.
                        _buildSectionTitle(context, l10n.lecturerSpaceHeading),

                        const SizedBox(height: NetLearnSpace.s12),

                        _buildShortcutGrid(context, l10n, activeClass, classes),

                        const SizedBox(height: NetLearnSpace.s20),

                        // Recent Activities — placeholder jujur; diganti
                        // feed aktivitas nyata saat backend tersedia.
                        NlContentTransition(
                          child: statsAsync.when(
                            loading: () => _buildRecentActivitiesShell(
                              context,
                              const _ProgressSkeleton(),
                            ),
                            error: (error, stackTrace) =>
                                _buildRecentActivitiesShell(
                                  context,
                                  _StatsError(onRetry: _refresh),
                                ),
                            data: (stats) =>
                                _buildRecentActivities(context, stats),
                          ),
                        ),

                      ]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: const LecturerBottomNavbar(currentIndex: 0),
    );
  }

  /// `.hero.dashboard-hero` — blok gradien di paling atas dashboard.
  ///
  /// Lonceng, avatar, sapaan, dan NIP digabung di sini, bukan di app bar, karena
  /// di desain semuanya berada pada satu bidang ungu (`.dashboard-profile-top`
  /// memegang lonceng dan avatar; `.greeting` memegang sapaan). Lonceng sekarang
  /// bisa ditekan untuk membuka panel Notifications.
  Widget _buildHero(
    BuildContext context,
    LecturerProfile? profile,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use lecturer's name for personalized greeting, fallback to generic if not available
    final greetingName = profile?.name.isNotEmpty == true
        ? profile!.name
        : null;
    final greetingText = greetingName != null
        ? l10n.lecturerGreeting(greetingName)
        : l10n.lecturerGreeting(l10n.lecturer);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        NetLearnSpace.s20,
        NetLearnSpace.s12,
        NetLearnSpace.s20,
        NetLearnSpace.s4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                NlAvatarWidget(
                  config: profile?.avatarConfig ??
                      AvatarConfig.defaultFor(
                        profile?.id ?? profile?.name ?? 'lecturer',
                      ),
                  size: 44,
                  borderWidth: 2,
                  borderColor: isDark
                      ? NetLearnColors.darkLine
                      : NetLearnColors.white,
                  onTap: () {
                    context.go('/lecturer/profile');
                  },
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF35C779),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? NetLearnColors.darkApp
                            : NetLearnColors.appBg,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: NetLearnSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        greetingText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: isDark
                              ? NetLearnColors.darkText
                              : NetLearnColors.neutral900,
                        ),
                      ),
                    ),
                    if (profile?.isAdmin == true) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFD97706).withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD97706),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  profile?.isAdmin == true
                      ? (profile!.identityNumber.isNotEmpty
                          ? 'Administrator • ${profile.identityNumber}'
                          : 'Administrator')
                      : (profile != null && profile.identityNumber.isNotEmpty
                          ? '${l10n.lecturerDashboardSubtitle} • ${profile.identityNumber}'
                          : l10n.lecturerDashboardSubtitle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? NetLearnColors.darkMuted
                        : NetLearnColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          NlNotificationBell(
            onTap: _openNotifications,
            tooltip: l10n.notificationsTitle,
          ),
          const SizedBox(width: 8),
          _HeroIconButton(
            icon: Icons.help_outline_rounded,
            onTap: () {
              context.push('/lecturer/about');
            },
          ),
        ],
      ),
    );
  }

  /// `.section-heading h2` — judul bagian ungu, bukan eyebrow pucat.
  ///
  /// Label lama memakai gaya eyebrow (`labelSmall`) yang warnanya meredup ke teks
  /// sekunder. Di desain, heading bagian memakai warna brand penuh supaya hierarki
  /// halaman terbaca tanpa perlu garis pemisah tambahan.
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,

      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: context.onSurface,
      ),
    );
  }

  /// Judul "Recent Activities" plus isinya. Dipakai untuk state loading/error
  /// supaya judulnya tetap terlihat saat data belum atau tidak bisa dimuat.
  Widget _buildRecentActivitiesShell(BuildContext context, Widget body) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildSectionTitle(context, l10n.recentActivity)),
            // Ikon jam di kanan heading "Recent Activity" — Figma `Dashboard Dosen 2`
            // (86:308) menampilkan ikon jam kecil di sisi kanan section heading.
            Icon(Icons.schedule, size: 18, color: context.mutedText),
          ],
        ),
        const SizedBox(height: NetLearnSpace.s12),
        body,
      ],
    );
  }

  /// Recent Activities menampilkan aktivitas terbaru dosen.
  ///
  /// Karena belum ada backend aktivitas nyata, bagian ini menampilkan placeholder
  /// yang jujur. Data aktivitas sebenarnya akan ditambahkan ketika backend tersedia.
  Widget _buildRecentActivities(
    BuildContext context,
    LecturerDashboardStats stats,
  ) {
    final l10n = AppLocalizations.of(context)!;

    // Placeholder activities based on published content stats
    // NOTE: This is placeholder data since there's no activity backend yet.
    // When backend is available, replace with actual activity feed.
    final activities = <_ActivityItem>[
      if (stats.publishedMaterialCount > 0)
        _ActivityItem(
          icon: Icons.menu_book_outlined,
          title: l10n.shortcutManageMaterials,
          subtitle: l10n.publishedOfTotal(
            stats.publishedMaterialCount,
            stats.materialCount,
          ),
        ),
      if (stats.publishedAssessmentCount > 0)
        _ActivityItem(
          icon: Icons.assignment_outlined,
          title: l10n.assignment,
          subtitle: l10n.publishedOfTotal(
            stats.publishedAssessmentCount,
            stats.assessmentCount,
          ),
        ),
      if (stats.materialCount > 0 && stats.publishedMaterialCount == 0)
        _ActivityItem(
          icon: Icons.drafts_outlined,
          title: l10n.draft,
          subtitle:
              '${stats.materialCount} ${l10n.materials.toLowerCase()} ${l10n.notFilledYet}',
        ),
    ];

    if (activities.isEmpty) {
      return _buildRecentActivitiesShell(
        context,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: NetLearnSpace.s16,
            vertical: NetLearnSpace.s24,
          ),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(NetLearnRadius.card),
            border: Border.all(color: context.border),
          ),
          child: Column(
            children: [
              Icon(Icons.history_outlined, size: 28, color: context.mutedText),
              const SizedBox(height: NetLearnSpace.s8),
              Text(
                l10n.noNotifications, // Reusing "No notifications yet" as "No activities yet"
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: context.mutedText),
              ),
            ],
          ),
        ),
      );
    }

    return _buildRecentActivitiesShell(
      context,
      // Figma `72:192` — Recent Activity is one white card containing the
      // items, not a stack of separate tiles. Dividers separate the rows.
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: NetLearnSpace.s16,
          vertical: NetLearnSpace.s4,
        ),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(NetLearnRadius.card),
          border: Border.all(color: context.border),
        ),
        child: Column(
          children: [
            for (var i = 0; i < activities.length; i++) ...[
              _ActivityTile(activity: activities[i]),
              // Pemisah antarbaris di dalam satu kartu. `thickness: 0.5`
              // adalah hairline (≈1 device px di 2–3x DPR); ketebalan default
              // Divider (1dp) terbaca seperti garis tebal pada perangkat
              // dibanding referensi Figma `72:192`.
              if (i < activities.length - 1)
                Divider(
                  height: NetLearnSpace.s24,
                  thickness: 0.5,
                  color: context.border,
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// "Recent Notifications" — keadaan kosong yang jujur.
  ///
  /// Tidak ada tabel, provider, maupun route notifikasi di NetLearn, jadi daftar
  /// apa pun di sini akan menjadi karangan. Bagian ini hanya menyatakan bahwa
  /// belum ada notifikasi, dan siap diisi begitu backend-nya ada.
  // ignore: unused_element
  Widget _buildNotifications(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, l10n.recentNotifications),
        const SizedBox(height: NetLearnSpace.s12),
        const _NotificationsEmpty(),
      ],
    );
  }

  /// `.shortcut-grid.learning-space-grid` — delapan pintu masuk ruang mengajar.
  ///
  /// Tiga kolom sesuai Figma `Dashboard Dosen` (`72-2`). Grid-nya memakai
  /// [NlMetricGrid] (`bordered: false`) supaya logika baris setara tidak
  /// ditulis ulang.
  ///
  /// Shortcut `Profile` telah dihapus dari grid: pintu ke profil tetap ada
  /// lewat avatar di hero dan tab Profil di bar bawah. `Virtual Lab` membuka
  /// halaman lab 2D yang sama dengan mahasiswa, lewat route `/lecturer` agar
  /// penjaga peran tidak memantulkannya ke dashboard.
  Widget _buildShortcutGrid(
    BuildContext context,
    AppLocalizations l10n, [
    LecturerClass? activeClass,
    List<LecturerClass>? classes,
  ]) {
    final hasActiveClass = activeClass != null &&
        activeClass.id.isNotEmpty &&
        activeClass.id != kLegacyFallbackClassId;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final accents = NetLearnAccents.grid;

    return NlMetricGrid(
      bordered: false,
      padding: EdgeInsets.zero,
      gap: NetLearnSpace.s12,
      bottomGap: 0,
      columns: 3,
      children: [
        NlShortcutTile(
          icon: Icons.menu_book_outlined,
          accentColor: accents[0],
          title: l10n.shortcutManageMaterials,
          subtitle: hasActiveClass
              ? l10n.classModulesCount(activeClass.moduleCount)
              : l10n.shortcutManageMaterialsHint,
          onTap: () {
            context.push('/lecturer/materials');
          },
        ),

        NlShortcutTile(
          icon: Icons.assignment_outlined,
          accentColor: accents[1],
          title: l10n.shortcutAssignments,
          subtitle: l10n.shortcutAssignmentHint,
          onTap: () {
            context.push('/lecturer/assessments');
          },
        ),

        NlShortcutTile(
          icon: Icons.quiz_outlined,
          accentColor: accents[2],
          title: l10n.shortcutManageQuestions,
          subtitle: l10n.shortcutManageQuestionsHint,
          onTap: () {
            context.push('/lecturer/assessments');
          },
        ),

        NlShortcutTile(
          icon: Icons.view_in_ar_rounded,
          accentColor: accents[3],
          title: l10n.shortcutScanner,
          subtitle: l10n.shortcutScannerHint,
          onTap: () {
            context.push('/lecturer/ar');
          },
        ),

        NlShortcutTile(
          icon: Icons.campaign_outlined,
          accentColor: accents[4],
          title: l10n.manageAnnouncements,
          subtitle: l10n.shortcutManageQuestionsHint,
          onTap: () {
            context.push('/lecturer/announcements');
          },
        ),

        NlShortcutTile(
          icon: Icons.groups_outlined,
          accentColor: accents[5],
          title: l10n.studentList,
          subtitle: hasActiveClass
              ? l10n.classMembersCount(activeClass.memberCount)
              : l10n.studentScoreSummary,
          onTap: () {
            context.push('/lecturer/students');
          },
        ),

        // Row 3: Learning Video, Virtual Lab — Profile dihapus sesuai Figma `72:2`.
        NlShortcutTile(
          icon: Icons.play_circle_outline_rounded,
          accentColor: accents[1],
          title: l10n.learningVideo,
          subtitle: l10n.watchAndLearn,
          onTap: () {
            context.push('/lecturer/video-list');
          },
        ),

        // Logo Virtual Lab mengikuti referensi Dashboard Mahasiswa: simbol
        // jaringan putih di dalam lingkaran ungu — node-node perangkat yang
        // saling terhubung (satu node di atas, dua di bawah, tersambung
        // garis). Glyph Material yang membentuk susunan persis itu adalah
        // `lan_outlined`; proyek tidak punya asset ikon custom untuk tile ini,
        // jadi tidak ada aset asli Figma yang bisa dipakai kembali.
        NlShortcutTile(
          icon: Icons.lan_outlined,
          accentColor: accents[0],
          title: l10n.virtualLab,
          subtitle: l10n.networkPractice,
          // Lab yang sama dengan mahasiswa, dipasang di bawah /lecturer supaya
          // penjaga peran tidak memantulkan dosen ke dashboard.
          onTap: () {
            context.push('/lecturer/virtual-lab');
          },
        ),

        // Row 3 (slot 3): Kelola Kelas (Manage Class) — melengkapi grid menjadi 3x3 simetris.
        NlShortcutTile(
          icon: Icons.school_outlined,
          accentColor: accents[2],
          title: l10n.manageClassesTitle,
          subtitle: (classes != null && classes.isNotEmpty)
              ? (isId ? '${classes.length} Kelas' : '${classes.length} Classes')
              : (isId ? 'Semua Kelas' : 'All Classes'),
          onTap: () {
            context.push('/lecturer/classes');
          },
        ),
      ],
    );
  }
}

/// Tombol ikon di hero dashboard dosen.
///
/// Dipakai tombol About (`?`) saja sekarang — loncengnya pindah ke
/// [NlNotificationBell] yang dibagi dengan dashboard mahasiswa karena
/// butuh logika dot yang sama. Bentuknya tetap kotak rounded
/// semi-transparan dengan ikon putih, sesuai Figma `Dashboard Dosen`
/// (46:665).
class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeroIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
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
          child: Center(
            child: Icon(
              icon,
              size: 19,
              color: isDark ? NetLearnColors.darkText : NetLearnColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _ActivityTile extends StatelessWidget {
  final _ActivityItem activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NetLearnSpace.s12),
      child: Row(
        children: [
          // Icon circle — light orange background with orange icon,
          // matching the Figma `Dashboard Dosen 2` reference.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E6),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(activity.icon, color: const Color(0xFFFF8A50), size: 18),
          ),
          const SizedBox(width: NetLearnSpace.s12),
          // Content — title and subtitle stacked vertically.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontSize: 11, color: context.mutedText),
                ),
              ],
            ),
          ),
          // Chevron right — aligned to the far right.
          Icon(
            Icons.chevron_right_rounded,
            color: context.mutedText,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _ProgressSkeleton extends StatelessWidget {
  const _ProgressSkeleton();

  @override
  Widget build(BuildContext context) {
    // Tinggi mendekati panel aktivitas terisi supaya isi halaman
    // tidak melompat jauh saat data tiba.
    return const NlNotificationsPreviewSkeleton(rows: 3);
  }
}

class _StatsError extends StatelessWidget {
  final VoidCallback onRetry;

  const _StatsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NetLearnSpace.s16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: context.accent),
          const SizedBox(width: NetLearnSpace.s12),
          Expanded(child: Text(l10n.dashboardLoadError)),
          TextButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}

/// Keadaan kosong untuk "Recent Notifications".
///
/// Dibuat sejajar dengan [_StatsError] (permukaan bertema, sudut kartu) supaya
/// bagian ini tidak terlihat seperti elemen asing di dashboard.
class _NotificationsEmpty extends StatelessWidget {
  const _NotificationsEmpty();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: NetLearnSpace.s16,
        vertical: NetLearnSpace.s24,
      ),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 28,
            color: context.mutedText,
          ),
          const SizedBox(height: NetLearnSpace.s8),
          Text(
            l10n.noNotifications,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: context.mutedText),
          ),
        ],
      ),
    );
  }
}

/// Kartu khusus untuk Role Admin di atas dashboard untuk membuka halaman Kelola Pengguna.
class _AdminUserManagementCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AdminUserManagementCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const amberColor = Color(0xFFD97706);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF282118) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(NetLearnRadius.card),
            border: Border.all(
              color: amberColor.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: amberColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.manage_accounts_rounded,
                  color: amberColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isId
                          ? 'Panel Admin • Kelola Pengguna'
                          : 'Admin Panel • User Management',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFFFDE68A)
                            : const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isId
                          ? 'Tambah akun, nonaktifkan, atau hapus akun mahasiswa & dosen'
                          : 'Add, deactivate, or delete student & lecturer accounts',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFFD6C39A)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: amberColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
