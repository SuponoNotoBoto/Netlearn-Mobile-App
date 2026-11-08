import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_profile_section.dart';
import 'lecturer_dashboard_controller.dart';

class LecturerProfileInfoPage extends ConsumerWidget {
  const LecturerProfileInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final profile = ref.watch(lecturerProfileProvider);

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.profileInfo,
          style: Theme.of(context).textTheme.titleLarge,
        ),
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

          final nip = data.identityNumber.isEmpty ? '-' : data.identityNumber;

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
                NlProfileSection(
                  title: l10n.profileInfo.toUpperCase(),
                  children: [
                    NlProfileRow(
                      icon: Icons.badge_outlined,
                      label: l10n.fullName,
                      value: data.name,
                    ),
                    NlProfileRow(
                      icon: Icons.email_outlined,
                      label: l10n.email,
                      value: data.email,
                    ),
                    NlProfileRow(
                      icon: Icons.verified_user_outlined,
                      label: l10n.nip,
                      value: nip,
                    ),
                    NlProfileRow(
                      icon: Icons.person_outline_rounded,
                      label: l10n.role,
                      value: l10n.roleLecturer,
                    ),
                  ],
                ),

                const SizedBox(height: NetLearnSpace.s24),

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
    );
  }
}