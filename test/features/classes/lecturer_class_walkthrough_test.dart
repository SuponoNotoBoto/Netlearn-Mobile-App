import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/shared/widgets/nl_walkthrough_overlay.dart';

void main() {
  testWidgets('NlWalkthroughOverlay steps forward, backward, and finishes', (
    tester,
  ) async {
    final key1 = GlobalKey();
    final key2 = GlobalKey();
    final key3 = GlobalKey();
    final key4 = GlobalKey();

    var preparedTab = 0;
    bool? finishedWithCompleted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Column(
                children: [
                  SizedBox(key: key1, width: 100, height: 32),
                  SizedBox(key: key2, width: 120, height: 40),
                  SizedBox(key: key3, width: 200, height: 120),
                  SizedBox(key: key4, width: 200, height: 120),
                ],
              ),
              NlWalkthroughOverlay(
                isIndonesian: true,
                steps: [
                  NlWalkthroughStep(
                    targetKey: key1,
                    title: 'Status Kelas Masih Draf',
                    description: 'Kelas masih draft belum publish.',
                    onPrepare: () async => preparedTab = 0,
                  ),
                  NlWalkthroughStep(
                    targetKey: key2,
                    title: 'Isi Minimal 1 Modul & 1 Materi',
                    description: 'Isi minimal 1 modul dan 1 materi sebelum publish.',
                    onPrepare: () async => preparedTab = 0,
                  ),
                  NlWalkthroughStep(
                    targetKey: key3,
                    title: 'Atur Kelas di Settings & Gates',
                    description: 'Atur pretest, posttest, dan leaderboard.',
                    onPrepare: () async => preparedTab = 1,
                  ),
                  NlWalkthroughStep(
                    targetKey: key4,
                    title: 'Kode Kelas untuk Siswa',
                    description: 'Kode inilah yang harus dimasukkan oleh siswa.',
                    onPrepare: () async => preparedTab = 2,
                  ),
                ],
                onFinish: ({required bool completed}) {
                  finishedWithCompleted = completed;
                },
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Step 1
    expect(find.text('Panduan 1/4'), findsOneWidget);
    expect(find.text('Status Kelas Masih Draf'), findsOneWidget);
    expect(preparedTab, 0);

    // Step 2
    await tester.tap(find.byKey(const Key('walkthrough_next_btn')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Panduan 2/4'), findsOneWidget);
    expect(find.text('Isi Minimal 1 Modul & 1 Materi'), findsOneWidget);

    // Step 3 (switches to tab 1)
    await tester.tap(find.byKey(const Key('walkthrough_next_btn')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Panduan 3/4'), findsOneWidget);
    expect(find.text('Atur Kelas di Settings & Gates'), findsOneWidget);
    expect(preparedTab, 1);

    // Back to Step 2
    await tester.tap(find.byKey(const Key('walkthrough_prev_btn')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Panduan 2/4'), findsOneWidget);

    // Forward to Step 3 and Step 4 (switches to tab 2)
    await tester.tap(find.byKey(const Key('walkthrough_next_btn')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('walkthrough_next_btn')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Panduan 4/4'), findsOneWidget);
    expect(find.text('Kode Kelas untuk Siswa'), findsOneWidget);
    expect(preparedTab, 2);

    // Finish
    await tester.tap(find.byKey(const Key('walkthrough_next_btn')));
    await tester.pump();
    expect(finishedWithCompleted, isTrue);
  });

  testWidgets('NlWalkthroughOverlay skip triggers completed=false', (
    tester,
  ) async {
    final key1 = GlobalKey();
    bool? finishedWithCompleted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              SizedBox(key: key1, width: 100, height: 32),
              NlWalkthroughOverlay(
                isIndonesian: false,
                steps: [
                  NlWalkthroughStep(
                    targetKey: key1,
                    title: 'Draft Status',
                    description: 'Still draft.',
                  ),
                ],
                onFinish: ({required bool completed}) {
                  finishedWithCompleted = completed;
                },
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Guide 1/1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('walkthrough_skip_btn')));
    await tester.pump();
    expect(finishedWithCompleted, isFalse);
  });
}
