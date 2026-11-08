import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_client.dart';

/// Reads and writes the signed-in student's virtual-lab canvas.
///
/// The canvas is per account: `virtual_lab_canvases` keyed by `user_id` (PK)
/// with RLS `((SELECT auth.uid()) = user_id)` — migration `20261022120000` —
/// so one student's devices and IP configuration can never show up in another
/// student's lab. `resetUserSession` (core/session/session_reset.dart)
/// invalidates [virtualLabControllerProvider] on sign-in/sign-out, but
/// Riverpod reuses the Notifier instance across invalidates, so load/save
/// that straddle an account switch are additionally discarded here by
/// comparing the current user id with the one captured before the call.
class VirtualLabRepository {
  const VirtualLabRepository();

  /// Akun pemilik canvas saat ini; null ketika sudah keluar.
  ///
  /// Diekspos ke controller supaya load/save yang melewati pergantian akun
  /// bisa dibuang: Riverpod memakai ulang instance Notifier antar-invalidate,
  /// jadi hasil load akun lama bisa mendarat di kanvas akun baru.
  String? get currentUserId => supabase.auth.currentUser?.id;

  Future<Map<String, dynamic>?> load() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await supabase
        .from('virtual_lab_canvases')
        .select('state')
        .eq('user_id', userId)
        .maybeSingle();

    final state = row?['state'];
    return state is Map<String, dynamic> ? state : null;
  }

  Future<void> save(
    Map<String, dynamic> state, {
    required String forUserId,
  }) async {
    // Canvas akun yang sudah keluar tidak boleh menimpa baris akun berikutnya.
    if (supabase.auth.currentUser?.id != forUserId) return;

    await supabase.from('virtual_lab_canvases').upsert({
      'user_id': forUserId,
      'state': state,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

/// Overridden in tests with a fake so the lab stays offline.
final virtualLabRepositoryProvider = Provider<VirtualLabRepository>(
  (ref) => const VirtualLabRepository(),
);
