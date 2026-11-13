import 'dart:convert';
import 'package:flutter/material.dart';

/// Serializable configuration for a consistent chibi cartoon avatar.
///
/// Stored as `jsonb` in `public.profiles.avatar_config` (and mirrored to
/// `SharedPreferences` + `subnet_drill_scores.avatar_config` for instant load).
class AvatarConfig {
  final String base;
  final String primaryColorHex;
  final String bgColorHex;
  final String headwear;
  final String eyewear;
  final String accessory;

  const AvatarConfig({
    this.base = 'cat',
    this.primaryColorHex = '#FFB74D',
    this.bgColorHex = '#EDE7F6',
    this.headwear = 'none',
    this.eyewear = 'none',
    this.accessory = 'none',
  });

  Color get primaryColor => _parseHex(primaryColorHex, const Color(0xFFFFB74D));
  Color get bgColor => _parseHex(bgColorHex, const Color(0xFFEDE7F6));

  AvatarConfig copyWith({
    String? base,
    String? primaryColorHex,
    String? bgColorHex,
    String? headwear,
    String? eyewear,
    String? accessory,
  }) {
    return AvatarConfig(
      base: base ?? this.base,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      bgColorHex: bgColorHex ?? this.bgColorHex,
      headwear: headwear ?? this.headwear,
      eyewear: eyewear ?? this.eyewear,
      accessory: accessory ?? this.accessory,
    );
  }

  Map<String, dynamic> toMap() => {
        'base': base,
        'primaryColorHex': primaryColorHex,
        'bgColorHex': bgColorHex,
        'headwear': headwear,
        'eyewear': eyewear,
        'accessory': accessory,
      };

  String toJsonString() => jsonEncode(toMap());

  factory AvatarConfig.fromMap(Map<String, dynamic> map) {
    final rawBase = map['base']?.toString() ?? 'cat';
    final validBase = AvatarCatalog.bases.any((b) => b.id == rawBase)
        ? rawBase
        : 'cat';

    final rawHead = map['headwear']?.toString() ?? 'none';
    final validHead = AvatarCatalog.headwear.any((h) => h.id == rawHead)
        ? rawHead
        : 'none';

    final rawEye = map['eyewear']?.toString() ?? 'none';
    final validEye = AvatarCatalog.eyewear.any((e) => e.id == rawEye)
        ? rawEye
        : 'none';

    final rawAcc = map['accessory']?.toString() ?? 'none';
    final validAcc = AvatarCatalog.accessories.any((a) => a.id == rawAcc)
        ? rawAcc
        : 'none';

    return AvatarConfig(
      base: validBase,
      primaryColorHex: map['primaryColorHex']?.toString() ?? '#FFB74D',
      bgColorHex: map['bgColorHex']?.toString() ?? '#EDE7F6',
      headwear: validHead,
      eyewear: validEye,
      accessory: validAcc,
    );
  }

  static AvatarConfig? fromDynamic(dynamic raw) {
    if (raw == null) return null;
    if (raw is AvatarConfig) return raw;
    if (raw is Map) {
      return AvatarConfig.fromMap(Map<String, dynamic>.from(raw));
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return AvatarConfig.fromMap(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }
    return null;
  }

  /// Generates a deterministic, cute starter cartoon avatar from any user ID or name
  /// so classmates who have not yet customized still get a charming, unique character.
  factory AvatarConfig.defaultFor(String seed) {
    final clean = seed.trim().isEmpty ? 'netlearn' : seed.trim();
    var hash = 0;
    for (var i = 0; i < clean.length; i++) {
      hash = ((hash * 31) + clean.codeUnitAt(i)) & 0x7fffffff;
    }

    const starterBases = [
      'cat',
      'dog',
      'bear',
      'rabbit',
      'fox',
      'panda',
      'monkey',
      'frog',
      'tiger',
      'lion',
      'hamster',
      'owl',
      'koala',
    ];
    const starterColors = [
      '#FFB74D',
      '#D7A86E',
      '#A1887F',
      '#F48FB1',
      '#FF8A65',
      '#90CAF9',
      '#CE93D8',
      '#B0BEC5',
    ];
    const starterBgs = [
      '#EDE7F6',
      '#E3F2FD',
      '#FFF3E0',
      '#FCE4EC',
      '#E8F5E9',
      '#E0F7FA',
      '#FFFDE7',
      '#F3E5F5',
    ];

    final baseIdx = hash % starterBases.length;
    final bgIdx = (hash ~/ 7) % starterBgs.length;
    final chosenBase = starterBases[baseIdx];

    // Natural default color per species with variation
    final defaultHex = switch (chosenBase) {
      'panda' => '#ECEFF1',
      'fox' => '#FF8A65',
      'koala' => '#B0BEC5',
      'bear' => '#A1887F',
      'rabbit' => '#F8BBD0',
      'monkey' => '#A1887F',
      'frog' => '#80CBC4',
      'tiger' => '#FFB74D',
      'lion' => '#FFE082',
      'hamster' => '#FFCC80',
      _ => starterColors[(hash ~/ 3) % starterColors.length],
    };

    return AvatarConfig(
      base: chosenBase,
      primaryColorHex: defaultHex,
      bgColorHex: starterBgs[bgIdx],
    );
  }

  static Color _parseHex(String hex, Color fallback) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      final val = int.tryParse('FF$cleaned', radix: 16);
      if (val != null) return Color(val);
    } else if (cleaned.length == 8) {
      final val = int.tryParse(cleaned, radix: 16);
      if (val != null) return Color(val);
    }
    return fallback;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarConfig &&
          base == other.base &&
          primaryColorHex == other.primaryColorHex &&
          bgColorHex == other.bgColorHex &&
          headwear == other.headwear &&
          eyewear == other.eyewear &&
          accessory == other.accessory;

  @override
  int get hashCode => Object.hash(
        base,
        primaryColorHex,
        bgColorHex,
        headwear,
        eyewear,
        accessory,
      );
}

/// Metadata for a selectable avatar character or accessory item.
class AvatarCatalogItem {
  final String id;
  final String labelId;
  final String labelEn;
  final String? requiredBadgeId;
  final int requiredBadgeCount;
  final String? unlockHintId;
  final String? unlockHintEn;

  const AvatarCatalogItem({
    required this.id,
    required this.labelId,
    required this.labelEn,
    this.requiredBadgeId,
    this.requiredBadgeCount = 0,
    this.unlockHintId,
    this.unlockHintEn,
  });

  String label(bool isId) => isId ? labelId : labelEn;

  String? unlockHint(bool isId) => isId ? unlockHintId : unlockHintEn;

  bool isUnlocked({
    required Set<String> unlockedBadges,
    bool isLecturer = false,
  }) {
    if (isLecturer) return true;
    if (requiredBadgeCount > 0) {
      return unlockedBadges.length >= requiredBadgeCount;
    }
    if (requiredBadgeId != null && requiredBadgeId!.isNotEmpty) {
      return unlockedBadges.contains(requiredBadgeId);
    }
    return true;
  }
}

/// Complete catalog of characters, colors, headwear, eyewear, and accessories.
class AvatarCatalog {
  static const List<AvatarCatalogItem> bases = [
    AvatarCatalogItem(id: 'cat', labelId: 'Kucing', labelEn: 'Cat'),
    AvatarCatalogItem(id: 'dog', labelId: 'Anjing', labelEn: 'Puppy'),
    AvatarCatalogItem(id: 'bear', labelId: 'Beruang', labelEn: 'Bear'),
    AvatarCatalogItem(id: 'rabbit', labelId: 'Kelinci', labelEn: 'Bunny'),
    AvatarCatalogItem(id: 'fox', labelId: 'Rubah', labelEn: 'Fox'),
    AvatarCatalogItem(id: 'panda', labelId: 'Panda', labelEn: 'Panda'),
    AvatarCatalogItem(id: 'monkey', labelId: 'Monyet', labelEn: 'Monkey'),
    AvatarCatalogItem(id: 'frog', labelId: 'Katak', labelEn: 'Frog'),
    AvatarCatalogItem(id: 'tiger', labelId: 'Harimau', labelEn: 'Tiger'),
    AvatarCatalogItem(id: 'lion', labelId: 'Singa', labelEn: 'Lion'),
    AvatarCatalogItem(id: 'hamster', labelId: 'Hamster', labelEn: 'Hamster'),
    AvatarCatalogItem(id: 'owl', labelId: 'Burung Hantu', labelEn: 'Owl'),
    AvatarCatalogItem(id: 'koala', labelId: 'Koala', labelEn: 'Koala'),
    AvatarCatalogItem(
      id: 'penguin',
      labelId: 'Pinguin',
      labelEn: 'Penguin',
      requiredBadgeId: 'network_scholar',
      unlockHintId: 'Buka dengan menyelesaikan bacaan materi (Lencana Network Scholar)',
      unlockHintEn: 'Unlock by completing material reading (Network Scholar badge)',
    ),
    AvatarCatalogItem(
      id: 'robot',
      labelId: 'Cyber Bot',
      labelEn: 'Cyber Bot',
      requiredBadgeId: 'packet_slinger',
      unlockHintId: 'Buka dengan menyelesaikan simulasi Virtual Lab (Lencana Packet Slinger)',
      unlockHintEn: 'Unlock by completing Virtual Lab ping test (Packet Slinger badge)',
    ),
  ];

  static const List<String> primaryColorHexes = [
    '#37474F', // Charcoal Classic
    '#FFB74D', // Warm Orange
    '#FF8A65', // Fox Coral
    '#A1887F', // Cozy Brown
    '#F48FB1', // Cotton Pink
    '#CE93D8', // Lavender
    '#90CAF9', // Sky Blue
    '#80CBC4', // Mint Teal
    '#AED581', // Matcha Green
    '#FFE082', // Sunny Butter
    '#B0BEC5', // Koala Silver
    '#ECEFF1', // Cloud White
    '#9575CD', // Royal Violet
  ];

  static const List<String> bgColorHexes = [
    '#EDE7F6', // Soft Purple
    '#E3F2FD', // Soft Blue
    '#FFF3E0', // Soft Peach
    '#FCE4EC', // Soft Rose
    '#E8F5E9', // Soft Mint
    '#E0F7FA', // Soft Cyan
    '#FFFDE7', // Soft Lemon
    '#F3E5F5', // Soft Lilac
    '#FBE9E7', // Soft Coral
    '#ECEFF1', // Soft Slate
  ];

  static const List<AvatarCatalogItem> headwear = [
    AvatarCatalogItem(id: 'none', labelId: 'Tanpa Topi', labelEn: 'None'),
    AvatarCatalogItem(id: 'sprout', labelId: 'Tunas Daun', labelEn: 'Leaf Sprout'),
    AvatarCatalogItem(id: 'bow', labelId: 'Pita Lucu', labelEn: 'Cute Bow'),
    AvatarCatalogItem(id: 'hat_cap', labelId: 'Topi Kasual', labelEn: 'Baseball Cap'),
    AvatarCatalogItem(id: 'hat_beanie', labelId: 'Kupluk Hangat', labelEn: 'Cozy Beanie'),
    AvatarCatalogItem(
      id: 'hat_graduate',
      labelId: 'Topi Wisuda',
      labelEn: 'Grad Cap',
      requiredBadgeId: 'fast_learner',
      unlockHintId: 'Buka dengan menuntaskan modul & kuis (Lencana Fast Learner)',
      unlockHintEn: 'Unlock by completing modules & quiz (Fast Learner badge)',
    ),
    AvatarCatalogItem(
      id: 'hat_wizard',
      labelId: 'Topi Penyihir AR',
      labelEn: 'AR Wizard Hat',
      requiredBadgeId: 'ar_pioneer',
      unlockHintId: 'Buka dengan memindai marker AR 3D (Lencana AR Pioneer)',
      unlockHintEn: 'Unlock by scanning a 3D AR marker (AR Pioneer badge)',
    ),
    AvatarCatalogItem(
      id: 'crown',
      labelId: 'Mahkota Juara',
      labelEn: 'Royal Crown',
      requiredBadgeCount: 3,
      unlockHintId: 'Buka dengan mengumpulkan minimal 3 Lencana Pencapaian!',
      unlockHintEn: 'Unlock by earning at least 3 Achievement Badges!',
    ),
  ];

  static const List<AvatarCatalogItem> eyewear = [
    AvatarCatalogItem(id: 'none', labelId: 'Tanpa Kacamata', labelEn: 'None'),
    AvatarCatalogItem(id: 'glasses_round', labelId: 'Bulat Manis', labelEn: 'Round Glasses'),
    AvatarCatalogItem(id: 'glasses_nerd', labelId: 'Kacamata Belajar', labelEn: 'Study Frames'),
    AvatarCatalogItem(
      id: 'monocle',
      labelId: 'Monokel Cendekia',
      labelEn: 'Scholar Monocle',
      requiredBadgeId: 'network_scholar',
      unlockHintId: 'Buka dengan Lencana Network Scholar (baca materi hingga tuntas)',
      unlockHintEn: 'Unlock with the Network Scholar badge (finish reading material)',
    ),
    AvatarCatalogItem(
      id: 'glasses_cool',
      labelId: 'Kacamata Keren',
      labelEn: 'Cool Shades',
      requiredBadgeId: 'packet_slinger',
      unlockHintId: 'Buka dengan Lencana Packet Slinger (tes ping di Virtual Lab)',
      unlockHintEn: 'Unlock with the Packet Slinger badge (Virtual Lab ping test)',
    ),
  ];

  static const List<AvatarCatalogItem> accessories = [
    AvatarCatalogItem(id: 'none', labelId: 'Tanpa Ekstra', labelEn: 'None'),
    AvatarCatalogItem(id: 'bowtie', labelId: 'Dasi Kupu', labelEn: 'Bowtie'),
    AvatarCatalogItem(id: 'scarf', labelId: 'Syal Hangat', labelEn: 'Cozy Scarf'),
    AvatarCatalogItem(
      id: 'headphone',
      labelId: 'Headphone Cyber',
      labelEn: 'Cyber Headphones',
      requiredBadgeId: 'subnet_master',
      unlockHintId: 'Buka dengan skor 100+ di Subnet Drill (Lencana Subnet Master)',
      unlockHintEn: 'Unlock by scoring 100+ in Subnet Drill (Subnet Master badge)',
    ),
  ];

  /// Computes a gamification title based on earned points and badges.
  static String socialRankTitle({
    required double totalPoints,
    required int badgeCount,
    required bool isLecturer,
    required bool isId,
  }) {
    if (isLecturer) {
      return isId ? 'Dosen Pembimbing Kelas' : 'Class Mentor & Lecturer';
    }
    if (totalPoints >= 250 || badgeCount >= 4) {
      return isId ? 'Master Arsitek Jaringan' : 'Network Master Architect';
    }
    if (totalPoints >= 150 || badgeCount >= 3) {
      return isId ? 'Spesialis Paket & Subnet' : 'Packet & Subnet Specialist';
    }
    if (totalPoints >= 60 || badgeCount >= 1) {
      return isId ? 'Penjelajah Jaringan' : 'Network Explorer';
    }
    return isId ? 'Kadet Jaringan Muda' : 'Junior Net Cadet';
  }
}

