import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/assessment/assessment_completed_dialog.dart';
import 'package:netlearn/features/assessment/assessment_controller.dart';
import 'package:netlearn/features/assessment/assessment_result_page.dart';
import 'package:netlearn/l10n/app_localizations.dart';

void main() {
  group('Custom Quiz Title Adaptation', () {
    testWidgets('AssessmentResultView displays custom quiz title in completion message without pretest/posttest', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('id'),
          home: Scaffold(
            body: AssessmentResultView(
              isLoading: false,
              errorMessage: null,
              title: 'Kuis Subnetting CIDR',
              assessmentType: 'custom_quiz_1',
              score: 85,
              correctCount: 8,
              wrongCount: 2,
              totalQuestions: 10,
              passed: true,
              onRetry: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Memastikan judul kuis muncul dan tidak ada teks "Post Test telah selesai"
      expect(find.text('Kuis Subnetting CIDR'), findsWidgets);
      expect(find.text('Kuis Subnetting CIDR telah berhasil diselesaikan.'), findsOneWidget);
      expect(find.textContaining('Post Test'), findsNothing);
      expect(find.textContaining('Pretest'), findsNothing);
    });

    testWidgets('showAssessmentCompletedDialog adapts to custom quiz title in dialog', (tester) async {
      const customItem = AssessmentListItem(
        id: 'quiz-abc',
        title: 'Kuis Routing Dinamis',
        assessmentType: 'task',
        durationMinutes: 15,
        deadline: null,
        status: 'completed',
        unlocked: true,
        completed: true,
        score: 90,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('id'),
          home: Builder(
            builder: (context) {
              return Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    final l10n = AppLocalizations.of(context)!;
                    showAssessmentCompletedDialog(context, customItem, l10n);
                  },
                ),
              );
            },
          ),
        ),
      );

      // Tap trigger button
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Dialog harus menampilkan judul kuis
      expect(find.text('Kuis Routing Dinamis'), findsWidgets);
      expect(find.text('Kuis Routing Dinamis sudah Anda selesaikan.'), findsOneWidget);
      expect(find.textContaining('Post Test'), findsNothing);
    });
  });
}

