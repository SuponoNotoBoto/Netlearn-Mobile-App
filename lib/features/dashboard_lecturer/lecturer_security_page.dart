import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LecturerSecurityPage extends StatelessWidget {
  const LecturerSecurityPage({super.key});

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
          'Keamanan & Kata Sandi',
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
          // Card 1: Account info
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NetLearnColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Email Akun',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1D26),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'supono@kampus.ac.id',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1D26),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Status Akun',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1D26),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Aktif',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Card 2: Password actions
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NetLearnColors.border),
            ),
            child: Column(
              children: [
                _SecurityActionRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'Ubah Kata Sandi',
                  subtitle: 'Ganti kata sandi akun Anda secara berkala',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Form ubah kata sandi')),
                    );
                  },
                ),
                const Divider(height: 1, color: NetLearnColors.border),
                _SecurityActionRow(
                  icon: Icons.mail_outline_rounded,
                  title: 'Lupa Kata Sandi',
                  subtitle: 'Kirim tautan pemulihan ke email terdaftar',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tautan pemulihan kata sandi')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Penggantian kata sandi akan diverifikasi melalui email kampus Anda.',
            style: TextStyle(fontSize: 10, color: Color(0xFF6C727F)),
          ),
        ],
      ),
    );
  }
}

class _SecurityActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SecurityActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: NetLearnColors.purple100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: NetLearnColors.primary),
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
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1D26),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6C727F),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF6C727F),
            ),
          ],
        ),
      ),
    );
  }
}

