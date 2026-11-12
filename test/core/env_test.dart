import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/core/constants/env.dart';

void main() {
  tearDown(() => dotenv.clean());

  test('Env does not expose hardcoded credentials when .env entries are empty', () {
    dotenv.loadFromString(
      envString: '''
SUPABASE_URL=
SUPABASE_PUBLISHABLE_KEY=
GROQ_API_KEY=
GEMINI_API_KEY=
OPENROUTER_API_KEY=
''',
      isOptional: true,
    );

    expect(Env.supabaseUrl, isEmpty);
    expect(Env.supabasePublishableKey, isEmpty);
    expect(Env.supabaseAnonKey, isEmpty);
    expect(Env.groqApiKey, isEmpty);
    expect(Env.geminiApiKey, isEmpty);
    expect(Env.openrouterApiKey, isEmpty);
  });

  test('Env reads and trims configured values from dotenv', () {
    dotenv.loadFromString(
      envString: '''
SUPABASE_URL= https://custom-project.supabase.co
SUPABASE_PUBLISHABLE_KEY= sb_publishable_custom
GROQ_API_KEY= test-groq
GEMINI_API_KEY= test-gemini
OPENROUTER_API_KEY= test-openrouter
''',
      isOptional: true,
    );

    expect(Env.supabaseUrl, 'https://custom-project.supabase.co');
    expect(Env.supabasePublishableKey, 'sb_publishable_custom');
    expect(Env.groqApiKey, 'test-groq');
    expect(Env.geminiApiKey, 'test-gemini');
    expect(Env.openrouterApiKey, 'test-openrouter');
  });
}
