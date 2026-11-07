import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/nl_profile_section.dart';
import '../../shared/widgets/nl_stats_strip.dart';
import 'lecturer_academic_info_page.dart';
import 'lecturer_profile_info_page.dart';
import 'lecturer_security_page.dart';

class LecturerProfilePage extends StatefulWidget {
  final VoidCallback? onBackToDashboard;
  final VoidCallback? onNavigateToStudents;

  const LecturerProfilePage({
    super.key,
    this.onBackToDashboard,
    this.onNavigateToStudents,
  });

  @override
  State<LecturerProfilePage> createState() => _LecturerProfilePageState();
}

class _LecturerProfilePageState extends State<LecturerProfilePage> {
  bool _isDarkMode = false;
  Locale _locale = const Locale('id');

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NetLearnRadius.card),
          ),
          title: const Text(
            'Keluar Akun',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun dosen NetLearn?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: NetLearnColors.danger,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sesi logout akan aktif saat alur login dibuat.'),
                  ),
                );
              },
              child: const Text('Ya, Keluar'),
            ),
          ],
        );
      },
    );
  }

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
          child: Container(
            height: 1,
            color: const Color(0xFFECEEF2),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: NetLearnColors.neutral900),
          onPressed: () {
            if (widget.onBackToDashboard != null) {
              widget.onBackToDashboard!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Profil',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: NetLearnColors.neutral900,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: NetLearnColors.neutral900),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Belum ada notifikasi baru')),
              );
            },
          ),
        ],
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
          // 1. Hero header identitas (NetLearn 2.0 style)
          const NlProfileHeader(
            name: 'Dr. Supono, M.Kom.',
            subtitle: '198507122010121001',
            initial: 'D',
            roleLabel: 'Dosen Pengampu',
            academicTag: 'Pendidikan Teknologi Informasi • Semester Ganjil 2026/2027',
            bio: 'Membimbing dan membangun keahlian jaringan komputer generasi masa depan.',
          ),

          const SizedBox(height: NetLearnSpace.s16),

          // 2. Stats strip (3 kolom angka terpadu)
          const NlStatsStrip(
            items: [
              NlStatsStripItem(
                value: '48',
                label: 'Total Mahasiswa',
              ),
              NlStatsStripItem(
                value: '4',
                label: 'Materi Ajar',
              ),
              NlStatsStripItem(
                value: '84.5%',
                label: 'Rata-rata Nilai',
              ),
            ],
          ),

          const SizedBox(height: NetLearnSpace.s24),

          // 3. Menu heading "Pengaturan & aktivitas"
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Pengaturan & aktivitas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D26),
                  ),
                ),
              ),
              SizedBox(width: NetLearnSpace.s8),
              Icon(
                Icons.settings_rounded,
                size: 16,
                color: NetLearnColors.neutral500,
              ),
            ],
          ),

          const SizedBox(height: NetLearnSpace.s8),

          // 4. Unified profile menu card (6 baris persis NetLearn 2.0)
          NlProfileMenuCard(
            rows: [
              // Row 1: Informasi Profil
              NlProfileMenuRow(
                type: NlProfileMenuRowType.navigation,
                tintIndex: 0, // blue-tint
                icon: Icons.person_rounded,
                title: 'Informasi Profil',
                subtitle: 'Informasi akun',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LecturerProfileInfoPage(),
                    ),
                  );
                },
              ),

              // Row 2: Informasi Akademik
              NlProfileMenuRow(
                type: NlProfileMenuRowType.navigation,
                tintIndex: 3, // purple-tint
                icon: Icons.school_rounded,
                title: 'Informasi Akademik',
                subtitle: 'Informasi akademik',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LecturerAcademicInfoPage(),
                    ),
                  );
                },
              ),

              // Row 3: Daftar Mahasiswa
              NlProfileMenuRow(
                type: NlProfileMenuRowType.navigation,
                tintIndex: 4, // orange-tint
                icon: Icons.groups_outlined,
                title: 'Daftar Mahasiswa',
                subtitle: 'Ringkasan data mahasiswa',
                onTap: () {
                  if (widget.onNavigateToStudents != null) {
                    widget.onNavigateToStudents!();
                  }
                },
              ),

              // Row 4: Keamanan & Kata Sandi
              NlProfileMenuRow(
                type: NlProfileMenuRowType.navigation,
                tintIndex: 3, // purple-tint
                icon: Icons.shield_rounded,
                title: 'Keamanan & Kata Sandi',
                subtitle: 'Status akun',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LecturerSecurityPage(),
                    ),
                  );
                },
              ),

              // Row 5: Tema Mode Gelap
              NlProfileMenuRow(
                type: NlProfileMenuRowType.themeSwitch,
                tintIndex: 1, // indigo-tint
                icon: _isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                title: 'Mode Gelap',
                subtitle: _isDarkMode ? 'Tema Gelap' : 'Tema Terang',
                switchValue: _isDarkMode,
                onSwitchChanged: (enabled) {
                  setState(() {
                    _isDarkMode = enabled;
                  });
                },
              ),

              // Row 6: Bahasa
              NlProfileMenuRow(
                type: NlProfileMenuRowType.language,
                tintIndex: 2, // green-tint
                icon: Icons.language_rounded,
                title: 'Bahasa',
                subtitle: _locale.languageCode == 'id'
                    ? 'Bahasa Indonesia'
                    : 'English',
                locale: _locale,
                onLanguageChanged: (languageCode) {
                  setState(() {
                    _locale = Locale(languageCode);
                  });
                },
              ),
            ],
          ),

          // 5. Logout button (full-width, outline danger — Figma 51:237)
          const SizedBox(height: NetLearnSpace.s24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _showLogoutDialog,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Keluar Akun',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: NetLearnColors.danger,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: NetLearnColors.danger,
                side: const BorderSide(color: NetLearnColors.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),

          // 6. Version text
          const SizedBox(height: NetLearnSpace.s16),
          const Text(
            'NetLearn Mobile v1.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6C727F),
              fontSize: 11,
            ),
          ),

          const SizedBox(height: NetLearnSpace.s16),

          // 7. Read-only note
          const Text(
            'Profil hanya dapat diubah melalui sistem informasi akademik kampus',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6C727F),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

