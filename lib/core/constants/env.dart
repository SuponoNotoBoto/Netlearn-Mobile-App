// ============================================================================
// MODULE: Environment Variable & Credential Configuration
// DESCRIPTION: Mengelola pembacaan kredensial aplikasi secara aman melalui file
//              .env atau compile-time environment (--dart-define) tanpa
//              menyimpan nilai rahasia secara hardcoded di dalam kode sumber.
// ============================================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// [Env]
///
/// Kelas utilitas statis yang menyediakan akses terpusat ke variabel lingkungan
/// untuk layanan backend Supabase dan multi-provider AI (Groq, Gemini, OpenRouter).
class Env {
  Env._();

  // ---------------------------------------------------------------------------
  // SECTION: Fallback Configuration Constants
  // ---------------------------------------------------------------------------

  // Nilai default dikosongkan untuk mematuhi standar keamanan repositori publik
  // (mencegah kebocoran kredensial / secret scanning). Seluruh nilai wajib disuplai
  // melalui file `.env` lokal atau argumen `--dart-define`.
  static const String _defaultSupabaseUrl =
      '';
  static const String _defaultSupabasePublishableKey =
      '';

  // ---------------------------------------------------------------------------
  // SECTION: Internal Resolution Helpers
  // ---------------------------------------------------------------------------

  /// Memastikan `dotenv` telah terinisialisasi sebelum membaca variabel.
  /// Pada lingkungan pengujian (CLI/unit test non-Web), fungsi ini dapat
  /// membaca `.env` secara sinkron jika belum dimuat di `main()`.
  static void _ensureInitialized() {
    if (dotenv.isInitialized) return;
    if (!kIsWeb) {
      try {
        final file = File('.env');
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          dotenv.loadFromString(envString: content);
        }
      } catch (_) {}
    }
  }

  /// Mengambil nilai variabel berdasarkan urutan prioritas:
  /// 1. Variabel dari file `.env` (via `flutter_dotenv`).
  /// 2. Variabel compile-time (`String.fromEnvironment` / `--dart-define`).
  /// 3. Nilai `fallback` jika keduanya kosong.
  static String _get(String key, {String fallback = ''}) {
    _ensureInitialized();
    if (dotenv.isInitialized) {
      final value = dotenv.env[key];
      if (value != null && value.isNotEmpty) return value;
    }
    final fromEnv = String.fromEnvironment(key);
    if (fromEnv.isNotEmpty) return fromEnv;
    return fallback;
  }

  // ---------------------------------------------------------------------------
  // SECTION: Public Credential Getters
  // ---------------------------------------------------------------------------

  /// Endpoint URL proyek Supabase (`https://<project_id>.supabase.co`).
  static String get supabaseUrl =>
      _get('SUPABASE_URL', fallback: _defaultSupabaseUrl);

  /// Kunci publik (Publishable / Anon Key) Supabase yang diamankan dengan
  /// Row Level Security (RLS) di sisi PostgreSQL.
  static String get supabasePublishableKey =>
      _get('SUPABASE_PUBLISHABLE_KEY', fallback: _defaultSupabasePublishableKey);

  /// Alias kompatibilitas untuk kunci publik Supabase (`SUPABASE_ANON_KEY`).
  static String get supabaseAnonKey =>
      _get('SUPABASE_ANON_KEY', fallback: _defaultSupabasePublishableKey);

  /// Kunci API untuk layanan inferensi AI prioritas utama (Groq LPU).
  static String get groqApiKey => _get('GROQ_API_KEY');

  /// Kunci API untuk layanan Google Gemini AI.
  static String get geminiApiKey => _get('GEMINI_API_KEY');

  /// Kunci API untuk layanan agregator model AI OpenRouter.
  static String get openrouterApiKey => _get('OPENROUTER_API_KEY');
}


