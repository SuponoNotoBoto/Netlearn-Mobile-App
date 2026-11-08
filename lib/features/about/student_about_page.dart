import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_topbar.dart';
import '../../shared/widgets/student_bottom_navbar.dart';
import 'about_netlearn_content.dart';

/// Halaman "About NetLearn" mahasiswa (revisi Figma Make "About Application").
///
/// Seluruh isi halaman (kartu identitas, fitur utama, tiga kartu unduhan)
/// hidup di [AboutNetLearnContent] yang dipakai bersama dengan halaman dosen —
/// kontennya tidak digandakan. Yang berbeda di sini hanya bar atas, bar
/// navigasi bawah mahasiswa, tombol lonceng di kanan bar, dan tidak ada
/// tombol "Back to Dashboard" terpisah di tubuh: bar atas sudah menyediakan
/// jalur pulang satu ketukan, dan revisi desain merapatkan halaman tanpa
/// tombol itu.
class StudentAboutPage extends StatelessWidget {
  const StudentAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.background,
      // `appBar` (bukan anak `Column`) karena `NlTopBar` membungkus `AppBar`.
      appBar: NlTopBar(
        title: l10n.aboutNetLearn,
        onBack: () => goBack(context, fallback: '/student'),
        actions: IconButton(
          onPressed: () => context.push('/student/notifications'),
          tooltip: l10n.notificationsTitle,
          padding: const EdgeInsets.all(NetLearnSpace.s7),
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.notifications_none_rounded, size: 19),
        ),
      ),
      // Frame About menandai tab Dashboard sebagai tab aktif: halaman ini
      // bercabang dari dashboard, bukan salah satu dari lima tab.
      bottomNavigationBar: const StudentBottomNavbar(currentIndex: 0),
      body: const AboutNetLearnContent(),
    );
  }
}
