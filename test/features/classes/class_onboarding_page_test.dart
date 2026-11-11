import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/core/theme/app_theme.dart';
import 'package:netlearn/features/classes/class_onboarding_page.dart';
import 'package:netlearn/l10n/app_localizations.dart';
import 'package:netlearn/shared/widgets/nl_netlearn_logo.dart';

Widget _wrapWithLocale({
  required Locale locale,
  required Widget child,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('id')],
      home: Scaffold(body: SafeArea(child: child)),
    ),
  );
}

void main() {
  testWidgets(
    'Student join class displays standard NlNetLearnLogo without hub fallback icon',
    (tester) async {
      await tester.pumpWidget(
        _wrapWithLocale(
          locale: const Locale('id'),
          child: const ClassOnboardingView(
            role: ClassOnboardingRole.student,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final logoFinder = find.byType(NlNetLearnLogo);
      expect(logoFinder, findsOneWidget);
      final logo = tester.widget<NlNetLearnLogo>(logoFinder);
      expect(logo.inverse, isTrue);
      expect(find.byIcon(Icons.hub_rounded), findsNothing);
    },
  );

  testWidgets(
    'Lecturer create class uses standard NlNetLearnLogo and Indonesian form labels in id locale',
    (tester) async {
      await tester.pumpWidget(
        _wrapWithLocale(
          locale: const Locale('id'),
          child: ClassOnboardingView(
            role: ClassOnboardingRole.lecturer,
            onCreateOverride: ({
              required String name,
              String? description,
              String? semester,
              required bool useTemplate,
              required bool pretestEnabled,
              required bool posttestEnabled,
              required bool leaderboardEnabled,
              String? firstModuleTitle,
            }) async {
              return (classId: 'cls-1', code: 'NET123');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final logoFinder = find.byType(NlNetLearnLogo);
      expect(logoFinder, findsOneWidget);
      expect(tester.widget<NlNetLearnLogo>(logoFinder).inverse, isTrue);
      expect(find.byIcon(Icons.hub_rounded), findsNothing);

      expect(find.text('Gunakan Template NetLearn'), findsOneWidget);
      expect(find.text('Buat Kelas Kustom'), findsOneWidget);
      expect(find.text('Use NetLearn Template'), findsNothing);
      expect(find.text('Create Custom Class'), findsNothing);

      final semesterField = tester.widget<TextField>(
        find.byKey(const Key('create_class_semester_field')),
      );
      expect(semesterField.controller?.text, 'Ganjil 2026/2027');

      await tester.enterText(
        find.byKey(const Key('create_class_name_field')),
        'Jaringan Kustom',
      );
      await tester.ensureVisible(
        find.byKey(const Key('create_class_mode_custom')),
      );
      await tester.tap(find.byKey(const Key('create_class_mode_custom')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('create_class_submit_button')),
      );
      await tester.tap(find.byKey(const Key('create_class_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Jaringan Kustom (Kelas Kustom)'), findsOneWidget);
    },
  );

  testWidgets(
    'Lecturer create class uses English defaults and template origin label in en locale',
    (tester) async {
      await tester.pumpWidget(
        _wrapWithLocale(
          locale: const Locale('en'),
          child: ClassOnboardingView(
            role: ClassOnboardingRole.lecturer,
            onCreateOverride: ({
              required String name,
              String? description,
              String? semester,
              required bool useTemplate,
              required bool pretestEnabled,
              required bool posttestEnabled,
              required bool leaderboardEnabled,
              String? firstModuleTitle,
            }) async {
              return (classId: 'cls-2', code: 'NET999');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Use NetLearn Template'), findsOneWidget);
      expect(find.text('Create Custom Class'), findsOneWidget);

      final semesterField = tester.widget<TextField>(
        find.byKey(const Key('create_class_semester_field')),
      );
      expect(semesterField.controller?.text, 'Odd 2026/2027');
      expect(find.text('Ganjil 2026/2027'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('create_class_name_field')),
        'Net Course',
      );
      await tester.ensureVisible(
        find.byKey(const Key('create_class_submit_button')),
      );
      await tester.tap(find.byKey(const Key('create_class_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Net Course (NetLearn Template)'), findsOneWidget);
    },
  );
}

