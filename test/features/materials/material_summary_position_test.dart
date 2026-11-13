import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:netlearn/features/materials/material_lab_binding.dart';
import 'package:netlearn/features/materials/material_reader_page.dart';
import 'package:netlearn/features/materials/student_materials_controller.dart';
import 'package:netlearn/features/materials/widgets/material_lab_card.dart';
import 'package:netlearn/l10n/app_localizations.dart';
import 'package:netlearn/shared/models/material_model.dart';

void main() {
  group('Material Reader Summary Positioning', () {
    testWidgets('Renders summary card above virtual lab practical', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const testMaterial = MaterialModel(
        id: 'mat-101',
        title: 'Materi Jaringan Dasar',
        titleId: 'Materi Jaringan Dasar',
        isCore: true,
        published: true,
        lockStatus: 'unlocked',
        moduleNumber: 1,
        orderIndex: 1,
        summary: 'Ini adalah ringkasan materi jaringan komputer yang menempel pada aplikasi.',
        summaryId: 'Ini adalah ringkasan materi jaringan komputer yang menempel pada aplikasi.',
        content: '<!--netlearn-lab:{"enabled":true,"preset":"star","title":"Lab Topologi Bintang"}-->',
        contentId: '<!--netlearn-lab:{"enabled":true,"preset":"star","title":"Lab Topologi Bintang"}-->',
      );

      // Pastikan fromMaterial menghasilkan binding valid
      final binding = MaterialLabBinding.fromMaterial(testMaterial);
      expect(binding, isNotNull);

      final router = GoRouter(
        initialLocation: '/reader',
        routes: [
          GoRoute(
            path: '/reader',
            builder: (context, state) => const MaterialReaderPage(
              materialId: 'mat-101',
              fromLecturer: true,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentMaterialProvider('mat-101').overrideWith(
              (ref) => Future.value(testMaterial),
            ),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('id'),
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Memastikan ringkasan / summary muncul sebagai materi yang menempel pada aplikasi
      final summaryFinder = find.text(
        'Ini adalah ringkasan materi jaringan komputer yang menempel pada aplikasi.',
      );
      expect(summaryFinder, findsOneWidget);

      // Cari MaterialLabCard di widget tree
      expect(find.byType(MaterialLabCard), findsOneWidget);

      // Verifikasi posisi Y: Ringkasan berada di atas Praktikum Virtual Lab
      final summaryOffset = tester.getTopLeft(summaryFinder).dy;
      final labOffset = tester.getTopLeft(find.byType(MaterialLabCard)).dy;
      expect(summaryOffset, lessThan(labOffset));
    });
  });
}
