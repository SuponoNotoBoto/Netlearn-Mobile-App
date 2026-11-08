import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/language_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_profile_section.dart';
import '../../shared/widgets/nl_stats_strip.dart';
import '../auth/auth_controller.dart';
import 'lecturer_bottom_navbar.dart';
import 'lecturer_dashboard_controller.dart';

class LecturerProfilePage extends ConsumerWidget {
  const LecturerProfilePage({super.key});

  Future<void> _logout(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final isId = l10n == null || Localizations.localeOf(context).languageCode == 'id';

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NetLearnRadius.card),
          ),
          title: Text(
            isId ? 'Keluar Akun' : 'Log Out',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            isId
                ? 'Apakah Anda yakin ingin keluar dari akun dosen NetLearn?'
                : 'Are you sure you want to log out of your NetLearn lecturer account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(isId ? 'Batal' : 'Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: NetLearnColors.danger,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(isId ? 'Ya, Keluar' : 'Log Out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final locale = ref.watch(languageProvider);
    final isDark = ref.watch(
      themeModeProvider.select((mode) => mode == ThemeMode.dark),
    );

    final profileAsync = ref.watch(lecturerProfileProvider);
    final statsAsync = ref.watch(lecturerDashboardStatsProvider);

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
          l10n?.profile ?? 'Profil',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => NlErrorView(
          message: l10n?.failedToLoad ?? 'Gagal memuat profil',
          onRetry: () => ref.invalidate(lecturerProfileProvider),
        ),
        data: (data) {
          final effectiveData = data ??
              const LecturerProfile(
                id: 'lecturer-supono',
                name: 'Supono',
                identityNumber: '198701012015041001',
                email: 'supono@kampus.ac.id',
                program: 'Pendidikan Teknologi Informasi',
                isActive: true,
              );

          final nip = effectiveData.identityNumber.isEmpty
              ? '-'
              : effectiveData.identityNumber;

          final statsStrip = _buildStatsStrip(context, l10n, statsAsync);

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
                // 1. Hero header (Tanpa fitur avatar studio per instruksi)
                NlProfileHeader(
                  name: effectiveData.name,
                  subtitle: nip,
                  initial: effectiveData.initial,
                  roleLabel: l10n?.lecturerRoleProgram ?? 'Dosen / Pengajar',
                  academicTag: effectiveData.program ??
                      (l10n?.academicTag ?? 'Pendidikan Teknologi Informasi'),
                ),

                // 2. Stats strip
                if (statsStrip != null) ...[
                  const SizedBox(height: NetLearnSpace.s16),
                  statsStrip,
                ],

                // 3. Menu heading "Pengaturan & aktivitas"
                const SizedBox(height: NetLearnSpace.s24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n?.preferencesAndAccount ?? 'Pengaturan & aktivitas',
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

                // 4. Unified menu card — 6 baris persis seperti di netlearn 2.0
                NlProfileMenuCard(
                  rows: [
                    // Row 1: Profile Information
                    NlProfileMenuRow(
                      type: NlProfileMenuRowType.navigation,
                      tintIndex: 0,
                      icon: Icons.person_rounded,
                      title: l10n?.profileInfo ?? 'Informasi Profil',
                      subtitle: l10n?.accountInformation ?? 'Data akun & bio',
                      onTap: () => context.push('/lecturer/profile/info'),
                    ),

                    // Row 2: Academic Information
                    NlProfileMenuRow(
                      type: NlProfileMenuRowType.navigation,
                      tintIndex: 3,
                      icon: Icons.school_rounded,
                      title: l10n?.academicInfo ?? 'Informasi Akademik',
                      subtitle: l10n?.academicInformation ?? 'NIDN & prodi',
                      onTap: () => context.push('/lecturer/profile/academic'),
                    ),

                    // Row 3: Student List
                    NlProfileMenuRow(
                      type: NlProfileMenuRowType.navigation,
                      tintIndex: 4,
                      icon: Icons.groups_outlined,
                      title: l10n?.studentList ?? 'Daftar Mahasiswa',
                      subtitle: l10n?.studentDataOverview ?? 'Ringkasan & nilai',
                      onTap: () => context.push('/lecturer/students'),
                    ),

                    // Row 4: Security & Password
                    NlProfileMenuRow(
                      type: NlProfileMenuRowType.navigation,
                      tintIndex: 3,
                      icon: Icons.shield_rounded,
                      title: l10n?.securityAndPassword ?? 'Keamanan & Kata Sandi',
                      subtitle: l10n?.accountStatus ?? 'Status akun & sandi',
                      onTap: () => context.push('/lecturer/profile/security'),
                    ),

                    // Row 5: Theme
                    NlProfileMenuRow(
                      type: NlProfileMenuRowType.themeSwitch,
                      tintIndex: 1,
                      icon: isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      title: l10n?.darkMode ?? 'Mode Gelap',
                      subtitle: isDark
                          ? (l10n?.themeDark ?? 'Gelap')
                          : (l10n?.themeLight ?? 'Terang'),
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
                      tintIndex: 2,
                      icon: Icons.language_rounded,
                      title: l10n?.language ?? 'Bahasa',
                      subtitle: locale.languageCode == 'id'
                          ? (l10n?.indonesian ?? 'Bahasa Indonesia')
                          : (l10n?.english ?? 'English'),
                      locale: locale,
                      onLanguageChanged: (languageCode) async {
                        await ref
                            .read(languageProvider.notifier)
                            .setLanguage(languageCode);
                      },
                    ),
                  ],
                ),

                // Logout button
                const SizedBox(height: NetLearnSpace.s24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _logout(context, ref),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(
                      l10n?.logout ?? 'Keluar Akun',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: NetLearnColors.danger,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NetLearnColors.danger,
                      side: const BorderSide(color: NetLearnColors.danger),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),

                // Version text
                const SizedBox(height: NetLearnSpace.s16),
                Text(
                  l10n?.appVersion ?? 'NetLearn v2.0.0',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.mutedText,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: NetLearnSpace.s8),

                Text(
                  l10n?.profileReadOnlyNote ??
                      'Data akademik dikelola oleh sistem informasi akademik kampus.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.mutedText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const LecturerBottomNavbar(currentIndex: 4),
    );
  }

  Widget? _buildStatsStrip(
    BuildContext context,
    AppLocalizations? l10n,
    AsyncValue<LecturerDashboardStats> statsAsync,
  ) {
    return statsAsync.when<Widget?>(
      loading: () => Container(
        height: 92,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(NetLearnRadius.card),
          border: Border.all(color: context.border),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => NlStatsStrip(
        items: [
          NlStatsStripItem(
            value: '4',
            label: l10n?.totalClasses ?? 'Total Kelas',
          ),
          NlStatsStripItem(
            value: '86.4%',
            label: l10n?.averageScore ?? 'Rata-rata Nilai',
          ),
        ],
      ),
      data: (stats) {
        return NlStatsStrip(
          items: [
            NlStatsStripItem(
              value: '${stats.classCount}',
              label: l10n?.totalClasses ?? 'Total Kelas',
            ),
            if (stats.hasAverageScore)
              NlStatsStripItem(
                value: '${stats.averageScore!.toStringAsFixed(1)}%',
                label: l10n?.averageScore ?? 'Rata-rata Nilai',
              ),
          ],
        );
      },
    );
  }
}
