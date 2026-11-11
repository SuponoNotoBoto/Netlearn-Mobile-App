import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/core/constants/env.dart';

void main() {
  tearDown(() => dotenv.clean());

  test('Env provides public Supabase fallback when .env entries are empty', () {
    dotenv.loadFromString(
      envString: '''
SUPABASE_URL=
SUPABASE_PUBLISHABLE_KEY=
''',
      isOptional: true,
    );

    expect(Env.supabaseUrl, startsWith('https://'));
    expect(Uri.parse(Env.supabaseUrl).host, isNotEmpty);
    expect(Env.supabasePublishableKey, isNotEmpty);
  });

  test('Env prioritizes non-empty values from dotenv over fallback', () {
    dotenv.loadFromString(
      envString: '''
SUPABASE_URL=https://custom-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_custom
GROQ_API_KEY=test-groq
''',
      isOptional: true,
    );

    expect(Env.supabaseUrl, 'https://custom-project.supabase.co');
    expect(Env.supabasePublishableKey, 'sb_publishable_custom');
    expect(Env.groqApiKey, 'test-groq');
  });
}
