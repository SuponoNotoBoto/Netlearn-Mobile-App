import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_profile_section.dart';
import '../../shared/widgets/nl_skeleton.dart';
import 'lecturer_dashboard_controller.dart';

class LecturerAcademicInfoPage extends ConsumerWidget {
  const LecturerAcademicInfoPage({super.key});

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
          l10n.academicInfo,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: profile.when(
        loading: () => const NlSkeletonList(
          itemCount: 4,
          padding: EdgeInsets.all(NetLearnSpace.s20),
        ),
        error: (error, stackTrace) => NlErrorView(
          message: l10n.failedToLoad,
          onRetry: () => ref.invalidate(lecturerProfileProvider),
        ),
        data: (data) {
          if (data == null) {
            return NlErrorView(message: l10n.profileNotFound);
          }

          final nip = data.identityNumber.isEmpty ? '-' : data.identityNumber;
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
                NlProfileSection(
                  title: l10n.academicInfo.toUpperCase(),
                  children: [
                    NlProfileRow(
                      icon: Icons.badge_outlined,
                      label: l10n.nip,
                      value: nip,
                    ),
                    NlProfileRow(
                      icon: Icons.account_balance_outlined,
                      label: l10n.department,
                      value: l10n.informaticsEngineering,
                    ),
                    NlProfileRow(
                      icon: Icons.school_outlined,
                      label: l10n.studyProgram,
                      value: l10n.informationTechnologyEducation,
                    ),
                    NlProfileRow(
                      icon: Icons.verified_user_outlined,
                      label: l10n.accountStatus,
                      value: isActive ? l10n.active : l10n.inactive,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}