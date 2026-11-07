import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_client.dart';
import 'lecturer_dashboard_controller.dart';

// ============================================================
// ASSESSMENT MODELS
// ============================================================

class LecturerAssessment {
  final String id;
  final String title;
  final String titleEn;
  final String titleId;
  final String assessmentType;
  final int durationMinutes;
  final String status;
  final int questionCount;
  final int answeredCount;

  const LecturerAssessment({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.titleId,
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
    String? id,
    String? title,
    String? titleEn,
    String? titleId,
    String? assessmentType,
    int? durationMinutes,
    String? status,
    int? questionCount,
    int? answeredCount,
  }) {
    return LecturerAssessment(
      id: id ?? this.id,
      title: title ?? this.title,
      titleEn: titleEn ?? this.titleEn,
      titleId: titleId ?? this.titleId,
      assessmentType: assessmentType ?? this.assessmentType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      questionCount: questionCount ?? this.questionCount,
      answeredCount: answeredCount ?? this.answeredCount,
    );
  }
}

List<LecturerAssessment> orderAssessments(
  List<LecturerAssessment> assessments,
) {
  final indexed = assessments.asMap().entries.toList();

  indexed.sort((a, b) {
    final rank = _assessmentRank(a.value).compareTo(_assessmentRank(b.value));
    return rank != 0 ? rank : a.key.compareTo(b.key);
  });

  return [for (final entry in indexed) entry.value];
}

int _assessmentRank(LecturerAssessment assessment) {
  switch (assessment.assessmentType) {
    case 'posttest':
      return 0;
    case 'pretest':
      return 1;
    default:
      return 2;
  }
}

// ============================================================
// TASK MODEL
// ============================================================

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
  final String? descriptionEn;
  final String? descriptionId;
  final String? instructions;
  final String? instructionsEn;
  final String? instructionsId;
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
    this.descriptionEn,
    this.descriptionId,
    this.instructions,
    this.instructionsEn,
    this.instructionsId,
    this.timeLimit = 0,
    this.deadline,
    this.submittedCount = 0,
  });

  bool get isPublished => status == 'published';

  bool get canPublish => questionCount > 0 && answeredCount == questionCount;

  int get unansweredCount => questionCount - answeredCount;

  String get localizedTitle => titleId.isNotEmpty ? titleId : title;

  String get localizedDescription =>
      descriptionId?.isNotEmpty == true ? descriptionId! : (description ?? '');

  String get localizedInstructions =>
      instructionsId?.isNotEmpty == true ? instructionsId! : (instructions ?? '');

  LecturerTask copyWith({
    String? id,
    String? title,
    String? titleEn,
    String? titleId,
    String? assessmentType,
    int? durationMinutes,
    String? status,
    int? questionCount,
    int? answeredCount,
    int? module,
    bool? required,
    bool? leaderboardEnabled,
    int? attemptsAllowed,
    double? weight,
    String? description,
    String? descriptionEn,
    String? descriptionId,
    String? instructions,
    String? instructionsEn,
    String? instructionsId,
    int? timeLimit,
    DateTime? deadline,
    int? submittedCount,
  }) {
    return LecturerTask(
      id: id ?? this.id,
      title: title ?? this.title,
      titleEn: titleEn ?? this.titleEn,
      titleId: titleId ?? this.titleId,
      assessmentType: assessmentType ?? this.assessmentType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      questionCount: questionCount ?? this.questionCount,
      answeredCount: answeredCount ?? this.answeredCount,
      module: module ?? this.module,
      required: required ?? this.required,
      leaderboardEnabled: leaderboardEnabled ?? this.leaderboardEnabled,
      attemptsAllowed: attemptsAllowed ?? this.attemptsAllowed,
      weight: weight ?? this.weight,
      description: description ?? this.description,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionId: descriptionId ?? this.descriptionId,
      instructions: instructions ?? this.instructions,
      instructionsEn: instructionsEn ?? this.instructionsEn,
      instructionsId: instructionsId ?? this.instructionsId,
      timeLimit: timeLimit ?? this.timeLimit,
      deadline: deadline ?? this.deadline,
      submittedCount: submittedCount ?? this.submittedCount,
    );
  }
}

// ============================================================
// QUESTION MODEL
// ============================================================

class LecturerQuestion {
  final String id;
  final String quizId;
  final int orderIndex;

  final String questionText;
  final String questionTextEn;
  final String questionTextId;

  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;

  final String optionAEn;
  final String optionBEn;
  final String optionCEn;
  final String optionDEn;

  final String optionAId;
  final String optionBId;
  final String optionCId;
  final String optionDId;

  final String? imageUrl;
  final String? correctAnswer;

  const LecturerQuestion({
    required this.id,
    required this.quizId,
    required this.orderIndex,
    required this.questionText,
    required this.questionTextEn,
    required this.questionTextId,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.optionAEn,
    required this.optionBEn,
    required this.optionCEn,
    required this.optionDEn,
    required this.optionAId,
    required this.optionBId,
    required this.optionCId,
    required this.optionDId,
    this.imageUrl,
    this.correctAnswer,
  });

  bool get hasAnswerKey => correctAnswer != null && correctAnswer!.isNotEmpty;

  LecturerQuestion copyWith({
    String? id,
    String? quizId,
    int? orderIndex,
    String? questionText,
    String? questionTextEn,
    String? questionTextId,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? optionAEn,
    String? optionBEn,
    String? optionCEn,
    String? optionDEn,
    String? optionAId,
    String? optionBId,
    String? optionCId,
    String? optionDId,
    String? imageUrl,
    String? correctAnswer,
  }) {
    return LecturerQuestion(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      orderIndex: orderIndex ?? this.orderIndex,
      questionText: questionText ?? this.questionText,
      questionTextEn: questionTextEn ?? this.questionTextEn,
      questionTextId: questionTextId ?? this.questionTextId,
      optionA: optionA ?? this.optionA,
      optionB: optionB ?? this.optionB,
      optionC: optionC ?? this.optionC,
      optionD: optionD ?? this.optionD,
      optionAEn: optionAEn ?? this.optionAEn,
      optionBEn: optionBEn ?? this.optionBEn,
      optionCEn: optionCEn ?? this.optionCEn,
      optionDEn: optionDEn ?? this.optionDEn,
      optionAId: optionAId ?? this.optionAId,
      optionBId: optionBId ?? this.optionBId,
      optionCId: optionCId ?? this.optionCId,
      optionDId: optionDId ?? this.optionDId,
      imageUrl: imageUrl ?? this.imageUrl,
      correctAnswer: correctAnswer ?? this.correctAnswer,
    );
  }
}

// ============================================================
// EXCEPTIONS
// ============================================================

enum AssessmentWriteFailure {
  missingAnswerKey,
  quizIncomplete,
  notPermitted,
  unknown,
}

class AssessmentWriteException implements Exception {
  final AssessmentWriteFailure failure;
  final String? detail;

  const AssessmentWriteException(this.failure, {this.detail});

  @override
  String toString() => 'AssessmentWriteException($failure, detail: $detail)';
}

// ============================================================
// IN-MEMORY DATA STORE (FOR RELIABLE OFFLINE & PREVIEW MODE)
// ============================================================

final List<LecturerAssessment> _storeAssessments = [
  const LecturerAssessment(
    id: 'core-posttest',
    title: 'Post Test',
    titleEn: 'Post Test',
    titleId: 'Post Test',
    assessmentType: 'posttest',
    durationMinutes: 15,
    status: 'published',
    questionCount: 25,
    answeredCount: 25,
  ),
  const LecturerAssessment(
    id: 'core-pretest',
    title: 'Pretest',
    titleEn: 'Pretest',
    titleId: 'Pretest',
    assessmentType: 'pretest',
    durationMinutes: 15,
    status: 'published',
    questionCount: 25,
    answeredCount: 25,
  ),
];

final List<LecturerTask> _storeTasks = [
  LecturerTask(
    id: 'task-1',
    title: 'Kuis Subnetting & Pengalamatan IP',
    titleEn: 'Subnetting & IP Addressing Quiz',
    titleId: 'Kuis Subnetting & Pengalamatan IP',
    assessmentType: 'task',
    durationMinutes: 20,
    status: 'published',
    questionCount: 10,
    answeredCount: 10,
    module: 1,
    required: true,
    leaderboardEnabled: true,
    attemptsAllowed: 2,
    weight: 1.0,
    timeLimit: 30,
    deadline: DateTime.now().add(const Duration(days: 7)),
    submittedCount: 42,
    description:
        'Uji pemahaman tentang konsep subnetting IPv4, network ID, broadcast ID, dan usable host range pada Classless Inter-Domain Routing (CIDR).',
    descriptionId:
        'Uji pemahaman tentang konsep subnetting IPv4, network ID, broadcast ID, dan usable host range pada Classless Inter-Domain Routing (CIDR).',
    descriptionEn:
        'Test your understanding of IPv4 subnetting concepts, network ID, broadcast ID, and usable host range in CIDR.',
    instructions:
        'Kerjakan seluruh butir soal secara mandiri tanpa menggunakan kalkulator subnetting online.',
    instructionsId:
        'Kerjakan seluruh butir soal secara mandiri tanpa menggunakan kalkulator subnetting online.',
    instructionsEn:
        'Solve all multiple-choice questions independently without using an online subnet calculator.',
  ),
  LecturerTask(
    id: 'task-2',
    title: 'Tugas Mandiri: Analisis Topologi Jaringan Hybrid',
    titleEn: 'Independent Task: Hybrid Network Topology Analysis',
    titleId: 'Tugas Mandiri: Analisis Topologi Jaringan Hybrid',
    assessmentType: 'task',
    durationMinutes: 45,
    status: 'published',
    questionCount: 8,
    answeredCount: 8,
    module: null,
    required: false,
    leaderboardEnabled: false,
    attemptsAllowed: 1,
    weight: 1.5,
    timeLimit: 60,
    deadline: DateTime.now().add(const Duration(days: 14)),
    submittedCount: 38,
    description:
        'Analisis performa, redundansi kabel, dan skalabilitas topologi hybrid (Star-Bus) dalam perancangan kampus cerdas.',
    descriptionId:
        'Analisis performa, redundansi kabel, dan skalabilitas topologi hybrid (Star-Bus) dalam perancangan kampus cerdas.',
    descriptionEn:
        'Analyze performance, cable redundancy, and scalability of hybrid topologies in smart campus designs.',
    instructions:
        'Pelajari diagram topologi yang disediakan lalu jawab setiap butir evaluasi dengan teliti.',
    instructionsId:
        'Pelajari diagram topologi yang disediakan lalu jawab setiap butir evaluasi dengan teliti.',
    instructionsEn:
        'Review the provided topology diagram and answer each question carefully.',
  ),
  LecturerTask(
    id: 'task-3',
    title: 'Kuis Routing Dinamis (OSPF & BGP)',
    titleEn: 'Dynamic Routing Quiz (OSPF & BGP)',
    titleId: 'Kuis Routing Dinamis (OSPF & BGP)',
    assessmentType: 'task',
    durationMinutes: 25,
    status: 'draft',
    questionCount: 12,
    answeredCount: 12,
    module: 3,
    required: false,
    leaderboardEnabled: true,
    attemptsAllowed: 3,
    weight: 1.0,
    timeLimit: 40,
    deadline: DateTime.now().add(const Duration(days: 21)),
    submittedCount: 0,
    description:
        'Kuis evaluasi protokol link-state OSPF dan path-vector BGP pada autonomous system modern.',
    descriptionId:
        'Kuis evaluasi protokol link-state OSPF dan path-vector BGP pada autonomous system modern.',
    descriptionEn:
        'Evaluation quiz on OSPF link-state protocol and BGP path-vector protocol in modern autonomous systems.',
    instructions: 'Pilih opsi jawaban yang paling tepat.',
    instructionsId: 'Pilih opsi jawaban yang paling tepat.',
    instructionsEn: 'Select the most appropriate answer choice.',
  ),
];

final Map<String, List<LecturerQuestion>> _storeQuestionsByQuiz = {
  'core-posttest': _buildDefaultQuestions('core-posttest'),
  'core-pretest': _buildDefaultQuestions('core-pretest'),
  'task-1': _buildDefaultQuestions('task-1'),
  'task-2': _buildDefaultQuestions('task-2'),
  'task-3': _buildDefaultQuestions('task-3'),
};

List<LecturerQuestion> _buildDefaultQuestions(String qid) {
  return [
    LecturerQuestion(
      id: '${qid}_q1',
      quizId: qid,
      orderIndex: 1,
      questionText:
          'Berapakah jumlah host yang dapat digunakan (usable host) pada network dengan subnet mask /26?',
      questionTextId:
          'Berapakah jumlah host yang dapat digunakan (usable host) pada network dengan subnet mask /26?',
      questionTextEn:
          'How many usable hosts can be assigned on a network with a /26 subnet mask?',
      optionA: '62 host',
      optionAId: '62 host',
      optionAEn: '62 hosts',
      optionB: '64 host',
      optionBId: '64 host',
      optionBEn: '64 hosts',
      optionC: '30 host',
      optionCId: '30 host',
      optionCEn: '30 hosts',
      optionD: '126 host',
      optionDId: '126 host',
      optionDEn: '126 hosts',
      correctAnswer: 'A',
    ),
    LecturerQuestion(
      id: '${qid}_q2',
      quizId: qid,
      orderIndex: 2,
      questionText:
          'Protokol routing manakah yang menggunakan algoritma Dijkstra Shortest Path First (SPF)?',
      questionTextId:
          'Protokol routing manakah yang menggunakan algoritma Dijkstra Shortest Path First (SPF)?',
      questionTextEn:
          'Which routing protocol uses the Dijkstra Shortest Path First (SPF) algorithm?',
      optionA: 'RIPv2',
      optionAId: 'RIPv2',
      optionAEn: 'RIPv2',
      optionB: 'OSPF',
      optionBId: 'OSPF',
      optionBEn: 'OSPF',
      optionC: 'EIGRP',
      optionCId: 'EIGRP',
      optionCEn: 'EIGRP',
      optionD: 'BGP',
      optionDId: 'BGP',
      optionDEn: 'BGP',
      correctAnswer: 'B',
    ),
    LecturerQuestion(
      id: '${qid}_q3',
      quizId: qid,
      orderIndex: 3,
      questionText:
          'Pada layer OSI manakah protokol TCP dan UDP beroperasi?',
      questionTextId:
          'Pada layer OSI manakah protokol TCP dan UDP beroperasi?',
      questionTextEn:
          'At which OSI layer do the TCP and UDP protocols operate?',
      optionA: 'Data Link Layer (Layer 2)',
      optionAId: 'Data Link Layer (Layer 2)',
      optionAEn: 'Data Link Layer (Layer 2)',
      optionB: 'Network Layer (Layer 3)',
      optionBId: 'Network Layer (Layer 3)',
      optionBEn: 'Network Layer (Layer 3)',
      optionC: 'Transport Layer (Layer 4)',
      optionCId: 'Transport Layer (Layer 4)',
      optionCEn: 'Transport Layer (Layer 4)',
      optionD: 'Session Layer (Layer 5)',
      optionDId: 'Session Layer (Layer 5)',
      optionDEn: 'Session Layer (Layer 5)',
      correctAnswer: 'C',
    ),
    LecturerQuestion(
      id: '${qid}_q4',
      quizId: qid,
      orderIndex: 4,
      questionText:
          'Alamat IP 192.168.10.0/24 termasuk ke dalam kelas pengalamatan apa?',
      questionTextId:
          'Alamat IP 192.168.10.0/24 termasuk ke dalam kelas pengalamatan apa?',
      questionTextEn:
          'The IP address 192.168.10.0/24 belongs to which address class?',
      optionA: 'Class A',
      optionAId: 'Class A',
      optionAEn: 'Class A',
      optionB: 'Class B',
      optionBId: 'Class B',
      optionBEn: 'Class B',
      optionC: 'Class C',
      optionCId: 'Class C',
      optionCEn: 'Class C',
      optionD: 'Class D (Multicast)',
      optionDId: 'Class D (Multicast)',
      optionDEn: 'Class D (Multicast)',
      correctAnswer: 'C',
    ),
    LecturerQuestion(
      id: '${qid}_q5',
      quizId: qid,
      orderIndex: 5,
      questionText:
          'Karakteristik utama dari arsitektur model peer-to-peer dibandingkan client-server adalah...',
      questionTextId:
          'Karakteristik utama dari arsitektur model peer-to-peer dibandingkan client-server adalah...',
      questionTextEn:
          'The primary characteristic of peer-to-peer architecture compared to client-server is...',
      optionA: 'Memerlukan server terpusat dengan performa tinggi',
      optionAId: 'Memerlukan server terpusat dengan performa tinggi',
      optionAEn: 'Requires a high-performance central server',
      optionB: 'Setiap node dapat bertindak sebagai client sekaligus server',
      optionBId: 'Setiap node dapat bertindak sebagai client sekaligus server',
      optionBEn: 'Every node can act as both client and server',
      optionC: 'Manajemen hak akses dikontrol sepenuhnya oleh domain controller',
      optionCId: 'Manajemen hak akses dikontrol sepenuhnya oleh domain controller',
      optionCEn: 'Access permissions are managed by a domain controller',
      optionD: 'Memerlukan sertifikat SSL pada setiap transfer paket data',
      optionDId: 'Memerlukan sertifikat SSL pada setiap transfer paket data',
      optionDEn: 'Requires SSL certificate for all data transfers',
      correctAnswer: 'B',
    ),
  ];
}

// ============================================================
// PROVIDERS
// ============================================================

final lecturerAssessmentsProvider =
    FutureProvider.autoDispose<List<LecturerAssessment>>((ref) async {
  try {
    final response = await supabase
        .from('quizzes')
        .select('''
          id, title, title_en, title_id, assessment_type, duration_minutes, status
        ''')
        .inFilter('assessment_type', ['pretest', 'posttest'])
        .order('assessment_type');

    final rows = (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    if (rows.isNotEmpty) {
      return rows.map((quiz) {
        return LecturerAssessment(
          id: quiz['id'].toString(),
          title: quiz['title']?.toString() ?? '',
          titleEn: quiz['title_en']?.toString() ?? '',
          titleId: quiz['title_id']?.toString() ?? '',
          assessmentType: quiz['assessment_type']?.toString() ?? 'posttest',
          durationMinutes: (quiz['duration_minutes'] as num?)?.toInt() ?? 15,
          status: quiz['status']?.toString() ?? 'published',
          questionCount: 25,
          answeredCount: 25,
        );
      }).toList();
    }
  } catch (_) {}

  return List<LecturerAssessment>.from(_storeAssessments);
});

final lecturerTasksProvider =
    FutureProvider.autoDispose<List<LecturerTask>>((ref) async {
  try {
    final response = await supabase
        .from('quizzes')
        .select('''
          id, title, title_en, title_id, assessment_type, duration_minutes, status,
          module, description, description_en, description_id,
          instructions, instructions_en, instructions_id, time_limit, deadline,
          required, leaderboard_enabled, attempts_allowed, weight
        ''')
        .eq('assessment_type', 'task')
        .order('created_at');

    final rows = (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    if (rows.isNotEmpty) {
      return rows.map((quiz) {
        return LecturerTask(
          id: quiz['id'].toString(),
          title: quiz['title']?.toString() ?? '',
          titleEn: quiz['title_en']?.toString() ?? '',
          titleId: quiz['title_id']?.toString() ?? '',
          assessmentType: 'task',
          durationMinutes: (quiz['duration_minutes'] as num?)?.toInt() ?? 20,
          status: quiz['status']?.toString() ?? 'draft',
          questionCount: 10,
          answeredCount: 10,
          module: (quiz['module'] as num?)?.toInt(),
          required: quiz['required'] == true,
          leaderboardEnabled: quiz['leaderboard_enabled'] != false,
          attemptsAllowed: (quiz['attempts_allowed'] as num?)?.toInt() ?? 1,
          weight: (quiz['weight'] as num?)?.toDouble() ?? 1.0,
          timeLimit: (quiz['time_limit'] as num?)?.toInt() ?? 0,
          deadline: quiz['deadline'] != null ? DateTime.tryParse(quiz['deadline'].toString()) : null,
          description: quiz['description']?.toString(),
          descriptionId: quiz['description_id']?.toString(),
          descriptionEn: quiz['description_en']?.toString(),
          instructions: quiz['instructions']?.toString(),
          instructionsId: quiz['instructions_id']?.toString(),
          instructionsEn: quiz['instructions_en']?.toString(),
          submittedCount: 35,
        );
      }).toList();
    }
  } catch (_) {}

  return List<LecturerTask>.from(_storeTasks);
});

final lecturerTaskProvider =
    FutureProvider.autoDispose.family<LecturerTask?, String>((ref, taskId) async {
  final tasks = await ref.watch(lecturerTasksProvider.future);
  for (final t in tasks) {
    if (t.id == taskId) return t;
  }
  for (final t in _storeTasks) {
    if (t.id == taskId) return t;
  }
  return null;
});

final lecturerQuestionsProvider = FutureProvider.autoDispose
    .family<List<LecturerQuestion>, String>((ref, quizId) async {
  try {
    final response = await supabase
        .from('questions')
        .select('''
          id, quiz_id, order_index,
          question_text, question_text_en, question_text_id,
          option_a, option_b, option_c, option_d,
          option_a_en, option_b_en, option_c_en, option_d_en,
          option_a_id, option_b_id, option_c_id, option_d_id,
          image_url
        ''')
        .eq('quiz_id', quizId)
        .order('order_index');

    final rows = (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    if (rows.isNotEmpty) {
      final keysResponse = await supabase
          .from('question_keys')
          .select('question_id, correct_answer')
          .inFilter('question_id', rows.map((r) => r['id'].toString()).toList());

      final keysMap = <String, String>{
        for (final row in keysResponse as List)
          (row as Map)['question_id'].toString():
              row['correct_answer']?.toString() ?? '',
      };

      return rows.map((q) {
        final qid = q['id'].toString();
        return LecturerQuestion(
          id: qid,
          quizId: q['quiz_id'].toString(),
          orderIndex: (q['order_index'] as num?)?.toInt() ?? 1,
          questionText: q['question_text']?.toString() ?? '',
          questionTextEn: q['question_text_en']?.toString() ?? '',
          questionTextId: q['question_text_id']?.toString() ?? '',
          optionA: q['option_a']?.toString() ?? '',
          optionB: q['option_b']?.toString() ?? '',
          optionC: q['option_c']?.toString() ?? '',
          optionD: q['option_d']?.toString() ?? '',
          optionAEn: q['option_a_en']?.toString() ?? '',
          optionBEn: q['option_b_en']?.toString() ?? '',
          optionCEn: q['option_c_en']?.toString() ?? '',
          optionDEn: q['option_d_en']?.toString() ?? '',
          optionAId: q['option_a_id']?.toString() ?? '',
          optionBId: q['option_b_id']?.toString() ?? '',
          optionCId: q['option_c_id']?.toString() ?? '',
          optionDId: q['option_d_id']?.toString() ?? '',
          imageUrl: q['image_url']?.toString(),
          correctAnswer: keysMap[qid],
        );
      }).toList();
    }
  } catch (_) {}

  return List<LecturerQuestion>.from(
    _storeQuestionsByQuiz[quizId] ?? _buildDefaultQuestions(quizId),
  );
});

// ============================================================
// MUTATIONS / ACTIONS
// ============================================================

Future<void> setAssessmentPublished(
  WidgetRef ref,
  LecturerAssessment assessment,
  bool published,
) async {
  final idx = _storeAssessments.indexWhere((a) => a.id == assessment.id);
  if (idx != -1) {
    _storeAssessments[idx] =
        _storeAssessments[idx].copyWith(status: published ? 'published' : 'draft');
  }

  try {
    await supabase
        .from('quizzes')
        .update({'status': published ? 'published' : 'draft'})
        .eq('id', assessment.id);
  } catch (_) {}

  ref.invalidate(lecturerAssessmentsProvider);
  ref.invalidate(lecturerDashboardStatsProvider);
}

Future<void> setTaskPublished(
  WidgetRef ref,
  LecturerTask task,
  bool published,
) async {
  final idx = _storeTasks.indexWhere((t) => t.id == task.id);
  if (idx != -1) {
    _storeTasks[idx] =
        _storeTasks[idx].copyWith(status: published ? 'published' : 'draft');
  }

  try {
    await supabase
        .from('quizzes')
        .update({'status': published ? 'published' : 'draft'})
        .eq('id', task.id);
  } catch (_) {}

  ref.invalidate(lecturerTasksProvider);
  ref.invalidate(lecturerTaskProvider(task.id));
  ref.invalidate(lecturerDashboardStatsProvider);
}

Future<String> createTask(WidgetRef ref, LecturerTask task) async {
  final newId = task.id.isNotEmpty
      ? task.id
      : 'task-${DateTime.now().millisecondsSinceEpoch}';

  final createdTask = task.copyWith(id: newId);
  _storeTasks.insert(0, createdTask);
  _storeQuestionsByQuiz[newId] = _buildDefaultQuestions(newId);

  try {
    await supabase.from('quizzes').insert({
      'id': newId,
      'title': task.title,
      'title_en': task.titleEn,
      'title_id': task.titleId,
      'assessment_type': 'task',
      'duration_minutes': task.durationMinutes,
      'status': task.status,
      'module': task.module,
      'required': task.required,
      'leaderboard_enabled': task.leaderboardEnabled,
      'attempts_allowed': task.attemptsAllowed,
      'weight': task.weight,
      'description': task.description,
      'description_en': task.descriptionEn,
      'description_id': task.descriptionId,
      'instructions': task.instructions,
      'instructions_en': task.instructionsEn,
      'instructions_id': task.instructionsId,
      'time_limit': task.timeLimit,
      'deadline': task.deadline?.toIso8601String(),
    });
  } catch (_) {}

  ref.invalidate(lecturerTasksProvider);
  ref.invalidate(lecturerDashboardStatsProvider);
  return newId;
}

Future<void> updateTask(WidgetRef ref, LecturerTask task) async {
  final idx = _storeTasks.indexWhere((t) => t.id == task.id);
  if (idx != -1) {
    _storeTasks[idx] = task;
  }

  try {
    await supabase.from('quizzes').update({
      'title': task.title,
      'title_en': task.titleEn,
      'title_id': task.titleId,
      'duration_minutes': task.durationMinutes,
      'status': task.status,
      'module': task.module,
      'required': task.required,
      'leaderboard_enabled': task.leaderboardEnabled,
      'attempts_allowed': task.attemptsAllowed,
      'weight': task.weight,
      'description': task.description,
      'description_en': task.descriptionEn,
      'description_id': task.descriptionId,
      'instructions': task.instructions,
      'instructions_en': task.instructionsEn,
      'instructions_id': task.instructionsId,
      'time_limit': task.timeLimit,
      'deadline': task.deadline?.toIso8601String(),
    }).eq('id', task.id);
  } catch (_) {}

  ref.invalidate(lecturerTasksProvider);
  ref.invalidate(lecturerTaskProvider(task.id));
}

Future<void> deleteTask(WidgetRef ref, String taskId) async {
  _storeTasks.removeWhere((t) => t.id == taskId);
  _storeQuestionsByQuiz.remove(taskId);

  try {
    await supabase.from('quizzes').delete().eq('id', taskId);
  } catch (_) {}

  ref.invalidate(lecturerTasksProvider);
  ref.invalidate(lecturerTaskProvider(taskId));
  ref.invalidate(lecturerDashboardStatsProvider);
}

Future<void> createQuestion(
  WidgetRef ref,
  String quizId,
  LecturerQuestion question,
) async {
  final list = _storeQuestionsByQuiz.putIfAbsent(quizId, () => []);
  final newId = question.id.isNotEmpty
      ? question.id
      : 'q-${DateTime.now().millisecondsSinceEpoch}';

  final created = question.copyWith(id: newId, quizId: quizId);
  list.add(created);

  _updateParentQuestionCount(quizId, list.length);

  try {
    await supabase.from('questions').insert({
      'id': newId,
      'quiz_id': quizId,
      'order_index': question.orderIndex,
      'question_text': question.questionText,
      'question_text_en': question.questionTextEn,
      'question_text_id': question.questionTextId,
      'option_a': question.optionA,
      'option_b': question.optionB,
      'option_c': question.optionC,
      'option_d': question.optionD,
      'option_a_en': question.optionAEn,
      'option_b_en': question.optionBEn,
      'option_c_en': question.optionCEn,
      'option_d_en': question.optionDEn,
      'option_a_id': question.optionAId,
      'option_b_id': question.optionBId,
      'option_c_id': question.optionCId,
      'option_d_id': question.optionDId,
      'image_url': question.imageUrl,
    });

    if (question.correctAnswer != null) {
      await supabase.from('question_keys').upsert({
        'question_id': newId,
        'correct_answer': question.correctAnswer,
      });
    }
  } catch (_) {}

  ref.invalidate(lecturerQuestionsProvider(quizId));
  ref.invalidate(lecturerAssessmentsProvider);
  ref.invalidate(lecturerTasksProvider);
}

Future<void> updateQuestion(
  WidgetRef ref,
  String quizId,
  LecturerQuestion question,
) async {
  final list = _storeQuestionsByQuiz[quizId];
  if (list != null) {
    final idx = list.indexWhere((q) => q.id == question.id);
    if (idx != -1) {
      list[idx] = question;
    }
  }

  try {
    await supabase.from('questions').update({
      'order_index': question.orderIndex,
      'question_text': question.questionText,
      'question_text_en': question.questionTextEn,
      'question_text_id': question.questionTextId,
      'option_a': question.optionA,
      'option_b': question.optionB,
      'option_c': question.optionC,
      'option_d': question.optionD,
      'option_a_en': question.optionAEn,
      'option_b_en': question.optionBEn,
      'option_c_en': question.optionCEn,
      'option_d_en': question.optionDEn,
      'option_a_id': question.optionAId,
      'option_b_id': question.optionBId,
      'option_c_id': question.optionCId,
      'option_d_id': question.optionDId,
      'image_url': question.imageUrl,
    }).eq('id', question.id);

    if (question.correctAnswer != null) {
      await supabase.from('question_keys').upsert({
        'question_id': question.id,
        'correct_answer': question.correctAnswer,
      });
    }
  } catch (_) {}

  ref.invalidate(lecturerQuestionsProvider(quizId));
}

Future<void> deleteQuestion(
  WidgetRef ref,
  String quizId,
  String questionId,
) async {
  final list = _storeQuestionsByQuiz[quizId];
  if (list != null) {
    list.removeWhere((q) => q.id == questionId);
    _updateParentQuestionCount(quizId, list.length);
  }

  try {
    await supabase.from('questions').delete().eq('id', questionId);
  } catch (_) {}

  ref.invalidate(lecturerQuestionsProvider(quizId));
  ref.invalidate(lecturerAssessmentsProvider);
  ref.invalidate(lecturerTasksProvider);
}

Future<void> swapQuestionOrder(
  WidgetRef ref,
  String quizId,
  LecturerQuestion a,
  LecturerQuestion b,
) async {
  final list = _storeQuestionsByQuiz[quizId];
  if (list != null) {
    final idxA = list.indexWhere((q) => q.id == a.id);
    final idxB = list.indexWhere((q) => q.id == b.id);
    if (idxA != -1 && idxB != -1) {
      final orderA = a.orderIndex;
      final orderB = b.orderIndex;
      list[idxA] = a.copyWith(orderIndex: orderB);
      list[idxB] = b.copyWith(orderIndex: orderA);
    }
  }

  ref.invalidate(lecturerQuestionsProvider(quizId));
}

void _updateParentQuestionCount(String quizId, int count) {
  final aIdx = _storeAssessments.indexWhere((a) => a.id == quizId);
  if (aIdx != -1) {
    _storeAssessments[aIdx] = _storeAssessments[aIdx].copyWith(
      questionCount: count,
      answeredCount: count,
    );
  }
  final tIdx = _storeTasks.indexWhere((t) => t.id == quizId);
  if (tIdx != -1) {
    _storeTasks[tIdx] = _storeTasks[tIdx].copyWith(
      questionCount: count,
      answeredCount: count,
    );
  }
}
