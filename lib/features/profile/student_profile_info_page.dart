import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_profile_section.dart';
import '../../shared/widgets/nl_topbar.dart';
import 'student_profile_controller.dart';

/// Profile Information view for the student, mirroring the lecturer's
/// `/lecturer/profile-info` page but reading [studentProfileProvider].
///
/// Read-only on purpose: name, identity number and email belong to the account
/// the admin manages, so the page only reports the current row.
class StudentProfileInfoPage extends ConsumerWidget {
  const StudentProfileInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final profile = ref.watch(studentProfileProvider);

    return Scaffold(
      backgroundColor: context.background,
      appBar: NlTopBar(
        title: l10n.profileInfo,
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

          final name = data['name']?.toString().trim().isNotEmpty == true
              ? data['name'].toString()
              : l10n.student;
          final identityNumber =
              data['identity_number']?.toString().trim().isNotEmpty == true
                  ? data['identity_number'].toString()
                  : '-';

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
                  title: l10n.profileInfo.toUpperCase(),
                  children: [
                    NlProfileRow(
                      icon: Icons.badge_outlined,
                      label: l10n.fullName,
                      value: name,
                    ),
                    NlProfileRow(
                      icon: Icons.email_outlined,
                      label: l10n.email,
                      value: data['email']?.toString() ?? '-',
                    ),
                    NlProfileRow(
                      icon: Icons.credit_card_outlined,
                      label: l10n.identityNumber,
                      value: identityNumber,
                    ),
                    NlProfileRow(
                      icon: Icons.person_outline_rounded,
                      label: l10n.role,
                      value: l10n.student,
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