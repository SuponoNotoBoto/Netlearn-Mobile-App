import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/academic_info.dart';
import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_profile_section.dart';
import '../../shared/widgets/nl_skeleton.dart';
import '../../shared/widgets/nl_topbar.dart';
import '../../shared/widgets/status_badge.dart';
import 'student_profile_controller.dart';

/// Academic Information view for the student, mirroring the lecturer's
/// `/lecturer/academic` page but reading [studentProfileProvider].
///
/// Four rows in a fixed order: NIM, Department, Study Program, Account Status.
/// The `profiles` row carries no semester, so the page no longer implies one.
/// NIM is real data (empty renders "-"); Department and Study Program are
/// proper nouns kept in English regardless of the selected language, and the
/// status is the [StatusBadge] used everywhere else instead of plain text.
class StudentAcademicInfoPage extends ConsumerWidget {
  const StudentAcademicInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final profile = ref.watch(studentProfileProvider);

    return Scaffold(
      backgroundColor: context.background,
      appBar: NlTopBar(
        title: l10n.academicInfo,
        onBack: () => goBack(context),
      ),
      body: profile.when(
        loading: () => const NlSkeletonList(
          itemCount: 4,
          padding: EdgeInsets.all(NetLearnSpace.s20),
        ),
        error: (error, stackTrace) => NlErrorView(
          message: l10n.failedToLoad,
          onRetry: () => ref.invalidate(studentProfileProvider),
        ),
        data: (data) {
          if (data == null) {
            return NlErrorView(message: l10n.profileNotFound);
          }

          final identityNumber =
              data['identity_number']?.toString().trim().isNotEmpty == true
                  ? data['identity_number'].toString()
                  : '-';
          final isActive = data['is_active'] == true;
          final statusLabel = isActive ? 'Active' : 'Inactive';

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
                NlProfileSection(
                  title: l10n.academicInfo.toUpperCase(),
                  children: [
                    NlProfileRow(
                      icon: Icons.badge_outlined,
                      label: l10n.identityNumber,
                      value: identityNumber,
                    ),
                    NlProfileRow(
                      icon: Icons.account_balance_outlined,
                      label: l10n.department,
                      value: kDepartmentName,
                    ),
                    NlProfileRow(
                      icon: Icons.school_outlined,
                      label: l10n.studyProgram,
                      value: kStudyProgramName,
                    ),
                    NlProfileRow(
                      icon: Icons.verified_user_outlined,
                      label: l10n.accountStatus,
                      value: statusLabel,
                      valueWidget: StatusBadge(
                        status: isActive
                            ? NetLearnStatus.linked
                            : NetLearnStatus.down,
                        label: statusLabel,
                      ),
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