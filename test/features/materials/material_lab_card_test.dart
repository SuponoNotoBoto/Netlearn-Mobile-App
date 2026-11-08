import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/materials/material_lab_binding.dart';
import 'package:netlearn/features/materials/widgets/material_lab_card.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  testWidgets('MaterialLabCard renders title, badge, instructions, and CTA button',
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

    await tester.pumpWidget(buildTestableWidget(const MaterialLabCard(binding: binding)));
    await tester.pumpAndSettle();

    expect(find.text('PRAKTIKUM VIRTUAL LAB'), findsOneWidget);
    expect(find.text('Topologi Star'), findsOneWidget);
    expect(find.text('Praktikum Topologi Star LAN'), findsOneWidget);
    expect(find.text('Eksperimen 1 switch dan 3 PC dalam satu subnet'), findsOneWidget);
    expect(find.text('Panduan Tugas Lab:'), findsOneWidget);
    expect(find.text('Hubungkan setiap PC ke port switch.'), findsOneWidget);
    expect(find.text('Buka di Virtual Lab'), findsOneWidget);
  });
}

