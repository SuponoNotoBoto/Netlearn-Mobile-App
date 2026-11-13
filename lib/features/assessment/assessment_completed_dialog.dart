import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import 'assessment_controller.dart';

/// Gerbang tunggal "boleh tidaknya suatu assessment dibuka" (Tugas 2/3
/// revisi).
///
/// Kenapa diekstrak: dulu kartu daftar assessment, kartu Learning Progress,
/// sel Learning Space, dan tombol mulai di halaman instruksi masing-masing
/// memutuskan sendiri dengan data yang berbeda-beda, sehingga assessment yang
/// sudah selesai masih bisa dipaksa dibuka — berakhir di halaman error
/// ASSESSMENT_LOCKED dengan tombol Retry yang mengulang kegagalan yang sama
/// (server `start_assessment_attempt` memang menolak, hanya lewat teks yang
/// tidak membantu). Semua pintu kini memanggil persis percabangan yang sama.
enum AssessmentEntryAction {
  /// Belum selesai dan terbuka — jalur normal ke halaman instruksi.
  openInstructions,

  /// Sudah selesai dikerjakan — dialog hasil yang menjelaskan dulu.
  showCompleted,

  /// Belum selesai tetapi belum terbuka — dialog terkunci.
  showLocked,
}

/// Percabangan gerbang, dipisahkan penuh dari widget supaya bisa diuji
/// offline (test/assessment_entry_test.dart).
///
/// Urutannya wajib sama dengan kartu daftar assessment yang lama: `completed`
/// diperiksa lebih dulu (assessment yang selesai tetap menawarkan hasilnya,
/// bukan dialog terkunci), baru `unlocked`.
AssessmentEntryAction resolveAssessmentEntry({
  required bool completed,
  required bool unlocked,
  bool canAttemptAgain = false,
}) {
  if (completed && !canAttemptAgain) {
    return AssessmentEntryAction.showCompleted;
  }

  if (!unlocked) {
    return AssessmentEntryAction.showLocked;
  }

  return AssessmentEntryAction.openInstructions;
}

/// Dialog "sudah dikerjakan" yang ringkas: judul plus satu baris penjelasan
/// saja — detail skor/status/rincian ada di halaman hasil, bukan di sini.
Future<void> showAssessmentCompletedDialog(
  BuildContext context,
  AssessmentListItem assessment,
  AppLocalizations l10n,
) {
  final isId = Localizations.localeOf(context).languageCode == 'id';
  final quizTitle = assessment.title.trim();
  final isCustomQuiz = !assessment.isPretest && !assessment.isPosttest;

  final hasQuizPrefix = quizTitle.toLowerCase().startsWith('kuis') ||
      quizTitle.toLowerCase().startsWith('quiz');
  final quizLabel = hasQuizPrefix
      ? quizTitle
      : (isId ? 'Kuis $quizTitle' : 'Quiz $quizTitle');

  final dialogTitle = isCustomQuiz && quizTitle.isNotEmpty
      ? quizTitle
      : (assessment.isPretest
          ? l10n.pretest
          : (assessment.isPosttest ? l10n.posttest : l10n.assessmentCompletedTitle));

  final String dialogBody;
  if (assessment.canAttemptAgain) {
    dialogBody = isId
        ? 'Anda sudah pernah mengerjakan ${isCustomQuiz && quizTitle.isNotEmpty ? quizLabel : 'asesmen ini'}, namun masih memiliki kesempatan percobaan lagi.'
        : 'You have submitted ${isCustomQuiz && quizTitle.isNotEmpty ? quizLabel : 'this assessment'} before, but you still have attempts remaining.';
  } else if (isCustomQuiz && quizTitle.isNotEmpty) {
    dialogBody = isId
        ? '$quizLabel sudah Anda selesaikan.'
        : 'You have already completed $quizLabel.';
  } else {
    dialogBody = l10n.assessmentCompletedBody;
  }

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(dialogTitle),
        content: Text(dialogBody),
        actions: [
          if (assessment.canAttemptAgain)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  final routeParam = assessment.isPretest
                      ? 'pretest'
                      : (assessment.isPosttest ? 'posttest' : assessment.id);
                  context.push('/student/assessment-instructions/$routeParam');
                }
              },
              child: Text(isId ? 'Coba Lagi' : 'Retake'),
            ),
          // Hanya ada bila data attempt mencatat id-nya; tap ini masuk
          // halaman hasil attempt terakhir.
          if (assessment.attemptId != null)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                if (context.mounted) {
                  context.push(
                    '/student/assessment-result/${assessment.attemptId}',
                  );
                }
              },
              child: Text(l10n.viewAssessmentResult),
            ),
          // Selalu ada: seluruh percabangan dialog ini jalan minimal harus
          // punya cara keluar.
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.close),
          ),
        ],
      );
    },
  );
}

/// Dialog terkunci yang sama dengan yang dulu dirender kartu daftar
/// assessment — kini dipakai bersama oleh semua pintu masuk assessment.
Future<void> showAssessmentLockedDialog(
  BuildContext context,
  AssessmentListItem assessment,
  AppLocalizations l10n,
) {
  final isId = Localizations.localeOf(context).languageCode == 'id';
  final quizTitle = assessment.title.trim();
  final isCustomQuiz = !assessment.isPretest && !assessment.isPosttest;

  final hasQuizPrefix = quizTitle.toLowerCase().startsWith('kuis') ||
      quizTitle.toLowerCase().startsWith('quiz');
  final quizLabel = hasQuizPrefix
      ? quizTitle
      : (isId ? 'Kuis $quizTitle' : 'Quiz $quizTitle');

  final dialogTitle = isCustomQuiz && quizTitle.isNotEmpty
      ? quizTitle
      : (assessment.isPretest
          ? l10n.pretest
          : (assessment.isPosttest ? l10n.posttest : l10n.assessmentLockedTitle));

  final String dialogBody;
  if (assessment.module != null) {
    dialogBody = isId
        ? '${isCustomQuiz && quizTitle.isNotEmpty ? quizLabel : 'Kuis ini'} terkunci. Harap selesaikan seluruh materi bacaan dan video pada Modul ${assessment.module} terlebih dahulu.'
        : '${isCustomQuiz && quizTitle.isNotEmpty ? quizLabel : 'This quiz'} is locked. Please complete all reading and video materials in Module ${assessment.module} first.';
  } else if (assessment.isPosttest) {
    dialogBody = l10n.assessmentLockedPosttest;
  } else if (isCustomQuiz && quizTitle.isNotEmpty) {
    dialogBody = isId
        ? '$quizLabel saat ini masih terkunci.'
        : '$quizLabel is currently locked.';
  } else {
    dialogBody = l10n.assessmentLockedGeneric;
  }

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(dialogTitle),
        content: Text(dialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.close),
          ),
        ],
      );
    },
  );
}

/// Satu pintu masuk yang benar untuk tombol Pretest/Posttest dari mana pun
/// (kartu Learning Progress, sel Learning Space, dan pemanggil berikutnya).
///
/// Jalur normal (`openInstructions`) tidak pernah membaca provider — jangan
/// menambah latensi pada alur yang paling sering dipakai; hanya cabang
/// dialog yang butuh detail item (skor, id attempt, judul) dan karena itu
/// membaca daftar yang sudah ada. Bila daftarnya gagal (RLS, jaringan) siswa
/// tidak diblokir: jatuh ke halaman instruksi dan server tetap menjaga
/// percobaan lewat `start_assessment_attempt`.
Future<void> openAssessmentEntry(
  BuildContext context,
  WidgetRef ref, {
  required String assessmentType,
  required bool completed,
  required bool unlocked,
}) async {
  final l10n = AppLocalizations.of(context)!;

  final action = resolveAssessmentEntry(
    completed: completed,
    unlocked: unlocked,
  );

  if (action == AssessmentEntryAction.openInstructions) {
    context.push('/student/assessment-instructions/$assessmentType');
    return;
  }

  AssessmentListItem? item;

  try {
    final items = await ref.read(assessmentListProvider.future);

    for (final candidate in items) {
      if (candidate.assessmentType == assessmentType) {
        item = candidate;
        break;
      }
    }
  } catch (error) {
    if (context.mounted) {
      context.push('/student/assessment-instructions/$assessmentType');
    }
    return;
  }

  if (!context.mounted) {
    return;
  }

  if (item == null) {
    // Tanpa data, dialog kosong justru membingungkan — instruksi tetap bisa
    // dibaca dan tombol mulai di sana dipagari gerbang yang sama.
    context.push('/student/assessment-instructions/$assessmentType');
    return;
  }

  if (action == AssessmentEntryAction.showCompleted) {
    await showAssessmentCompletedDialog(context, item, l10n);
    return;
  }

  await showAssessmentLockedDialog(context, item, l10n);
}
