class Env {
  Env._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dsqxjnanoallwujlymmp.supabase.co',
  );

  /// Publishable (anon) key. Never ship the secret key here.
  ///
  /// The project's legacy `anon` JWT is rejected with
  /// `UNAUTHORIZED_INVALID_API_KEY`; use the publishable key instead. Override
  /// at build time with
  /// `--dart-define=SUPABASE_PUBLISHABLE_KEY=...`.
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_Rhf4KG8xiXjdkkytIEBm8w_sPn4FVQq',
  );

  /// Kept so existing `--dart-define=SUPABASE_ANON_KEY=...` setups keep working.
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Groq API Key for NetBot AI Tutor.
  ///
  /// Built-in system API key. Can be overridden at build time with
  /// `--dart-define=GROQ_API_KEY=...`.
  static const groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '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',
  );

  /// Deprecated alias kept for backwards compatibility.
  static const geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
}
