import 'package:flutter/material.dart';

import '../about/about_netlearn_content.dart';
import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_topbar.dart';
import 'lecturer_bottom_navbar.dart';

/// Halaman "About NetLearn" dosen (revisi Figma Make "About Application").
///
/// Mirror halaman mahasiswa tapi memakai [LecturerBottomNavbar], bar atas
/// tanpa lonceng, dan fallback tujuan dosen. Isi halamannya satu dan sama
/// dengan halaman mahasiswa ([AboutNetLearnContent]).
class LecturerAboutPage extends StatelessWidget {
  const LecturerAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.background,
      appBar: NlTopBar(
        title: l10n.aboutNetLearn,
        onBack: () => goBack(context, fallback: '/lecturer'),
      ),
      bottomNavigationBar: const LecturerBottomNavbar(currentIndex: 0),
      body: const AboutNetLearnContent(),
    );
  }
}
