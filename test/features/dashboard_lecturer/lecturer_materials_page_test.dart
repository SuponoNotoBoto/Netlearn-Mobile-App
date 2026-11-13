import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:netlearn/core/theme/app_theme.dart';
import 'package:netlearn/features/classes/class_controller.dart';
import 'package:netlearn/features/classes/class_models.dart';
import 'package:netlearn/features/dashboard_lecturer/lecturer_bottom_navbar.dart';
import 'package:netlearn/features/dashboard_lecturer/lecturer_materials_controller.dart';
import 'package:netlearn/features/dashboard_lecturer/lecturer_materials_page.dart';
import 'package:netlearn/l10n/app_localizations.dart';
import 'package:netlearn/shared/models/material_model.dart';

void main() {
  const activeClass = LecturerClass(
    id: 'cls-1',
    name: 'Jaringan Komputer A',
    status: 'draft',
  );

  const sampleMaterials = [
    MaterialModel(
      id: 'mat-1',
      moduleNumber: 1,
      isCore: false,
      orderIndex: 1,
      title: 'Pengenalan OSI Layer',
      titleId: 'Pengenalan OSI Layer',
      published: true,
      lockStatus: 'unlocked',
    ),
  ];

  Widget buildTestApp() {
    final router = GoRouter(
      initialLocation: '/lecturer/materials',
      routes: [
        GoRoute(
          path: '/lecturer/materials',
          builder: (context, state) => const LecturerMaterialsPage(),
        ),
        GoRoute(
          path: '/lecturer/materials/create',
          builder: (context, state) =>
              const Scaffold(body: Text('Create Material Page')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        lecturerMaterialsProvider.overrideWith((ref) async => sampleMaterials),
        activeLecturerClassProvider.overrideWith(
          (ref) => const AsyncValue.data(activeClass),
        ),
        lecturerClassesProvider.overrideWith((ref) async => [activeClass]),
        classModulesProvider('cls-1').overrideWith((ref) async => const []),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets(
    'hides top add-material button and shows floating (+) above navbar',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('Tambah Materi'), findsNothing);
      expect(find.text('Tambah Modul'), findsNothing);

      final fabFinder = find.byKey(const Key('lecturer_materials_fab'));
      final navFinder = find.byType(LecturerBottomNavbar);
      expect(fabFinder, findsOneWidget);
      expect(navFinder, findsOneWidget);

      final fabRect = tester.getRect(fabFinder);
      final navRect = tester.getRect(navFinder);
      expect(fabRect.bottom <= navRect.top, isTrue);
      expect(fabRect.right > navRect.center.dx, isTrue);
    },
  );

  testWidgets(
    'tapping floating (+) shows Tambah Modul then Tambah Materi and opens actions',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('lecturer_materials_fab')));
      await tester.pumpAndSettle();

      final addModuleFinder =
          find.byKey(const Key('lecturer_materials_fab_add_module'));
      final addMaterialFinder =
          find.byKey(const Key('lecturer_materials_fab_add_material'));

      expect(addModuleFinder, findsOneWidget);
      expect(addMaterialFinder, findsOneWidget);
      expect(find.text('Tambah Modul'), findsOneWidget);
      expect(find.text('Tambah Materi'), findsOneWidget);

      // Option 1 (Tambah Modul) appears above Option 2 (Tambah Materi).
      expect(
        tester.getTopLeft(addModuleFinder).dy <
            tester.getTopLeft(addMaterialFinder).dy,
        isTrue,
      );

      // Tapping Tambah Modul opens the add-module dialog.
      await tester.tap(addModuleFinder);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('module_dialog_title_id')), findsOneWidget);

      // Close dialog, re-open speed dial, and tap Tambah Materi.
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('lecturer_materials_fab')));
      await tester.pumpAndSettle();

      await tester.tap(addMaterialFinder);
      await tester.pumpAndSettle();
      expect(find.text('Create Material Page'), findsOneWidget);
    },
  );
}

