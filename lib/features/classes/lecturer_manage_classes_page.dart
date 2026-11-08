import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../dashboard_lecturer/lecturer_bottom_navbar.dart';
import 'class_controller.dart';
import 'lecturer_manage_class_section.dart';

/// Full dedicated page for managing lecturer classes (v7 Multi-Class LMS).
/// Replaces the section at the bottom of the Lecturer Dashboard.
class LecturerManageClassesPage extends ConsumerWidget {
  const LecturerManageClassesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.manageClassesTitle,
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(lecturerClassesProvider);
          await ref.read(lecturerClassesProvider.future);
        },
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            NetLearnSpace.s20,
            NetLearnSpace.s16,
            NetLearnSpace.s20,
            NetLearnSpace.s32,
          ),
          child: LecturerManageClassSection(
            showHeaderTitle: false,
          ),
        ),
      ),
      bottomNavigationBar: const LecturerBottomNavbar(currentIndex: 0),
    );
  }
}

