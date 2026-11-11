import 'package:flutter/material.dart';

import 'ar_scanner_page.dart';

/// Lecturer entry to the AR Scanner.
///
/// Uses the shared [ArScannerPage] with the lecturer bottom navigation.
class LecturerArScannerPage extends StatelessWidget {
  const LecturerArScannerPage({super.key})
      : currentNavIndex = 2,
        testArViewBuilder = null;

  /// Creates a test-friendly version with a fake AR view.
  const LecturerArScannerPage.test({
    super.key,
    required this.currentNavIndex,
    required this.testArViewBuilder,
  });

  final int currentNavIndex;
  final Widget Function(
    BuildContext,
    void Function(
      dynamic,
      dynamic,
      dynamic,
      dynamic,
    ),
  )? testArViewBuilder;

  @override
  Widget build(BuildContext context) {
    if (testArViewBuilder != null) {
      return ArScannerPage.test(
        isLecturer: true,
        currentNavIndex: currentNavIndex,
        testArViewBuilder: testArViewBuilder!,
      );
    }
    return const ArScannerPage.lecturer();
  }
}
