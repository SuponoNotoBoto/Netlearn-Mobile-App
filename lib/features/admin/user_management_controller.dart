import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/env.dart';
import '../../core/supabase/supabase_client.dart';
import 'user_management_models.dart';

/// Provider daftar seluruh pengguna (mahasiswa, dosen, dan admin) untuk panel Admin.
final managedUsersProvider =
    FutureProvider.autoDispose<List<ManagedUserAccount>>((ref) async {
  return UserManagementService.fetchUsers();
});

/// Layanan manajemen pengguna oleh Admin: daftar akun, tambah akun, aktif/nonaktifkan, dan hapus akun.
class UserManagementService {
  UserManagementService._();

  static bool _isMissingRpcError(Object error) {
    if (error is PostgrestException) {
      final code = error.code ?? '';
      final msg = error.message.toLowerCase();
      return code == 'PGRST202' ||
          code == '42883' ||
          msg.contains('could not find the function') ||
          msg.contains('does not exist');
    }
    final msg = error.toString().toLowerCase();
    return msg.contains('pgrst202') || msg.contains('could not find the function');
  }

  /// Mengambil daftar semua pengguna dari Supabase.
  static Future<List<ManagedUserAccount>> fetchUsers() async {
    try {
      final dynamic rpcRes = await supabase.rpc('admin_list_users');
      if (rpcRes is List) {
        return rpcRes
            .map((e) => ManagedUserAccount.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      if (!_isMissingRpcError(e)) {
        // Jika error bukan karena RPC belum terpasang (misal unauthorized), teruskan jika query langsung juga gagal.
      }
    }

    final rows = await supabase
        .from('profiles')
        .select(
          'id, name, identity_number, email, program, role, is_active, avatar_config, created_at',
        )
        .order('created_at', ascending: false);

    return (rows as List)
        .map((e) => ManagedUserAccount.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Menambahkan akun baru (mahasiswa, dosen, atau admin) tanpa mengganggu sesi Admin yang sedang aktif.
  static Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? identityNumber,
    String? program,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedIdentity = identityNumber?.trim() ?? '';
    final trimmedProgram = program?.trim() ?? '';

    if (trimmedName.isEmpty) {
      throw Exception('Nama lengkap wajib diisi.');
    }
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      throw Exception('Format email tidak valid.');
    }
    if (password.length < 6) {
      throw Exception('Kata sandi minimal 6 karakter.');
    }

    // 1. Prioritas utama: panggil RPC `admin_create_user` (membuat user auth terkonfirmasi + profile atomik).
    try {
      await supabase.rpc(
        'admin_create_user',
        params: {
          'p_email': trimmedEmail,
          'p_password': password,
          'p_name': trimmedName,
          'p_role': role,
          'p_identity_number': trimmedIdentity,
          'p_program': trimmedProgram.isEmpty ? null : trimmedProgram,
        },
      );
      return;
    } catch (e) {
      if (!_isMissingRpcError(e)) {
        final msg = e.toString();
        if (msg.toLowerCase().contains('already') ||
            msg.toLowerCase().contains('duplicate')) {
          throw Exception('Email atau NIM/NIDN sudah terdaftar.');
        }
        if (e is PostgrestException) {
          throw Exception(e.message);
        }
        rethrow;
      }
    }

    // 2. Fallback REST signup ke GoTrue agar sesi Admin saat ini di SDK tidak tertimpa.
    final supabaseUrl = Env.supabaseUrl;
    final apiKey = Env.supabasePublishableKey.isNotEmpty
        ? Env.supabasePublishableKey
        : Env.supabaseAnonKey;

    if (supabaseUrl.isEmpty || apiKey.isEmpty) {
      throw Exception('Konfigurasi server Supabase belum tersedia.');
    }

    final uri = Uri.parse('$supabaseUrl/auth/v1/signup');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'apikey': apiKey,
      },
      body: jsonEncode({
        'email': trimmedEmail,
        'password': password,
        'data': {
          'name': trimmedName,
          'role': role,
          'identity_number': trimmedIdentity,
          if (trimmedProgram.isNotEmpty) 'program': trimmedProgram,
        },
      }),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final errMsg = (decoded is Map
              ? (decoded['msg'] ?? decoded['error_description'] ?? decoded['message'])
              : null)
          ?.toString();
      if (errMsg != null &&
          errMsg.toLowerCase().contains('already registered')) {
        throw Exception('Email sudah terdaftar di sistem.');
      }
      throw Exception(errMsg ?? 'Gagal membuat akun baru (${response.statusCode}).');
    }

    String? newUserId;
    if (decoded is Map) {
      newUserId = decoded['id']?.toString() ??
          (decoded['user'] is Map ? decoded['user']['id']?.toString() : null);
    }

    if (newUserId != null && newUserId.isNotEmpty) {
      try {
        await supabase.from('profiles').upsert({
          'id': newUserId,
          'name': trimmedName,
          'email': trimmedEmail,
          'role': role,
          'identity_number': trimmedIdentity,
          if (trimmedProgram.isNotEmpty) 'program': trimmedProgram,
          'is_active': true,
        });
      } catch (_) {
        // Trigger auth.users mungkin sudah membuat baris profil secara otomatis.
      }
    }
  }

  /// Mengaktifkan atau menonaktifkan akun pengguna.
  static Future<void> setUserActive({
    required String userId,
    required bool isActive,
  }) async {
    final currentUid = supabase.auth.currentUser?.id;
    if (userId == currentUid) {
      throw Exception('Anda tidak dapat menonaktifkan akun Anda sendiri.');
    }

    try {
      await supabase.rpc(
        'admin_set_user_active',
        params: {
          'p_user_id': userId,
          'p_is_active': isActive,
        },
      );
      return;
    } catch (e) {
      if (!_isMissingRpcError(e)) {
        if (e is PostgrestException) {
          throw Exception(e.message);
        }
        rethrow;
      }
    }

    final updated = await supabase
        .from('profiles')
        .update({'is_active': isActive})
        .eq('id', userId)
        .select('id');

    if ((updated as List).isEmpty) {
      throw Exception(
        'Gagal memperbarui status akun. Pastikan fungsi RPC admin_set_user_active atau kebijakan RLS Admin sudah terpasang di Supabase.',
      );
    }
  }

  /// Menghapus akun pengguna secara permanen.
  static Future<void> deleteUser({
    required String userId,
  }) async {
    final currentUid = supabase.auth.currentUser?.id;
    if (userId == currentUid) {
      throw Exception('Anda tidak dapat menghapus akun Anda sendiri.');
    }

    try {
      await supabase.rpc(
        'admin_delete_user',
        params: {'p_user_id': userId},
      );
      return;
    } catch (e) {
      if (!_isMissingRpcError(e)) {
        if (e is PostgrestException) {
          throw Exception(e.message);
        }
        rethrow;
      }
    }

    final deleted = await supabase
        .from('profiles')
        .delete()
        .eq('id', userId)
        .select('id');

    if ((deleted as List).isEmpty) {
      throw Exception(
        'Gagal menghapus akun. Pastikan fungsi RPC admin_delete_user sudah dijalankan di Supabase SQL Editor.',
      );
    }
  }
}

