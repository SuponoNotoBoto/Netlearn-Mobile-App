// ============================================================================
// MODULE: Application Entry Point & Bootstrap
// DESCRIPTION: Titik masuk utama aplikasi NetLearn Mobile. Mengelola pemuatan
//              environment variable (.env), inisialisasi koneksi Supabase,
//              fallback error screen, serta konfigurasi global MaterialApp.
// ============================================================================

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

// ---------------------------------------------------------------------------
// SECTION: Main Bootstrap Sequence
// ---------------------------------------------------------------------------

/// [main]
///
/// Menjalankan urutan inisialisasi awal aplikasi sebelum merender widget tree:
/// 1. Memastikan binding engine Flutter siap.
/// 2. Memuat konfigurasi `.env` secara opsional agar tidak memicu crash jika
///    dijalankan melalui parameter `--dart-define`.
/// 3. Menginisialisasi client Supabase beserta mekanisme fallback layar error
///    apabila koneksi server atau kredensial belum dikonfigurasi.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Memuat file .env lokal untuk kredensial Supabase dan API key AI.
  try {
    await dotenv.load(fileName: ".env", isOptional: true);
  } catch (e) {
    debugPrint('Dotenv load warning: $e');
  }

  bool isSupabaseReady = false;
  String? initError;

  // Inisialisasi instance tunggal (singleton) Supabase Client.
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

  // Fallback UI: Menampilkan layar diagnostik ramah pengguna jika gagal
  // terhubung ke backend, mencegah layar putih (blank screen).
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

  // Menjalankan aplikasi utama di dalam cakupan state management Riverpod.
  runApp(const ProviderScope(child: NetLearnApp()));
}

// ---------------------------------------------------------------------------
// SECTION: Root Application Widget
// ---------------------------------------------------------------------------

/// [NetLearnApp]
///
/// Widget akar (root) aplikasi yang mengintegrasikan konfigurasi router
/// ([GoRouter]), lokalisasi dwibahasa (Indonesia & Inggris), serta tema
/// tampilan (Light & Dark Mode) secara reaktif melalui Riverpod.
class NetLearnApp extends ConsumerStatefulWidget {
  const NetLearnApp({super.key});

  @override
  ConsumerState<NetLearnApp> createState() => _NetLearnAppState();
}

class _NetLearnAppState extends ConsumerState<NetLearnApp> {
  @override
  void initState() {
    super.initState();

    // Memulihkan preferensi bahasa dan tema yang tersimpan di penyimpanan lokal
    // segera setelah frame pertama diinisialisasi.
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
