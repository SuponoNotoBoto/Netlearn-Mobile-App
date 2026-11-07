import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_bottom_nav_bar.dart';

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
        context.go('/lecturer/assessments');
        break;

      case 3:
        context.go('/lecturer/students');
        break;

      case 4:
        context.go('/lecturer/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isId = l10n == null || Localizations.localeOf(context).languageCode == 'id';

    return NlBottomNavBar(
      currentIndex: currentIndex,
      onSelect: (index) => _onItemTapped(context, index),
      destinations: [
        NlNavDestination(
          label: isId ? 'Beranda' : 'Dashboard',
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
        ),
        NlNavDestination(
          label: isId ? 'Materi' : 'Materials',
          icon: Icons.menu_book_outlined,
          activeIcon: Icons.menu_book_rounded,
        ),
        NlNavDestination(
          label: isId ? 'Asesmen' : 'Assessment',
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment_rounded,
        ),
        NlNavDestination(
          label: isId ? 'Mahasiswa' : 'Students',
          icon: Icons.groups_outlined,
          activeIcon: Icons.groups_rounded,
        ),
        NlNavDestination(
          label: isId ? 'Profil' : 'Profile',
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
        ),
      ],
    );
  }
}

