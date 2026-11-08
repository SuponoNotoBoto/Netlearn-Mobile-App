import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Card surface following `design.md` ("Design System Token Specs"):
/// - Standard card: `--bg-card-container` (`#FFFFFF`), `--radius-md` (`16px`),
///   `--shadow-soft-sm` (`0 4px 12px rgba(140, 82, 255, 0.04)`), `--spacing-lg` (`16px`) padding.
/// - Banner / Overview card (`isBanner: true`): `--bg-card-banner` (`#ECE6FF`),
///   `--radius-lg` (`24px`), `--shadow-soft-md` (`0 8px 24px rgba(140, 82, 255, 0.06)`).
class NlSurfaceCard extends StatelessWidget {
  const NlSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.isBanner = false,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool isBanner;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radiusValue = borderRadius ??
        (isBanner ? NetLearnRadius.radiusLg : NetLearnRadius.radiusMd);
    final radius = BorderRadius.circular(radiusValue);

    final bgColor = isDark
        ? (isBanner ? NetLearnColors.darkRaised : context.surface)
        : (isBanner ? NetLearnColors.cardBannerBg : NetLearnColors.white);

    final borderColor = isDark
        ? NetLearnColors.darkLine
        : (isBanner ? NetLearnColors.purple100 : NetLearnColors.neutral200);

    final shadows = isDark
        ? const <BoxShadow>[]
        : (isBanner ? NetLearnShadows.softMd : NetLearnShadows.softSm);

    final content = Container(
      padding: padding ?? const EdgeInsets.all(NetLearnSpace.lg),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        border: Border.all(color: borderColor),
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: content,
      ),
    );
  }
}
