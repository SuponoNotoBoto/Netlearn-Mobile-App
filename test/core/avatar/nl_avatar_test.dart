import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/core/avatar/nl_avatar_models.dart';
import 'package:netlearn/core/avatar/nl_avatar_widget.dart';

void main() {
  group('NL Avatar Catalog & Animal Characters', () {
    test('AvatarCatalog includes new animal bases', () {
      final baseIds = AvatarCatalog.bases.map((b) => b.id).toList();

      expect(baseIds, contains('monkey'));
      expect(baseIds, contains('frog'));
      expect(baseIds, contains('tiger'));
      expect(baseIds, contains('lion'));
      expect(baseIds, contains('hamster'));

      final monkey = AvatarCatalog.bases.firstWhere((b) => b.id == 'monkey');
      expect(monkey.labelId, 'Monyet');
      expect(monkey.labelEn, 'Monkey');

      final frog = AvatarCatalog.bases.firstWhere((b) => b.id == 'frog');
      expect(frog.labelId, 'Katak');
      expect(frog.labelEn, 'Frog');
    });

    test('AvatarConfig.fromMap validates and retains animal bases', () {
      for (final species in ['monkey', 'frog', 'tiger', 'lion', 'hamster']) {
        final config = AvatarConfig.fromMap({'base': species});
        expect(config.base, species);
      }
    });

    testWidgets('Renders all new animal bases cleanly without throwing', (tester) async {
      for (final species in ['monkey', 'frog', 'tiger', 'lion', 'hamster']) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: NlAvatarWidget(
                  config: AvatarConfig(base: species),
                  size: 96,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(NlAvatarWidget), findsOneWidget);
      }
    });
  });
}

