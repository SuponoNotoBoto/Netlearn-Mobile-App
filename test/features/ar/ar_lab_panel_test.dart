import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/ar/ar_lab_panel.dart';
import 'package:netlearn/features/ar/ar_lab_scene.dart';
import 'package:netlearn/features/ar/ip_simulation.dart';
import 'package:netlearn/l10n/app_localizations.dart';

// The Modul 4 panel is a compact, controlled overlay: the 3D lab is the scene,
// so the panel only edits one computer at a time and reports the engine result.
// These tests pin that contract down without any AR/native code — selection
// switches the edited fields, per-computer values persist, a valid test reports
// success, an invalid one reports the specific failure, and reset restores the
// defaults. The scanner relies on onTestResult to animate the packet only on
// success.
Widget _host(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: const <Locale>[Locale('en'), Locale('id')],
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

Finder _field(Key key) => find.descendant(
      of: find.byKey(key),
      matching: find.byType(TextFormField),
    );

String _fieldText(WidgetTester tester, Key key) =>
    tester.widget<TextFormField>(_field(key)).controller!.text;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void _sizeSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

class _Harness extends StatefulWidget {
  final List<IpConnectionResult> results;
  final List<Object?> resets;

  const _Harness({required this.results, required this.resets});

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  ArLabDevice _selected = ArLabDevice.pcA;

  @override
  Widget build(BuildContext context) {
    return ArLabPanel(
      selectedDevice: _selected,
      onSelect: (ArLabDevice device) => setState(() => _selected = device),
      onTestResult: widget.results.add,
      onReset: () => widget.resets.add(Object()),
      onClose: () {},
    );
  }
}

void main() {
  group('ArLabPanel', () {
    testWidgets('shows Computer A defaults first', (tester) async {
      _sizeSurface(tester);
      await tester.pumpWidget(
        _host(_Harness(results: <IpConnectionResult>[], resets: <Object?>[])),
      );
      await tester.pumpAndSettle();

      expect(_fieldText(tester, ArLabPanel.ipFieldKey), ArLabPanel.defaultIpA);
      expect(
          _fieldText(tester, ArLabPanel.maskFieldKey), ArLabPanel.defaultMaskA);
    });

    testWidgets('the selector switches which computer is edited', (tester) async {
      _sizeSurface(tester);
      await tester.pumpWidget(
        _host(_Harness(results: <IpConnectionResult>[], resets: <Object?>[])),
      );
      await tester.pumpAndSettle();

      await _tap(tester, find.byKey(ArLabPanel.chipBKey));

      expect(tester.takeException(), isNull);
      expect(_fieldText(tester, ArLabPanel.ipFieldKey), ArLabPanel.defaultIpB);
      expect(
          _fieldText(tester, ArLabPanel.maskFieldKey), ArLabPanel.defaultMaskB);
    });

    testWidgets('per-computer edits persist across selection', (tester) async {
      _sizeSurface(tester);
      await tester.pumpWidget(
        _host(_Harness(results: <IpConnectionResult>[], resets: <Object?>[])),
      );
      await tester.pumpAndSettle();

      await tester.enterText(_field(ArLabPanel.ipFieldKey), '10.0.0.7');
      await tester.pumpAndSettle();

      // Switch to B and back; A's edit must survive.
      await _tap(tester, find.byKey(ArLabPanel.chipBKey));
      await _tap(tester, find.byKey(ArLabPanel.chipAKey));

      expect(_fieldText(tester, ArLabPanel.ipFieldKey), '10.0.0.7');
    });

    testWidgets('a valid test reports success', (tester) async {
      _sizeSurface(tester);
      final List<IpConnectionResult> results = <IpConnectionResult>[];
      await tester.pumpWidget(
        _host(_Harness(results: results, resets: <Object?>[])),
      );
      await tester.pumpAndSettle();

      await _tap(tester, find.byKey(ArLabPanel.testButtonKey));

      expect(results, hasLength(1));
      expect(results.single.success, isTrue);
      expect(find.text('Connection Succeeded'), findsOneWidget);
    });

    testWidgets('collapses the form after a test and reopens on Edit', (tester) async {
      _sizeSurface(tester);
      final List<IpConnectionResult> results = <IpConnectionResult>[];
      await tester.pumpWidget(
        _host(_Harness(results: results, resets: <Object?>[])),
      );
      await tester.pumpAndSettle();

      await _tap(tester, find.byKey(ArLabPanel.testButtonKey));

      // The form is hidden after testing so the result and the 3D lab are
      // unobstructed, and an "Edit" button reopens it.
      expect(find.byKey(ArLabPanel.testButtonKey), findsNothing);
      expect(find.byKey(ArLabPanel.ipFieldKey), findsNothing);
      expect(find.byKey(ArLabPanel.editButtonKey), findsOneWidget);
      expect(find.text('Connection Succeeded'), findsOneWidget);

      await _tap(tester, find.byKey(ArLabPanel.editButtonKey));
      expect(find.byKey(ArLabPanel.testButtonKey), findsOneWidget);
      expect(find.byKey(ArLabPanel.editButtonKey), findsNothing);
      expect(_fieldText(tester, ArLabPanel.ipFieldKey), ArLabPanel.defaultIpA);
    });

    testWidgets('an invalid address reports the specific failure', (tester) async {
      _sizeSurface(tester);
      final List<IpConnectionResult> results = <IpConnectionResult>[];
      await tester.pumpWidget(
        _host(_Harness(results: results, resets: <Object?>[])),
      );
      await tester.pumpAndSettle();

      await tester.enterText(_field(ArLabPanel.ipFieldKey), '300.0.0.1');
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(ArLabPanel.testButtonKey));

      expect(results, hasLength(1));
      expect(results.single.success, isFalse);
      expect(results.single.failure, IpSimulationFailure.invalidIpA);
      expect(find.text('Connection Failed'), findsOneWidget);
    });

    testWidgets('reset restores defaults and notifies the scanner', (tester) async {
      _sizeSurface(tester);
      final List<Object?> resets = <Object?>[];
      await tester.pumpWidget(
        _host(_Harness(results: <IpConnectionResult>[], resets: resets)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(_field(ArLabPanel.ipFieldKey), '10.0.0.7');
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(ArLabPanel.resetButtonKey));

      expect(resets, hasLength(1));
      expect(_fieldText(tester, ArLabPanel.ipFieldKey), ArLabPanel.defaultIpA);
      expect(find.text('Connection Succeeded'), findsNothing);
    });
  });
}
