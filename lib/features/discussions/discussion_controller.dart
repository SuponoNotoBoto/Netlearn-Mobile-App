import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_client.dart';
import 'discussion_models.dart';

final classDiscussionThreadsProvider = FutureProvider.autoDispose
    .family<List<DiscussionThread>, ({String classId, int? moduleNumber})>(
  (ref, args) async {
    if (args.classId.trim().isEmpty) {
      return const <DiscussionThread>[];
    }

    final dynamic res = await supabase.rpc(
      'get_class_discussion_threads',
      params: {
        'p_class': args.classId,
        'p_module': args.moduleNumber,
      },
    );

    if (res is! List) return const <DiscussionThread>[];
    return res
        .map((row) =>
            DiscussionThread.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  },
);

final discussionThreadDetailProvider =
    FutureProvider.autoDispose.family<DiscussionThread?, String>(
  (ref, threadId) async {
    if (threadId.trim().isEmpty) return null;

    final dynamic res = await supabase.rpc(
      'get_discussion_thread_detail',
      params: {'p_thread': threadId},
    );

    if (res is List && res.isNotEmpty) {
      return DiscussionThread.fromMap(
        Map<String, dynamic>.from(res.first as Map),
      );
    }
    if (res is Map) {
      return DiscussionThread.fromMap(Map<String, dynamic>.from(res));
    }
    return null;
  },
);

final discussionThreadRepliesProvider =
    FutureProvider.autoDispose.family<List<DiscussionReply>, String>(
  (ref, threadId) async {
    if (threadId.trim().isEmpty) return const <DiscussionReply>[];

    final dynamic res = await supabase.rpc(
      'get_discussion_thread_replies',
      params: {'p_thread': threadId},
    );

    if (res is! List) return const <DiscussionReply>[];
    return res
        .map((row) =>
            DiscussionReply.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  },
);

void invalidateDiscussions(WidgetRef ref, {String? threadId}) {
  ref.invalidate(classDiscussionThreadsProvider);
  if (threadId != null && threadId.isNotEmpty) {
    ref.invalidate(discussionThreadDetailProvider(threadId));
    ref.invalidate(discussionThreadRepliesProvider(threadId));
  } else {
    ref.invalidate(discussionThreadDetailProvider);
    ref.invalidate(discussionThreadRepliesProvider);
  }
}

Future<void> createDiscussionThreadAction(
  WidgetRef ref, {
  required String classId,
  int? moduleNumber,
  String? materialId,
  required String title,
  required String body,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw StateError('NOT_SIGNED_IN');
  }

  final validMaterialUuid = (materialId != null &&
          RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(materialId))
      ? materialId
      : null;

  await supabase.from('class_discussion_threads').insert({
    'class_id': classId,
    'module_number': moduleNumber,
    'material_id': validMaterialUuid,
    'author_id': user.id,
    'title': title.trim(),
    'body': body.trim(),
  });

  invalidateDiscussions(ref);
}

Future<void> createDiscussionReplyAction(
  WidgetRef ref, {
  required String threadId,
  required String body,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw StateError('NOT_SIGNED_IN');
  }

  await supabase.from('class_discussion_replies').insert({
    'thread_id': threadId,
    'author_id': user.id,
    'body': body.trim(),
  });

  invalidateDiscussions(ref, threadId: threadId);
}

Future<void> toggleDiscussionUpvoteAction(
  WidgetRef ref, {
  required String threadId,
}) async {
  await supabase.rpc(
    'toggle_discussion_thread_upvote',
    params: {'p_thread': threadId},
  );
  invalidateDiscussions(ref, threadId: threadId);
}

Future<void> setDiscussionThreadPinnedAction(
  WidgetRef ref, {
  required String threadId,
  required bool isPinned,
}) async {
  await supabase
      .from('class_discussion_threads')
      .update({'is_pinned': isPinned, 'updated_at': DateTime.now().toIso8601String()})
      .eq('id', threadId);
  invalidateDiscussions(ref, threadId: threadId);
}

Future<void> setDiscussionThreadResolvedAction(
  WidgetRef ref, {
  required String threadId,
  required bool isResolved,
}) async {
  await supabase
      .from('class_discussion_threads')
      .update({
        'is_resolved': isResolved,
        'updated_at': DateTime.now().toIso8601String(),
      })
      .eq('id', threadId);
  invalidateDiscussions(ref, threadId: threadId);
}

Future<void> setDiscussionReplyAcceptedAction(
  WidgetRef ref, {
  required String threadId,
  required String replyId,
  required bool accepted,
}) async {
  await supabase
      .from('class_discussion_replies')
      .update({'is_accepted_answer': accepted})
      .eq('id', replyId);
  if (accepted) {
    await supabase
        .from('class_discussion_threads')
        .update({
          'is_resolved': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', threadId);
  }
  invalidateDiscussions(ref, threadId: threadId);
}

Future<void> deleteDiscussionThreadAction(
  WidgetRef ref, {
  required String threadId,
}) async {
  await supabase.from('class_discussion_threads').delete().eq('id', threadId);
  invalidateDiscussions(ref, threadId: threadId);
}

Future<void> deleteDiscussionReplyAction(
  WidgetRef ref, {
  required String threadId,
  required String replyId,
}) async {
  await supabase.from('class_discussion_replies').delete().eq('id', replyId);
  invalidateDiscussions(ref, threadId: threadId);
}

