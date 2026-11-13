import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/core/theme/app_theme.dart';
import 'package:netlearn/features/auth/auth_widgets.dart';
import 'package:netlearn/shared/widgets/nl_netlearn_logo.dart';

void main() {
  testWidgets('AuthHero renders new logo, NetLearn title, and tagline in light & dark themes', (tester) async {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [AuthHero()],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AuthHero), findsOneWidget);
      final logoFinder = find.byType(NlNetLearnLogo);
      expect(logoFinder, findsOneWidget);
      expect(tester.widget<NlNetLearnLogo>(logoFinder).inverse, isTrue);
      expect(find.text('NetLearn'), findsOneWidget);
      expect(find.text('Computer Networking LMS'), findsOneWidget);
    }
  });

  testWidgets('NlNetLearnLogo paints cleanly in both inverse and normal modes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Row(
            children: [
              NlNetLearnLogo(size: 40, inverse: false),
              NlNetLearnLogo(size: 64, inverse: true),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NlNetLearnLogo), findsNWidgets(2));
    expect(find.bySemanticsLabel('NetLearn'), findsNWidgets(2));
  });
}

