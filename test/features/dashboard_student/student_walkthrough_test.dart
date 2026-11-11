import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:netlearn/core/router/app_router.dart';
import 'package:netlearn/features/dashboard_student/student_walkthrough.dart';
import 'package:netlearn/features/profile/student_profile_controller.dart';
import 'package:netlearn/shared/widgets/nl_walkthrough_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp({required GoRouter router, List<dynamic> overrides = const []}) {
  return ProviderScope(
    overrides: [
      appRouterProvider.overrideWithValue(router),
      studentProfileProvider.overrideWith(
        (ref) async => <String, dynamic>{'id': 'stu-1', 'name': 'Test Student'},
      ),
      ...overrides,
    ],
    child: MaterialApp.router(
      locale: const Locale('id'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('id')],
      routerConfig: router,
    ),
  );
}

GoRouter _buildStudentTestRouter({
  Future<void> Function(BuildContext context, WidgetRef ref)? onAction,
}) {
  return GoRouter(
    initialLocation: '/student',
    routes: [
      GoRoute(
        path: '/student',
        builder: (context, state) => Scaffold(
          body: Consumer(
            builder: (context, ref, _) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        key: StudentWalkthroughKeys.profileAvatarKey,
                        width: 48,
                        height: 48,
                      ),
                      ElevatedButton(
                        key: const Key('walkthrough_test_trigger'),
                        onPressed: () {
                          if (onAction != null) {
                            onAction(context, ref);
                          } else {
                            StudentWalkthroughManager.instance.start(
                              context,
                              ref,
                            );
                          }
                        },
                        child: const Text('Start'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    key: StudentWalkthroughKeys.leaderboardButtonKey,
                    width: 140,
                    height: 36,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        key: StudentWalkthroughKeys.materiTileKey,
                        width: 120,
                        height: 80,
                      ),
                      SizedBox(
                        key: StudentWalkthroughKeys.assessmentTileKey,
                        width: 120,
                        height: 80,
                      ),
                      SizedBox(
                        key: StudentWalkthroughKeys.virtualLabTileKey,
                        width: 120,
                        height: 80,
                      ),
                      SizedBox(
                        key: StudentWalkthroughKeys.arScannerTileKey,
                        width: 120,
                        height: 80,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/student/profile',
        builder: (context, state) => Scaffold(
          body: Center(
            child: SizedBox(
              key: StudentWalkthroughKeys.customProfileKey,
              width: 180,
              height: 44,
            ),
          ),
        ),
      ),
    ],
  );
}

void main() {
  testWidgets(
    'StudentWalkthroughManager walks through all 7 steps across /student and /student/profile',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() async {
        StudentWalkthroughManager.instance.dismiss();
      });

      final router = _buildStudentTestRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(_buildTestApp(router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('walkthrough_test_trigger')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Step 1: Klik Profile (/student)
      expect(StudentWalkthroughManager.instance.isActive, isTrue);
      expect(
        router.routeInformationProvider.value.uri.path,
        '/student',
      );
      expect(find.text('Panduan 1/7'), findsOneWidget);
      expect(find.text('Buka Halaman Profil'), findsOneWidget);

      // Step 2: Custom Profile (/student/profile)
      await tester.tap(find.byKey(const Key('walkthrough_next_btn')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/student/profile',
      );
      expect(find.text('Panduan 2/7'), findsOneWidget);
      expect(find.text('Kustomisasi Profil & Avatar'), findsOneWidget);

      // Back to Step 1 (/student)
      await tester.tap(find.byKey(const Key('walkthrough_prev_btn')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/student',
      );
      expect(find.text('Panduan 1/7'), findsOneWidget);

      // Forward to Step 2 then Step 3 (Materi on /student)
      await tester.tap(find.byKey(const Key('walkthrough_next_btn')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('walkthrough_next_btn')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/student',
      );
      expect(find.text('Panduan 3/7'), findsOneWidget);
      expect(find.text('Materi Pembelajaran'), findsOneWidget);

      // Step 4: Assessment
      await tester.tap(find.byKey(const Key('walkthrough_next_btn')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Panduan 4/7'), findsOneWidget);
      expect(find.text('Asesmen & Tugas'), findsOneWidget);

      // Step 5: Virtual Lab
      await tester.tap(find.byKey(const Key('walkthrough_next_btn')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Panduan 5/7'), findsOneWidget);
      expect(find.text('Virtual Lab Jaringan'), findsOneWidget);

      // Step 6: AR Scanner
      await tester.tap(find.byKey(const Key('walkthrough_next_btn')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Panduan 6/7'), findsOneWidget);
      expect(find.text('AR Scanner Perangkat'), findsOneWidget);

      // Step 7: Leaderboard
      await tester.tap(find.byKey(const Key('walkthrough_next_btn')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Panduan 7/7'), findsOneWidget);
      expect(find.text('Papan Peringkat (Leaderboard)'), findsOneWidget);

      // Finish walkthrough
      await tester.tap(find.byKey(const Key('walkthrough_next_btn')));
      await tester.pumpAndSettle();
      expect(StudentWalkthroughManager.instance.isActive, isFalse);
      expect(find.text('Panduan 7/7'), findsNothing);
      expect(
        router.routeInformationProvider.value.uri.path,
        '/student',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'StudentWalkthroughManager.maybeStartFirstTime only shows once per userId',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() async {
        StudentWalkthroughManager.instance.dismiss();
      });

      SharedPreferences.setMockInitialValues({});
      var currentUserId = 'stu-1';

      final router = _buildStudentTestRouter(
        onAction: (context, ref) =>
            StudentWalkthroughManager.instance.maybeStartFirstTime(
          context,
          ref,
          userId: currentUserId,
        ),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(_buildTestApp(router: router));
      await tester.pumpAndSettle();

      // First run for stu-1 should launch the walkthrough.
      await tester.tap(find.byKey(const Key('walkthrough_test_trigger')));
      await tester.pumpAndSettle();
      expect(StudentWalkthroughManager.instance.isActive, isTrue);
      expect(find.text('Panduan 1/7'), findsOneWidget);

      // Dismiss and re-trigger for stu-1 -> should NOT reopen.
      StudentWalkthroughManager.instance.dismiss();
      await tester.pumpAndSettle();
      expect(StudentWalkthroughManager.instance.isActive, isFalse);

      await tester.tap(find.byKey(const Key('walkthrough_test_trigger')));
      await tester.pumpAndSettle();
      expect(StudentWalkthroughManager.instance.isActive, isFalse);

      // Different user stu-2 -> should launch.
      currentUserId = 'stu-2';
      await tester.tap(find.byKey(const Key('walkthrough_test_trigger')));
      await tester.pumpAndSettle();
      expect(StudentWalkthroughManager.instance.isActive, isTrue);
      expect(find.text('Panduan 1/7'), findsOneWidget);

      StudentWalkthroughManager.instance.dismiss();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'NlWalkthroughOverlay clears target rect on step transition and retries delayed targets',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final key1 = GlobalKey();
      final key2 = GlobalKey();
      var showSecondTarget = false;
      bool? finishedCompleted;

      late StateSetter setHostState;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setHostState = setState;
                return Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(key: key1, width: 100, height: 40),
                        if (showSecondTarget)
                          SizedBox(key: key2, width: 160, height: 60),
                      ],
                    ),
                    NlWalkthroughOverlay(
                      isIndonesian: true,
                      steps: [
                        NlWalkthroughStep(
                          targetKey: key1,
                          title: 'Langkah Pertama',
                          description: 'Deskripsi langkah pertama.',
                        ),
                        NlWalkthroughStep(
                          targetKey: key2,
                          title: 'Langkah Kedua',
                          description: 'Deskripsi langkah kedua.',
                          onPrepare: () async {
                            // Mount target 2 slightly after onPrepare returns so retry loop resolves it.
                            unawaited(
                              Future<void>.delayed(
                                const Duration(milliseconds: 120),
                                () => setHostState(() => showSecondTarget = true),
                              ),
                            );
                          },
                        ),
                      ],
                      onFinish: ({required bool completed}) {
                        finishedCompleted = completed;
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Panduan 1/2'), findsOneWidget);

      await tester.tap(find.byKey(const Key('walkthrough_next_btn')));
      // Advance past onPrepare (350ms) and delayed target mount (120ms + 50ms retries).
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Panduan 2/2'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(find.text('Langkah Kedua'), findsOneWidget);
      await tester.tap(find.byKey(const Key('walkthrough_next_btn')));
      await tester.pump();
      expect(finishedCompleted, isTrue);
    },
  );
}

