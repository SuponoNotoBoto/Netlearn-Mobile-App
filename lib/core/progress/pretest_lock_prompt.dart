import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

/// Pop-up "belum mengerjakan Pretest" untuk modul yang dikunci olehnya.
///
/// Dipakai halaman Materials dan dashboard ketika mahasiswa menyentuh modul
/// Pertama yang masih tertutup Pretest. Kalau tombolnya ditindak lanjuti,
/// targetnya halaman instruksi Pretest — sama dengan kartu Pretest
/// (`/student/assessment-instructions/pretest`), bukan daftar assessment
/// generik, supaya mahasiswa langsung menjumpai aturan percobaannya.
///
/// Return `void`: penelepon tidak perlu tindak lanjut — dialog ini sendiri
/// yang membuka rute bila mahasiswa memilih "Kerjakan Pretest".
Future<void> showPretestLockedDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) {
    return;
  }

  final go = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.pretestLockedTitle),
      content: Text(l10n.pretestLockedMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.close),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.startPretest),
        ),
      ],
    ),
  );

  if (go == true && context.mounted) {
    context.push('/student/assessment-instructions/pretest');
  }
}
