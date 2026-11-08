import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'nl_topbar.dart';

class UnderDevelopmentPage extends StatelessWidget {
  final String title;
  final String message;

  const UnderDevelopmentPage({
    super.key,
    required this.title,
    this.message = 'Fitur ini sedang dalam tahap pengembangan dan akan segera hadir.',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: context.background,
      appBar: NlTopBar(
        title: title,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.construction_rounded,
                  size: 44,
                  color: primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tahap Pengembangan',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
