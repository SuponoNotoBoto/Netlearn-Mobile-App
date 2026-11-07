import 'package:flutter/foundation.dart';

@immutable
class LecturerAssessment {
  final String id;
  final String title;
  final String assessmentType;
  final int durationMinutes;
  final String status;
  final int questionCount;
  final int answeredCount;

  const LecturerAssessment({
    required this.id,
    required this.title,
    required this.assessmentType,
    required this.durationMinutes,
    required this.status,
    required this.questionCount,
    required this.answeredCount,
  });

  bool get isPretest => assessmentType == 'pretest';
  bool get isPublished => status == 'published';
  bool get canPublish => questionCount > 0 && answeredCount == questionCount;
  int get unansweredCount => questionCount - answeredCount;

  LecturerAssessment copyWith({
    String? status,
    int? answeredCount,
    int? questionCount,
  }) {
    return LecturerAssessment(
      id: id,
      title: title,
      assessmentType: assessmentType,
      durationMinutes: durationMinutes,
      status: status ?? this.status,
      questionCount: questionCount ?? this.questionCount,
      answeredCount: answeredCount ?? this.answeredCount,
    );
  }
}

@immutable
class LecturerTask {
  final String id;
  final String title;
  final String titleEn;
  final String titleId;
  final String assessmentType;
  final int durationMinutes;
  final String status;
  final int questionCount;
  final int answeredCount;
  final int? module;
  final bool required;
  final bool leaderboardEnabled;
  final int attemptsAllowed;
  final double weight;
  final String? description;
  final String? instructions;
  final int timeLimit;
  final DateTime? deadline;
  final int submittedCount;

  const LecturerTask({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.titleId,
    required this.assessmentType,
    required this.durationMinutes,
    required this.status,
    required this.questionCount,
    required this.answeredCount,
    this.module,
    this.required = false,
    this.leaderboardEnabled = true,
    this.attemptsAllowed = 1,
    this.weight = 1.0,
    this.description,
    this.instructions,
    this.timeLimit = 0,
    this.deadline,
    this.submittedCount = 0,
  });

  bool get isPublished => status == 'published';
  bool get canPublish => questionCount > 0 && answeredCount == questionCount;
  int get unansweredCount => questionCount - answeredCount;
  String get localizedTitle => titleId.isNotEmpty ? titleId : title;

  LecturerTask copyWith({
    String? status,
    int? questionCount,
    int? answeredCount,
    String? title,
    String? titleId,
    String? titleEn,
    String? description,
    String? instructions,
    int? module,
    bool? required,
    bool? leaderboardEnabled,
    int? attemptsAllowed,
    DateTime? deadline,
    int? durationMinutes,
    int? timeLimit,
  }) {
    return LecturerTask(
      id: id,
      title: title ?? this.title,
      titleEn: titleEn ?? this.titleEn,
      titleId: titleId ?? this.titleId,
      assessmentType: assessmentType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      questionCount: questionCount ?? this.questionCount,
      answeredCount: answeredCount ?? this.answeredCount,
      module: module ?? this.module,
      required: required ?? this.required,
      leaderboardEnabled: leaderboardEnabled ?? this.leaderboardEnabled,
      attemptsAllowed: attemptsAllowed ?? this.attemptsAllowed,
      weight: weight,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      timeLimit: timeLimit ?? this.timeLimit,
      deadline: deadline ?? this.deadline,
      submittedCount: submittedCount,
    );
  }
}

@immutable
class StudentScoreModel {
  final String id;
  final String name;
  final String identityNumber;
  final double? pretestScore;
  final double? posttestScore;

  const StudentScoreModel({
    required this.id,
    required this.name,
    required this.identityNumber,
    this.pretestScore,
    this.posttestScore,
  });
}

String formatScoreValue(double? score) {
  if (score == null) return '—';
  return score % 1 == 0 ? score.toInt().toString() : score.toStringAsFixed(1);
}

/// Initial dataset for gate assessments (Post-test & Pretest)
List<LecturerAssessment> getInitialAssessments() {
  return [
    const LecturerAssessment(
      id: 'quiz-posttest',
      title: 'Post Test - Ujian Akhir Pembelajaran Jaringan Komputer',
      assessmentType: 'posttest',
      durationMinutes: 30,
      status: 'published',
      questionCount: 25,
      answeredCount: 25,
    ),
    const LecturerAssessment(
      id: 'quiz-pretest',
      title: 'Pretest - Asesmen Awal Pemahaman Jaringan Komputer',
      assessmentType: 'pretest',
      durationMinutes: 20,
      status: 'published',
      questionCount: 20,
      answeredCount: 20,
    ),
  ];
}

/// Initial dataset for custom tasks and LMS quizzes
List<LecturerTask> getInitialTasks() {
  return [
    LecturerTask(
      id: 'task-1',
      title: 'Tugas 1: Subnetting IPv4 & CIDR',
      titleEn: 'Assignment 1: IPv4 Subnetting & CIDR',
      titleId: 'Tugas 1: Subnetting IPv4 & CIDR',
      assessmentType: 'task',
      durationMinutes: 45,
      status: 'published',
      questionCount: 10,
      answeredCount: 10,
      module: 1,
      required: true,
      leaderboardEnabled: true,
      attemptsAllowed: 1,
      deadline: DateTime.now().add(const Duration(days: 3)),
      submittedCount: 18,
      description: 'Perhitungan rentang IP, subnet mask, subnetting kelas C dan VLSM.',
      instructions: 'Kerjakan soal pilihan ganda berikut dan pastikan mengisi sebelum batas waktu.',
    ),
    LecturerTask(
      id: 'task-2',
      title: 'Kuis Checkpoint 1: Konsep Model OSI & TCP/IP',
      titleEn: 'Checkpoint Quiz 1: OSI & TCP/IP Model Concepts',
      titleId: 'Kuis Checkpoint 1: Konsep Model OSI & TCP/IP',
      assessmentType: 'quiz',
      durationMinutes: 15,
      status: 'published',
      questionCount: 15,
      answeredCount: 15,
      module: 2,
      required: true,
      leaderboardEnabled: true,
      attemptsAllowed: 2,
      deadline: DateTime.now().add(const Duration(days: 5)),
      submittedCount: 22,
      description: 'Uji pemahaman tentang 7 lapisan model OSI dan 4 lapisan protokol TCP/IP.',
      instructions: 'Pilihlah salah satu jawaban yang paling tepat dari pilihan yang tersedia.',
    ),
    LecturerTask(
      id: 'task-3',
      title: 'Tugas 2: Desain Topologi Jaringan Kampus',
      titleEn: 'Assignment 2: Campus Network Topology Design',
      titleId: 'Tugas 2: Desain Topologi Jaringan Kampus',
      assessmentType: 'task',
      durationMinutes: 60,
      status: 'draft',
      questionCount: 5,
      answeredCount: 5,
      module: null,
      required: false,
      leaderboardEnabled: false,
      attemptsAllowed: 1,
      deadline: DateTime.now().add(const Duration(days: 10)),
      submittedCount: 0,
      description: 'Perancangan topologi hybrid (Star-Bus) untuk efisiensi jaringan kampus.',
      instructions: 'Analisis kebutuhan perangkat keras dan susun skema pengalamatan IP.',
    ),
  ];
}

/// Initial dataset for student score recap table
List<StudentScoreModel> getInitialStudents() {
  return const [
    StudentScoreModel(
      id: 's-1',
      name: 'Rafi Ahmad Fauzan',
      identityNumber: '220535603123',
      pretestScore: 80.0,
      posttestScore: 92.0,
    ),
    StudentScoreModel(
      id: 's-2',
      name: 'Ahmad Dahlan',
      identityNumber: '220535603101',
      pretestScore: 75.0,
      posttestScore: 88.0,
    ),
    StudentScoreModel(
      id: 's-3',
      name: 'Siti Aminah',
      identityNumber: '220535603102',
      pretestScore: 85.0,
      posttestScore: 95.0,
    ),
    StudentScoreModel(
      id: 's-4',
      name: 'Budi Santoso',
      identityNumber: '220535603103',
      pretestScore: 60.0,
      posttestScore: 78.0,
    ),
    StudentScoreModel(
      id: 's-5',
      name: 'Dewi Lestari',
      identityNumber: '220535603104',
      pretestScore: 70.0,
      posttestScore: 84.0,
    ),
    StudentScoreModel(
      id: 's-6',
      name: 'Eko Prasetyo',
      identityNumber: '220535603105',
      pretestScore: null,
      posttestScore: null,
    ),
    StudentScoreModel(
      id: 's-7',
      name: 'Fajar Ramadhan',
      identityNumber: '220535603106',
      pretestScore: 65.0,
      posttestScore: 80.0,
    ),
    StudentScoreModel(
      id: 's-8',
      name: 'Gita Permata',
      identityNumber: '220535603107',
      pretestScore: 90.0,
      posttestScore: 98.0,
    ),
    StudentScoreModel(
      id: 's-9',
      name: 'Hendra Wijaya',
      identityNumber: '220535603108',
      pretestScore: 55.0,
      posttestScore: 72.0,
    ),
    StudentScoreModel(
      id: 's-10',
      name: 'Indah Sari',
      identityNumber: '220535603109',
      pretestScore: 82.0,
      posttestScore: 90.0,
    ),
  ];
}

