// ============================================================================
// MODULE: Authentication API & Service Layer
// DESCRIPTION: Abstraksi dan implementasi layanan autentikasi pengguna dengan
//              Supabase Auth, mencakup login multi-identifier, registrasi,
//              manajemen sesi, serta pemulihan kata sandi berbasis OTP.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';

// ---------------------------------------------------------------------------
// SECTION: Authentication Contract & Data Models
// ---------------------------------------------------------------------------

/// [AuthApi]
///
/// Kontrak antarmuka (interface) untuk seluruh operasi autentikasi.
/// Dipisahkan dari implementasi konkret agar mudah di-mock pada pengujian unit.
abstract class AuthApi {
  /// Memverifikasi kredensial login menggunakan email atau nomor identitas (NIM/NIP)
  /// melalui fungsi RPC di sisi server. Mengembalikan alamat email jika valid.
  Future<String?> verifyLoginCredentials({
    required String identifier,
    required String password,
  });

  /// Melakukan proses sign-in ke sesi Supabase Auth menggunakan email dan password.
  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  /// Mendaftarkan akun pengguna baru beserta metadata profil (nama, peran, NIM/NIP).
  Future<RegisterResult> register({
    required String name,
    required String email,
    required String password,
    required String identityNumber,
    String role = 'student',
  });

  /// Mengambil ID pengguna yang sedang aktif pada sesi saat ini (`null` jika belum login).
  String? get currentUserId;

  /// Mengambil data profil dasar (`id`, `role`, `is_active`) dari tabel `profiles`.
  Future<Map<String, dynamic>?> fetchProfile(String userId);

  /// Mengakhiri sesi pengguna saat ini dari perangkat lokal dan server.
  Future<void> signOut();

  /// Mengirimkan email berisi kode OTP pemulihan kata sandi ke alamat email pengguna.
  Future<void> sendPasswordReset(String email);

  /// Memverifikasi token OTP 6-digit untuk pemulihan kata sandi.
  Future<void> verifyRecoveryOtp({
    required String email,
    required String token,
  });

  /// Memperbarui kata sandi untuk pengguna yang telah terautentikasi melalui sesi aktif.
  Future<void> updatePassword(String password);
}

/// [RegisterResult]
///
/// Merepresentasikan hasil operasi registrasi akun baru, termasuk status apakah
/// pengguna harus melakukan konfirmasi email terlebih dahulu.
class RegisterResult {
  const RegisterResult({
    required this.emailConfirmationRequired,
    this.userId,
  });

  final bool emailConfirmationRequired;
  final String? userId;
}

// ---------------------------------------------------------------------------
// SECTION: Supabase Authentication Implementation
// ---------------------------------------------------------------------------

/// [SupabaseAuthApi]
///
/// Implementasi konkret dari [AuthApi] yang berinteraksi langsung dengan
/// layanan Supabase Auth dan tabel `profiles` PostgreSQL.
class SupabaseAuthApi implements AuthApi {
  const SupabaseAuthApi();

  @override
  Future<String?> verifyLoginCredentials({
    required String identifier,
    required String password,
  }) async {
    // Memanggil fungsi RPC PostgreSQL untuk mencocokkan NIM/NIP atau Email.
    final result = await supabase.rpc(
      'verify_login_credentials',
      params: {'identifier': identifier, 'password': password},
    );

    return result?.toString();
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<RegisterResult> register({
    required String name,
    required String email,
    required String password,
    required String identityNumber,
    String role = 'student',
  }) async {
    // Metadata yang dikirimkan pada `data` akan ditangkap oleh database trigger
    // `handle_new_user` di Supabase untuk membuat baris otomatis di tabel `profiles`.
    final response = await supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'name': name.trim(),
        'role': role,
        'identity_number': identityNumber.trim(),
      },
    );

    final session = response.session;
    final user = response.user;

    if (session != null && user != null) {
      return RegisterResult(
        emailConfirmationRequired: false,
        userId: user.id,
      );
    }

    return const RegisterResult(emailConfirmationRequired: true);
  }

  @override
  String? get currentUserId => supabase.auth.currentUser?.id;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) {
    return supabase
        .from('profiles')
        .select('id, role, is_active')
        .eq('id', userId)
        .maybeSingle();
  }

  @override
  Future<void> signOut() => supabase.auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) {
    return supabase.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    await supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
  }

  @override
  Future<void> updatePassword(String password) async {
    await supabase.auth.updateUser(UserAttributes(password: password));
  }
}

/// Provider Riverpod untuk menyuplai instance [AuthApi] ke seluruh fitur aplikasi.
final authApiProvider = Provider<AuthApi>((ref) => const SupabaseAuthApi());


