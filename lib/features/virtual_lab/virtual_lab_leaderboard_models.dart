import 'package:flutter/foundation.dart';
import '../../core/avatar/nl_avatar_models.dart';

/// Metadata untuk opsi filter misi praktikum di leaderboard.
@immutable
class VirtualLabMissionMeta {
  final String id;
  final String titleId;
  final String titleEn;
  final int moduleNumber;
  final String defaultPreset;

  const VirtualLabMissionMeta({
    required this.id,
    required this.titleId,
    required this.titleEn,
    required this.moduleNumber,
    required this.defaultPreset,
  });

  String localizedTitle(String langCode) => langCode == 'en' ? titleEn : titleId;

  /// Daftar misi praktikum default berdasarkan modul standar NetLearn.
  static const List<VirtualLabMissionMeta> defaultMissions = [
    VirtualLabMissionMeta(
      id: 'module_1_p2p',
      titleId: 'Modul 1: Topologi P2P',
      titleEn: 'Module 1: P2P Topology',
      moduleNumber: 1,
      defaultPreset: 'p2p',
    ),
    VirtualLabMissionMeta(
      id: 'module_2_star',
      titleId: 'Modul 2: Topologi Star LAN',
      titleEn: 'Module 2: Star LAN Topology',
      moduleNumber: 2,
      defaultPreset: 'star',
    ),
    VirtualLabMissionMeta(
      id: 'module_3_dual_subnet',
      titleId: 'Modul 3: Routing & Gateway',
      titleEn: 'Module 3: Routing & Gateway',
      moduleNumber: 3,
      defaultPreset: 'dual_subnet',
    ),
    VirtualLabMissionMeta(
      id: 'module_4_dhcp_server',
      titleId: 'Modul 4: Layanan Server DHCP',
      titleEn: 'Module 4: DHCP Server Service',
      moduleNumber: 4,
      defaultPreset: 'dhcp_server',
    ),
  ];
}

/// Satu entri skor misi praktikum Virtual Lab oleh seorang mahasiswa.
@immutable
class VirtualLabScore {
  final String id;
  final String studentId;
  final String studentName;
  final String? classId;
  final String materialId;
  final String materialTitle;
  final String preset;
  final int score;
  final int completedTasks;
  final int totalTasks;
  final bool isPassed;
  final DateTime date;
  final AvatarConfig? avatarConfig;

  const VirtualLabScore({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.classId,
    required this.materialId,
    required this.materialTitle,
    required this.preset,
    required this.score,
    required this.completedTasks,
    required this.totalTasks,
    required this.isPassed,
    required this.date,
    this.avatarConfig,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'classId': classId,
        'materialId': materialId,
        'materialTitle': materialTitle,
        'preset': preset,
        'score': score,
        'completedTasks': completedTasks,
        'totalTasks': totalTasks,
        'isPassed': isPassed,
        'date': date.toIso8601String(),
        if (avatarConfig != null) 'avatarConfig': avatarConfig!.toMap(),
      };

  factory VirtualLabScore.fromMap(Map<String, dynamic> map) => VirtualLabScore(
        id: map['id']?.toString() ?? '',
        studentId: map['studentId']?.toString() ?? map['user_id']?.toString() ?? '',
        studentName: map['studentName']?.toString() ?? map['student_name']?.toString() ?? 'Mahasiswa',
        classId: map['classId']?.toString() ?? map['class_id']?.toString(),
        materialId: map['materialId']?.toString() ?? map['material_id']?.toString() ?? '',
        materialTitle: map['materialTitle']?.toString() ?? map['material_title']?.toString() ?? 'Praktikum Virtual Lab',
        preset: map['preset']?.toString() ?? '',
        score: (map['score'] as num?)?.toInt() ?? 0,
        completedTasks: (map['completedTasks'] as num?)?.toInt() ?? (map['completed_tasks'] as num?)?.toInt() ?? 0,
        totalTasks: (map['totalTasks'] as num?)?.toInt() ?? (map['total_tasks'] as num?)?.toInt() ?? 0,
        isPassed: map['isPassed'] == true || map['is_passed'] == true,
        date: DateTime.tryParse(map['date']?.toString() ?? map['updated_at']?.toString() ?? '') ?? DateTime.now(),
        avatarConfig: AvatarConfig.fromDynamic(
          map['avatarConfig'] ?? map['avatar_config'],
        ),
      );
}

/// Akumulasi performa praktikum Virtual Lab seorang mahasiswa di seluruh misi.
@immutable
class VirtualLabOverallScore {
  final String studentId;
  final String studentName;
  final String? classId;
  final int totalScore;
  final double averageScore;
  final int completedMissions;
  final int totalAvailableMissions;
  final DateTime lastSubmittedAt;
  final AvatarConfig? avatarConfig;

  const VirtualLabOverallScore({
    required this.studentId,
    required this.studentName,
    this.classId,
    required this.totalScore,
    required this.averageScore,
    required this.completedMissions,
    required this.totalAvailableMissions,
    required this.lastSubmittedAt,
    this.avatarConfig,
  });

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'studentName': studentName,
        'classId': classId,
        'totalScore': totalScore,
        'averageScore': averageScore,
        'completedMissions': completedMissions,
        'totalAvailableMissions': totalAvailableMissions,
        'lastSubmittedAt': lastSubmittedAt.toIso8601String(),
        if (avatarConfig != null) 'avatarConfig': avatarConfig!.toMap(),
      };

  factory VirtualLabOverallScore.fromMap(Map<String, dynamic> map) =>
      VirtualLabOverallScore(
        studentId: map['studentId']?.toString() ?? '',
        studentName: map['studentName']?.toString() ?? 'Mahasiswa',
        classId: map['classId']?.toString(),
        totalScore: (map['totalScore'] as num?)?.toInt() ?? 0,
        averageScore: (map['averageScore'] as num?)?.toDouble() ?? 0.0,
        completedMissions: (map['completedMissions'] as num?)?.toInt() ?? 0,
        totalAvailableMissions:
            (map['totalAvailableMissions'] as num?)?.toInt() ?? 4,
        lastSubmittedAt:
            DateTime.tryParse(map['lastSubmittedAt']?.toString() ?? '') ??
                DateTime.now(),
        avatarConfig: AvatarConfig.fromDynamic(map['avatarConfig']),
      );
}

