import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/core/theme/app_theme.dart';
import 'package:netlearn/features/classes/class_controller.dart';
import 'package:netlearn/features/classes/class_leaderboard_page.dart';
import 'package:netlearn/features/classes/class_models.dart';
import 'package:netlearn/features/subnet_drill/subnet_drill_leaderboard.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_leaderboard_service.dart';
import 'package:netlearn/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ClassLeaderboardPage', () {
    testWidgets('Overall tab renders podium with top 3 students like Subnet Drill',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const entries = [
        ClassLeaderboardEntry(
          rankPosition: 1,
          studentId: 's1',
          displayName: 'Andi Juara',
          cohort: 'final',
          weightedScore: 98,
          unweightedAvg: 98,
          completedAssessments: 2,
          totalRankedAssessments: 2,
          policyVersion: 1,
          isMe: false,
        ),
        ClassLeaderboardEntry(
          rankPosition: 2,
          studentId: 's2',
          displayName: 'Budi Kedua',
          cohort: 'final',
          weightedScore: 91,
          unweightedAvg: 91,
          completedAssessments: 2,
          totalRankedAssessments: 2,
          policyVersion: 1,
          isMe: true,
        ),
        ClassLeaderboardEntry(
          rankPosition: 3,
          studentId: 's3',
          displayName: 'Citra Ketiga',
          cohort: 'in_progress',
          weightedScore: 84,
          unweightedAvg: 84,
          completedAssessments: 1,
          totalRankedAssessments: 2,
          policyVersion: 1,
          isMe: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            classLeaderboardProvider('class-a').overrideWith(
              (ref) async => entries,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('id'),
            home: const ClassLeaderboardPage(classId: 'class-a'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final podiumFinder = find.byKey(const Key('overall_leaderboard_podium'));
      expect(podiumFinder, findsOneWidget);
      expect(find.descendant(of: podiumFinder, matching: find.text('👑')), findsOneWidget);
      expect(find.descendant(of: podiumFinder, matching: find.text('🥈')), findsOneWidget);
      expect(find.descendant(of: podiumFinder, matching: find.text('🥉')), findsOneWidget);
      expect(find.descendant(of: podiumFinder, matching: find.text('98 pts')), findsOneWidget);
      expect(find.descendant(of: podiumFinder, matching: find.text('91 pts')), findsOneWidget);
      expect(find.descendant(of: podiumFinder, matching: find.text('84 pts')), findsOneWidget);
    });

    testWidgets('Subnet Drill and Virtual Lab tabs stay isolated to requested classId',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await SubnetDrillLeaderboardService.saveScore(
        classId: 'class-a',
        studentId: 'u1',
        studentName: 'Siswa Kelas A',
        score: 90,
        maxStreak: 4,
      );
      await VirtualLabLeaderboardService.saveScore(
        classId: 'class-a',
        studentId: 'u1',
        studentName: 'Siswa Kelas A',
        materialId: 'module_1_p2p',
        materialTitle: 'Modul 1: P2P',
        preset: 'p2p',
        score: 96,
        completedTasks: 3,
        totalTasks: 3,
        isPassed: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            classLeaderboardProvider('class-b').overrideWith(
              (ref) async => const [],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('id'),
            home: const ClassLeaderboardPage(classId: 'class-b'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Subnet Drill tab in Class B -> must be empty
      await tester.tap(find.byKey(const Key('leaderboard_tab_subnet_drill')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('subnet_drill_leaderboard_empty')), findsOneWidget);
      expect(find.text('Siswa Kelas A'), findsNothing);

      // Switch to Virtual Lab tab in Class B -> must be empty
      await tester.tap(find.byKey(const Key('leaderboard_tab_virtual_lab')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('virtual_lab_leaderboard_empty')), findsOneWidget);
      expect(find.text('Siswa Kelas A'), findsNothing);
    });
  });
}

