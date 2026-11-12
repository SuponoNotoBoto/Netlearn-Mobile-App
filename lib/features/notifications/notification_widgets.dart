import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/announcement_model.dart';
import '../../shared/models/reminder_model.dart';
import '../../shared/widgets/nl_tap_scale.dart';

/// Titik penanda "belum dibaca" pada kartu notifikasi.
///
/// Frame `16:1126` di Figma menggambarnya 5px di sebelah judul, tepat setelah
/// teksnya — bukan di sudut kartu. Warnanya aksen (`#543cd1`).
class NotificationUnreadDot extends StatelessWidget {
  static const double dotSize = 5;

  const NotificationUnreadDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        color: context.accent,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Waktu relatif pada baris meta kartu notifikasi ("2 hours ago").
///
/// Tanpa satuan bahasa Inggris yang di-hardcode, berbeda dengan
/// `ReminderItem.timeLeft` yang menyusun sendiri kedua bahasanya.
String notificationTimeLabel(
  DateTime timestamp,
  AppLocalizations l10n, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final difference = reference.difference(timestamp);

  // Waktu di masa depan (jam perangkat yang tidak sinkron) dibaca sebagai
  // "baru saja" daripada "−3 hours ago".
  if (difference.isNegative || difference.inMinutes < 60) {
    return difference.inMinutes < 1
        ? l10n.notificationJustNow
        : l10n.notificationMinutesAgo(difference.inMinutes);
  }

  if (difference.inHours < 24) {
    return l10n.notificationHoursAgo(difference.inHours);
  }

  return l10n.notificationDaysAgo(difference.inDays);
}

/// Kartu pengumuman, sesuai frame "Notifikasi Announcement" (`16:1117` belum
/// dibaca, `16:1161` sudah dibaca).
///
/// Bedanya hanya warna: yang belum dibaca memakai latar `#fbfaff` dengan garis
/// `#dad3f6` dan titik aksen setelah judul; yang sudah dibaca memakai
/// permukaan kartu biasa. Susunannya sama untuk keduanya, sama seperti di
/// Figma — yang berubah bukan hanya dot-nya.
class AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final bool unread;
  final VoidCallback onTap;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = unread
        ? (isDark ? NetLearnColors.notificationUnreadBgDark : NetLearnColors.notificationUnreadBg)
        : context.surface;

    final borderColor = unread
        ? (isDark
            ? NetLearnColors.notificationUnreadBorderDark
            : NetLearnColors.notificationUnreadBorder)
        : context.border;

    return NlTapScale(
      pressedScale: 0.985,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NetLearnRadius.card),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(NetLearnRadius.card),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  // `tintBackgrounds[0]` bukan ekspresi konstan, jadi dekorasi ini
                  // tidak bisa `const`.
                  decoration: BoxDecoration(
                    color: NetLearnAccents.tintBackgrounds[0],
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.campaign_rounded,
                    size: 18,
                    color: NetLearnAccents.tintForegrounds[0],
                  ),
                ),
                const SizedBox(width: NetLearnSpace.s10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              announcement.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: NetLearnSpace.s4),
                            const NotificationUnreadDot(),
                          ],
                        ],
                      ),
                      if (announcement.displayContent.isNotEmpty) ...[
                        const SizedBox(height: NetLearnSpace.s7),
                        Text(
                          announcement.displayContent,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            height: 1.75,
                            color: context.mutedText,
                          ),
                        ),
                      ],
                      const SizedBox(height: NetLearnSpace.s10),
                      Text(
                        '${notificationTimeLabel(announcement.publishedAt ?? announcement.createdAt, l10n)} · '
                        '${unread ? l10n.notificationUnread : l10n.notificationRead}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          color: context.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: NetLearnSpace.s10),
                Padding(
                  padding: const EdgeInsets.only(top: NetLearnSpace.s9),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: context.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu pengingat deadline.
///
/// Geometrinya sama dengan [AnnouncementCard] (padding 18, radius 16, tile 36,
/// judul 12px, isi 11px, meta 9px) ditambah satu baris lencana status — tinggi
/// frame pengingat memang lebih tinggi dari frame pengumuman. Warna tile-nya
/// memakai pasangan orange-tint seperti di daftar pengingat.
///
/// Lencananya barisnya sendiri di bawah isi kartu, bukan di samping judul:
/// di desain `.badge` duduk di dalam kolom teks setelah paragraf dengan
/// `margin-top:12px`, dan tinggi itulah yang membuat kartu pengingat 156.
///
/// Warnanya badge netral. Kelas `.badge.urgency` tidak punya aturan di CSS
/// desain, jadi tidak ada warna khusus per status yang bisa ditiru — yang
/// berbeda antar status hanya teksnya.
///
/// Kartu ini belum punya status baca: yang tersimpan lokal baru status baca
/// pengumuman, jadi tidak ada dot dan tidak ada label "Unread"/"Read" di baris
/// meta.
class ReminderCard extends StatelessWidget {
  final ReminderItem reminder;
  final VoidCallback onTap;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isIndonesian = Localizations.localeOf(context).languageCode == 'id';

    // Pengingat "belum dikerjakan" tidak punya waktu untuk di-countdown —
    // lencana dan metanya dari status itu, bukan dari deadline.
    final isNotCompleted =
        reminder.reason == ReminderReason.notCompleted;

    final urgencyLabel = isNotCompleted
        ? l10n.reminderNotCompleted
        : _urgencyLabel(l10n, isIndonesian);

    final metaText = isNotCompleted
        ? '${_assessmentLabel(l10n)} · ${l10n.reminderNotCompleted}'
        : '${reminder.formatDeadline(isIndonesian)} · ${reminder.timeLeft(isIndonesian)}';
    final trimmedClassName = reminder.className?.trim();
    final classLabel = trimmedClassName != null && trimmedClassName.isNotEmpty
        ? (isIndonesian
            ? 'Kelas: $trimmedClassName'
            : 'Class: $trimmedClassName')
        : null;

    return NlTapScale(
      pressedScale: 0.985,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NetLearnRadius.card),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(NetLearnRadius.card),
              border: Border.all(color: context.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: NetLearnAccents.tintBackgrounds[4],
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isNotCompleted
                        ? Icons.assignment_late_rounded
                        : Icons.schedule_rounded,
                    size: 18,
                    color: NetLearnAccents.tintForegrounds[4],
                  ),
                ),
                const SizedBox(width: NetLearnSpace.s10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.localizedTitle(isIndonesian),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      if (reminder.subject != null && reminder.subject!.isNotEmpty) ...[
                        const SizedBox(height: NetLearnSpace.s7),
                        Text(
                          reminder.subject!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            height: 1.75,
                            color: context.mutedText,
                          ),
                        ),
                      ],
                      if (classLabel != null) ...[
                        const SizedBox(height: NetLearnSpace.s7),
                        Row(
                          children: [
                            Icon(
                              Icons.class_outlined,
                              size: 12,
                              color: context.accent,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                classLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: context.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      // `.badge` muncul sebagai baris tersendiri setelah isi kartu,
                      // berjarak 12px dari atasnya.
                      Padding(
                        padding: const EdgeInsets.only(top: NetLearnSpace.s12),
                        child: _UrgencyBadge(label: urgencyLabel),
                      ),
                      const SizedBox(height: NetLearnSpace.s10),
                      Text(
                        metaText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          color: context.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: NetLearnSpace.s10),
                Padding(
                  padding: const EdgeInsets.only(top: NetLearnSpace.s9),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: context.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Label asesmen untuk baris meta kartu "belum dikerjakan"
  /// (`Pre-test · Belum dikerjakan` dsb). Pengingat dosen digabung satu item
  /// per mahasiswa: dua asesmen yang belum dikerjakan dirender sebagai
  /// `Pre-test & Post-test`, bukan dua kartu untuk orang yang sama.
  String _assessmentLabel(AppLocalizations l10n) {
    if (reminder.assessmentTypes.length > 1) {
      return '${l10n.pretest} & ${l10n.posttest}';
    }

    final type = reminder.assessmentTypes.isNotEmpty
        ? reminder.assessmentTypes.first
        : reminder.assessmentType;
    return type == 'posttest' ? l10n.posttest : l10n.pretest;
  }

  /// Teks lencana urgensi.
  ///
  /// Yang berbeda antar status hanya teksnya; warnanya netral untuk semuanya
  /// karena `.badge.urgency` di desain tidak punya aturan warna sendiri.
  ///
  /// `upcoming` tidak punya label sendiri: jendela query pengingat hanya 24 jam,
  /// jadi sisa waktunya itulah yang paling jujur untuk ditampilkan.
  String _urgencyLabel(AppLocalizations l10n, bool isIndonesian) {
    if (reminder.isOverdue) {
      return l10n.reminderOverdue;
    }

    switch (reminder.reminderType) {
      case 'due_tomorrow':
        return l10n.reminderDueTomorrow;
      case 'due_soon':
        return l10n.reminderDueSoon;
      default:
        return reminder.timeLeft(isIndonesian);
    }
  }
}

/// Lencana status pengingat.
///
/// Geometrinya `.badge` di desain: `padding:5px 7px`, radius 6, teks 8px
/// weight 600 — sama dengan chip status di dashboard mahasiswa.
class _UrgencyBadge extends StatelessWidget {
  final String label;

  const _UrgencyBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final statusColors = Theme.of(context).extension<NetLearnStatusColors>();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NetLearnSpace.s7,
        vertical: NetLearnSpace.s5,
      ),
      decoration: BoxDecoration(
        color: statusColors?.neutralBg ?? NetLearnColors.neutralBg,
        borderRadius: BorderRadius.circular(NetLearnRadius.badge),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: statusColors?.neutralText ?? NetLearnColors.neutralText,
        ),
      ),
    );
  }
}

/// Detail pengumuman sebagai bottom sheet.
///
/// Dipakai panel lonceng dan halaman Notifikasi supaya keduanya membuka detail
/// yang sama, bukan dua sheet yang pelan-pelan berbeda isi.
void showAnnouncementDetail(BuildContext context, AnnouncementModel announcement) {
  final l10n = AppLocalizations.of(context)!;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.mutedText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              announcement.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.by} ${announcement.lecturerId}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.mutedText,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: context.border),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Text(
                  announcement.displayContent,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!announcement.published)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: NetLearnColors.warningBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.announcementDraft,
                  style: const TextStyle(
                    color: NetLearnColors.warningText,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
