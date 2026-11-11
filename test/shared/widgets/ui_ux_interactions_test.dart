import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/core/theme/app_theme.dart';
import 'package:netlearn/shared/widgets/nl_button.dart';
import 'package:netlearn/shared/widgets/nl_micro_transition.dart';
import 'package:netlearn/shared/widgets/nl_skeleton.dart';
import 'package:netlearn/shared/widgets/nl_tap_scale.dart';

void main() {
  group('UI/UX Button Press Animation, Micro Transitions & Skeletons', () {
    testWidgets(
      'NlButton scales down on pointer press and restores to 1.0 on release',
      (tester) async {
        var pressedCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Center(
                child: NlButton(
                  label: 'Mulai Belajar',
                  onPressed: () {
                    pressedCount++;
                  },
                ),
              ),
            ),
          ),
        );

        final scaleFinder = find.descendant(
          of: find.byType(NlTapScale),
          matching: find.byType(ScaleTransition),
        );
        expect(scaleFinder, findsOneWidget);

        ScaleTransition scaleTransition = tester.widget(scaleFinder);
        expect(scaleTransition.scale.value, closeTo(1.0, 0.001));

        final center = tester.getCenter(find.byType(NlButton));
        final gesture = await tester.startGesture(center);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        scaleTransition = tester.widget(scaleFinder);
        expect(scaleTransition.scale.value, lessThan(0.98));

        await gesture.up();
        await tester.pumpAndSettle();

        scaleTransition = tester.widget(scaleFinder);
        expect(scaleTransition.scale.value, closeTo(1.0, 0.001));
        expect(pressedCount, 1);
      },
    );

    testWidgets(
      'NlContentTransition smoothly transitions between skeleton and loaded content',
      (tester) async {
        var isLoading = true;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Column(
                    children: [
                      NlContentTransition(
                        child: isLoading
                            ? const NlDashboardProgressSkeleton(
                                key: ValueKey('skeleton'),
                                moduleRows: 2,
                              )
                            : const Text(
                                'Loaded Progress Content',
                                key: ValueKey('loaded'),
                              ),
                      ),
                      ElevatedButton(
                        onPressed: () => setState(() => isLoading = false),
                        child: const Text('Finish Loading'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        expect(find.byType(NlDashboardProgressSkeleton), findsOneWidget);
        expect(find.text('Loaded Progress Content'), findsNothing);

        // Verify skeleton settles cleanly with pumpAndSettle
        await tester.pumpAndSettle();

        await tester.tap(find.text('Finish Loading'));
        await tester.pump(const Duration(milliseconds: 80));
        expect(find.text('Loaded Progress Content'), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byType(NlDashboardProgressSkeleton), findsNothing);
        expect(find.text('Loaded Progress Content'), findsOneWidget);
      },
    );

    testWidgets(
      'NlSkeletonBox supports shimmer animation when animateInTest is true',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(
              body: Column(
                children: [
                  NlSkeletonBox(
                    width: 120,
                    height: 16,
                    animateInTest: true,
                  ),
                  NlNotificationsPreviewSkeleton(
                    rows: 2,
                    animateInTest: true,
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(NlSkeletonBox), findsWidgets);
      },
    );

    testWidgets(
      'NlPageTransitionsBuilder animates route push smoothly',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: NlButton(
                    label: 'Buka Halaman Kedua',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const Scaffold(
                            body: Center(child: Text('Halaman Kedua')),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Buka Halaman Kedua'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        expect(find.text('Halaman Kedua'), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.text('Halaman Kedua'), findsOneWidget);
      },
    );
  });
}

