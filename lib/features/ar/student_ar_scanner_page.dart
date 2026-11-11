import 'package:flutter/material.dart';

import 'ar_scanner_page.dart';

class StudentArScannerPage extends StatelessWidget {
  const StudentArScannerPage({super.key})
      : currentNavIndex = 2,
        testArViewBuilder = null;

  /// Creates a test-friendly version with a fake AR view.
  const StudentArScannerPage.test({
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
        isLecturer: false,
        currentNavIndex: currentNavIndex,
        testArViewBuilder: testArViewBuilder!,
      );
    }
    return const ArScannerPage.student();
  }
}
