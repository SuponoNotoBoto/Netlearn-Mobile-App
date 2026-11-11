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
import '../profile/avatar_customizer_dialog.dart';
import 'lecturer_bottom_navbar.dart';
import 'lecturer_dashboard_controller.dart';
import '../classes/class_controller.dart';
import '../classes/class_models.dart';
import '../classes/lecturer_manage_class_section.dart';

/// Lecturer profile page matching Figma `ProfileScreen.tsx` (Dosen branch).
///
/// Structure:
/// 1. Hero header with avatar, name, NIP, role pill, academic tag.
/// 2. Stats strip (classes, average score) — only when data is valid.
/// 3. Menu heading "Pengaturan & aktivitas" with Settings icon.
/// 4. Unified menu (6 rows) via [NlProfileMenuCard], in the exact same order as
///    the student profile: Profile Information, Academic Information,
///    Assessment History, Security & Password, Theme, Language. Each row pushes
///    to its own lecturer sub-page.
/// 5. Full-width danger logout button.
/// 6. Version text.
class LecturerProfilePage extends ConsumerWidget {
  const LecturerProfilePage({super.key});

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

    final profile = ref.watch(lecturerProfileProvider);

    final statsAsync = ref.watch(lecturerDashboardStatsProvider);
    final activeClass = ref.watch(activeLecturerClassProvider).value;
    final classes = ref.watch(lecturerClassesProvider).value;

    return Scaffold(
      backgroundColor: context.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFECEEF2),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
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
            ref.invalidate(lecturerProfileProvider);
          },
        ),

        data: (data) {
          if (data == null) {
            return NlErrorView(
              message: l10n.profileNotFound,
            );
          }

          final nip = data.identityNumber.isEmpty ? '-' : data.identityNumber;

          final statsStrip = _statsStrip(
            context,
            l10n,
            statsAsync,
            activeClass,
          );

          return RefreshIndicator(
            color: context.accent,
            onRefresh: () async {
              ref.invalidate(lecturerProfileProvider);
              ref.invalidate(lecturerDashboardStatsProvider);
              await ref.read(lecturerProfileProvider.future);
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
                  name: data.name,
                  subtitle: nip,
                  initial: data.initial,
                  userId: data.id,
                  roleLabel: l10n.lecturerRoleProgram,
                  academicTag: (activeClass != null &&
                          activeClass.id.isNotEmpty &&
                          activeClass.id != kLegacyFallbackClassId)
                      ? '${activeClass.name}${activeClass.semester != null ? ' • ${activeClass.semester}' : ''}'
                      : l10n.academicTag,
                  avatarConfig: data.avatarConfig ??
                      AvatarConfig.defaultFor(data.id.isEmpty ? data.name : data.id),
                  bio: data.bio,
                  onEditAvatar: () {
                    showAvatarCustomizerSheet(
                      context,
                      ref,
                      initialConfig: data.avatarConfig ??
                          AvatarConfig.defaultFor(data.id.isEmpty ? data.name : data.id),
                      initialBio: data.bio,
                      isLecturer: true,
                    );
                  },
                ),

                if (classes != null &&
                    activeClass != null &&
                    activeClass.id != kLegacyFallbackClassId) ...[
                  const SizedBox(height: NetLearnSpace.s12),
                  LecturerActiveClassBar(
                    classes: classes,
                    activeClass: activeClass,
                  ),
                ],

                // 2. Stats strip (only when valid)
                if (statsStrip != null) ...[
                  const SizedBox(height: NetLearnSpace.s16),
                  statsStrip,
                ],

                // 3. Menu heading "Preferences & account"
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
                          color: const Color(0xFF1A1D26),
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

                // 4. Unified menu card, same six rows and order as the student
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
                      onTap: () => context.push('/lecturer/profile-info'),
                    ),

                    // Row 2: Academic Information
                    NlProfileMenuRow(
                      type: NlProfileMenuRowType.navigation,
                      tintIndex: 3,
                      icon: Icons.school_rounded,
                      title: l10n.academicInfo,
                      subtitle: l10n.academicInformation,
                      onTap: () => context.push('/lecturer/academic'),
                    ),

                    // Row 3: Student List
                    NlProfileMenuRow(
                      type: NlProfileMenuRowType.navigation,
                      tintIndex: 4,
                      icon: Icons.groups_outlined,
                      title: l10n.studentList,
                      subtitle: l10n.studentDataOverview,
                      onTap: () => context.push('/lecturer/students'),
                    ),

                    // Row 4: Security & Password
                    NlProfileMenuRow(
                      type: NlProfileMenuRowType.navigation,
                      tintIndex: 3, // purple-tint
                      icon: Icons.shield_rounded,
                      title: l10n.securityAndPassword,
                      subtitle: l10n.accountStatus,
                      onTap: () => context.push('/lecturer/security'),
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

                // Logout button (full-width, outline danger — Figma 51:237)
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
                        borderRadius: BorderRadius.circular(24),
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

      bottomNavigationBar: const LecturerBottomNavbar(
        currentIndex: 4,
      ),
    );
  }

  /// `.unified-stats` — ringkasan dua angka di bawah header identitas.
  ///
  /// Sumbernya `lecturer_dashboard()`, satu-satunya tempat yang bisa melihat
  /// lintas tabel, dan keduanya memang milik dosen ini:
  ///  * `classCount` — jumlah `classes` dengan `lecturer_id = auth.uid()`;
  ///  * `averageScore` — rata-rata skor percobaan terakhir tiap kuis milik
  ///    mahasiswa yang terdaftar di kelasnya. Bernilai `null` sampai ada
  ///    percobaan yang disubmit.
  ///
  /// Metrik "Materi Aktif" dari desain profil sengaja TIDAK dirender:
  /// `material_count` pada RPC itu `count(*) from public.materials` — angka
  /// global yang tidak di-scope ke dosen ini, dan tak ada kolom "aktif" untuk
  /// memfilter. Menampilkannya di profil seolah-olah milik dosen akan
  /// menyesatkan, jadi lebih baik ditunda sampai ada data per-dosen.
  ///
  /// `null` berarti tidak ada yang dirender: saat memuat, saat gagal, atau saat
  /// dosen belum punya kelas. Nol yang tidak dapat dipercaya tidak boleh tampil
  /// sebagai angka yang seolah valid.
  Widget? _statsStrip(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<LecturerDashboardStats> statsAsync, [
    LecturerClass? activeClass,
  ]
  ) {
    return statsAsync.when<Widget?>(
      loading: () => const _StatsStripSkeleton(),
      error: (error, stackTrace) => null,
      data: (stats) {
        final isClassScoped = activeClass != null &&
            activeClass.id.isNotEmpty &&
            activeClass.id != kLegacyFallbackClassId;

        if (isClassScoped) {
          return NlStatsStrip(
            items: [
              NlStatsStripItem(
                value: '${stats.totalStudents}',
                label: l10n.totalStudents,
                semanticLabel: '${l10n.totalStudents} ${stats.totalStudents}',
              ),
              NlStatsStripItem(
                value: '${stats.materialCount}',
                label: l10n.materials,
                semanticLabel: '${l10n.materials} ${stats.materialCount}',
              ),
              if (stats.hasAverageScore)
                NlStatsStripItem(
                  value: l10n.scorePercent(
                    stats.averageScore!.toStringAsFixed(1),
                  ),
                  label: l10n.averageScore,
                  semanticLabel:
                      '${l10n.averageScore} ${stats.averageScore!.toStringAsFixed(1)}%',
                ),
            ],
          );
        }

        if (!stats.hasClassContext) {
          return null;
        }

        return NlStatsStrip(
          items: [
            NlStatsStripItem(
              value: '${stats.classCount}',
              label: l10n.totalClasses,
            ),
            if (stats.hasAverageScore)
              NlStatsStripItem(
                value: l10n.scorePercent(
                  stats.averageScore!.toStringAsFixed(1),
                ),
                label: l10n.averageScore,
              ),
          ],
        );
      },
    );
  }
}

/// Placeholder setinggi [NlStatsStrip] selama angka dimuat, supaya Academic
/// Information di bawahnya tidak melompat saat data tiba.
class _StatsStripSkeleton extends StatelessWidget {
  const _StatsStripSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}