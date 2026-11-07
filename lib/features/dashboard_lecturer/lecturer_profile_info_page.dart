import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/nl_profile_section.dart';

class LecturerProfileInfoPage extends StatelessWidget {
  const LecturerProfileInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NetLearnColors.appBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: NetLearnColors.border),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: NetLearnColors.neutral900),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Informasi Profil',
          style: TextStyle(
            color: NetLearnColors.neutral900,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          NetLearnSpace.s20,
          NetLearnSpace.s16,
          NetLearnSpace.s20,
          NetLearnSpace.s32,
        ),
        children: [
          const NlProfileSection(
            title: 'INFORMASI PROFIL',
            children: [
              NlProfileRow(
                icon: Icons.badge_outlined,
                label: 'Nama Lengkap',
                value: 'Dr. Supono, M.Kom.',
              ),
              NlProfileRow(
                icon: Icons.email_outlined,
                label: 'Email Resmi',
                value: 'supono@kampus.ac.id',
              ),
              NlProfileRow(
                icon: Icons.verified_user_outlined,
                label: 'NIP / NIDN',
                value: '198507122010121001',
              ),
              NlProfileRow(
                icon: Icons.person_outline_rounded,
                label: 'Peran Akun',
                value: 'Dosen Pengampu',
              ),
            ],
          ),

          const SizedBox(height: NetLearnSpace.s24),

          const Text(
            'Profil hanya dapat diubah melalui sistem informasi akademik kampus.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: NetLearnColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

