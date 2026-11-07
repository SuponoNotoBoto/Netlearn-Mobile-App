import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/nl_profile_section.dart';

class LecturerAcademicInfoPage extends StatelessWidget {
  const LecturerAcademicInfoPage({super.key});

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
          'Informasi Akademik',
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
          NlProfileSection(
            title: 'INFORMASI AKADEMIK',
            children: [
              const NlProfileRow(
                icon: Icons.badge_outlined,
                label: 'NIP',
                value: '198507122010121001',
              ),
              const NlProfileRow(
                icon: Icons.account_balance_outlined,
                label: 'Jurusan / Departemen',
                value: 'Teknik Informatika',
              ),
              const NlProfileRow(
                icon: Icons.school_outlined,
                label: 'Program Studi',
                value: 'Pendidikan Teknologi Informasi',
              ),
              NlProfileRow(
                icon: Icons.verified_user_outlined,
                label: 'Status Akun',
                value: 'Aktif',
                valueWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Aktif',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

