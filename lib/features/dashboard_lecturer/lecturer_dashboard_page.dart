import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/nl_metric_grid.dart';
import '../../shared/widgets/nl_notification_bell.dart';
import '../../shared/widgets/nl_promo_banner.dart';
import '../../shared/widgets/nl_shortcut_tile.dart';
import 'lecturer_profile_page.dart';

class LecturerDashboardPage extends StatefulWidget {
  const LecturerDashboardPage({super.key});

  @override
  State<LecturerDashboardPage> createState() => _LecturerDashboardPageState();
}

class _LecturerDashboardPageState extends State<LecturerDashboardPage> {
  int _currentNavIndex = 0;
  String _selectedClass = 'TI-3A (Jaringan Komputer)';

  final List<String> _classList = [
    'TI-3A (Jaringan Komputer)',
    'TI-3B (Jaringan Komputer)',
  ];

  @override
  Widget build(BuildContext context) {
    if (_currentNavIndex == 4) {
      return Scaffold(
        body: LecturerProfilePage(
          onBackToDashboard: () => setState(() => _currentNavIndex = 0),
          onNavigateToStudents: () => setState(() => _currentNavIndex = 3),
        ),
        bottomNavigationBar: _buildBottomNavbar(),
      );
    }

    return Scaffold(
      backgroundColor: NetLearnColors.appBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildCurrentTab(),
            ),
            _buildBottomNavbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentNavIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildMaterialsTab();
      case 2:
        return _buildAssessmentsTab();
      case 3:
        return _buildStudentsTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  // ==========================================
  // TAB 1: BERANDA (DASHBOARD UTAMA)
  // ==========================================
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Section (Sapaan, Avatar Simpel, Notifikasi, Bantuan)
          _buildHero(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: NetLearnSpace.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: NetLearnSpace.s12),

                // 2. Bar Kelas Aktif (Active Class Bar)
                _buildActiveClassBar(),
                const SizedBox(height: NetLearnSpace.s16),

                // 3. Promo Banner (Siap Mengajar Hari Ini)
                NlPromoBanner(
                  title: 'Siap Mengajar Hari Ini?',
                  subtitle:
                      'Kelola materi, pengumuman, dan pantau progres mahasiswa melalui dashboard Anda.',
                  ctaLabel: 'Kelola Materi',
                  onPressed: () {
                    setState(() => _currentNavIndex = 1);
                  },
                ),
                const SizedBox(height: NetLearnSpace.s20),

                // 4. Section Title: Ruang Pengajaran
                _buildSectionTitle('Ruang Pengajaran'),
                const SizedBox(height: NetLearnSpace.s12),

                // 5. Shortcut Grid (3 Kolom - Tanpa AR & Tanpa Virtual Lab)
                _buildShortcutGrid(),
                const SizedBox(height: NetLearnSpace.s24),

                // 6. Ringkasan Statistik
                _buildSectionTitle('Statistik Semester'),
                const SizedBox(height: NetLearnSpace.s12),
                _buildStatsStrip(),
                const SizedBox(height: NetLearnSpace.s24),

                // 7. Recent Activities (Aktivitas Terkini)
                _buildRecentActivities(),
                const SizedBox(height: NetLearnSpace.s32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      color: NetLearnColors.appBg,
      padding: const EdgeInsets.fromLTRB(
        NetLearnSpace.s20,
        NetLearnSpace.s12,
        NetLearnSpace.s20,
        NetLearnSpace.s8,
      ),
      child: Row(
        children: [
          // Avatar sederhana (lingkaran inisial - tanpa fitur custom avatar)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: NetLearnColors.purple100,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: NetLearnShadows.softSm,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Text(
                    'D',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: NetLearnColors.primary,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: NetLearnColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: NetLearnSpace.s12),

          // Nama & Sapaan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Halo, Bapak Dosen 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: NetLearnColors.neutral900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Dosen Pengampu • 198507122010121001',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: NetLearnColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Tombol Notifikasi (Lonceng)
          NlNotificationBell(
            hasUnread: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifikasi terbaru telah ditampilkan'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // Tombol Bantuan
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _showAboutDialog();
              },
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: NetLearnColors.border),
                  boxShadow: NetLearnShadows.softSm,
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  size: 20,
                  color: NetLearnColors.neutral700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveClassBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: NetLearnColors.border),
        boxShadow: NetLearnShadows.softSm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: NetLearnColors.purple100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.school_rounded,
              size: 18,
              color: NetLearnColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KELAS AKTIF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: NetLearnColors.primary,
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedClass,
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: NetLearnColors.neutral900,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: NetLearnColors.neutral500,
                    ),
                    items: _classList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedClass = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: NetLearnColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(NetLearnRadius.radiusPill),
            ),
            child: const Text(
              'Aktif',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: NetLearnColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: NetLearnColors.neutral900,
      ),
    );
  }

  Widget _buildShortcutGrid() {
    final accents = NetLearnColors.gridAccents;

    return NlMetricGrid(
      columns: 3,
      gap: NetLearnSpace.s12,
      children: [
        NlShortcutTile(
          icon: Icons.menu_book_outlined,
          accentColor: accents[0],
          title: 'Kelola Materi',
          subtitle: '4 Modul Ajar',
          onTap: () => setState(() => _currentNavIndex = 1),
        ),
        NlShortcutTile(
          icon: Icons.assignment_outlined,
          accentColor: accents[1],
          title: 'Tugas & Kuis',
          subtitle: '3 Tugas Aktif',
          onTap: () => setState(() => _currentNavIndex = 2),
        ),
        NlShortcutTile(
          icon: Icons.quiz_outlined,
          accentColor: accents[2],
          title: 'Bank Soal',
          subtitle: 'Ujian & Latihan',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Membuka Bank Soal Ujian')),
            );
          },
        ),
        NlShortcutTile(
          icon: Icons.campaign_outlined,
          accentColor: accents[3],
          title: 'Pengumuman',
          subtitle: 'Kirim Info Kelas',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kelola Pengumuman Kelas')),
            );
          },
        ),
        NlShortcutTile(
          icon: Icons.groups_outlined,
          accentColor: accents[4],
          title: 'Mahasiswa',
          subtitle: '48 Mahasiswa',
          onTap: () => setState(() => _currentNavIndex = 3),
        ),
        NlShortcutTile(
          icon: Icons.play_circle_outline_rounded,
          accentColor: accents[5],
          title: 'Video Kuliah',
          subtitle: 'Tonton Materi',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Daftar Video Pembelajaran')),
            );
          },
        ),
        NlShortcutTile(
          icon: Icons.school_outlined,
          accentColor: accents[6],
          title: 'Kelola Kelas',
          subtitle: '2 Kelas Diampu',
          onTap: () => setState(() => _currentNavIndex = 3),
        ),
      ],
    );
  }

  Widget _buildStatsStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: NetLearnColors.border),
        boxShadow: NetLearnShadows.softSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCol('2', 'Kelas', NetLearnColors.primary),
          _buildDivider(),
          _buildStatCol('48', 'Mahasiswa', NetLearnColors.info),
          _buildDivider(),
          _buildStatCol('4', 'Modul', NetLearnColors.success),
          _buildDivider(),
          _buildStatCol('84%', 'Rerata', NetLearnColors.orange),
        ],
      ),
    );
  }

  Widget _buildStatCol(String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: NetLearnColors.neutral500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: NetLearnColors.border,
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Expanded(
              child: Text(
                'Aktivitas Terkini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: NetLearnColors.neutral900,
                ),
              ),
            ),
            Icon(Icons.schedule, size: 18, color: NetLearnColors.neutral400),
          ],
        ),
        const SizedBox(height: NetLearnSpace.s12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: NetLearnSpace.s16,
            vertical: NetLearnSpace.s8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(NetLearnRadius.card),
            border: Border.all(color: NetLearnColors.border),
            boxShadow: NetLearnShadows.softSm,
          ),
          child: Column(
            children: [
              _buildActivityTile(
                icon: Icons.menu_book_outlined,
                iconColor: NetLearnColors.primary,
                title: 'Materi 4: IP Address & Subnetting',
                subtitle: 'Diterbitkan untuk Kelas TI-3A & TI-3B',
                time: '2 jam lalu',
              ),
              const Divider(height: 16, thickness: 0.5, color: NetLearnColors.border),
              _buildActivityTile(
                icon: Icons.assignment_turned_in_outlined,
                iconColor: NetLearnColors.success,
                title: 'Tugas 1: Perhitungan Subnetting IPv4',
                subtitle: '18 dari 24 mahasiswa sudah mengumpulkan',
                time: 'Hari ini, 14:20',
              ),
              const Divider(height: 16, thickness: 0.5, color: NetLearnColors.border),
              _buildActivityTile(
                icon: Icons.campaign_outlined,
                iconColor: NetLearnColors.orange,
                title: 'Pengumuman: Jadwal Praktikum Lab 1',
                subtitle: 'Terkirim ke seluruh mahasiswa kelas TI-3A',
                time: 'Kemarin',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: NetLearnColors.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: NetLearnColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 10,
              color: NetLearnColors.neutral400,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: MATERI AJAR
  // ==========================================
  Widget _buildMaterialsTab() {
    final modules = [
      {
        'no': '01',
        'title': 'Dasar-Dasar Jaringan Komputer',
        'desc': 'Konsep LAN, MAN, WAN, model referensi OSI dan TCP/IP',
        'items': '3 Bacaan • 1 Video',
        'status': 'Terbit',
      },
      {
        'no': '02',
        'title': 'Perangkat Jaringan Komputer',
        'desc': 'Router, Switch, Hub, NIC, dan media transmisi kabel UTP/STP',
        'items': '2 Bacaan • 1 Video',
        'status': 'Terbit',
      },
      {
        'no': '03',
        'title': 'Topologi Jaringan Komputer',
        'desc': 'Topologi Star, Bus, Ring, Mesh, serta kelebihan & kekurangannya',
        'items': '2 Bacaan • 2 Video',
        'status': 'Terbit',
      },
      {
        'no': '04',
        'title': 'IP Addressing & Subnetting',
        'desc': 'Alamat IPv4, Classful vs CIDR, subnet mask, dan network planning',
        'items': '4 Bacaan • 2 Video',
        'status': 'Terbit',
      },
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(NetLearnSpace.s20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Daftar Modul Materi'),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tambah Modul Materi Baru')),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Tambah Modul', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: NetLearnColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(NetLearnRadius.radiusPill),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: NetLearnSpace.s16),
        ...modules.map((m) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(NetLearnRadius.card),
              border: Border.all(color: NetLearnColors.border),
              boxShadow: NetLearnShadows.softSm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: NetLearnColors.purple100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    m['no']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: NetLearnColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              m['title']!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: NetLearnColors.neutral900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: NetLearnColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              m['status']!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: NetLearnColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m['desc']!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: NetLearnColors.neutral500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m['items']!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: NetLearnColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // TAB 3: PENILAIAN & ASESMEN
  // ==========================================
  Widget _buildAssessmentsTab() {
    final tasks = [
      {
        'title': 'Tugas 1: Subnetting IPv4 & CIDR',
        'deadline': '10 Nov 2026, 23:59 WIB',
        'submitted': '18 / 24 Mahasiswa',
        'progress': 0.75,
      },
      {
        'title': 'Kuis 1: Konsep Model OSI & TCP/IP',
        'deadline': '12 Nov 2026, 12:00 WIB',
        'submitted': '22 / 24 Mahasiswa',
        'progress': 0.91,
      },
      {
        'title': 'Tugas 2: Desain Topologi Star',
        'deadline': '18 Nov 2026, 23:59 WIB',
        'submitted': '8 / 24 Mahasiswa',
        'progress': 0.33,
      },
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(NetLearnSpace.s20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Daftar Tugas & Asesmen'),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Buat Tugas / Asesmen Baru')),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Buat Tugas', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: NetLearnColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(NetLearnRadius.radiusPill),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: NetLearnSpace.s16),
        ...tasks.map((t) {
          final progress = t['progress'] as double;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(NetLearnRadius.card),
              border: Border.all(color: NetLearnColors.border),
              boxShadow: NetLearnShadows.softSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t['title'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: NetLearnColors.neutral900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: NetLearnColors.neutral400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tenggat: ${t['deadline']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: NetLearnColors.neutral500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pengumpulan: ${t['submitted']}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: NetLearnColors.primary,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: NetLearnColors.neutral700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: NetLearnColors.purple50,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      NetLearnColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // TAB 4: MAHASISWA & KELAS
  // ==========================================
  Widget _buildStudentsTab() {
    final students = [
      {'name': 'Ahmad Fauzi', 'nim': '22010101', 'score': '88', 'status': 'Aktif'},
      {'name': 'Budi Santoso', 'nim': '22010102', 'score': '82', 'status': 'Aktif'},
      {'name': 'Citra Lestari', 'nim': '22010103', 'score': '95', 'status': 'Aktif'},
      {'name': 'Dimas Pratama', 'nim': '22010104', 'score': '79', 'status': 'Aktif'},
      {'name': 'Eka Saputra', 'nim': '22010105', 'score': '85', 'status': 'Aktif'},
      {'name': 'Fitri Handayani', 'nim': '22010106', 'score': '91', 'status': 'Aktif'},
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(NetLearnSpace.s20),
      children: [
        _buildSectionTitle('Daftar Mahasiswa - $_selectedClass'),
        const SizedBox(height: NetLearnSpace.s12),
        ...students.map((s) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(NetLearnRadius.radiusSm),
              border: Border.all(color: NetLearnColors.border),
              boxShadow: NetLearnShadows.softSm,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: NetLearnColors.purple100,
                  child: Text(
                    s['name']![0],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: NetLearnColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['name']!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: NetLearnColors.neutral900,
                        ),
                      ),
                      Text(
                        'NIM: ${s['nim']}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: NetLearnColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Nilai: ${s['score']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: NetLearnColors.primary,
                      ),
                    ),
                    Text(
                      s['status']!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: NetLearnColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProfileTab() {
    return LecturerProfilePage(
      onBackToDashboard: () => setState(() => _currentNavIndex = 0),
      onNavigateToStudents: () => setState(() => _currentNavIndex = 3),
    );
  }

  // ==========================================
  // BOTTOM NAVIGATION BAR (TANPA AR SCANNER)
  // ==========================================
  Widget _buildBottomNavbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: NetLearnColors.border),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: NetLearnColors.primary,
        unselectedItemColor: NetLearnColors.neutral400,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book_rounded),
            label: 'Materi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment_rounded),
            label: 'Asesmen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups_rounded),
            label: 'Mahasiswa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NetLearnRadius.card),
          ),
          title: const Text(
            'Tentang NetLearn',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'NetLearn Mobile App\nComputer Networking Learning Management System\nVersi 1.0.0',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }
}
