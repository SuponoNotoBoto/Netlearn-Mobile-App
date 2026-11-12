import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/core/theme/app_theme.dart';
import 'package:netlearn/features/dashboard_lecturer/notification_controller.dart';
import 'package:netlearn/features/notifications/notification_widgets.dart';
import 'package:netlearn/l10n/app_localizations.dart';
import 'package:netlearn/shared/models/reminder_model.dart';
import 'package:netlearn/shared/models/student_model.dart';

void main() {
  group('mergeClassWithMissingCoreQuizzes', () {
    test('uses class quizzes and adds only missing core fallback templates', () {
      final classRows = [
        {'id': 'c-pre', 'assessment_type': 'pretest', 'title': 'Pretest Kelas A'},
        {'id': 'c-task', 'assessment_type': 'task', 'title': 'Tugas 1'},
      ];
      final globalRows = [
        {'id': 'g-pre', 'assessment_type': 'pretest', 'title': 'Pretest Global'},
        {'id': 'g-post', 'assessment_type': 'posttest', 'title': 'Posttest Global'},
        {'id': 'g-task', 'assessment_type': 'task', 'title': 'Tugas Global'},
      ];

      final merged = mergeClassWithMissingCoreQuizzes(classRows, globalRows);
      expect(merged.map((r) => r['id']).toList(), [
        'c-pre',
        'c-task',
        'g-post',
      ]);
    });

    test('does not append global rows when class already defines pretest and posttest', () {
      final classRows = [
        {'id': 'c-pre', 'assessment_type': 'pretest'},
        {'id': 'c-post', 'assessment_type': 'posttest'},
      ];
      final globalRows = [
        {'id': 'g-pre', 'assessment_type': 'pretest'},
        {'id': 'g-post', 'assessment_type': 'posttest'},
      ];

      final merged = mergeClassWithMissingCoreQuizzes(classRows, globalRows);
      expect(merged.map((r) => r['id']).toList(), ['c-pre', 'c-post']);
    });
  });

  group('buildStudentDeadlineReminders', () {
    final now = DateTime(2026, 11, 12, 10, 0);

    test('deduplicates duplicate core and task rows and propagates className', () {
      final upcomingIso = now.add(const Duration(hours: 6)).toIso8601String();
      final quizRows = [
        {
          'id': 'pre-1',
          'title': 'Pretest',
          'assessment_type': 'pretest',
          'deadline': null,
          'materials': null,
        },
        {
          'id': 'pre-2',
          'title': 'Pretest Duplikat',
          'assessment_type': 'pretest',
          'deadline': null,
          'materials': null,
        },
        {
          'id': 'post-1',
          'title': 'Posttest',
          'assessment_type': 'posttest',
          'deadline': null,
          'materials': null,
        },
        {
          'id': 'task-1',
          'title': 'Tugas Subnetting',
          'assessment_type': 'task',
          'deadline': upcomingIso,
          'materials': {'title': 'Subnetting'},
        },
        {
          'id': 'task-2',
          'title': 'Tugas Subnetting',
          'assessment_type': 'task',
          'deadline': upcomingIso,
          'materials': {'title': 'Subnetting'},
        },
      ];

      final reminders = buildStudentDeadlineReminders(
        quizRows,
        <String>{},
        now,
        className: 'Jaringan Komputer A',
      );

      expect(reminders.map((r) => r.id).toList(), ['pre-1', 'post-1', 'task-1']);
      expect(reminders.every((r) => r.className == 'Jaringan Komputer A'), isTrue);
      expect(reminders.first.subtitle(true), 'Pretest · Kelas: Jaringan Komputer A');
      expect(reminders.first.subtitle(false), 'Pretest · Class: Jaringan Komputer A');
    });

    test('skips core assessments already completed via flow flags or disabled', () {
      final quizRows = [
        {
          'id': 'pre-1',
          'title': 'Pretest',
          'assessment_type': 'pretest',
          'deadline': null,
          'materials': null,
        },
        {
          'id': 'pre-duplicate',
          'title': 'Pretest Copy',
          'assessment_type': 'pretest',
          'deadline': null,
          'materials': null,
        },
        {
          'id': 'post-1',
          'title': 'Posttest',
          'assessment_type': 'posttest',
          'deadline': null,
          'materials': null,
        },
      ];

      // Completed pretest by quiz ID should suppress duplicate copy too.
      final afterPretestAttempt = buildStudentDeadlineReminders(
        quizRows,
        {'pre-1'},
        now,
        className: 'Kelas B',
      );
      expect(afterPretestAttempt.map((r) => r.id).toList(), ['post-1']);

      // Flow flags: pretest completed, posttest disabled -> empty reminders.
      final nonePending = buildStudentDeadlineReminders(
        quizRows,
        <String>{},
        now,
        className: 'Kelas B',
        pretestCompleted: true,
        posttestEnabled: false,
      );
      expect(nonePending, isEmpty);
    });
  });

  group('buildLecturerMissingAssessmentReminders', () {
    test('attaches active className and skips students with all published assessments done', () {
      const students = [
        StudentModel(
          id: 's1',
          name: 'Budi',
          identityNumber: '22001',
          isActive: true,
          pretestScore: null,
          posttestScore: 90,
        ),
        StudentModel(
          id: 's2',
          name: 'Sari',
          identityNumber: '22002',
          isActive: true,
          pretestScore: 80,
          posttestScore: 95,
        ),
      ];

      final reminders = buildLecturerMissingAssessmentReminders(
        students,
        {'pretest', 'posttest'},
        className: 'TI-2A',
      );

      expect(reminders, hasLength(1));
      expect(reminders.first.studentId, 's1');
      expect(reminders.first.assessmentTypes, ['pretest']);
      expect(reminders.first.className, 'TI-2A');
    });
  });

  testWidgets('ReminderCard displays class indicator when className is set', (tester) async {
    const withClass = ReminderItem(
      id: 'rem-1',
      title: 'Pretest Jaringan',
      assessmentType: 'pretest',
      reason: ReminderReason.notCompleted,
      className: 'TI-3B',
    );
    const withoutClass = ReminderItem(
      id: 'rem-2',
      title: 'Posttest Jaringan',
      assessmentType: 'posttest',
      reason: ReminderReason.notCompleted,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView(
            children: [
              ReminderCard(reminder: withClass, onTap: () {}),
              ReminderCard(reminder: withoutClass, onTap: () {}),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Kelas: TI-3B'), findsOneWidget);
    expect(find.byIcon(Icons.class_outlined), findsOneWidget);
  });
}

