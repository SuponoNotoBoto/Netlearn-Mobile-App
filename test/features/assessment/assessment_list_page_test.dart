import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/core/theme/app_theme.dart';
import 'package:netlearn/features/assessment/assessment_controller.dart';
import 'package:netlearn/features/assessment/assessment_list_page.dart';
import 'package:netlearn/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'AssessmentListPage renders completed Curriculum Evaluation card safely when score is null',
    (tester) async {
      const items = [
        AssessmentListItem(
          id: 'pretest-1',
          title: 'Pretest Jaringan',
          assessmentType: 'pretest',
          durationMinutes: 30,
          deadline: null,
          status: 'published',
          unlocked: true,
          completed: true,
          score: null,
        ),
        AssessmentListItem(
          id: 'posttest-1',
          title: 'Posttest Jaringan',
          assessmentType: 'posttest',
          durationMinutes: 30,
          deadline: null,
          status: 'published',
          unlocked: true,
          completed: true,
          score: 88,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assessmentListProvider.overrideWith((ref) async => items),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AssessmentListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Evaluasi Kurikulum'), findsOneWidget);
      expect(find.text('Pretest Jaringan'), findsOneWidget);
      expect(find.text('Posttest Jaringan'), findsOneWidget);
      expect(find.text('88%'), findsOneWidget);
    },
  );
}

