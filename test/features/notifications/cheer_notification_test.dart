import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/core/avatar/nl_avatar_models.dart';
import 'package:netlearn/core/theme/app_theme.dart';
import 'package:netlearn/features/achievements/achievement_service.dart';
import 'package:netlearn/features/notifications/cheer_notification_service.dart';
import 'package:netlearn/features/profile/public_profile_sheet.dart';
import 'package:netlearn/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CheerNotificationService', () {
    test('records and retrieves received cheers correctly', () async {
      final now = DateTime.now();
      final item = CheerNotificationItem(
        id: 'c1',
        senderId: 'user-budi',
        senderName: 'Budi Santoso',
        classId: 'class-ti-3b',
        className: 'TI-3B',
        createdAt: now,
      );

      final map = item.toMap();
      final parsed = CheerNotificationItem.fromMap(map);

      expect(parsed.id, 'c1');
      expect(parsed.senderName, 'Budi Santoso');
      expect(parsed.className, 'TI-3B');
      expect(parsed.senderId, 'user-budi');
    });
  });

  group('PublicMemberProfile fresh avatar mapping', () {
    test('uses newest avatarConfig and overrides fallback if present', () {
      const newCfg = AvatarConfig(
        base: 'fox',
        primaryColorHex: '#FF8A65',
        bgColorHex: '#EDE7F6',
        headwear: 'hat_cap',
        eyewear: 'glasses_round',
        accessory: 'bowtie',
      );

      final profileMap = {
        'user_id': 'u1',
        'display_name': 'Rendy',
        'role': 'student',
        'avatar_config': newCfg.toMap(),
        'cheers_count': 5,
        'cheered_today': false,
      };

      final profile = PublicMemberProfile.fromMap(profileMap);
      expect(profile.avatarConfig?.base, 'fox');
      expect(profile.avatarConfig?.headwear, 'hat_cap');
      expect(profile.avatarConfig?.eyewear, 'glasses_round');
      expect(profile.avatarConfig?.accessory, 'bowtie');
      expect(profile.cheersCount, 5);
      expect(profile.cheeredToday, isFalse);
    });
  });

  group('Achievement Badges specifications', () {
    test('allBadges have detailed descriptions and class-agnostic requirements', () {
      expect(AchievementService.allBadges.length, 5);
      for (final badge in AchievementService.allBadges) {
        expect(badge.id.isNotEmpty, isTrue);
        expect(badge.titleId.isNotEmpty, isTrue);
        expect(badge.descriptionId.isNotEmpty, isTrue);
        expect(badge.requirementId.isNotEmpty, isTrue);
        expect(badge.requirementEn.isNotEmpty, isTrue);
      }

      final networkScholar = AchievementService.allBadges.firstWhere((b) => b.id == 'network_scholar');
      expect(networkScholar.requirementId.contains('kelas mana saja'), isTrue);

      final fastLearner = AchievementService.allBadges.firstWhere((b) => b.id == 'fast_learner');
      expect(fastLearner.requirementId.contains('kelas mana saja'), isTrue);

      final packetSlinger = AchievementService.allBadges.firstWhere((b) => b.id == 'packet_slinger');
      expect(packetSlinger.requirementId.contains('kelas mana saja'), isTrue);
    });
  });

  testWidgets('Profile Cheers banner and modal sheet widget test', (tester) async {
    final testCheer = CheerNotificationItem(
      id: 'cheer-1',
      senderId: 'user-rina',
      senderName: 'Rina Mahasiswi',
      classId: 'class-1',
      className: 'Jaringan Komputer A',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView(
            children: [
              Container(
                key: const Key('profile_cheers_banner_test'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('👋 1 Semangat Diterima'),
                    Text('${testCheer.senderName} memberimu semangat!'),
                    Text('Kelas: ${testCheer.className}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_cheers_banner_test')), findsOneWidget);
    expect(find.text('👋 1 Semangat Diterima'), findsOneWidget);
    expect(find.text('Rina Mahasiswi memberimu semangat!'), findsOneWidget);
    expect(find.text('Kelas: Jaringan Komputer A'), findsOneWidget);
  });
}

