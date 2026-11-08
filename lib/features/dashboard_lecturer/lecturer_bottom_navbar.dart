import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_bottom_nav_bar.dart';

/// Navigasi dosen: Dashboard, Materi, AR Scanner, Assessment, Profil.
///
/// Tampilan bar ini sepenuhnya milik [NlBottomNavBar], yang juga dipakai
/// `StudentBottomNavbar` supaya kedua bar benar-benar identik secara visual --
/// ikon, perlakuan tombol tengah yang terangkat, titik indikator aktif, dan
/// warna tidak aktif semuanya berasal dari satu tempat. Yang berbeda hanya
/// tujuan `context.go()`-nya.
///
/// PRD §15 juga menyebut tab "Mahasiswa". Tab itu masih hilang dengan sengaja:
/// isinya akan dibaca dari `classes` dan `enrollments`, dan dosen belum bisa
/// membaca kedua tabel itu sebelum data kelas ada. Menambahkan tab yang selalu
/// kosong lebih buruk daripada tidak memilikinya.
class LecturerBottomNavbar extends StatelessWidget {
  final int currentIndex;

  const LecturerBottomNavbar({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/lecturer');
        break;

      case 1:
        context.go('/lecturer/materials');
        break;

      case 2:
        context.go('/lecturer/ar');
        break;

      case 3:
        context.go('/lecturer/assessments');
        break;

      case 4:
        context.go('/lecturer/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return NlBottomNavBar(
      currentIndex: currentIndex,
      onSelect: (index) => _onItemTapped(context, index),
      destinations: [
        NlNavDestination(
          label: l10n.dashboard,
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
        ),
        NlNavDestination(
          label: l10n.materials,
          icon: Icons.menu_book_outlined,
          activeIcon: Icons.menu_book_rounded,
        ),
        NlNavDestination(
          label: l10n.arScanner,
          icon: Icons.view_in_ar_rounded,
          activeIcon: Icons.view_in_ar_rounded,
          isCenter: true,
        ),
        NlNavDestination(
          label: l10n.assessment,
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment_rounded,
        ),
        NlNavDestination(
          label: l10n.profile,
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
        ),
      ],
    );
  }
}
