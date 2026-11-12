import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  // Credentials and API keys must be provided via `.env` or `--dart-define`
  // so no values are hardcoded in source control.
  static const String _defaultSupabaseUrl = '';
  static const String _defaultSupabasePublishableKey = '';

  static void _ensureInitialized() {
    if (dotenv.isInitialized) return;
    if (!kIsWeb) {
      try {
        final file = File('.env');
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          dotenv.loadFromString(envString: content, isOptional: true);
        }
      } catch (_) {}
    }
  }

  static String _get(
    String key, {
    String dartDefine = '',
    String fallback = '',
  }) {
    _ensureInitialized();
    if (dotenv.isInitialized) {
      final value = dotenv.env[key]?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    final fromEnv = dartDefine.trim();
    if (fromEnv.isNotEmpty) return fromEnv;
    return fallback;
  }

  static String get supabaseUrl => _get(
        'SUPABASE_URL',
        dartDefine: const String.fromEnvironment('SUPABASE_URL'),
        fallback: _defaultSupabaseUrl,
      );

  static String get supabasePublishableKey => _get(
        'SUPABASE_PUBLISHABLE_KEY',
        dartDefine: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
        fallback: _defaultSupabasePublishableKey,
      );

  static String get supabaseAnonKey => _get(
        'SUPABASE_ANON_KEY',
        dartDefine: const String.fromEnvironment('SUPABASE_ANON_KEY'),
        fallback: _defaultSupabasePublishableKey,
      );

  static String get groqApiKey => _get(
        'GROQ_API_KEY',
        dartDefine: const String.fromEnvironment('GROQ_API_KEY'),
      );
  static String get geminiApiKey => _get(
        'GEMINI_API_KEY',
        dartDefine: const String.fromEnvironment('GEMINI_API_KEY'),
      );
  static String get openrouterApiKey => _get(
        'OPENROUTER_API_KEY',
        dartDefine: const String.fromEnvironment('OPENROUTER_API_KEY'),
      );
}

