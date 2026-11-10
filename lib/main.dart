import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/env.dart';
import 'core/localization/language_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env", isOptional: true);
  } catch (e) {
    debugPrint('Dotenv load warning: $e');
  }

  bool isSupabaseReady = false;
  String? initError;

  try {
    final supabaseUrl = Env.supabaseUrl;
    final supabaseKey = Env.supabasePublishableKey.isNotEmpty
        ? Env.supabasePublishableKey
        : Env.supabaseAnonKey;

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
      publishableKey: supabaseKey,
    );
    isSupabaseReady = true;
  } catch (e, st) {
    initError = e.toString();
    debugPrint('Supabase initialize error: $e\n$st');
  }

  if (!isSupabaseReady) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Gagal Menghubungkan ke Server',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    initError ?? 'Terjadi kesalahan saat inisialisasi Supabase.',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => main(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(const ProviderScope(child: NetLearnApp()));
}

class NetLearnApp extends ConsumerStatefulWidget {
  const NetLearnApp({super.key});

  @override
  ConsumerState<NetLearnApp> createState() => _NetLearnAppState();
}

class _NetLearnAppState extends ConsumerState<NetLearnApp> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref.read(languageProvider.notifier).initialize();
      await ref.read(themeModeProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(languageProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'NetLearn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('id'),
      ],
      routerConfig: router,
    );
  }
}
