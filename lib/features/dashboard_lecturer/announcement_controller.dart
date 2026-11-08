import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../shared/models/announcement_model.dart';
import '../classes/class_controller.dart';
import 'notification_controller.dart';

class AnnouncementWriteException implements Exception {
  final AnnouncementWriteFailure failure;

  /// The raw message, kept for the log. Never shown to the user: Postgres text
  /// leaks table and policy names.
  final String? detail;

  const AnnouncementWriteException(this.failure, [this.detail]);

  @override
  String toString() => 'AnnouncementWriteException($failure)';
}

enum AnnouncementWriteFailure {
  notPermitted,
  titleTooLong,
  contentTooLong,
  unknown,
}

/// Translates a failed `announcements` write into a typed failure.
///
/// Mirrors [mapLecturerWriteError] in lecturer_materials_controller.dart. Pure
/// and offline-testable: with postgrest 2.9.1 (supabase_flutter 2.17.2) the
/// client THROWS a `PostgrestException` on failure — the old code's
/// `response.error` read was dead because a successful insert/update/delete
/// without `.select()` returns null, so `response.error` crashed with a
/// NoSuchMethodError after the write had already succeeded.
AnnouncementWriteException mapAnnouncementWriteError(Object error) {
  if (error is! PostgrestException) {
    return AnnouncementWriteException(
      AnnouncementWriteFailure.unknown,
      error.toString(),
    );
  }

  final code = error.code ?? '';

  // `message` is non-nullable on PostgrestException; constraint names such as
  // announcements_title_length arrive inside it.
  final message = error.message;

  // 42501 with no recognisable message is the generic RLS refusal, which for a
  // lecturer is almost always "no INSERT policy" or "not the row's owner".
  if (code == '42501') {
    return AnnouncementWriteException(
      AnnouncementWriteFailure.notPermitted,
      message,
    );
  }

  if (message.contains('announcements_title_length') || code == '22001') {
    return AnnouncementWriteException(
      AnnouncementWriteFailure.titleTooLong,
      message,
    );
  }

  if (message.contains('announcements_content_length')) {
    return AnnouncementWriteException(
      AnnouncementWriteFailure.contentTooLong,
      message,
    );
  }

  return AnnouncementWriteException(
    AnnouncementWriteFailure.unknown,
    message.isEmpty ? error.toString() : message,
  );
}

/// Refreshes every provider that reads announcements for the lecturer and students.
///
/// Both must be invalidated on any write: userAnnouncementsProvider backs the
/// dashboard bell and the lecturer/student notifications page. Invalidating
/// at family level (without parameters) refreshes all cached instances.
void _invalidateAnnouncements(WidgetRef ref, String lecturerId) {
  ref.invalidate(lecturerAnnouncementsProvider);
  ref.invalidate(userAnnouncementsProvider);
}

/// Flips an announcement between published and draft.
///
/// Split from [updateAnnouncement] because it is the one write a lecturer
/// performs from the list, and because it must not drag the whole edited draft
/// along: an accidental edit on the form should not be saved by tapping
/// publish.
///
/// Unpublishing also clears `published_at`: the student list orders by it, so
/// leaving a stale value would let a republished copy remember (and sort by) a
/// date from before it was hidden.
Future<void> setAnnouncementPublished(
  WidgetRef ref,
  AnnouncementModel announcement,
  bool publish,
) async {
  final updates = <String, dynamic>{'published': publish};

  if (publish) {
    // UTC: waktu lokal WIB (UTC+7) membuat published_at 7 jam ke depan
    // kalau distempel langsung dari DateTime.now().
    updates['published_at'] = DateTime.now().toUtc().toIso8601String();
  } else {
    updates['published_at'] = null;
  }

  try {
    final rows = await supabase
        .from('announcements')
        .update(updates)
        .eq('id', announcement.id)
        .eq('lecturer_id', announcement.lecturerId)
        .select('id');

    // The filter above covers ownership, so zero rows means the announcement
    // is gone (deleted elsewhere) or RLS refused the update. Without this the
    // update would be reported as a success it is not.
    if (rows.isEmpty) {
      throw const AnnouncementWriteException(AnnouncementWriteFailure.notPermitted);
    }
  } on AnnouncementWriteException {
    rethrow;
  } catch (error) {
    throw mapAnnouncementWriteError(error);
  }

  _invalidateAnnouncements(ref, announcement.lecturerId);
}

Future<void> createAnnouncement(
  WidgetRef ref, {
  required String title,
  required String content,
  required String recipientScope,
  required bool publish,
  String? classId,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw const AnnouncementWriteException(AnnouncementWriteFailure.notPermitted);
  }

  // Resolve target class: explicit parameter > active lecturer class
  String? targetClassId = classId;
  if (targetClassId == null) {
    final activeClass = await resolveActiveLecturerClass(ref);
    if (activeClass != null && !activeClass.isLegacyFallback) {
      targetClassId = activeClass.id;
    }
  }

  // Embed class tag in content as fallback for immediate offline/pre-migration isolation
  var finalContent = content;
  if (targetClassId != null && !finalContent.contains('<!--class:')) {
    finalContent = '$finalContent\n<!--class:$targetClassId-->';
  }

  final announcement = <String, dynamic>{
    'lecturer_id': user.id,
    'title': title,
    'content': finalContent,
    'recipient_scope': recipientScope,
    'published': publish,
    // Timestamps are the database's job: created_at/updated_at have defaults,
    // and on updates the announcements_set_updated_at trigger overwrites any
    // client value, so sending one here would be dead weight that lies.
    // UTC, bukan waktu lokal WIB: supaya published_at tidak 7 jam ke depan.
    if (publish) 'published_at': DateTime.now().toUtc().toIso8601String(),
    if (targetClassId != null) 'class_id': targetClassId,
  };

  try {
    try {
      // `.select('id').single()` does two things: it makes a null-safe success
      // value for postgrest 2.9.1 and it makes RLS refusals fail loudly (single
      // throws PGRST116 when the row did not come back).
      await supabase
          .from('announcements')
          .insert(announcement)
          .select('id')
          .single();
    } on PostgrestException catch (e) {
      // If class_id column does not exist yet on remote DB (code 42703 or PGRST204), retry without class_id
      final isMissingCol = e.code == '42703' ||
          e.code == 'PGRST204' ||
          e.message.contains('class_id');
      if (isMissingCol && announcement.containsKey('class_id')) {
        final fallback = Map<String, dynamic>.from(announcement)..remove('class_id');
        await supabase
            .from('announcements')
            .insert(fallback)
            .select('id')
            .single();
      } else {
        rethrow;
      }
    }
  } catch (error) {
    throw mapAnnouncementWriteError(error);
  }

  _invalidateAnnouncements(ref, user.id);
}

Future<void> updateAnnouncement(
  WidgetRef ref, {
  required String id,
  required String title,
  required String content,
  required String recipientScope,
  required bool publish,
  String? classId,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw const AnnouncementWriteException(AnnouncementWriteFailure.notPermitted);
  }

  String? targetClassId = classId;
  if (targetClassId == null) {
    final activeClass = await resolveActiveLecturerClass(ref);
    if (activeClass != null && !activeClass.isLegacyFallback) {
      targetClassId = activeClass.id;
    }
  }

  // Preserve or update class tag in content
  final cleanContent = content.replaceAll(RegExp(r'\s*<!--class:[^>]+-->'), '').trim();
  final finalContent = targetClassId != null
      ? '$cleanContent\n<!--class:$targetClassId-->'
      : cleanContent;

  final updates = <String, dynamic>{
    'title': title,
    'content': finalContent,
    'recipient_scope': recipientScope,
    'published': publish,
    'class_id': ?targetClassId,
  };

  if (publish) {
    // Republishing stamps a fresh date the student list can order by — in
    // UTC, not local WIB time (local now() would land 7 hours in the future).
    updates['published_at'] = DateTime.now().toUtc().toIso8601String();
  } else {
    // Saving as a draft clears a stale stamp, the same rule
    // setAnnouncementPublished applies: a published row always has a stamp,
    // a draft never does.
    updates['published_at'] = null;
  }

  try {
    try {
      final rows = await supabase
          .from('announcements')
          .update(updates)
          .eq('id', id)
          .eq('lecturer_id', user.id)
          .select('id');

      if (rows.isEmpty) {
        throw const AnnouncementWriteException(AnnouncementWriteFailure.notPermitted);
      }
    } on PostgrestException catch (e) {
      final isMissingCol = e.code == '42703' ||
          e.code == 'PGRST204' ||
          e.message.contains('class_id');
      if (isMissingCol && updates.containsKey('class_id')) {
        final fallback = Map<String, dynamic>.from(updates)..remove('class_id');
        final rows = await supabase
            .from('announcements')
            .update(fallback)
            .eq('id', id)
            .eq('lecturer_id', user.id)
            .select('id');

        if (rows.isEmpty) {
          throw const AnnouncementWriteException(AnnouncementWriteFailure.notPermitted);
        }
      } else {
        rethrow;
      }
    }
  } on AnnouncementWriteException {
    rethrow;
  } catch (error) {
    throw mapAnnouncementWriteError(error);
  }

  _invalidateAnnouncements(ref, user.id);
}

Future<void> deleteAnnouncement(
  WidgetRef ref,
  AnnouncementModel announcement,
) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw const AnnouncementWriteException(AnnouncementWriteFailure.notPermitted);
  }

  try {
    final rows = await supabase
        .from('announcements')
        .delete()
        .eq('id', announcement.id)
        .eq('lecturer_id', user.id)
        .select('id');

    if (rows.isEmpty) {
      throw const AnnouncementWriteException(AnnouncementWriteFailure.notPermitted);
    }
  } on AnnouncementWriteException {
    rethrow;
  } catch (error) {
    throw mapAnnouncementWriteError(error);
  }

  _invalidateAnnouncements(ref, user.id);
}

/// Every announcement the lecturer created: published and drafts.
///
/// Scoped to the lecturer's currently active class so that switching classes
/// hides other classes' announcements and switching back restores them.
final lecturerAnnouncementsProvider = FutureProvider.autoDispose
    .family<List<AnnouncementModel>, String>((ref, lecturerId) async {
  // Watch active class so class switches reload this provider immediately
  ref.watch(activeLecturerClassIdProvider);
  final activeClass = await resolveActiveLecturerClass(ref);

  List<dynamic> response;
  try {
    response = await supabase
        .from('announcements')
        .select('''
          id,
          lecturer_id,
          title,
          content,
          recipient_scope,
          published,
          published_at,
          class_id,
          created_at,
          updated_at
        ''')
        .eq('lecturer_id', lecturerId)
        .order('created_at', ascending: false);
  } on PostgrestException catch (e) {
    if (e.code == '42703' || e.code == 'PGRST204' || e.message.contains('class_id')) {
      response = await supabase
          .from('announcements')
          .select('''
            id,
            lecturer_id,
            title,
            content,
            recipient_scope,
            published,
            published_at,
            created_at,
            updated_at
          ''')
          .eq('lecturer_id', lecturerId)
          .order('created_at', ascending: false);
    } else {
      rethrow;
    }
  }

  final list = response
      .map((item) => AnnouncementModel.fromMap(Map<String, dynamic>.from(item)))
      .toList();

  if (activeClass != null && !activeClass.isLegacyFallback) {
    return list.where((a) => a.classId == activeClass.id).toList();
  }

  return list;
});
