import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Baris label-nilai untuk data teknis seperti IP, subnet mask, dan gateway.
///
/// Value menggunakan font monospace dan right-aligned.
/// semanticsValue digunakan agar TalkBack membaca nilai
/// dengan format yang lebih mudah dipahami.
class TechDataRow extends StatelessWidget {
  final String label;
  final String value;
  final String? semanticsValue;

  const TechDataRow({
    super.key,
    required this.label,
    required this.value,
    this.semanticsValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: NetLearnSpace.s4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(
                alpha: 0.7,
              ),
            ),
          ),
          Semantics(
            label: semanticsValue ?? value,
            child: ExcludeSemantics(
              child: Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}