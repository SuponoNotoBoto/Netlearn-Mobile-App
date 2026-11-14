import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:netlearn/core/theme/app_theme.dart';
import 'package:netlearn/features/materials/material_detail_page.dart';
import 'package:netlearn/features/materials/student_materials_controller.dart';
import 'package:netlearn/l10n/app_localizations.dart';
import 'package:netlearn/shared/models/material_model.dart';

void main() {
  testWidgets(
      'MaterialDetailPage renders summary with PTI 2025 A regular bodyLarge typography (not bold)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const summaryText =
        'Ringkasan materi jaringan dasar harus mengikuti tipografi bacaan PTI 2025 A.';

    const material = MaterialModel(
      id: 'mat-summary-1',
      title: 'Materi Topologi Jaringan',
      titleId: 'Materi Topologi Jaringan',
      isCore: true,
      published: true,
      lockStatus: 'unlocked',
      moduleNumber: 1,
      orderIndex: 1,
      summary: summaryText,
      summaryId: summaryText,
      content: 'Isi materi praktikum.',
      contentId: 'Isi materi praktikum.',
    );

    final router = GoRouter(
      initialLocation: '/detail',
      routes: [
        GoRoute(
          path: '/detail',
          builder: (context, state) => const MaterialDetailPage(
            materialId: 'mat-summary-1',
            fromLecturer: true,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentMaterialProvider('mat-summary-1').overrideWith(
            (ref) async => material,
          ),
          isMaterialUnlockedProvider('mat-summary-1').overrideWith(
            (ref) async => true,
          ),
          studentMaterialProgressProvider('mat-summary-1').overrideWith(
            (ref) async => null,
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('id'),
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final summaryFinder = find.text(summaryText);
    expect(summaryFinder, findsOneWidget);

    final textWidget = tester.widget<Text>(summaryFinder);
    final style = textWidget.style!;
    expect(style.fontWeight, FontWeight.w400);
    expect(style.fontSize, 12);
    expect(style.height, 1.7);
  });
}

