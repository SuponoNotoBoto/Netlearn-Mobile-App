import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_netlearn_logo.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  static const Duration _fullSequence = Duration(milliseconds: 2200);
  static const Duration _reducedSequence = Duration(milliseconds: 1400);
  static const Duration _loadingPeriod = Duration(milliseconds: 1100);
  static const double _loadingDelayFraction = 500 / 2200;

  late final AnimationController _sequence;
  late final AnimationController _loading;
  late Animation<double> _brandOpacity;
  late Animation<double> _brandScale;

  bool _configurationDone = false;
  bool _reducedMotion = false;
  bool _loadingStarted = false;
  bool _navigationDone = false;

  @override
  void initState() {
    super.initState();

    _sequence = AnimationController(vsync: this);
    _loading = AnimationController(vsync: this, duration: _loadingPeriod);
    _sequence.addStatusListener(_onSequenceStatus);
    _sequence.addListener(_maybeStartLoading);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_configurationDone) {
      return;
    }
    _configurationDone = true;

    _reducedMotion = MediaQuery.of(context).disableAnimations;
    _sequence.duration = _reducedMotion ? _reducedSequence : _fullSequence;

    _brandOpacity = _reducedMotion
        ? ConstantTween<double>(1).animate(_sequence)
        : TweenSequence<double>([
            TweenSequenceItem<double>(
              tween: Tween(begin: 0.0, end: 1.0)
                  .chain(CurveTween(curve: Curves.easeOut)),
              weight: 23,
            ),
            TweenSequenceItem<double>(
              tween: ConstantTween<double>(1),
              weight: 63,
            ),
            TweenSequenceItem<double>(
              tween: Tween(begin: 1.0, end: 0.0)
                  .chain(CurveTween(curve: Curves.easeIn)),
              weight: 14,
            ),
          ]).animate(_sequence);

    _brandScale = _reducedMotion
        ? ConstantTween<double>(1).animate(_sequence)
        : TweenSequence<double>([
            TweenSequenceItem<double>(
              tween: Tween(begin: 0.94, end: 1.0)
                  .chain(CurveTween(curve: Curves.easeOut)),
              weight: 23,
            ),
            TweenSequenceItem<double>(
              tween: ConstantTween<double>(1),
              weight: 77,
            ),
          ]).animate(_sequence);

    _sequence.forward();
  }

  @override
  void dispose() {
    _sequence.removeListener(_maybeStartLoading);
    _sequence.removeStatusListener(_onSequenceStatus);
    _sequence.dispose();
    _loading.dispose();
    super.dispose();
  }

  void _maybeStartLoading() {
    if (_reducedMotion || _loadingStarted || _navigationDone) {
      return;
    }

    if (_sequence.value >= _loadingDelayFraction) {
      _loadingStarted = true;
      _loading.repeat();
    }
  }

  void _onSequenceStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        _navigationDone ||
        !mounted) {
      return;
    }

    _navigationDone = true;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: NetLearnGradients.hero),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _sequence,
                builder: (context, child) {
                  return Opacity(
                    opacity: _brandOpacity.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: _brandScale.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const NlNetLearnLogo(inverse: true, size: 64),
                    const SizedBox(height: NetLearnSpace.s24),
                    const Text(
                      'NetLearn',
                      style: TextStyle(
                        fontFamily: AppTheme.displayFontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 34,
                        height: 40.8 / 34,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: NetLearnSpace.s20),
                    Text(
                      l10n.splashTagline,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        height: 1.5,
                        color: Color(0xFFCEC8ED),
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Semantics(
                label: l10n.splashOpening,
                child: ExcludeSemantics(
                  child: _LoadingBar(
                    animation: _loading,
                    animated: !_reducedMotion,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  static const double _thumbLeftStart = -44;
  static const double _thumbLeftEnd = 84;

  final Animation<double> animation;
  final bool animated;

  const _LoadingBar({required this.animation, required this.animated});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final progress = animated ? animation.value : 0.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: SizedBox(
            width: 80,
            height: 2,
            child: Stack(
              children: [
                Container(color: Colors.white.withValues(alpha: 0.2)),
                Positioned(
                  left: _thumbLeftStart +
                      (_thumbLeftEnd - _thumbLeftStart) * progress,
                  top: 0,
                  child: Container(
                    width: 40,
                    height: 2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

