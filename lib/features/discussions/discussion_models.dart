import '../../core/avatar/nl_avatar_models.dart';

class DiscussionThread {
  final String id;
  final String classId;
  final int? moduleNumber;
  final String? materialId;
  final String authorId;
  final String authorName;
  final String authorRole;
  final AvatarConfig? authorAvatarConfig;
  final String title;
  final String body;
  final bool isPinned;
  final bool isResolved;
  final int upvoteCount;
  final int replyCount;
  final bool upvotedByMe;
  final bool isMine;
  final bool canModerate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DiscussionThread({
    required this.id,
    required this.classId,
    this.moduleNumber,
    this.materialId,
    required this.authorId,
    required this.authorName,
    this.authorRole = 'student',
    this.authorAvatarConfig,
    required this.title,
    required this.body,
    this.isPinned = false,
    this.isResolved = false,
    this.upvoteCount = 0,
    this.replyCount = 0,
    this.upvotedByMe = false,
    this.isMine = false,
    this.canModerate = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAuthorLecturer =>
      authorRole == 'lecturer' || authorRole == 'admin';

  AvatarConfig get effectiveAvatar =>
      authorAvatarConfig ??
      AvatarConfig.defaultFor(authorId.isEmpty ? authorName : authorId);

  factory DiscussionThread.fromMap(Map<String, dynamic> map) {
    final created =
        DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now();
    final updated =
        DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? created;

    return DiscussionThread(
      id: map['id']?.toString() ?? '',
      classId: map['class_id']?.toString() ?? '',
      moduleNumber: (map['module_number'] as num?)?.toInt(),
      materialId: map['material_id']?.toString(),
      authorId: map['author_id']?.toString() ?? '',
      authorName: map['author_name']?.toString() ?? 'Pengguna',
      authorRole: map['author_role']?.toString() ?? 'student',
      authorAvatarConfig: AvatarConfig.fromDynamic(map['author_avatar_config']),
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      isPinned: map['is_pinned'] == true,
      isResolved: map['is_resolved'] == true,
      upvoteCount: (map['upvote_count'] as num?)?.toInt() ?? 0,
      replyCount: (map['reply_count'] as num?)?.toInt() ?? 0,
      upvotedByMe: map['upvoted_by_me'] == true,
      isMine: map['is_mine'] == true,
      canModerate: map['can_moderate'] == true,
      createdAt: created,
      updatedAt: updated,
    );
  }
}

class DiscussionReply {
  final String id;
  final String threadId;
  final String authorId;
  final String authorName;
  final String authorRole;
  final AvatarConfig? authorAvatarConfig;
  final String body;
  final bool isAcceptedAnswer;
  final bool isMine;
  final bool canModerate;
  final DateTime createdAt;

  const DiscussionReply({
    required this.id,
    required this.threadId,
    required this.authorId,
    required this.authorName,
    this.authorRole = 'student',
    this.authorAvatarConfig,
    required this.body,
    this.isAcceptedAnswer = false,
    this.isMine = false,
    this.canModerate = false,
    required this.createdAt,
  });

  bool get isAuthorLecturer =>
      authorRole == 'lecturer' || authorRole == 'admin';

  AvatarConfig get effectiveAvatar =>
      authorAvatarConfig ??
      AvatarConfig.defaultFor(authorId.isEmpty ? authorName : authorId);

  factory DiscussionReply.fromMap(Map<String, dynamic> map) {
    return DiscussionReply(
      id: map['id']?.toString() ?? '',
      threadId: map['thread_id']?.toString() ?? '',
      authorId: map['author_id']?.toString() ?? '',
      authorName: map['author_name']?.toString() ?? 'Pengguna',
      authorRole: map['author_role']?.toString() ?? 'student',
      authorAvatarConfig: AvatarConfig.fromDynamic(map['author_avatar_config']),
      body: map['body']?.toString() ?? '',
      isAcceptedAnswer: map['is_accepted_answer'] == true,
      isMine: map['is_mine'] == true,
      canModerate: map['can_moderate'] == true,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

String formatRelativeDiscussionTime(DateTime time, {required bool isId}) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) {
    return isId ? 'Baru saja' : 'Just now';
  }
  if (diff.inMinutes < 60) {
    return isId ? '${diff.inMinutes}m lalu' : '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return isId ? '${diff.inHours}j lalu' : '${diff.inHours}h ago';
  }
  if (diff.inDays < 30) {
    return isId ? '${diff.inDays}h lalu' : '${diff.inDays}d ago';
  }
  return '${time.day}/${time.month}/${time.year}';
}

