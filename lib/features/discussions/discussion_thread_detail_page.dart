import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/avatar/nl_avatar_widget.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/nl_skeleton.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/nl_surface_card.dart';
import '../profile/public_profile_sheet.dart';
import 'discussion_controller.dart';
import 'discussion_models.dart';

class DiscussionThreadDetailPage extends ConsumerStatefulWidget {
  final String threadId;
  final bool isLecturer;

  const DiscussionThreadDetailPage({
    super.key,
    required this.threadId,
    this.isLecturer = false,
  });

  @override
  ConsumerState<DiscussionThreadDetailPage> createState() =>
      _DiscussionThreadDetailPageState();
}

class _DiscussionThreadDetailPageState
    extends ConsumerState<DiscussionThreadDetailPage> {
  final TextEditingController _replyController = TextEditingController();
  bool _sendingReply = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _sendingReply) return;

    final isId = Localizations.localeOf(context).languageCode == 'id';
    setState(() => _sendingReply = true);

    try {
      await createDiscussionReplyAction(
        ref,
        threadId: widget.threadId,
        body: text,
      );
      _replyController.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      debugPrint('createDiscussionReply failed: $e');
      if (!mounted) return;
      NlSnackBar.show(
        context,
        isId
            ? 'Gagal mengirim balasan. Silakan coba lagi.'
            : 'Could not send reply. Please try again.',
        tone: NlSnackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() => _sendingReply = false);
      }
    }
  }

  Future<void> _deleteThread(DiscussionThread thread, bool isId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isId ? 'Hapus Diskusi?' : 'Delete Thread?'),
        content: Text(
          isId
              ? 'Diskusi beserta seluruh balasannya akan dihapus secara permanen.'
              : 'This thread and all its replies will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isId ? 'Batal' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
            ),
            child: Text(isId ? 'Hapus' : 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await deleteDiscussionThreadAction(ref, threadId: thread.id);
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final threadAsync =
        ref.watch(discussionThreadDetailProvider(widget.threadId));
    final repliesAsync =
        ref.watch(discussionThreadRepliesProvider(widget.threadId));

    final thread = threadAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(isId ? 'Detail Diskusi' : 'Discussion Thread'),
        actions: [
          if (thread != null && (thread.canModerate || thread.isMine))
            PopupMenuButton<String>(
              key: const Key('discussion_thread_menu_btn'),
              onSelected: (action) async {
                if (action == 'pin') {
                  await setDiscussionThreadPinnedAction(
                    ref,
                    threadId: thread.id,
                    isPinned: !thread.isPinned,
                  );
                } else if (action == 'resolve') {
                  await setDiscussionThreadResolvedAction(
                    ref,
                    threadId: thread.id,
                    isResolved: !thread.isResolved,
                  );
                } else if (action == 'delete') {
                  await _deleteThread(thread, isId);
                }
              },
              itemBuilder: (ctx) => [
                if (thread.canModerate)
                  PopupMenuItem(
                    value: 'pin',
                    child: Text(
                      thread.isPinned
                          ? (isId ? 'Lepas Pin Diskusi' : 'Unpin Thread')
                          : (isId ? 'Pin Diskusi ke Atas' : 'Pin Thread'),
                    ),
                  ),
                PopupMenuItem(
                  value: 'resolve',
                  child: Text(
                    thread.isResolved
                        ? (isId ? 'Tandai Belum Terjawab' : 'Mark Unresolved')
                        : (isId ? 'Tandai Sudah Terjawab ✓' : 'Mark Resolved ✓'),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    isId ? 'Hapus Diskusi' : 'Delete Thread',
                    style: const TextStyle(color: AppColors.dangerRed),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: threadAsync.when(
                loading: () => const NlSkeletonDetail(
                  showBanner: false,
                  paragraphBlocks: 3,
                ),
                error: (_, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s24),
                    child: Text(
                      isId
                          ? 'Gagal memuat detail diskusi.'
                          : 'Could not load discussion.',
                    ),
                  ),
                ),
                data: (item) {
                  if (item == null) {
                    return Center(
                      child: Text(
                        isId
                            ? 'Diskusi tidak ditemukan.'
                            : 'Discussion not found.',
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      invalidateDiscussions(ref, threadId: widget.threadId);
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                      children: [
                        _buildQuestionHeader(context, item, isId),
                        const SizedBox(height: 20),
                        Text(
                          isId
                              ? 'Balasan & Jawaban (${item.replyCount})'
                              : 'Replies & Answers (${item.replyCount})',
                          style: AppTypography.sectionTitle(context),
                        ),
                        const SizedBox(height: 10),
                        repliesAsync.when(
                          loading: () => const NlSkeletonList(
                            itemCount: 2,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          error: (_, _) => Text(
                            isId
                                ? 'Gagal memuat balasan.'
                                : 'Could not load replies.',
                          ),
                          data: (replies) {
                            if (replies.isEmpty) {
                              return NlSurfaceCard(
                                child: Text(
                                  isId
                                      ? 'Belum ada balasan. Tulis tanggapan atau jawaban pertamamu di bawah!'
                                      : 'No replies yet. Write the first helpful answer below!',
                                  style: AppTypography.caption(context),
                                ),
                              );
                            }

                            return Column(
                              children: [
                                for (final reply in replies) ...[
                                  _ReplyTile(
                                    reply: reply,
                                    parentThread: item,
                                    isId: isId,
                                    onToggleAccept:
                                        (item.canModerate || item.isMine)
                                            ? () =>
                                                setDiscussionReplyAcceptedAction(
                                                  ref,
                                                  threadId: item.id,
                                                  replyId: reply.id,
                                                  accepted:
                                                      !reply.isAcceptedAnswer,
                                                )
                                            : null,
                                    onDelete:
                                        (reply.canModerate || reply.isMine)
                                            ? () => deleteDiscussionReplyAction(
                                                  ref,
                                                  threadId: item.id,
                                                  replyId: reply.id,
                                                )
                                            : null,
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Sticky Reply Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: BoxDecoration(
                color: isDark ? NetLearnColors.darkSurface : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? NetLearnColors.darkLine
                        : const Color(0xFFEDEAF6),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('discussion_reply_input'),
                      controller: _replyController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: isId
                            ? 'Tulis jawaban atau tanggapan...'
                            : 'Write a helpful reply...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? NetLearnColors.darkApp
                            : const Color(0xFFF6F4FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('discussion_reply_send_btn'),
                    onPressed: _sendingReply ? null : _sendReply,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF6C2CE2),
                      foregroundColor: Colors.white,
                    ),
                    icon: _sendingReply
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionHeader(
    BuildContext context,
    DiscussionThread thread,
    bool isId,
  ) {
    final moduleLabel = thread.moduleNumber != null
        ? 'Modul ${thread.moduleNumber}'
        : (isId ? 'Diskusi Umum' : 'General');

    return NlSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1ECFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  moduleLabel,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6C2CE2),
                  ),
                ),
              ),
              if (thread.isResolved)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isId ? '✓ Terjawab' : '✓ Resolved',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => showPublicProfileSheet(
              context,
              userId: thread.authorId,
              classId: thread.classId,
              fallbackName: thread.authorName,
              fallbackAvatar: thread.effectiveAvatar,
              fallbackRole: thread.authorRole,
            ),
            child: Row(
              children: [
                NlAvatarWidget(
                  config: thread.effectiveAvatar,
                  size: 38,
                  borderWidth: 2,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            thread.authorName,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (thread.isAuthorLecturer)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                isId ? 'DOSEN' : 'LECTURER',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        formatRelativeDiscussionTime(
                          thread.createdAt,
                          isId: isId,
                        ),
                        style: AppTypography.caption(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            thread.title,
            style: AppTypography.cardTitle(context).copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            thread.body,
            style: AppTypography.body(context).copyWith(height: 1.45),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const Key('discussion_detail_upvote_btn'),
            onPressed: () => toggleDiscussionUpvoteAction(
              ref,
              threadId: thread.id,
            ),
            icon: Icon(
              thread.upvotedByMe
                  ? Icons.thumb_up_alt_rounded
                  : Icons.thumb_up_off_alt_rounded,
              size: 16,
            ),
            label: Text(
              isId
                  ? 'Bermanfaat (${thread.upvoteCount})'
                  : 'Helpful (${thread.upvoteCount})',
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyTile extends StatelessWidget {
  final DiscussionReply reply;
  final DiscussionThread parentThread;
  final bool isId;
  final VoidCallback? onToggleAccept;
  final VoidCallback? onDelete;

  const _ReplyTile({
    required this.reply,
    required this.parentThread,
    required this.isId,
    this.onToggleAccept,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = reply.isAcceptedAnswer
        ? const Color(0xFF43A047)
        : (reply.isAuthorLecturer
            ? const Color(0xFF8C52FF).withValues(alpha: 0.55)
            : (isDark ? NetLearnColors.darkLine : const Color(0xFFE7E2F3)));

    return Container(
      key: Key('discussion_reply_tile_${reply.id}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? NetLearnColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: (reply.isAcceptedAnswer || reply.isAuthorLecturer) ? 1.6 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reply.isAcceptedAnswer) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 12,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isId ? 'Solusi Terpilih' : 'Accepted Answer',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => showPublicProfileSheet(
                    context,
                    userId: reply.authorId,
                    classId: parentThread.classId,
                    fallbackName: reply.authorName,
                    fallbackAvatar: reply.effectiveAvatar,
                    fallbackRole: reply.authorRole,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NlAvatarWidget(
                        config: reply.effectiveAvatar,
                        size: 32,
                        borderWidth: 1.5,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          reply.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (reply.isAuthorLecturer) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isId ? 'DOSEN' : 'LECTURER',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Text(
                formatRelativeDiscussionTime(reply.createdAt, isId: isId),
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF9A96A8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reply.body,
            style: AppTypography.body(context).copyWith(fontSize: 13),
          ),
          if (onToggleAccept != null || onDelete != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (onToggleAccept != null)
                  TextButton.icon(
                    onPressed: onToggleAccept,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: Icon(
                      reply.isAcceptedAnswer
                          ? Icons.check_circle_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 15,
                      color: const Color(0xFF2E7D32),
                    ),
                    label: Text(
                      reply.isAcceptedAnswer
                          ? (isId ? 'Batal Solusi' : 'Unmark Answer')
                          : (isId ? 'Tandai Solusi' : 'Mark Answer'),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                if (onDelete != null)
                  TextButton.icon(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 15,
                      color: AppColors.dangerRed,
                    ),
                    label: Text(
                      isId ? 'Hapus' : 'Delete',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.dangerRed,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
