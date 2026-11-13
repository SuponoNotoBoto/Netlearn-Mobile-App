// ============================================================================
// MODULE: Supabase Client Gateway
// DESCRIPTION: Menyediakan akses global (singleton getter) ke instance
//              SupabaseClient yang telah diinisialisasi saat aplikasi dimulai.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

/// [supabase]
///
/// Getter global untuk mengakses layanan autentikasi, database PostgREST,
/// pemanggilan RPC (Remote Procedure Call), dan penyimpanan Supabase.
SupabaseClient get supabase => Supabase.instance.client;

