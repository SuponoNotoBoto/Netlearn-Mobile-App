import 'package:flutter/material.dart';

import '../profile/change_password_page.dart';
import 'lecturer_bottom_navbar.dart';

/// Wrapper dosen atas halaman ubah kata sandi bersama.
///
/// Widget-nya dipindahkan ke `../profile/change_password_page.dart` ketika
/// mahasiswa mendapat flow Security & Password-nya sendiri — daripada kedua
/// role menyalin form yang sampai kapan pun harus berubah bersamaan. Bagian
/// yang membedakan (sumber profil, fallback back, navbar bawah) dikirim di
/// sini; router `/lecturer/security/change-password` tidak berubah.
class LecturerChangePasswordPage extends StatelessWidget {
  const LecturerChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChangePasswordPage(
      useStudentProfile: false,
      backFallback: '/lecturer/security',
      bottomNavbar: LecturerBottomNavbar(currentIndex: 4),
    );
  }
}
