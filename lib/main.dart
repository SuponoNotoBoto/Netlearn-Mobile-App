import 'package:flutter/material.dart';
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
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey.isNotEmpty
          ? Env.supabaseAnonKey
          : Env.supabasePublishableKey,
    );
  } catch (e) {
    debugPrint('Supabase init warning: $e');
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
