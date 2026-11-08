/// YouTube link helpers shared by the student video page and the admin
/// material form.
///
/// The database derives `materials.video_id` from `materials.video_url` inside
/// the `materials_before_write` trigger, and that trigger raises
/// `INVALID_VIDEO_URL` (SQLSTATE 22023) for anything its own regex cannot
/// parse. A bare 11 character id pasted from the YouTube share sheet is a
/// perfectly reasonable thing for an admin to type, but the trigger rejects it,
/// so the form normalises it into the canonical watch URL before writing.
///
/// The pattern below is deliberately the same shape as
/// `public.extract_youtube_id()` plus a bare-id branch. If the database regex
/// ever changes, this is the second place that has to follow.
library;

final RegExp _youtubeUrlPattern = RegExp(
  r'(?:youtu\.be/|youtube\.com/(?:watch\?(?:[^#]*&)?v=|embed/|shorts/|live/))([A-Za-z0-9_-]{11})',
);

final RegExp _bareVideoIdPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

/// Pulls the video id out of any link shape YouTube hands out, or out of a bare
/// id. Returns null when the input is empty or unrecognised.
String? extractYoutubeVideoId(String? input) {
  final value = input?.trim() ?? '';

  if (value.isEmpty) {
    return null;
  }

  if (_bareVideoIdPattern.hasMatch(value)) {
    return value;
  }

  return _youtubeUrlPattern.firstMatch(value)?.group(1);
}

/// The id a stored material should be played with.
///
/// `video_id` wins because the student page already resolved it that way: the
/// stored id is the one the database derived from the url when the material was
/// written, so it stays authoritative even if the url column is later edited by
/// hand outside the app.
String? resolveYoutubeVideoId({
  String? videoId,
  String? videoUrl,
}) {
  final storedId = videoId?.trim();

  if (storedId != null && storedId.isNotEmpty) {
    return storedId;
  }

  return extractYoutubeVideoId(videoUrl);
}

/// Canonical watch URL for whatever the admin typed, or the trimmed input when
/// it is not a YouTube link at all.
///
/// The second case is deliberate: writing the raw value lets the database stay
/// the single authority on what counts as a video link, and the resulting
/// `INVALID_VIDEO_URL` is translated for the admin by
/// `describeAdminWriteError`.
String normalizeYoutubeUrl(String input) {
  final value = input.trim();

  if (value.isEmpty) {
    return '';
  }

  final id = extractYoutubeVideoId(value);

  if (id == null) {
    return value;
  }

  return 'https://www.youtube.com/watch?v=$id';
}