import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

DateTime? _lastHapticTime;

void _triggerTactileHaptic() {
  final now = DateTime.now();
  if (_lastHapticTime != null &&
      now.difference(_lastHapticTime!) < const Duration(milliseconds: 45)) {
    return;
  }
  _lastHapticTime = now;
  HapticFeedback.selectionClick();
}

/// Splash factory kustom di tingkat `ThemeData` yang membungkus `InkRipple`
/// sekaligus memberikan umpan balik taktil di seluruh tombol Material dan `InkWell`
/// pada semua halaman dan semua role tanpa memicu error shader `ink_sparkle.frag`.
class NlTactileRippleFactory extends InteractiveInkFeatureFactory {
  const NlTactileRippleFactory();

  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  }) {
    _triggerTactileHaptic();
    return InkRipple.splashFactory.create(
      controller: controller,
      referenceBox: referenceBox,
      position: position,
      color: color,
      textDirection: textDirection,
      containedInkWell: containedInkWell,
      rectCallback: rectCallback,
      borderRadius: borderRadius,
      customBorder: customBorder,
      radius: radius,
      onRemoved: onRemoved,
    );
  }
}

/// Memberikan animasi tekan (tactile scale-down + spring release) saat elemen
/// interaktif disentuh pada perangkat Android/touch tanpa mengubah desain visual
/// maupun mengganggu arena gesture (`InkWell`, `ElevatedButton`, dll.).
class NlTapScale extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double scaleDown;
  final double? pressedScale;
  final Duration downDuration;
  final Duration upDuration;
  final bool enableHaptic;

  const NlTapScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scaleDown = 0.965,
    this.pressedScale,
    this.downDuration = const Duration(milliseconds: 95),
    this.upDuration = const Duration(milliseconds: 160),
    this.enableHaptic = true,
  });

  double get effectiveScaleDown => pressedScale ?? scaleDown;

  @override
  State<NlTapScale> createState() => _NlTapScaleState();
}

class _NlTapScaleState extends State<NlTapScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.downDuration,
      reverseDuration: widget.upDuration,
      value: 0.0,
    );
    _updateScaleAnimation();
  }

  @override
  void didUpdateWidget(covariant NlTapScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.downDuration != widget.downDuration ||
        oldWidget.upDuration != widget.upDuration) {
      _controller.duration = widget.downDuration;
      _controller.reverseDuration = widget.upDuration;
    }
    if (oldWidget.effectiveScaleDown != widget.effectiveScaleDown) {
      _updateScaleAnimation();
    }
    if (!widget.enabled && _controller.value > 0.0) {
      _controller.value = 0.0;
    }
  }

  void _updateScaleAnimation() {
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.effectiveScaleDown,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.enabled || !mounted) return;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) return;

    if (widget.enableHaptic) {
      _triggerTactileHaptic();
    }
    _controller.forward();
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!widget.enabled || !mounted) return;
    _controller.reverse();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (!widget.enabled || !mounted) return;
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!widget.enabled || disableAnimations) {
      return widget.child;
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
