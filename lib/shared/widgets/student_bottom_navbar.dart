import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import 'nl_bottom_nav_bar.dart';

/// Navigasi mahasiswa: Dashboard, Materi, AR Scanner, Assessment, Profil.
///
/// Tampilan bar ini sepenuhnya milik [NlBottomNavBar]; kelas ini hanya memetakan
/// indeks slot ke `context.go()` di bawah `/student`. Lecturer punya bar sendiri
/// dengan tampilan yang sama persis dan tujuan yang berbeda, jadi keduanya
/// berbagi widget presentasi tetapi tidak pernah berbagi callback.
///
/// `context.go()` dipertahankan apa adanya: bar navigasi bawah mengganti stack,
/// bukan menumpuk halaman baru. Mengubahnya menjadi `push()` akan membuat
/// tombol Kembali menumpuk lima halaman.
class StudentBottomNavbar extends StatelessWidget {
  final int currentIndex;

  const StudentBottomNavbar({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/student');
        break;

      case 1:
        context.go('/student/materials');
        break;

      case 2:
        context.go('/student/ar');
        break;

      case 3:
        context.go('/student/assessment');
        break;

      case 4:
        context.go('/student/profile');
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
          label: l10n.assignmentsTab,
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
