import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_topbar.dart';
import 'student_profile_controller.dart';

/// Security & Password mahasiswa — struktur yang disamakan dengan halaman
/// dosen ([LecturerSecurityPage], Figma 51:472): kartu informasi akun,
/// kartu dua aksi kata sandi, dan catatan keamanan di kaki halaman.
///
/// Dua jalur pengubahan kata sandi:
/// - `Change Password` → `/student/security/change-password` (form yang
///   sama dengan dosen); pengerjaannya masih placeholder demo di kedua role.
/// - `Forgot password?` → `/student/forgot-password` — satu halaman recovery
///   Supabase yang sama ([ForgotPasswordPage]); dosen memakai cabang
///   `/lecturer/forgot-password` dengan alasan yang sama (guard auth).
class StudentSecurityPage extends ConsumerWidget {
  const StudentSecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final profile = ref.watch(studentProfileProvider);

    return Scaffold(
      backgroundColor: context.background,
      appBar: NlTopBar(
        title: l10n.securityAndPassword,
        onBack: () => goBack(context),
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => NlErrorView(
          message: l10n.failedToLoad,
          onRetry: () => ref.invalidate(studentProfileProvider),
        ),
        data: (data) {
          if (data == null) {
            return NlErrorView(message: l10n.profileNotFound);
          }

          // Status asli dari `profiles.is_active` — kunjungan ke halaman ini
          // tidak pernah membentuk "Active" yang tidak didukung data.
          final isActive = data['is_active'] == true;

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
                // Kartu 1: Informasi Akun (Figma 51:472). Data sama dengan
                // kartu dosen; halaman ini sama sekali tidak menampilkan
                // password atau token.
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardLabel(text: l10n.accountEmail),
                      const SizedBox(height: 4),
                      Text(
                        data['email']?.toString() ?? '-',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CardLabel(text: l10n.accountStatus),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          // Badge dosen memakai warna hijau tetap; statusnya
                          // tetap mengikuti data, hanya teks yang berubah.
                          isActive ? l10n.active : l10n.inactive,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Kartu 2: aksi kata sandi (Figma 51:472) — baris yang sama
                // dengan yang dosen munculkan di halamannya.
                Container(
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    children: [
                      _SecurityActionRow(
                        icon: Icons.lock_outline_rounded,
                        title: l10n.changePassword,
                        subtitle: l10n.changePasswordHint,
                        onTap: () =>
                            context.push('/student/security/change-password'),
                      ),
                      Divider(height: 1, color: context.border),
                      _SecurityActionRow(
                        icon: Icons.mail_outline_rounded,
                        title: l10n.forgotPassword,
                        subtitle: l10n.forgotPasswordHint,
                        // Mahasiswa harus lewat cabang di bawah /student,
                        // bukan `/forgot-password` yang dibatasi auth guard
                        // login — pola yang persis sama dengan cabang dosen.
                        onTap: () => context.push('/student/forgot-password'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Catatan kaki, sama seperti dosen.
                Text(
                  l10n.securityFooterNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    color: context.mutedText,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Label kecil di dalam kartu akun (Figma 51:472).
class _CardLabel extends StatelessWidget {
  final String text;

  const _CardLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: context.onSurface,
      ),
    );
  }
}

/// Navigation row untuk kartu Password actions (Figma 51:472), metiknya
/// sama dengan baris yang dosen munculkan di halamannya.
class _SecurityActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SecurityActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.accentTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: context.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: context.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: context.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
