import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_error_view.dart';
import 'lecturer_dashboard_controller.dart';

class LecturerSecurityPage extends ConsumerWidget {
  const LecturerSecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final profile = ref.watch(lecturerProfileProvider);

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFECEEF2)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.securityAndPassword,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            // Same destination as the dashboard bell. It used to be an empty
            // callback, which made the icon look live and do nothing.
            onPressed: () => context.push('/lecturer/notifications'),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => NlErrorView(
          message: l10n.failedToLoad,
          onRetry: () => ref.invalidate(lecturerProfileProvider),
        ),
        data: (data) {
          if (data == null) {
            return NlErrorView(message: l10n.profileNotFound);
          }

          final isActive = data.isActive;

          return RefreshIndicator(
            color: context.accent,
            onRefresh: () async {
              ref.invalidate(lecturerProfileProvider);
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
                // Card 1: Account info (Figma 51:472)
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
                      Text(
                        l10n.accountEmail,
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1D26),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1D26),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.accountStatus,
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1D26),
                        ),
                      ),
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

                // Card 2: Password actions (Figma 51:472)
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
                            context.push('/lecturer/security/change-password'),
                      ),
                      Divider(height: 1, color: context.border),
                      _SecurityActionRow(
                        icon: Icons.mail_outline_rounded,
                        title: l10n.forgotPassword,
                        subtitle: l10n.forgotPasswordHint,
                        onTap: () => context.push('/lecturer/forgot-password'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Footer note
                // The generic `passwordDemoNote` claims password changes never
                // touch an authentication service, which stopped being true for
                // this screen the moment Forgot Password started sending a real
                // Supabase recovery code.
                Text(
                  l10n.securityFooterNote,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontSize: 9, color: const Color(0xFF6C727F)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Navigation row untuk card Password actions (Figma 51:472).
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
                        color: const Color(0xFF1A1D26),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: const Color(0xFF6C727F),
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
