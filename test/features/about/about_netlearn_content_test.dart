import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/core/theme/app_theme.dart';
import 'package:netlearn/features/about/about_netlearn_content.dart';
import 'package:netlearn/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'AboutNetLearnContent hides Manual Book download card while keeping AR Marker and Material Book cards',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AboutNetLearnContent(
                openDownload: (_) async {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('about-download-markers')),
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('about-download-markers')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('about-download-materials')),
        200,
        scrollable: find.byType(Scrollable),
      );
      expect(
        find.byKey(const ValueKey('about-download-materials')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('about-download-manuals')),
        findsNothing,
      );
    },
  );
}

