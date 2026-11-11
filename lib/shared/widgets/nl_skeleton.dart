import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme/app_theme.dart';

/// Mendeteksi apakah aplikasi sedang berjalan di dalam `flutter test`
/// (`TestWidgetsFlutterBinding`) agar animasi shimmer berulang tidak menahan
/// `tester.pumpAndSettle()` tanpa batas kecuali diminta lewat [animateInTest].
bool _isRunningInWidgetTest() {
  final bindingType = SchedulerBinding.instance.runtimeType.toString();
  return bindingType.contains('Test') || bindingType.contains('Automated');
}

/// Kotak skeleton dasar dengan efek shimmer halus yang mengikuti tema terang/gelap
/// aplikasi NetLearn tanpa mengubah layout maupun desain yang sudah ada.
class NlSkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final BoxShape shape;
  final bool animateInTest;

  const NlSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
    this.animateInTest = false,
  });

  const NlSkeletonBox.circle({
    super.key,
    required double size,
    this.animateInTest = false,
  }) : width = size,
       height = size,
       borderRadius = 0,
       shape = BoxShape.circle;

  @override
  State<NlSkeletonBox> createState() => _NlSkeletonBoxState();
}

class _NlSkeletonBoxState extends State<NlSkeletonBox>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  bool get _shouldAnimate {
    if (!widget.animateInTest && _isRunningInWidgetTest()) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    if (_shouldAnimate) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1350),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final baseColor = isDark
        ? const Color(0xFF282634)
        : const Color(0xFFEDEAF6);
    final highlightColor = isDark
        ? const Color(0xFF353246)
        : const Color(0xFFF7F5FC);

    final controller = _controller;
    if (controller == null || disableAnimations) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: baseColor,
          shape: widget.shape,
          borderRadius: widget.shape == BoxShape.circle
              ? null
              : BorderRadius.circular(widget.borderRadius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final slide = (controller.value * 2.4) - 1.2;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(slide - 0.8, -0.2),
              end: Alignment(slide + 0.8, 0.2),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}

/// Kartu skeleton yang mengikuti bentuk kartu standar NetLearn (`context.surface`,
/// `context.border`, `NetLearnRadius.card`).
class NlSkeletonCard extends StatelessWidget {
  final bool showLeadingBox;
  final double leadingSize;
  final bool leadingCircle;
  final bool showTrailingBadge;
  final bool? showTrailing;
  final bool showSubtitle;
  final EdgeInsetsGeometry padding;
  final bool animateInTest;

  const NlSkeletonCard({
    super.key,
    this.showLeadingBox = true,
    this.leadingSize = 44,
    this.leadingCircle = false,
    this.showTrailingBadge = true,
    this.showTrailing,
    this.showSubtitle = true,
    this.padding = const EdgeInsets.all(NetLearnSpace.s16),
    this.animateInTest = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTrailing = showTrailing ?? showTrailingBadge;
    return Semantics(
      label: 'Loading content',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(NetLearnRadius.card),
          border: Border.all(color: context.border),
        ),
        child: Row(
          children: [
            if (showLeadingBox) ...[
              leadingCircle
                  ? NlSkeletonBox.circle(
                      size: leadingSize,
                      animateInTest: animateInTest,
                    )
                  : NlSkeletonBox(
                      width: leadingSize,
                      height: leadingSize,
                      borderRadius: NetLearnRadius.moduleNumber,
                      animateInTest: animateInTest,
                    ),
              const SizedBox(width: NetLearnSpace.s12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  NlSkeletonBox(
                    width: 150,
                    height: 13,
                    borderRadius: 6,
                    animateInTest: animateInTest,
                  ),
                  if (showSubtitle) ...[
                    const SizedBox(height: 8),
                    NlSkeletonBox(
                      width: 100,
                      height: 10,
                      borderRadius: 5,
                      animateInTest: animateInTest,
                    ),
                  ],
                ],
              ),
            ),
            if (effectiveTrailing) ...[
              const SizedBox(width: NetLearnSpace.s12),
              NlSkeletonBox(
                width: 56,
                height: 22,
                borderRadius: NetLearnRadius.pill,
                animateInTest: animateInTest,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Daftar kartu skeleton untuk layar/bagian list saat data masih dirender.
class NlSkeletonList extends StatelessWidget {
  final int itemCount;
  final double spacing;
  final EdgeInsetsGeometry padding;
  final bool showTrailingBadge;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool animateInTest;

  const NlSkeletonList({
    super.key,
    this.itemCount = 3,
    this.spacing = NetLearnSpace.s12,
    this.padding = EdgeInsets.zero,
    this.showTrailingBadge = true,
    this.shrinkWrap = true,
    this.physics,
    this.animateInTest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            NlSkeletonCard(
              showTrailingBadge: showTrailingBadge,
              animateInTest: animateInTest,
            ),
            if (i < itemCount - 1) SizedBox(height: spacing),
          ],
        ],
      ),
    );
  }
}

/// Skeleton khusus bagian "Learning Progress" / ringkasan progres di Dashboard
/// supaya tinggi dan struktur visualnya identik dengan kartu asli saat memuat.
class NlDashboardProgressSkeleton extends StatelessWidget {
  final int moduleRows;
  final bool animateInTest;

  const NlDashboardProgressSkeleton({
    super.key,
    this.moduleRows = 2,
    this.animateInTest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading progress',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary progress card skeleton
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(NetLearnSpace.s16),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(NetLearnRadius.card),
              border: Border.all(color: context.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    NlSkeletonBox(
                      width: 120,
                      height: 12,
                      borderRadius: 6,
                      animateInTest: animateInTest,
                    ),
                    NlSkeletonBox(
                      width: 40,
                      height: 16,
                      borderRadius: 6,
                      animateInTest: animateInTest,
                    ),
                  ],
                ),
                const SizedBox(height: NetLearnSpace.s10),
                NlSkeletonBox(
                  width: double.infinity,
                  height: 8,
                  borderRadius: NetLearnRadius.pill,
                  animateInTest: animateInTest,
                ),
                const SizedBox(height: NetLearnSpace.s8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    NlSkeletonBox(
                      width: 90,
                      height: 9,
                      borderRadius: 4,
                      animateInTest: animateInTest,
                    ),
                    NlSkeletonBox(
                      width: 64,
                      height: 9,
                      borderRadius: 4,
                      animateInTest: animateInTest,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (moduleRows > 0) ...[
            const SizedBox(height: NetLearnSpace.s12),
            NlSkeletonList(
              itemCount: moduleRows,
              animateInTest: animateInTest,
            ),
          ],
        ],
      ),
    );
  }
}

/// Skeleton pratinjau notifikasi/aktivitas terbaru di Dashboard.
class NlNotificationsPreviewSkeleton extends StatelessWidget {
  final int rows;
  final int? count;
  final bool animateInTest;

  const NlNotificationsPreviewSkeleton({
    super.key,
    this.rows = 2,
    this.count,
    this.animateInTest = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRows = count ?? rows;
    return Semantics(
      label: 'Loading notifications',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: NetLearnSpace.s16,
          vertical: NetLearnSpace.s12,
        ),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(NetLearnRadius.card),
          border: Border.all(color: context.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < effectiveRows; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    NlSkeletonBox.circle(
                      size: 32,
                      animateInTest: animateInTest,
                    ),
                    const SizedBox(width: NetLearnSpace.s10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          NlSkeletonBox(
                            width: 140,
                            height: 12,
                            borderRadius: 5,
                            animateInTest: animateInTest,
                          ),
                          const SizedBox(height: 6),
                          NlSkeletonBox(
                            width: 96,
                            height: 9,
                            borderRadius: 4,
                            animateInTest: animateInTest,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i < effectiveRows - 1)
                Divider(
                  height: NetLearnSpace.s16,
                  thickness: 0.5,
                  color: context.border,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton untuk halaman detail (Baca Materi, Detail Materi, Video, PDF,
/// Instruksi/Hasil Assessment, dan Form Edit).
class NlSkeletonDetail extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final bool showBanner;
  final int paragraphBlocks;
  final bool animateInTest;

  const NlSkeletonDetail({
    super.key,
    this.padding = const EdgeInsets.all(NetLearnSpace.s20),
    this.showBanner = true,
    this.paragraphBlocks = 3,
    this.animateInTest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading detail',
      excludeSemantics: true,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showBanner) ...[
              NlSkeletonBox(
                width: double.infinity,
                height: 148,
                borderRadius: NetLearnRadius.card,
                animateInTest: animateInTest,
              ),
              const SizedBox(height: NetLearnSpace.s16),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(NetLearnSpace.s16),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(NetLearnRadius.card),
                border: Border.all(color: context.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NlSkeletonBox(
                    width: 96,
                    height: 10,
                    borderRadius: 5,
                    animateInTest: animateInTest,
                  ),
                  const SizedBox(height: 10),
                  NlSkeletonBox(
                    width: 220,
                    height: 16,
                    borderRadius: 6,
                    animateInTest: animateInTest,
                  ),
                  const SizedBox(height: 8),
                  NlSkeletonBox(
                    width: 160,
                    height: 12,
                    borderRadius: 5,
                    animateInTest: animateInTest,
                  ),
                  const SizedBox(height: 18),
                  for (var i = 0; i < paragraphBlocks; i++) ...[
                    NlSkeletonBox(
                      width: double.infinity,
                      height: 11,
                      borderRadius: 5,
                      animateInTest: animateInTest,
                    ),
                    const SizedBox(height: 8),
                    NlSkeletonBox(
                      width: double.infinity,
                      height: 11,
                      borderRadius: 5,
                      animateInTest: animateInTest,
                    ),
                    const SizedBox(height: 8),
                    NlSkeletonBox(
                      width: 180,
                      height: 11,
                      borderRadius: 5,
                      animateInTest: animateInTest,
                    ),
                    if (i < paragraphBlocks - 1) const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton untuk halaman Profil (Mahasiswa, Dosen, maupun Public Profile Sheet).
class NlSkeletonProfile extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final int menuRows;
  final bool animateInTest;

  const NlSkeletonProfile({
    super.key,
    this.padding = const EdgeInsets.all(NetLearnSpace.s20),
    this.menuRows = 4,
    this.animateInTest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading profile',
      excludeSemantics: true,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(NetLearnRadius.cardLg),
                border: Border.all(color: context.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NlSkeletonBox.circle(
                        size: 62,
                        animateInTest: animateInTest,
                      ),
                      const Spacer(),
                      NlSkeletonBox(
                        width: 72,
                        height: 24,
                        borderRadius: NetLearnRadius.pill,
                        animateInTest: animateInTest,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  NlSkeletonBox(
                    width: 180,
                    height: 16,
                    borderRadius: 6,
                    animateInTest: animateInTest,
                  ),
                  const SizedBox(height: 8),
                  NlSkeletonBox(
                    width: 120,
                    height: 12,
                    borderRadius: 5,
                    animateInTest: animateInTest,
                  ),
                ],
              ),
            ),
            const SizedBox(height: NetLearnSpace.s16),
            NlSkeletonList(
              itemCount: menuRows,
              animateInTest: animateInTest,
            ),
          ],
        ),
      ),
    );
  }
}
