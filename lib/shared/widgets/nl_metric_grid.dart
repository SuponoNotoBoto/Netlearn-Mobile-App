import 'package:flutter/material.dart';

class NlMetricGrid extends StatelessWidget {
  final List<Widget> children;
  final int columns;
  final double gap;
  final EdgeInsetsGeometry padding;

  const NlMetricGrid({
    super.key,
    required this.children,
    this.columns = 3,
    this.gap = 12.0,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final columnCount = columns < 1 ? 1 : columns;
    final rows = <List<Widget>>[];

    for (var i = 0; i < children.length; i += columnCount) {
      rows.add(
        children.sublist(
          i,
          (i + columnCount).clamp(0, children.length),
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) SizedBox(height: gap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var c = 0; c < rows[r].length; c++) ...[
                    if (c > 0) SizedBox(width: gap),
                    Expanded(child: rows[r][c]),
                  ],
                  // If row is not full, fill remaining space
                  for (var empty = rows[r].length; empty < columnCount; empty++) ...[
                    SizedBox(width: gap),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

