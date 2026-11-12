import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/core/theme/app_theme.dart';
import 'package:netlearn/features/assessment/assessment_controller.dart';
import 'package:netlearn/features/assessment/assessment_list_page.dart';
import 'package:netlearn/features/classes/class_controller.dart';
import 'package:netlearn/features/classes/class_models.dart';
import 'package:netlearn/features/dashboard_lecturer/lecturer_assessments_controller.dart';
import 'package:netlearn/features/profile/student_assessment_history_page.dart';
import 'package:netlearn/l10n/app_localizations.dart';

void main() {
  group('Student assessment class isolation', () {
    final sampleQuizzes = <Map<String, dynamic>>[
      {
        'id': 'pretest-a',
        'class_id': 'class-a',
        'assessment_type': 'pretest',
        'title': 'Pretest Kelas A',
      },
      {
        'id': 'posttest-a',
        'class_id': 'class-a',
        'assessment_type': 'posttest',
        'title': 'Posttest Kelas A',
      },
      {
        'id': 'task-a',
        'class_id': 'class-a',
        'assessment_type': 'posttest',
        'instructions': '<!--type:task-->\nKerjakan topologi VLAN',
        'title': 'Tugas VLAN Kelas A',
      },
      {
        'id': 'pretest-b',
        'class_id': 'class-b',
        'assessment_type': 'pretest',
        'title': 'Pretest Kelas B',
      },
      {
        'id': 'task-b',
        'class_id': 'class-b',
        'assessment_type': 'task',
        'title': 'Tugas Routing Kelas B',
      },
      {
        'id': 'pretest-global',
        'class_id': null,
        'assessment_type': 'pretest',
        'title': 'Pretest Global Template',
      },
      {
        'id': 'posttest-global',
        'class_id': null,
        'assessment_type': 'posttest',
        'title': 'Posttest Global Template',
      },
    ];

    test('isolates Class A without leaking Class B or global templates', () {
      final scopedA = resolveScopedClassAssessments(
        quizzes: sampleQuizzes,
        activeClassId: 'class-a',
        isLegacyFallback: false,
      );

      expect(
        scopedA.map((e) => e['id']),
        equals(['pretest-a', 'posttest-a', 'task-a']),
      );
    });

    test('does not pull global templates when Class B has no posttest', () {
      final scopedB = resolveScopedClassAssessments(
        quizzes: sampleQuizzes,
        activeClassId: 'class-b',
        isLegacyFallback: false,
      );

      expect(
        scopedB.map((e) => e['id']),
        equals(['pretest-b', 'task-b']),
      );
    });

    test('respects disabled pretest/posttest while keeping fallback task rows', () {
      final scopedA = resolveScopedClassAssessments(
        quizzes: sampleQuizzes,
        activeClassId: 'class-a',
        isLegacyFallback: false,
        pretestEnabled: false,
        posttestEnabled: false,
      );

      // `task-a` has assessment_type == 'posttest' + <!--type:task-->,
      // so disabling curriculum posttest must NOT hide the custom task.
      expect(scopedA.map((e) => e['id']), equals(['task-a']));
      expect(isTaskAssessmentRow(scopedA.single), isTrue);
    });

    test('legacy fallback mode only includes global class_id=null quizzes', () {
      final scopedLegacy = resolveScopedClassAssessments(
        quizzes: sampleQuizzes,
        activeClassId: kLegacyFallbackClassId,
        isLegacyFallback: true,
      );

      expect(
        scopedLegacy.map((e) => e['id']),
        equals(['pretest-global', 'posttest-global']),
      );
    });
  });

  group('Student assessment history class isolation', () {
    final quizzes = [
      {'id': 'q-a', 'class_id': 'class-a', 'assessment_type': 'pretest'},
      {'id': 'q-b', 'class_id': 'class-b', 'assessment_type': 'pretest'},
      {'id': 'q-g', 'class_id': null, 'assessment_type': 'posttest'},
    ];

    test('keeps only quiz metadata matching active student class', () {
      final forA = filterHistoryQuizzesByClass(
        quizzes: quizzes,
        activeClassId: 'class-a',
        isLegacyFallback: false,
      );
      expect(forA.keys, equals(['q-a']));

      final forB = filterHistoryQuizzesByClass(
        quizzes: quizzes,
        activeClassId: 'class-b',
        isLegacyFallback: false,
      );
      expect(forB.keys, equals(['q-b']));
    });

    test('legacy fallback history only includes global quizzes', () {
      final legacy = filterHistoryQuizzesByClass(
        quizzes: quizzes,
        activeClassId: null,
        isLegacyFallback: true,
      );
      expect(legacy.keys, equals(['q-g']));
    });
  });

  group('Lecturer assessment core vs task isolation', () {
    final rows = [
      {
        'id': 'core-pre-a',
        'class_id': 'class-a',
        'assessment_type': 'pretest',
      },
      {
        'id': 'core-post-a',
        'class_id': 'class-a',
        'assessment_type': 'posttest',
      },
      {
        'id': 'fallback-task-a',
        'class_id': 'class-a',
        'assessment_type': 'posttest',
        'instructions': '<!--type:task-->\nInstruksi tugas',
      },
      {
        'id': 'mod-task-a',
        'class_id': 'class-a',
        'assessment_type': 'posttest',
        'module': 2,
      },
      {
        'id': 'core-pre-b',
        'class_id': 'class-b',
        'assessment_type': 'pretest',
      },
      {
        'id': 'task-b',
        'class_id': 'class-b',
        'assessment_type': 'task',
      },
    ];

    test('core filter excludes custom fallback tasks and other classes', () {
      final coreA = filterLecturerCoreQuizzes(
        quizzes: rows,
        activeClassId: 'class-a',
        isLegacyFallback: false,
      );
      expect(coreA.map((e) => e['id']), equals(['core-pre-a', 'core-post-a']));
    });

    test('task filter captures task & fallback tasks scoped to active class', () {
      final tasksA = filterLecturerTaskQuizzes(
        quizzes: rows,
        activeClassId: 'class-a',
        isLegacyFallback: false,
      );
      expect(
        tasksA.map((e) => e['id']),
        equals(['fallback-task-a', 'mod-task-a']),
      );

      final tasksB = filterLecturerTaskQuizzes(
        quizzes: rows,
        activeClassId: 'class-b',
        isLegacyFallback: false,
      );
      expect(tasksB.map((e) => e['id']), equals(['task-b']));
    });
  });

  testWidgets(
    'AssessmentListPage shows class bar, isolates items by class, and hides empty core heading',
    (tester) async {
      const classA = StudentClass(
        id: 'class-a',
        name: 'Kelas Jaringan A',
        status: 'published',
        semester: 'Ganjil',
      );
      const classB = StudentClass(
        id: 'class-b',
        name: 'Kelas Keamanan B',
        status: 'published',
        semester: 'Genap',
      );

      final container = ProviderContainer(
        overrides: [
          studentClassesProvider.overrideWith((ref) async => [classA, classB]),
          classLearningFlowStatusProvider.overrideWith((ref, _) async => null),
          assessmentListProvider.overrideWith((ref) async {
            final activeId = ref.watch(activeStudentClassIdProvider) ?? 'class-a';
            if (activeId == 'class-b') {
              return const [
                AssessmentListItem(
                  id: 'task-b-1',
                  title: 'Lab Firewall Kelas B',
                  assessmentType: 'task',
                  durationMinutes: 25,
                  deadline: null,
                  status: 'published',
                  unlocked: true,
                  completed: false,
                  score: null,
                ),
              ];
            }
            return const [
              AssessmentListItem(
                id: 'pre-a-1',
                title: 'Pretest Kelas A',
                assessmentType: 'pretest',
                durationMinutes: 30,
                deadline: null,
                status: 'published',
                unlocked: true,
                completed: false,
                score: null,
              ),
            ];
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
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

      expect(find.byKey(const Key('student_my_classes_bar')), findsOneWidget);
      expect(find.text('Kelas Jaringan A'), findsWidgets);
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const Key('student_switch_class_class-a')),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const Key('student_switch_class_class-b')),
            )
            .selected,
        isFalse,
      );
      expect(find.text('Pretest Kelas A'), findsOneWidget);
      expect(find.text('Lab Firewall Kelas B'), findsNothing);
      expect(find.text('Evaluasi Kurikulum'), findsOneWidget);

      await tester.tap(find.byKey(const Key('student_switch_class_class-b')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const Key('student_switch_class_class-b')),
            )
            .selected,
        isTrue,
      );
      expect(find.text('Lab Firewall Kelas B'), findsOneWidget);
      expect(find.text('Pretest Kelas A'), findsNothing);
      expect(find.text('Evaluasi Kurikulum'), findsNothing);
    },
  );
}

