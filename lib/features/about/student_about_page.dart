import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_topbar.dart';
import '../../shared/widgets/student_bottom_navbar.dart';
import '../dashboard_student/student_walkthrough.dart';
import 'about_netlearn_content.dart';

/// Halaman "About NetLearn" mahasiswa (revisi Figma Make "About Application").
class StudentAboutPage extends ConsumerWidget {
  const StudentAboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isId = Localizations.localeOf(context).languageCode == 'id';

    return Scaffold(
      backgroundColor: context.background,
      appBar: NlTopBar(
        title: l10n.aboutNetLearn,
        onBack: () => goBack(context, fallback: '/student'),
        actions: IconButton(
          key: const Key('student_about_walkthrough_btn'),
          icon: const Icon(Icons.tips_and_updates_outlined),
          tooltip: isId ? 'Panduan Aplikasi' : 'App Guide',
          onPressed: () => StudentWalkthroughManager.instance.start(context, ref),
        ),
      ),
      bottomNavigationBar: const StudentBottomNavbar(currentIndex: 0),
      body: const AboutNetLearnContent(),
    );
  }
}
