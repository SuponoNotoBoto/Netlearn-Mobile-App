import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/core/localization/language_controller.dart';
import 'package:netlearn/features/materials/material_lab_binding.dart';
import 'package:netlearn/features/materials/widgets/material_lab_card.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_mission.dart';

class _TestLanguageController extends LanguageController {
  final Locale _initial;
  _TestLanguageController(this._initial);

  @override
  Locale build() => _initial;
}

void main() {
  Widget buildTestableWidget(Widget child, [String lang = 'id']) {
    return ProviderScope(
      key: UniqueKey(),
      overrides: [
        languageProvider.overrideWith(() => _TestLanguageController(Locale(lang))),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  testWidgets('MaterialLabCard renders title, badge, instructions, and CTA button in Indonesian',
      (tester) async {
    const binding = MaterialLabBinding(
      preset: 'star',
      title: 'Praktikum Topologi Star LAN',
      description: 'Eksperimen 1 switch dan 3 PC dalam satu subnet',
      instructions: [
        'Hubungkan setiap PC ke port switch.',
        'Atur konfigurasi IP static.',
      ],
    );

    await tester.pumpWidget(buildTestableWidget(const MaterialLabCard(binding: binding), 'id'));
    await tester.pumpAndSettle();

    expect(find.text('PRAKTIKUM VIRTUAL LAB'), findsOneWidget);
    expect(find.text('Topologi Star'), findsOneWidget);
    expect(find.text('Praktikum Topologi Star LAN'), findsOneWidget);
    expect(find.text('Eksperimen 1 switch dan 3 PC dalam satu subnet'), findsOneWidget);
    expect(find.text('Panduan Tugas Lab:'), findsOneWidget);
    expect(find.text('Hubungkan setiap PC ke port switch.'), findsOneWidget);
    expect(find.text('Buka di Virtual Lab'), findsOneWidget);
  });

  testWidgets('MaterialLabCard renders English text when language is English',
      (tester) async {
    const binding = MaterialLabBinding(
      preset: 'star',
      title: 'Praktikum Topologi Star LAN',
      description: 'Eksperimen 1 switch dan 3 PC dalam satu subnet',
      instructions: [
        'Hubungkan setiap PC ke port switch.',
        'Atur konfigurasi IP static.',
      ],
    );

    await tester.pumpWidget(buildTestableWidget(const MaterialLabCard(binding: binding), 'en'));
    await tester.pumpAndSettle();

    expect(find.text('VIRTUAL LAB PRACTICUM'), findsOneWidget);
    expect(find.text('Star Topology'), findsOneWidget);
    expect(find.text('Star Topology & Switch LAN Practical'), findsOneWidget);
    expect(find.text('Lab Task Guide:'), findsOneWidget);
    expect(find.text('Open in Virtual Lab'), findsOneWidget);
  });

  testWidgets('MaterialLabCard renders completed state and score in Indonesian',
      (tester) async {
    const binding = MaterialLabBinding(
      preset: 'star',
      materialId: 'modul_2',
      title: 'Praktikum Topologi Star LAN',
    );

    final dummySubmission = VirtualLabMissionSubmission(
      id: 'sub_test',
      userId: 'user_123',
      materialId: 'modul_2',
      materialTitle: 'Praktikum Topologi Star LAN',
      preset: 'star',
      score: 100,
      isPassed: true,
      submittedAt: DateTime(2026, 11, 8, 17, 30),
      completedTaskIds: const ['t1', 't2', 't3', 't4'],
      totalTasks: 4,
    );

    await tester.pumpWidget(buildTestableWidget(
      MaterialLabCard(
        binding: binding,
        submission: dummySubmission,
      ),
      'id',
    ));
    await tester.pumpAndSettle();

    expect(find.text('PRAKTIKUM SELESAI'), findsOneWidget);
    expect(find.text('Skor: 100/100'), findsOneWidget);
    expect(find.text('Evaluasi Lulus: Skor 100/100'), findsOneWidget);
    expect(find.text('Buka Kembali Lab'), findsOneWidget);
  });

  testWidgets('MaterialLabCard renders completed state and score in English',
      (tester) async {
    const binding = MaterialLabBinding(
      preset: 'star',
      materialId: 'modul_2',
      title: 'Praktikum Topologi Star LAN',
    );

    final dummySubmission = VirtualLabMissionSubmission(
      id: 'sub_test',
      userId: 'user_123',
      materialId: 'modul_2',
      materialTitle: 'Praktikum Topologi Star LAN',
      preset: 'star',
      score: 100,
      isPassed: true,
      submittedAt: DateTime(2026, 11, 8, 17, 30),
      completedTaskIds: const ['t1', 't2', 't3', 't4'],
      totalTasks: 4,
    );

    await tester.pumpWidget(buildTestableWidget(
      MaterialLabCard(
        binding: binding,
        submission: dummySubmission,
      ),
      'en',
    ));
    await tester.pumpAndSettle();

    expect(find.text('PRACTICUM COMPLETED'), findsOneWidget);
    expect(find.text('Score: 100/100'), findsOneWidget);
    expect(find.text('Evaluation Passed: Score 100/100'), findsOneWidget);
    expect(find.text('Reopen Lab'), findsOneWidget);
  });
}
