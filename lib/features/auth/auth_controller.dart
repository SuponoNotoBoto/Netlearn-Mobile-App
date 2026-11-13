import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session/session_reset.dart';
import '../../core/supabase/supabase_client.dart';
import 'auth_api.dart';

enum AppUserRole {
  student,
  lecturer,
  admin,
}

extension AppUserRoleX on AppUserRole {
  String get value {
    switch (this) {
      case AppUserRole.student:
        return 'student';
      case AppUserRole.lecturer:
        return 'lecturer';
      case AppUserRole.admin:
        return 'admin';
    }
  }
}

String _connectionFailedMessage =
    'Koneksi bermasalah. Periksa internet Anda dan coba lagi.';
String _serverProblemMessage =
    'Terjadi masalah pada server. Silakan coba lagi.';
String _unknownErrorMessage = 'Terjadi kesalahan. Silakan coba lagi.';

String _failureMessageFor(Object error) {
  if (error is SocketException) {
    return _connectionFailedMessage;
  }

  if (error is PostgrestException) {
    return _serverProblemMessage;
  }

  if (error is AuthException) {
    return error.message;
  }

  return _unknownErrorMessage;
}

enum RegisterOutcome {
  success,
  emailConfirmationRequired,
  emailAlreadyRegistered,
  weakPassword,
  invalidEmail,
  unknownError,
}

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final String? signedInRole;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.signedInRole,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? signedInRole,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      signedInRole: signedInRole ?? this.signedInRole,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  Future<bool> login({
    required String identityNumber,
    required String password,
    required AppUserRole role,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final identifier = identityNumber.trim();

      if (identifier.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'NIM/NIP wajib diisi.',
        );
        return false;
      }

      if (password.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Password wajib diisi.',
        );
        return false;
      }

      final api = ref.read(authApiProvider);

      final lookup =
          identifier.contains('@') ? identifier.toLowerCase() : identifier;

      final email = await api.verifyLoginCredentials(
        identifier: lookup,
        password: password,
      );

      if (email == null || email.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'NIM/email atau password tidak sesuai.',
        );
        return false;
      }

      await api.signInWithPassword(
        email: email,
        password: password,
      );

      final userId = api.currentUserId;

      if (userId == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login gagal. Sesi pengguna tidak ditemukan.',
        );
        return false;
      }

      final profile = await api.fetchProfile(userId);

      if (profile == null) {
        await api.signOut();
        resetUserSession(ref);

        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Profil pengguna tidak ditemukan.',
        );
        return false;
      }

      final profileRole = profile['role']?.toString();

      final isSupportedRole =
          profileRole == AppUserRole.student.value ||
          profileRole == AppUserRole.lecturer.value ||
          profileRole == AppUserRole.admin.value;

      if (!isSupportedRole) {
        await api.signOut();
        resetUserSession(ref);

        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Role akun tidak didukung.',
        );
        return false;
      }

      // Admin diizinkan masuk dari tab mahasiswa maupun tab dosen.
      if (profileRole != role.value &&
          profileRole != AppUserRole.admin.value) {
        await api.signOut();
        resetUserSession(ref);

        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Role akun tidak sesuai.',
        );
        return false;
      }

      final isActive = profile['is_active'] as bool? ?? false;

      if (!isActive) {
        await api.signOut();
        resetUserSession(ref);

        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Akun tidak aktif. Hubungi admin.',
        );
        return false;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        signedInRole: profileRole,
      );

      resetUserSession(ref);

      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message.contains('Invalid login credentials')
            ? 'NIM/email atau password tidak sesuai.'
            : e.message.contains('Email not confirmed')
                ? 'Email belum dikonfirmasi. Cek kotak masuk/spam email Anda.'
                : e.message,
      );

      return false;
    } on PostgrestException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _serverProblemMessage,
      );

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _failureMessageFor(e),
      );

      return false;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      await ref.read(authApiProvider).sendPasswordReset(
        email.trim(),
      );

      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _failureMessageFor(e),
      );

      return false;
    }
  }

  Future<bool> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      await ref.read(authApiProvider).verifyRecoveryOtp(
        email: email.trim(),
        token: token.trim(),
      );

      resetUserSession(ref);

      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
      );

      return false;
    }
  }

  Future<bool> completePasswordReset(String password) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      await ref.read(authApiProvider).updatePassword(password);

      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
      );

      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(authApiProvider).signOut();
    resetUserSession(ref);
    state = const AuthState();
  }

  void clearError() {
    if (!ref.mounted) {
      return;
    }

    state = state.copyWith(
      errorMessage: null,
    );
  }

  Future<RegisterOutcome> register({
    required String name,
    required String identityNumber,
    required String email,
    required String password,
    required String confirmPassword,
    AppUserRole role = AppUserRole.student,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    if (name.trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Nama lengkap wajib diisi.',
      );
      return RegisterOutcome.unknownError;
    }

    if (identityNumber.trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: role == AppUserRole.lecturer
            ? 'NIP wajib diisi.'
            : 'NIM wajib diisi.',
      );
      return RegisterOutcome.unknownError;
    }

    if (email.trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Email wajib diisi.',
      );
      return RegisterOutcome.invalidEmail;
    }

    if (!email.contains('@') || !email.contains('.')) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Masukkan alamat email yang valid.',
      );
      return RegisterOutcome.invalidEmail;
    }

    if (password.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Password wajib diisi.',
      );
      return RegisterOutcome.weakPassword;
    }

    if (password.length < 8) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Kata sandi minimal 8 karakter.',
      );
      return RegisterOutcome.weakPassword;
    }

    if (password != confirmPassword) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Konfirmasi password tidak cocok.',
      );
      return RegisterOutcome.unknownError;
    }

    try {
      final result = await ref.read(authApiProvider).register(
        name: name.trim(),
        email: email.trim(),
        password: password,
        identityNumber: identityNumber.trim(),
        role: role.value,
      );

      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
      );

      if (result.emailConfirmationRequired) {
        return RegisterOutcome.emailConfirmationRequired;
      }

      final userId = result.userId;
      if (userId == null) {
        state = state.copyWith(
          errorMessage: 'Registrasi gagal. Silakan coba lagi.',
        );
        return RegisterOutcome.unknownError;
      }

      final profile = await ref.read(authApiProvider).fetchProfile(userId);

      if (profile == null) {
        await ref.read(authApiProvider).signOut();
        resetUserSession(ref);

        state = state.copyWith(
          errorMessage: 'Profil pengguna tidak ditemukan.',
        );
        return RegisterOutcome.unknownError;
      }

      final profileRole = profile['role']?.toString();

      final isSupportedRole =
          profileRole == AppUserRole.student.value ||
          profileRole == AppUserRole.lecturer.value;

      if (!isSupportedRole) {
        await ref.read(authApiProvider).signOut();
        resetUserSession(ref);

        state = state.copyWith(
          errorMessage: 'Role akun tidak didukung.',
        );
        return RegisterOutcome.unknownError;
      }

      final isActive = profile['is_active'] as bool? ?? false;

      if (!isActive) {
        await ref.read(authApiProvider).signOut();
        resetUserSession(ref);

        state = state.copyWith(
          errorMessage: 'Akun tidak aktif. Hubungi admin.',
        );
        return RegisterOutcome.unknownError;
      }

      try {
        await ref.read(authApiProvider).signOut();
      } catch (_) {}

      resetUserSession(ref);

      return RegisterOutcome.success;
    } on AuthException catch (e) {
      String message;
      if (e.message.contains('User already registered') ||
          e.message.contains('already registered')) {
        message = 'Email sudah terdaftar. Silakan masuk atau gunakan email lain.';
        state = state.copyWith(
          isLoading: false,
          errorMessage: message,
        );
        return RegisterOutcome.emailAlreadyRegistered;
      } else if (e.message.contains('Password should be at least') ||
          e.message.contains('weak password')) {
        message = 'Kata sandi terlalu lemah. Minimal 8 karakter.';
        state = state.copyWith(
          isLoading: false,
          errorMessage: message,
        );
        return RegisterOutcome.weakPassword;
      } else if (e.message.contains('Invalid email')) {
        message = 'Format email tidak valid.';
        state = state.copyWith(
          isLoading: false,
          errorMessage: message,
        );
        return RegisterOutcome.invalidEmail;
      } else {
        message = e.message;
        state = state.copyWith(
          isLoading: false,
          errorMessage: message,
        );
        return RegisterOutcome.unknownError;
      }
    } on PostgrestException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _serverProblemMessage,
      );
      return RegisterOutcome.unknownError;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _failureMessageFor(e),
      );
      return RegisterOutcome.unknownError;
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

final authStateChangesProvider =
    StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange.map(
    (_) => const AuthState(),
  );
});

final currentProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>(
  (ref) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    final result = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return result;
  },
);

