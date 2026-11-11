import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/ar/student_ar_scanner_page.dart';
import 'package:netlearn/l10n/app_localizations.dart';
import 'package:netlearn/shared/widgets/student_bottom_navbar.dart';

// 360dp is the narrowest width the app still supports, so the marker hint and
// the top controls are checked there.
const double narrowWidth = 360;

/// A fake AR view for testing: it needs neither camera permission nor a platform
/// view and never produces a real session, so the scanner stays in its
/// "searching" state.
Widget _fakeArView(BuildContext context) {
  return const ColoredBox(color: Colors.black);
}

Widget _host({required Locale locale, TextScaler textScaler = TextScaler.noScaling}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('id')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      );
    },
    home: StudentArScannerPage.test(
      currentNavIndex: 2,
      testArViewBuilder: (context, onARViewCreated) => _fakeArView(context),
    ),
  );
}

void main() {
  group('StudentArScannerPage', () {
    testWidgets('shows the scanning hint and the student navbar', (tester) async {
      tester.view.physicalSize = const Size(narrowWidth * 3, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StudentBottomNavbar), findsOneWidget);
      expect(
        find.text('Point the camera at one of the NetLearn markers.'),
        findsOneWidget,
      );
    });

    testWidgets('shows the Indonesian hint when the locale is id', (tester) async {
      tester.view.physicalSize = const Size(narrowWidth * 3, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(locale: const Locale('id')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Arahkan kamera ke salah satu marker NetLearn.'),
        findsOneWidget,
      );
    });

    testWidgets('the help button opens the localized scanning guide', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(narrowWidth * 3, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(locale: const Locale('en')));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('How to scan a marker'), findsOneWidget);
      expect(find.textContaining('Print the NetLearn marker cards'), findsOneWidget);
    });

    testWidgets('holds at 360dp with a 1.3 text scale', (tester) async {
      tester.view.physicalSize = const Size(narrowWidth * 3, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(locale: const Locale('id'), textScaler: const TextScaler.linear(1.3)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the rescan control and it is safe to tap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(narrowWidth * 3, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      // In test mode there is no platform view to recreate, so this must be a
      // harmless no-op rather than an exception.
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
