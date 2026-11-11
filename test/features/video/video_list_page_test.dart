import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:netlearn/core/localization/language_controller.dart';
import 'package:netlearn/features/classes/class_models.dart';
import 'package:netlearn/features/video/video_list_page.dart';
import 'package:netlearn/l10n/app_localizations.dart';
import 'package:netlearn/shared/widgets/nl_empty_state.dart';

class _IndonesianLanguageController extends LanguageController {
  @override
  Locale build() => const Locale('id');
}

ClassModule _module({
  required String id,
  required int position,
  required String title,
  String status = 'published',
  int? templateModuleNumber,
}) {
  return ClassModule(
    id: id,
    classId: 'custom-class-1',
    position: position,
    title: title,
    titleEn: title,
    titleId: title,
    status: status,
    templateModuleNumber: templateModuleNumber,
  );
}

Widget _buildVideoListTestApp({
  required List<VideoListItem> items,
}) {
  final router = GoRouter(
    initialLocation: '/student/video-list',
    routes: [
      GoRoute(
        path: '/student/video-list',
        builder: (_, _) => const VideoListPage(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      languageProvider.overrideWith(_IndonesianLanguageController.new),
      videoListProvider.overrideWith((ref) async => items),
    ],
    child: MaterialApp.router(
      locale: const Locale('id'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  group('buildVideoListItems', () {
    test(
      'custom class with video in only one matkul returns strictly 1 item and ignores text-only modules',
      () {
        final modules = [
          _module(id: 'mod-1', position: 1, title: 'Matkul 1 - Pengenalan'),
          _module(id: 'mod-2', position: 2, title: 'Matkul 2 - Subnetting'),
          _module(id: 'mod-3', position: 3, title: 'Matkul 3 - Routing'),
        ];

        final rows = [
          {
            'id': 'mat-1',
            'module_id': 'mod-1',
            'module_number': 1,
            'order_index': 1,
            'title': 'Materi Bacaan Awal',
            'title_id': 'Materi Bacaan Awal',
            'video_url': null,
            'video_id': null,
          },
          {
            'id': 'mat-2',
            'module_id': 'mod-2',
            'module_number': 2,
            'order_index': 1,
            'title': 'Video Praktik Subnetting',
            'title_id': 'Video Praktik Subnetting',
            'video_url': 'https://youtu.be/dQw4w9WgXcQ',
            'video_id': 'dQw4w9WgXcQ',
          },
          {
            'id': 'mat-3',
            'module_id': 'mod-3',
            'module_number': 3,
            'order_index': 1,
            'title': 'PDF Modul Routing',
            'title_id': 'PDF Modul Routing',
            'video_url': '',
            'video_id': '',
          },
        ];

        final items = buildVideoListItems(
          rows,
          classModules: modules,
          onlyWithVideo: true,
          includeMultiplePerModule: true,
          filterDraftModules: true,
        );

        expect(items, hasLength(1));
        expect(items.single.id, 'mat-2');
        expect(items.single.moduleNumber, 2);
        expect(items.single.youtubeVideoId, 'dQw4w9WgXcQ');
      },
    );

    test(
      'custom class includes every material that has a valid video even within the same module',
      () {
        final modules = [
          _module(id: 'mod-1', position: 2, title: 'Topik A'),
          _module(id: 'mod-2', position: 1, title: 'Topik B'),
        ];

        final rows = [
          {
            'id': 'mat-a1',
            'module_id': 'mod-1',
            'module_number': 1,
            'order_index': 1,
            'title': 'Video A1',
            'video_url': 'https://www.youtube.com/watch?v=aaaaaaaaaaa',
            'video_id': null,
          },
          {
            'id': 'mat-a2',
            'module_id': 'mod-1',
            'module_number': 1,
            'order_index': 2,
            'title': 'Video A2',
            'video_url': 'https://youtu.be/bbbbbbbbbbb',
            'video_id': null,
          },
          {
            'id': 'mat-b1',
            'module_id': 'mod-2',
            'module_number': 2,
            'order_index': 1,
            'title': 'Video B1',
            'video_url': 'https://www.youtube.com/watch?v=ccccccccccc',
            'video_id': 'ccccccccccc',
          },
        ];

        final items = buildVideoListItems(
          rows,
          classModules: modules,
          onlyWithVideo: true,
          includeMultiplePerModule: true,
          filterDraftModules: true,
        );

        expect(items, hasLength(3));
        // mod-2 has position 1 so it comes first, then mod-1 (position 2).
        expect(items.map((e) => e.id).toList(), ['mat-b1', 'mat-a1', 'mat-a2']);
        expect(items.map((e) => e.moduleNumber).toList(), [1, 2, 2]);
      },
    );

    test(
      'custom class excludes materials in draft modules for students and handles empty videos',
      () {
        final modules = [
          _module(id: 'mod-pub', position: 1, title: 'Modul Pub', status: 'published'),
          _module(id: 'mod-draft', position: 2, title: 'Modul Draft', status: 'draft'),
        ];

        final rows = [
          {
            'id': 'mat-pub-novid',
            'module_id': 'mod-pub',
            'module_number': 1,
            'order_index': 1,
            'title': 'Teks Saja',
            'video_url': null,
            'video_id': null,
          },
          {
            'id': 'mat-draft-vid',
            'module_id': 'mod-draft',
            'module_number': 2,
            'order_index': 1,
            'title': 'Video Modul Draft',
            'video_url': 'https://youtu.be/ddddddddddd',
            'video_id': 'ddddddddddd',
          },
        ];

        final studentItems = buildVideoListItems(
          rows,
          classModules: modules,
          onlyWithVideo: true,
          includeMultiplePerModule: true,
          filterDraftModules: true,
        );
        expect(studentItems, isEmpty);

        final lecturerItems = buildVideoListItems(
          rows,
          classModules: modules,
          onlyWithVideo: true,
          includeMultiplePerModule: true,
          filterDraftModules: false,
        );
        expect(lecturerItems, hasLength(1));
        expect(lecturerItems.single.id, 'mat-draft-vid');
      },
    );

    test(
      'template / legacy mode keeps one representative card per core module including unavailable fallback',
      () {
        final rows = [
          {
            'id': 'tpl-1a',
            'module_number': 1,
            'order_index': 1,
            'title': 'Modul 1 Video',
            'video_url': 'https://youtu.be/eeeeeeeeeee',
            'video_id': 'eeeeeeeeeee',
          },
          {
            'id': 'tpl-1b',
            'module_number': 1,
            'order_index': 2,
            'title': 'Modul 1 Tambahan',
            'video_url': 'https://youtu.be/fffffffffff',
            'video_id': 'fffffffffff',
          },
          {
            'id': 'tpl-2',
            'module_number': 2,
            'order_index': 1,
            'title': 'Modul 2 Tanpa Video',
            'video_url': null,
            'video_id': null,
          },
        ];

        final items = buildVideoListItems(rows);
        expect(items, hasLength(2));
        expect(items[0].id, 'tpl-1a');
        expect(items[0].youtubeVideoId, 'eeeeeeeeeee');
        expect(items[1].id, 'tpl-2');
        expect(items[1].youtubeVideoId, isNull);
      },
    );
  });

  group('VideoListPage widget', () {
    testWidgets('shows single video card when custom class has 1 video', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildVideoListTestApp(
          items: const [
            VideoListItem(
              id: 'custom-vid-1',
              title: 'Video Dasar Jaringan Kustom',
              titleEn: 'Custom Networking Video',
              titleId: 'Video Dasar Jaringan Kustom',
              moduleNumber: 1,
              youtubeVideoId: 'dQw4w9WgXcQ',
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1 modul · Pilih video untuk mulai belajar'), findsOneWidget);
      expect(find.text('Video Dasar Jaringan Kustom'), findsOneWidget);
      expect(find.text('Tautan video tersedia'), findsOneWidget);
      expect(find.text('Video belum tersedia'), findsNothing);
    });

    testWidgets('shows multiple videos from same matkul with accurate module count', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildVideoListTestApp(
          items: const [
            VideoListItem(
              id: 'custom-vid-1',
              title: 'Video Bagian 1',
              titleEn: 'Video Part 1',
              titleId: 'Video Bagian 1',
              moduleNumber: 1,
              youtubeVideoId: 'aaaaaaaaaaa',
            ),
            VideoListItem(
              id: 'custom-vid-2',
              title: 'Video Bagian 2',
              titleEn: 'Video Part 2',
              titleId: 'Video Bagian 2',
              moduleNumber: 1,
              youtubeVideoId: 'bbbbbbbbbbb',
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1 modul · Pilih video untuk mulai belajar'), findsOneWidget);
      expect(find.text('Video Bagian 1'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Video Bagian 2'),
        250,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Video Bagian 2'), findsOneWidget);
    });

    testWidgets('shows empty state when class has no published videos', (
      tester,
    ) async {
      await tester.pumpWidget(_buildVideoListTestApp(items: const []));
      await tester.pumpAndSettle();

      expect(find.byType(NlEmptyState), findsOneWidget);
      expect(find.text('Belum ada video tersedia.'), findsOneWidget);
    });
  });
}

