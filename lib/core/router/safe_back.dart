import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Pops the current screen without ever stranding the user.
///
/// The shared [NlTopBar] back button used to be a bare `context.pop()`, which
/// only works when something sits underneath the current route. A deep link
/// that lands straight on a subpage (or a web reload that restores it) has an
/// empty GoRouter stack, so `pop()` is a silent no-op and the user is left on
/// a screen whose only navigation is the button they just pressed. The reader
/// even mixed stacks back when it pushed its PDF page through `Navigator` and
/// popped it through GoRouter, which tore the reader out from under it.
///
/// [goBack] pops when there is a previous route, and otherwise falls back to
/// the home screen of the logged-in area the current route belongs to
/// (`/student` or `/lecturer`) so the back button always ends somewhere the
/// user can navigate from.
///
/// [fallback] overrides that default destination for a single call. It exists
/// for the material and assessment pages, whose logical parent is a tab
/// (`/student/materials`, `/student/assessment`) rather than the dashboard, and
/// for a deep link the tab is not on the stack — landing the student on
/// `/student` would drop them out of the section they were reading. Ignored
/// when the stack can pop, so an in-app push still returns to the real parent.
void goBack(BuildContext context, {String? fallback}) {
  final router = GoRouter.of(context);

  if (router.canPop()) {
    router.pop();
    return;
  }

  if (fallback != null) {
    router.go(fallback);
    return;
  }

  final location = router.state.matchedLocation;

  final String defaultFallback;
  if (location.startsWith('/lecturer')) {
    defaultFallback = '/lecturer';
  } else if (location.startsWith('/student')) {
    defaultFallback = '/student';
  } else {
    defaultFallback = '/login';
  }

  router.go(defaultFallback);
}