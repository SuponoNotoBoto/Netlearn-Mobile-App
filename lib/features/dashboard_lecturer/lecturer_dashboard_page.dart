import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_metric_grid.dart';
import '../../shared/widgets/nl_notification_bell.dart';
import '../../shared/widgets/nl_promo_banner.dart';
import '../../shared/widgets/nl_shortcut_tile.dart';
import 'lecturer_bottom_navbar.dart';
import 'lecturer_dashboard_controller.dart';

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
    await ref.read(lecturerDashboardStatsProvider.future);
  }

  void _openNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Localizations.localeOf(context).languageCode == 'id'
              ? 'Fitur Notifikasi sedang dalam tahap pengembangan'
              : 'Notifications feature is currently under development',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(lecturerDashboardStatsProvider);
    final profileAsync = ref.watch(lecturerProfileProvider);

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: context.accent,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
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
                    NlPromoBanner(
                      title: Localizations.localeOf(context).languageCode == 'id'
                          ? 'Siap Mengajar Hari Ini?'
                          : 'Ready to Teach Today?',
                      subtitle: Localizations.localeOf(context).languageCode == 'id'
                          ? 'Kelola materi, asesmen, dan pantau progres mahasiswa melalui dashboard Anda.'
                          : 'Manage materials, assessments, and monitor student progress from your dashboard.',
                      ctaLabel: Localizations.localeOf(context).languageCode == 'id'
                          ? 'Kelola Materi'
                          : 'Manage Materials',
                      onPressed: () {
                        context.push('/lecturer/materials');
                      },
                    ),
                    const SizedBox(height: NetLearnSpace.s20),

                    _buildSectionTitle(context, l10n.lecturerSpaceHeading),
                    const SizedBox(height: NetLearnSpace.s12),

                    _buildShortcutGrid(context, l10n),
                    const SizedBox(height: NetLearnSpace.s20),

                    statsAsync.when(
                      loading: () => _buildRecentActivitiesShell(
                        context,
                        const Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, stackTrace) => _buildRecentActivitiesShell(
                        context,
                        Text(l10n.failedToLoad),
                      ),
                      data: (stats) => _buildRecentActivities(context, stats),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const LecturerBottomNavbar(currentIndex: 0),
    );
  }

  Widget _buildHero(
    BuildContext context,
    LecturerProfile? profile,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          // Simple avatar circle (initials) without complex avatar studio
          GestureDetector(
            onTap: () => context.go('/lecturer/profile'),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: NetLearnColors.heroAvatarBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? NetLearnColors.darkLine : NetLearnColors.white,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      profile?.initial ?? 'D',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: NetLearnColors.heroAvatarFg,
                        fontFamily: AppTheme.displayFontFamily,
                      ),
                    ),
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
                          color: isDark ? NetLearnColors.darkApp : NetLearnColors.appBg,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: NetLearnSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
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
                const SizedBox(height: 2),
                Text(
                  profile != null && profile.identityNumber.isNotEmpty
                      ? '${l10n.lecturerDashboardSubtitle} • ${profile.identityNumber}'
                      : l10n.lecturerDashboardSubtitle,
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

  Widget _buildShortcutGrid(BuildContext context, AppLocalizations l10n) {
    final accents = NetLearnAccents.grid;

    return NlMetricGrid(
      padding: EdgeInsets.zero,
      gap: NetLearnSpace.s12,
      columns: 3,
      children: [
        NlShortcutTile(
          icon: Icons.menu_book_outlined,
          accentColor: accents[0 % accents.length],
          title: l10n.shortcutManageMaterials,
          subtitle: l10n.shortcutManageMaterialsHint,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  Localizations.localeOf(context).languageCode == 'id'
                      ? 'Fitur Materi sedang dalam tahap pengembangan'
                      : 'Materials feature is currently under development',
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        NlShortcutTile(
          icon: Icons.assignment_outlined,
          accentColor: accents[1 % accents.length],
          title: l10n.shortcutAssignments,
          subtitle: l10n.shortcutAssignmentHint,
          onTap: () {
            context.push('/lecturer/assessments');
          },
        ),
        NlShortcutTile(
          icon: Icons.quiz_outlined,
          accentColor: accents[2 % accents.length],
          title: l10n.shortcutManageQuestions,
          subtitle: l10n.shortcutManageQuestionsHint,
          onTap: () {
            context.push('/lecturer/assessments');
          },
        ),
        NlShortcutTile(
          icon: Icons.view_in_ar_rounded,
          accentColor: accents[3 % accents.length],
          title: l10n.shortcutScanner,
          subtitle: l10n.shortcutScannerHint,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  Localizations.localeOf(context).languageCode == 'id'
                      ? 'Fitur AR Scanner sedang dalam tahap pengembangan'
                      : 'AR Scanner feature is currently under development',
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        NlShortcutTile(
          icon: Icons.campaign_outlined,
          accentColor: accents[4 % accents.length],
          title: l10n.manageAnnouncements,
          subtitle: l10n.shortcutManageQuestionsHint,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  Localizations.localeOf(context).languageCode == 'id'
                      ? 'Fitur Pengumuman sedang dalam tahap pengembangan'
                      : 'Announcements feature is currently under development',
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        NlShortcutTile(
          icon: Icons.groups_outlined,
          accentColor: accents[5 % accents.length],
          title: l10n.studentList,
          subtitle: l10n.studentScoreSummary,
          onTap: () {
            context.push('/lecturer/students');
          },
        ),
        NlShortcutTile(
          icon: Icons.play_circle_outline_rounded,
          accentColor: accents[1 % accents.length],
          title: l10n.learningVideo,
          subtitle: l10n.watchAndLearn,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  Localizations.localeOf(context).languageCode == 'id'
                      ? 'Fitur Video Pembelajaran sedang dalam tahap pengembangan'
                      : 'Learning video feature is currently under development',
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivitiesShell(BuildContext context, Widget body) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildSectionTitle(context, l10n.recentActivity)),
            Icon(Icons.schedule, size: 18, color: context.mutedText),
          ],
        ),
        const SizedBox(height: NetLearnSpace.s12),
        body,
      ],
    );
  }

  Widget _buildRecentActivities(
    BuildContext context,
    LecturerDashboardStats stats,
  ) {
    final l10n = AppLocalizations.of(context)!;

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
                l10n.noNotifications,
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NetLearnSpace.s10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.accentTint,
              borderRadius: BorderRadius.circular(NetLearnRadius.sm),
            ),
            child: Icon(activity.icon, size: 18, color: context.accent),
          ),
          const SizedBox(width: NetLearnSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? NetLearnColors.darkSurface : NetLearnColors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? NetLearnColors.darkLine : NetLearnColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? NetLearnColors.darkMuted : NetLearnColors.muted,
        ),
      ),
    );
  }
}
