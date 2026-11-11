import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// Descriptor for a single interactive spotlight walkthrough step.
class NlWalkthroughStep {
  const NlWalkthroughStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.tabIndex,
    this.icon = Icons.lightbulb_outline_rounded,
    this.accentColor = const Color(0xFF6C2CE2),
    this.highlightPadding = const EdgeInsets.all(6),
    this.highlightRadius = 14.0,
    this.onPrepare,
  });

  final GlobalKey targetKey;
  final String title;
  final String description;
  final int? tabIndex;
  final IconData icon;
  final Color accentColor;
  final EdgeInsets highlightPadding;
  final double highlightRadius;
  final Future<void> Function()? onPrepare;
}

/// Interactive spotlight coach-mark walkthrough overlay rendered inside an [OverlayEntry].
class NlWalkthroughOverlay extends StatefulWidget {
  const NlWalkthroughOverlay({
    super.key,
    required this.steps,
    required this.isIndonesian,
    required this.onFinish,
  });

  final List<NlWalkthroughStep> steps;
  final bool isIndonesian;
  final void Function({required bool completed}) onFinish;

  @override
  State<NlWalkthroughOverlay> createState() => _NlWalkthroughOverlayState();
}

class _NlWalkthroughOverlayState extends State<NlWalkthroughOverlay> {
  int _currentIndex = 0;
  Rect? _targetRect;
  bool _measuring = true;
  int _measureGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goToStep(0, waitBeforeMeasure: false);
    });
  }

  Future<void> _goToStep(
    int index, {
    bool waitBeforeMeasure = true,
  }) async {
    if (!mounted || index < 0 || index >= widget.steps.length) return;

    final generation = ++_measureGeneration;
    final step = widget.steps[index];

    setState(() {
      if (_currentIndex != index) {
        _targetRect = null;
      }
      _currentIndex = index;
      _measuring = true;
    });

    if (step.onPrepare != null) {
      await step.onPrepare!();
      if (!mounted || generation != _measureGeneration) return;
      if (waitBeforeMeasure) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (!mounted || generation != _measureGeneration) return;
      }
    }

    // Wait until target is mounted and within screen bounds (not still offscreen
    // from a page or tab slide transition).
    BuildContext? targetCtx;
    Rect? preCheckRect;
    final overlayObj = mounted ? context.findRenderObject() : null;
    final overlaySize = overlayObj is RenderBox && overlayObj.hasSize
        ? overlayObj.size
        : null;

    for (var attempt = 0; attempt < 40; attempt++) {
      targetCtx = step.targetKey.currentContext;
      if (targetCtx != null && targetCtx.mounted) {
        final ro = targetCtx.findRenderObject();
        if (ro is RenderBox && ro.hasSize && ro.attached) {
          final topLeft = ro.localToGlobal(
            Offset.zero,
            ancestor: overlayObj is RenderBox ? overlayObj : null,
          );
          final r = topLeft & ro.size;
          final onScreen = overlaySize == null ||
              (r.width > 0 &&
                  r.height > 0 &&
                  r.right > 0 &&
                  r.left < overlaySize.width);
          if (onScreen) {
            preCheckRect = r;
            break;
          }
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted || generation != _measureGeneration) return;
    }

    if (targetCtx != null && targetCtx.mounted && preCheckRect != null) {
      try {
        await Scrollable.ensureVisible(
          targetCtx,
          duration: const Duration(milliseconds: 220),
          alignment: 0.3,
          curve: Curves.easeOutCubic,
        );
      } catch (_) {
        // Target is outside a Scrollable (e.g. header badge); safe to ignore.
      }
      if (!mounted || generation != _measureGeneration) return;
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || generation != _measureGeneration) return;

    Rect? measured;
    final ctxAfterScroll = step.targetKey.currentContext;
    final ancestorObj = context.findRenderObject();
    final ancestorBox = ancestorObj is RenderBox && ancestorObj.hasSize
        ? ancestorObj
        : null;
    if (ctxAfterScroll != null && ctxAfterScroll.mounted) {
      final renderObj = ctxAfterScroll.findRenderObject();
      if (renderObj is RenderBox && renderObj.hasSize && renderObj.attached) {
        final topLeft = renderObj.localToGlobal(
          Offset.zero,
          ancestor: ancestorBox,
        );
        final raw = topLeft & renderObj.size;
        final validInView = raw.width > 0 &&
            raw.height > 0 &&
            (ancestorBox == null ||
                (raw.right > 0 &&
                    raw.left < ancestorBox.size.width &&
                    raw.bottom > 0 &&
                    raw.top < ancestorBox.size.height));
        if (validInView) {
          final pad = step.highlightPadding;
          measured = Rect.fromLTRB(
            raw.left - pad.left,
            raw.top - pad.top,
            raw.right + pad.right,
            raw.bottom + pad.bottom,
          );
        }
      }
    }

    if (!mounted || generation != _measureGeneration) return;
    setState(() {
      _targetRect = measured;
      _measuring = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentIndex];
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isId = widget.isIndonesian;
    final isLast = _currentIndex == widget.steps.length - 1;

    final rect = _targetRect;
    final double safeTop = padding.top + 12;
    final double safeBottom = padding.bottom + 12;

    // Decide whether tooltip card goes above or below the spotlight hole.
    bool placeBelow = true;
    if (rect != null) {
      final spaceAbove = rect.top - safeTop - 14;
      final spaceBelow = size.height - safeBottom - rect.bottom - 14;
      if (rect.center.dy >= size.height * 0.48 && spaceAbove >= spaceBelow) {
        placeBelow = false;
      } else if (spaceBelow < 220 && spaceAbove > spaceBelow) {
        placeBelow = false;
      }
    }

    final tooltipCard = Material(
      type: MaterialType.transparency,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: isDark ? NetLearnColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: step.accentColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: step.accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    step.icon,
                    size: 18,
                    color: step.accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: step.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isId
                        ? 'Panduan ${_currentIndex + 1}/${widget.steps.length}'
                        : 'Guide ${_currentIndex + 1}/${widget.steps.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: step.accentColor,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  key: const Key('walkthrough_skip_btn'),
                  onPressed: () => widget.onFinish(completed: false),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isDark ? NetLearnColors.darkMuted : AppColors.textMuted,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    isId ? 'Lewati' : 'Skip',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              step.title,
              style: TextStyle(
                fontFamily: AppTheme.displayFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? NetLearnColors.darkText : const Color(0xFF1D1C21),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              step.description,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark
                    ? NetLearnColors.darkMuted
                    : const Color(0xFF545163),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.steps.length, (i) {
                    final active = i == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 5),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? step.accentColor
                            : step.accentColor.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
                const Spacer(),
                if (_currentIndex > 0) ...[
                  OutlinedButton(
                    key: const Key('walkthrough_prev_btn'),
                    onPressed: _measuring
                        ? null
                        : () => _goToStep(_currentIndex - 1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: step.accentColor,
                      side: BorderSide(
                        color: step.accentColor.withValues(alpha: 0.4),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isId ? 'Kembali' : 'Back',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                FilledButton.icon(
                  key: const Key('walkthrough_next_btn'),
                  onPressed: _measuring
                      ? null
                      : () {
                          if (isLast) {
                            widget.onFinish(completed: true);
                          } else {
                            _goToStep(_currentIndex + 1);
                          }
                        },
                  icon: Icon(
                    isLast
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    size: 16,
                  ),
                  iconAlignment: IconAlignment.end,
                  label: Text(
                    isLast
                        ? (isId ? 'Selesai' : 'Finish')
                        : (isId ? 'Lanjut' : 'Next'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: step.accentColor,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          widget.onFinish(completed: false);
        }
      },
      child: Stack(
        children: [
          // Dark scrim with cutout spotlight hole; absorbs background taps.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(
                painter: _SpotlightBackdropPainter(
                  holeRect: rect,
                  holeRadius: step.highlightRadius,
                  accentColor: step.accentColor,
                ),
              ),
            ),
          ),
          if (rect != null && placeBelow)
            Positioned(
              left: 18,
              right: 18,
              top: (rect.bottom + 14).clamp(
                safeTop,
                (size.height - safeBottom - 260).clamp(safeTop, size.height),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      (size.height - safeBottom - rect.bottom - 20).clamp(
                    180.0,
                    size.height * 0.65,
                  ),
                ),
                child: SingleChildScrollView(child: tooltipCard),
              ),
            )
          else if (rect != null && !placeBelow)
            Positioned(
              left: 18,
              right: 18,
              bottom: (size.height - rect.top + 14).clamp(
                safeBottom,
                (size.height - safeTop - 260).clamp(safeBottom, size.height),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: (rect.top - safeTop - 20).clamp(
                    180.0,
                    size.height * 0.65,
                  ),
                ),
                child: SingleChildScrollView(child: tooltipCard),
              ),
            )
          else
            Positioned.fill(
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: tooltipCard,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpotlightBackdropPainter extends CustomPainter {
  const _SpotlightBackdropPainter({
    required this.holeRect,
    required this.holeRadius,
    required this.accentColor,
  });

  final Rect? holeRect;
  final double holeRadius;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scrimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.74)
      ..style = PaintingStyle.fill;

    final rect = holeRect;
    if (rect == null || rect.width <= 0 || rect.height <= 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), scrimPaint);
      return;
    }

    final clippedRect = Rect.fromLTRB(
      rect.left.clamp(2.0, size.width - 2.0),
      rect.top.clamp(2.0, size.height - 2.0),
      rect.right.clamp(2.0, size.width - 2.0),
      rect.bottom.clamp(2.0, size.height - 2.0),
    );
    if (clippedRect.width <= 2 || clippedRect.height <= 2) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), scrimPaint);
      return;
    }

    final effectiveRadius = holeRadius.clamp(
      0.0,
      clippedRect.shortestSide / 2.0,
    );
    final holeRRect = RRect.fromRectAndRadius(
      clippedRect,
      Radius.circular(effectiveRadius),
    );

    // Use even-odd fill so the spotlight cutout stays 100% transparent/bright
    // across Skia, Impeller, and Web without Path.combine artifacts.
    final backdropPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(holeRRect);
    canvas.drawPath(backdropPath, scrimPaint);

    // Soft outer glow halo around the highlighted widget
    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawRRect(holeRRect, glowPaint);

    // Crisp bright border so the spotlight target pops clearly
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.96)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(holeRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightBackdropPainter oldDelegate) {
    return oldDelegate.holeRect != holeRect ||
        oldDelegate.holeRadius != holeRadius ||
        oldDelegate.accentColor != accentColor;
  }
}

