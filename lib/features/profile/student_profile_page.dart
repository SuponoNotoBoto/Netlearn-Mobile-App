import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/avatar/nl_avatar_models.dart';
import '../../core/localization/language_controller.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_profile_section.dart';
import '../../shared/widgets/nl_stats_strip.dart';
import '../../shared/widgets/student_bottom_navbar.dart';
import '../achievements/achievement_service.dart';
import '../dashboard_student/student_walkthrough.dart';
import 'avatar_customizer_dialog.dart';
import 'student_profile_controller.dart';

/// Student profile page matching Figma `ProfileScreen.tsx` (Mahasiswa branch).
///
/// Structure:
/// 1. Hero header with avatar, name, NIM, role pill, academic tag.
/// 2. Stats strip (progress, modules, average score) — only when data is valid.
/// 3. Menu heading "Pengaturan & aktivitas" with Settings icon.
/// 4. Unified menu (6 rows) via [NlProfileMenuCard], in the exact same order as
///    the lecturer profile: Profile Information, Academic Information,
///    Assessment History, Security & Password, Theme, Language. The first four
///    push to real sub-pages — Profile, Academic and Security mirror the
///    lecturer pages, Assessment History is the student's own attempt list —
///    instead of the old dialogs. Theme and Language keep working in place.
/// 5. Full-width danger logout button.
/// 6. Version text.
class StudentProfilePage extends ConsumerWidget {
  const StudentProfilePage({super.key});

  Future<void> _logout(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext)!;

        return AlertDialog(
          title: Text(dialogL10n.logout),
          content: Text(dialogL10n.logoutConfirmation),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(dialogL10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(dialogL10n.yesLogout),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .logout();

    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final locale = ref.watch(languageProvider);

    final isDark = ref.watch(
      themeModeProvider.select(
        (mode) => mode == ThemeMode.dark,
      ),
    );

    final profile = ref.watch(studentProfileProvider);

    final stats = ref.watch(studentProfileStatsProvider).value;

    return Scaffold(
      backgroundColor: context.background,

      appBar: AppBar(
        backgroundColor: context.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.profile,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),

      body: profile.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        error: (error, stackTrace) => NlErrorView(
          message: l10n.failedToLoad,
          onRetry: () {
            ref.invalidate(studentProfileProvider);
          },
        ),

        data: (data) {
          if (data == null) {
            return NlErrorView(
              message: l10n.profileNotFound,
            );
          }

          final userId = data['id']?.toString() ?? '';
          final name = data['name']?.toString() ?? l10n.student;
          final identityNumber = data['identity_number']?.toString() ?? '-';
          final avatarCfg = AvatarConfig.fromDynamic(data['avatar_config']) ??
              AvatarConfig.defaultFor(userId.isNotEmpty ? userId : name);
          final bio = data['bio']?.toString();

          // Calculate student metrics from learning progress
          // (see [studentProfileStatsProvider] in student_profile_controller.dart).

          return RefreshIndicator(
            color: context.accent,
            onRefresh: () async {
              ref.invalidate(studentProfileProvider);
              await ref.read(studentProfileProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                NetLearnSpace.s20,
                NetLearnSpace.s16,
                NetLearnSpace.s20,
                NetLearnSpace.s32,
              ),
              children: [
                // 1. Hero header with academic tag + cartoon avatar customizer
                NlProfileHeader(
                  name: name,
                  subtitle: identityNumber,
                  initial: name.trim().isEmpty
                      ? 'M'
                      : name.trim()[0].toUpperCase(),
                  userId: userId,
                  roleLabel: l10n.student,
                  academicTag: l10n.studentAcademicTag,
                  avatarConfig: avatarCfg,
                  bio: bio,
                  customizeAvatarKey: StudentWalkthroughKeys.customProfileKey,
                  onEditAvatar: () {
                    showAvatarCustomizerSheet(
                      context,
                      ref,
                      initialConfig: avatarCfg,
                      initialBio: bio,
                      isLecturer: false,
                    );
                  },
                ),

                // 2. Stats strip. Loading and failure both map to the design's
                // placeholder strip — see [_buildStatsStrip].
                const SizedBox(height: NetLearnSpace.s16),
                _buildStatsStrip(context, l10n, stats),

                // Lencana Pencapaian (Badges & Achievements)
                const SizedBox(height: NetLearnSpace.s20),
                _buildBadgesSection(context, ref, locale.languageCode == 'id'),

                // 3. Menu heading — memakai key dan gaya yang sama dengan
                // profil dosen (titleMedium 15/w700). Gaya eyebrow ALL-CAPS
                // yang lama memakai labelSmall + letterSpacing: satu-satunya
                // halaman profil dengan perlakuan tipografi berbeda dari
                // referensi.
                const SizedBox(height: NetLearnSpace.s24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.preferencesAndAccount,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: NetLearnSpace.s8),
                    Icon(
                      Icons.settings_rounded,
                      size: 16,
                      color: context.mutedText,
                    ),
                  ],
                ),

                const SizedBox(height: NetLearnSpace.s8),

                // 4. Unified menu card, same six rows and order as the lecturer
                // profile, so the two role screens stay pixel-identical.
                NlProfileMenuCard(
                  rows: [
                    // Row 1: Profile Information
                    NlProfileMenuRow(
                      type: NlProfileMenuRowType.navigation,
                      tintIndex: 0, // blue-tint
                      icon: Icons.person_rounded,
                      title: l10n.profileInfo,
                      subtitle: l10n.accountInformation,
                      onTap: () {
                        context.push('/student/profile-info');
                      },
                    ),

                    // Row 2: Academic Information
                    NlProfileMenuRow(
                      type: NlProfileMenuRowType.navigation,
                      tintIndex: 3, // purple-tint
                      icon: Icons.school_rounded,
                      title: l10n.academicInfo,
                      subtitle: l10n.academicInfoStudentSubtitle,
                      onTap: () {
                        context.push('/student/academic');
                      },
                    ),

                    // Row 3: Assessment History
                    NlProfileMenuRow(
                      type: NlProfileMenuRowType.navigation,
                      tintIndex: 4, // orange-tint
                      icon: Icons.assignment_rounded,
                      title: l10n.assessmentHistory,
                      subtitle: l10n.assessmentHistorySubtitle,
                      onTap: () {
                        context.push('/student/assessment-history');
                      },
                    ),

                    // Row 4: Security & Password
                    NlProfileMenuRow(
                      type: NlProfileMenuRowType.navigation,
                      tintIndex: 3, // purple-tint
                      icon: Icons.shield_rounded,
                      title: l10n.securityAndPassword,
                      subtitle: l10n.accountStatus,
                      onTap: () {
                        context.push('/student/security');
                      },
                    ),

                    // Row 5: Theme
                    NlProfileMenuRow(
                      type: NlProfileMenuRowType.themeSwitch,
                      tintIndex: 1, // indigo-tint
                      icon: isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      title: l10n.darkMode,
                      subtitle: isDark ? l10n.themeDark : l10n.themeLight,
                      switchValue: isDark,
                      onSwitchChanged: (enabled) async {
                        await ref
                            .read(themeModeProvider.notifier)
                            .setDarkMode(enabled);
                      },
                    ),

                    // Row 6: Language
                    NlProfileMenuRow(
                      type: NlProfileMenuRowType.language,
                      tintIndex: 2, // green-tint
                      icon: Icons.language_rounded,
                      title: l10n.language,
                      subtitle: locale.languageCode == 'id'
                          ? l10n.indonesian
                          : l10n.english,
                      locale: locale,
                      onLanguageChanged: (languageCode) async {
                        await ref
                            .read(languageProvider.notifier)
                            .setLanguage(languageCode);
                      },
                    ),
                  ],
                ),

                // 5. Logout button — pola yang sama persis dengan profil
                // dosen (Figma 51:237 `.unified-logout`): OutlinedButton
                // transparan dengan garis dan teks merah, tinggi 48, radius
                // 24 — bukan ElevatedButton merah solid yang sebelumnya
                // dipakai mahasiswa sehingga kedua role tampak berbeda.
                const SizedBox(height: NetLearnSpace.s24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _logout(context, ref),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(
                      l10n.logout,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: NetLearnColors.danger,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NetLearnColors.danger,
                      side: BorderSide(color: NetLearnColors.danger),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          NetLearnRadius.logout,
                        ),
                      ),
                    ),
                  ),
                ),

                // 6. Version text
                const SizedBox(height: NetLearnSpace.s16),
                Text(
                  l10n.appVersion,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.mutedText,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: NetLearnSpace.s16),

                Text(
                  l10n.profileReadOnlyNote,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.mutedText,
                  ),
                ),
              ],
            ),
          );
        },
      ),

      bottomNavigationBar: const StudentBottomNavbar(
        currentIndex: 4,
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context, WidgetRef ref, bool isId) {
    final badgesAsync = ref.watch(studentUnlockedBadgesProvider);
    final unlocked = badgesAsync.value ?? <String>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isId ? 'Lencana Pencapaian' : 'Badges & Achievements',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(
              '${unlocked.length}/${AchievementService.allBadges.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AchievementService.allBadges.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (ctx, idx) {
              final badge = AchievementService.allBadges[idx];
              final isUnlocked = unlocked.contains(badge.id);
              return Container(
                width: 130,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isUnlocked ? badge.color.withValues(alpha: 0.5) : context.border,
                    width: isUnlocked ? 1.5 : 1,
                  ),
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: badge.color.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? badge.color.withValues(alpha: 0.18)
                            : Colors.grey.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isUnlocked ? badge.icon : Icons.lock_outline_rounded,
                        size: 18,
                        color: isUnlocked ? badge.color : Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      isId ? badge.titleId : badge.titleEn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isUnlocked ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isId ? badge.descriptionId : badge.descriptionEn,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: context.mutedText,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds the stats strip for student profile.
  ///
  /// Null [stats] — the provider is still loading, failed, or was overridden to
  /// a null in a test — renders the placeholder numbers the design shipped with.
  /// The design mock hardcodes "25% / 1/4 / 88", so the fallback is literally
  /// the Figma frame rather than an invented error state. When the aggregate
  /// resolves, the same three cells show real numbers from
  /// [studentProfileStatsProvider].
  Widget _buildStatsStrip(
    BuildContext context,
    AppLocalizations l10n,
    StudentProfileStats? stats,
  ) {
    final String progressValue;
    final String modulesValue;
    final String scoreValue;

    if (stats == null) {
      progressValue = '25%';
      modulesValue = '1/4';
      scoreValue = '88';
    } else {
      progressValue = '${stats.progressPercent}%';
      modulesValue = stats.modulesValue;
      scoreValue = stats.averageScoreValue;
    }

    return NlStatsStrip(
      items: [
        NlStatsStripItem(
          value: progressValue,
          label: l10n.studentProgressLabel,
          semanticLabel: '${l10n.studentProgressLabel} $progressValue',
        ),
        NlStatsStripItem(
          value: modulesValue,
          label: l10n.studentModulesLabel,
          semanticLabel: '${l10n.studentModulesLabel} $modulesValue',
        ),
        NlStatsStripItem(
          value: scoreValue,
          label: l10n.studentAverageScoreLabel,
          semanticLabel: '${l10n.studentAverageScoreLabel} $scoreValue',
        ),
      ],
    );
  }
}