import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';

abstract class AuthApi {
  Future<String?> verifyLoginCredentials({
    required String identifier,
    required String password,
  });

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  Future<RegisterResult> register({
    required String name,
    required String email,
    required String password,
    required String identityNumber,
    String role = 'student',
  });

  String? get currentUserId;

  Future<Map<String, dynamic>?> fetchProfile(String userId);

  Future<void> signOut();

  Future<void> sendPasswordReset(String email);

  Future<void> verifyRecoveryOtp({
    required String email,
    required String token,
  });

  Future<void> updatePassword(String password);
}

class RegisterResult {
  const RegisterResult({
    required this.emailConfirmationRequired,
    this.userId,
  });

  final bool emailConfirmationRequired;
  final String? userId;
}

class SupabaseAuthApi implements AuthApi {
  const SupabaseAuthApi();

  @override
  Future<String?> verifyLoginCredentials({
    required String identifier,
    required String password,
  }) async {
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

final authApiProvider = Provider<AuthApi>((ref) => const SupabaseAuthApi());

