import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/ar/ar_marker_catalog.dart';
import 'package:netlearn/features/ar/ar_object_detail_panel.dart';
import 'package:netlearn/l10n/app_localizations.dart';

// The Modul 1–3 detail panel is a controlled overlay that the scanner opens by
// tapping the 3D model (AR_PRD AR-10): the compact summary card stays visible
// while this "more detailed" layer is on top. These tests pin the localized
// content and the close contract down without any AR/native code — every object
// maps to its own definition/function/extra copy, the module badge matches the
// marker, and closing the panel never calls into the AR session.
Widget _host(Widget child, Locale locale) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const <Locale>[Locale('en'), Locale('id')],
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: Center(child: child)),
  );
}

void _sizeSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

ArMarker _marker(ArMarkerId id) =>
    arMarkerCatalog.firstWhere((m) => m.id == id);

void main() {
  group('ArObjectDetailPanel', () {
    testWidgets('shows the object name, module badge and close button',
        (tester) async {
      _sizeSurface(tester);
      await tester.pumpWidget(_host(
        ArObjectDetailPanel(
          marker: _marker(ArMarkerId.komputer),
          onClose: () {},
        ),
        const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Detailed Information'), findsOneWidget);
      expect(find.text('Desktop Computer'), findsOneWidget);
      expect(find.text('Module 1'), findsOneWidget);
      expect(find.byKey(ArObjectDetailPanel.closeButtonKey), findsOneWidget);
    });

    testWidgets('shows the three localized sections for the computer',
        (tester) async {
      _sizeSurface(tester);
      await tester.pumpWidget(_host(
        ArObjectDetailPanel(
          marker: _marker(ArMarkerId.komputer),
          onClose: () {},
        ),
        const Locale('en'),
      ));
      await tester.pumpAndSettle();

      // Generic section labels plus the computer's own extra label.
      expect(find.text('Definition'), findsOneWidget);
      expect(find.text('Function'), findsOneWidget);
      expect(find.text('Example Activities'), findsOneWidget);
      // Each section carries its own localized copy.
      expect(find.textContaining('end device'), findsOneWidget);
      expect(find.textContaining('source or destination'), findsOneWidget);
      expect(find.textContaining('streaming video'), findsOneWidget);
    });

    testWidgets('hub copy highlights the difference from a switch',
        (tester) async {
      _sizeSurface(tester);
      await tester.pumpWidget(_host(
        ArObjectDetailPanel(
          marker: _marker(ArMarkerId.hub),
          onClose: () {},
        ),
        const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Difference from a Switch'), findsOneWidget);
      expect(find.textContaining('broadcasts data to all devices'),
          findsOneWidget);
    });

    testWidgets('switch uses the "How It Works" extra section', (tester) async {
      _sizeSurface(tester);
      await tester.pumpWidget(_host(
        ArObjectDetailPanel(
          marker: _marker(ArMarkerId.switchDevice),
          onClose: () {},
        ),
        const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('How It Works'), findsOneWidget);
      expect(find.textContaining('MAC table'), findsOneWidget);
    });

    testWidgets('topology panel covers advantages and limitations',
        (tester) async {
      _sizeSurface(tester);
      await tester.pumpWidget(_host(
        ArObjectDetailPanel(
          marker: _marker(ArMarkerId.topologi),
          onClose: () {},
        ),
        const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Advantages and Limitations'), findsOneWidget);
      expect(find.textContaining('single point of failure'), findsOneWidget);
    });

    testWidgets('switches to Indonesian copy with the id locale', (tester) async {
      _sizeSurface(tester);
      await tester.pumpWidget(_host(
        ArObjectDetailPanel(
          marker: _marker(ArMarkerId.router),
          onClose: () {},
        ),
        const Locale('id'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Informasi Lengkap'), findsOneWidget);
      expect(find.text('Router'), findsOneWidget);
      expect(find.text('Modul 2'), findsOneWidget);
      expect(find.text('Pengertian'), findsOneWidget);
      expect(find.text('Fungsi'), findsOneWidget);
      expect(find.text('Cara Kerja'), findsOneWidget);
      expect(find.textContaining('tabel routing'), findsOneWidget);
    });

    testWidgets('close button invokes onClose without touching the scene',
        (tester) async {
      _sizeSurface(tester);
      var closed = false;
      await tester.pumpWidget(_host(
        ArObjectDetailPanel(
          marker: _marker(ArMarkerId.komputer),
          onClose: () => closed = true,
        ),
        const Locale('en'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ArObjectDetailPanel.closeButtonKey));
      await tester.pumpAndSettle();
      expect(closed, isTrue);
    });

    testWidgets('long copy scrolls instead of overflowing the screen',
        (tester) async {
      // A small surface keeps the panel under its 60%-height cap, so the copy
      // must scroll inside the card rather than paint beyond it.
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(
        ArObjectDetailPanel(
          marker: _marker(ArMarkerId.komputer),
          onClose: () {},
        ),
        const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final Scrollable scrollable = tester.widget<Scrollable>(
        find.descendant(
          of: find.byType(ArObjectDetailPanel),
          matching: find.byType(Scrollable),
        ),
      );
      expect(scrollable.axisDirection, AxisDirection.down);
      // Only one Scrollable: the panel's own, nothing stacked on top.
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}