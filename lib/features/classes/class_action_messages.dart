import 'package:flutter/material.dart';

import 'class_controller.dart';

/// Runs a class mutation and reports a failure as a snackbar instead of letting
/// it escape as an unhandled async error from a button callback.
Future<bool> runClassAction(
  BuildContext context,
  Future<void> Function() action, {
  String? successMessage,
}) async {
  try {
    await action();
    if (successMessage != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(classActionErrorMessage(context, error))),
      );
    }
    return false;
  }
}

/// User-facing text for a failed class action.
///
/// Maps by [ClassActionFailure] only; the raw server message is never shown
/// because it leaks table and policy names (same rule as
/// `mapAnnouncementWriteError`).
String classActionErrorMessage(BuildContext context, Object error) {
  final failure = mapClassActionError(error).failure;
  final isId = Localizations.localeOf(context).languageCode == 'id';

  String pick(String en, String id) => isId ? id : en;

  return switch (failure) {
    ClassActionFailure.classNameRequired =>
      pick('Class name is required.', 'Nama kelas wajib diisi.'),
    ClassActionFailure.classNotReady => pick(
        'The class needs at least one published module with a published material before it can be published.',
        'Kelas memerlukan minimal satu modul terpublikasi berisi materi terpublikasi sebelum dapat dipublikasikan.',
      ),
    ClassActionFailure.pretestNotReady => pick(
        'Publish a Pretest with keyed questions before enabling the Pretest gate.',
        'Publikasikan Pretest dengan soal berkunci sebelum mengaktifkan gerbang Pretest.',
      ),
    ClassActionFailure.posttestNotReady => pick(
        'Publish a Posttest with keyed questions before enabling the Posttest.',
        'Publikasikan Posttest dengan soal berkunci sebelum mengaktifkan Posttest.',
      ),
    ClassActionFailure.moduleTitleRequired =>
      pick('Module title is required.', 'Judul modul wajib diisi.'),
    ClassActionFailure.moduleNotReady => pick(
        'A module needs at least one published material before it can be published.',
        'Modul memerlukan minimal satu materi terpublikasi sebelum dapat dipublikasikan.',
      ),
    ClassActionFailure.assessmentNotReady => pick(
        'This assessment has no questions or has questions without an answer key.',
        'Asesmen ini belum memiliki soal atau ada soal tanpa kunci jawaban.',
      ),
    ClassActionFailure.invalidClassCode => pick(
        'The invite code is invalid, inactive, or the class is not open yet.',
        'Kode undangan tidak valid, nonaktif, atau kelas belum dibuka.',
      ),
    ClassActionFailure.tooManyAttempts => pick(
        'Too many attempts. Please wait a few minutes and try again.',
        'Terlalu banyak percobaan. Tunggu beberapa menit lalu coba lagi.',
      ),
    ClassActionFailure.classArchived =>
      pick('This class has been archived.', 'Kelas ini sudah diarsipkan.'),
    ClassActionFailure.notPermitted => pick(
        'You do not have permission to do this.',
        'Anda tidak memiliki izin untuk melakukan ini.',
      ),
    ClassActionFailure.leaderboardDisabled => pick(
        'The leaderboard is turned off for this class.',
        'Papan peringkat dinonaktifkan untuk kelas ini.',
      ),
    ClassActionFailure.unknown => pick(
        'Something went wrong. Please try again.',
        'Terjadi kesalahan. Silakan coba lagi.',
      ),
  };
}
