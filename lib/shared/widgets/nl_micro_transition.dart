import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Membangun animasi micro-transition (fade + subtle slide + micro-scale)
/// yang dipakai bersama oleh [NlPageTransitionsBuilder] dan [buildNlTransitionPage].
Widget buildNlRouteMicroTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final disableAnimations =
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  if (disableAnimations) {
    return child;
  }

  final curvedPrimary = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  final curvedSecondary = CurvedAnimation(
    parent: secondaryAnimation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.78, curve: Curves.easeOut),
    ),
  );

  final slideIn = Tween<Offset>(
    begin: const Offset(0.02, 0.012),
    end: Offset.zero,
  ).animate(curvedPrimary);

  final scaleIn = Tween<double>(
    begin: 0.988,
    end: 1.0,
  ).animate(curvedPrimary);

  final secondaryScaleOut = Tween<double>(
    begin: 1.0,
    end: 0.988,
  ).animate(curvedSecondary);

  return ScaleTransition(
    scale: secondaryScaleOut,
    child: FadeTransition(
      opacity: fadeIn,
      child: SlideTransition(
        position: slideIn,
        child: ScaleTransition(
          scale: scaleIn,
          child: child,
        ),
      ),
    ),
  );
}

/// Transisi halaman mikro (fade + subtle slide + micro-scale) untuk perpindahan
/// antarlayar yang halus di semua rute (`Navigator.push`, `GoRouter.go`, `GoRouter.push`)
/// tanpa mengubah struktur atau desain halaman.
class NlPageTransitionsBuilder extends PageTransitionsBuilder {
  const NlPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return buildNlRouteMicroTransition(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

/// Helper untuk `GoRoute.pageBuilder` agar perpindahan halaman via `context.go(...)`
/// maupun `context.push(...)` di seluruh role (Auth, Student, Lecturer) selalu
/// memiliki micro-transition yang halus.
CustomTransitionPage<T> buildNlTransitionPage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    name: state.name ?? state.path,
    arguments: state.extra,
    restorationId: state.pageKey.value,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: buildNlRouteMicroTransition,
    child: child,
  );
}

/// Mengubah `GoRouterWidgetBuilder` menjadi `GoRouterPageBuilder` dengan
/// micro-transition halus untuk seluruh rute aplikasi.
Page<dynamic> Function(BuildContext, GoRouterState) nlPageBuilder(
  Widget Function(BuildContext context, GoRouterState state) builder,
) {
  return (BuildContext context, GoRouterState state) =>
      buildNlTransitionPage<void>(
        state: state,
        child: builder(context, state),
      );
}

/// Micro-transition untuk perpindahan state di dalam satu halaman (misalnya dari
/// skeleton ke konten yang selesai dirender, atau perpindahan tab).
class NlContentTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final AlignmentGeometry alignment;

  const NlContentTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      return child;
    }

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: alignment,
          children: <Widget>[
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.02),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
