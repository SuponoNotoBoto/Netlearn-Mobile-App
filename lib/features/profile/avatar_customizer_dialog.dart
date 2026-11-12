import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/audio/sfx_service.dart';
import '../../core/avatar/nl_avatar_models.dart';
import '../../core/avatar/nl_avatar_widget.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../achievements/achievement_service.dart';
import '../classes/class_controller.dart';
import '../dashboard_lecturer/lecturer_dashboard_controller.dart';
import '../dashboard_student/student_dashboard_controller.dart';
import 'student_profile_controller.dart';

typedef AvatarSaveCallback = Future<void> Function(
  AvatarConfig config,
  String? bio,
);

/// Opens the interactive Cartoon Avatar & Social Bio Customizer sheet.
Future<AvatarConfig?> showAvatarCustomizerSheet(
  BuildContext context,
  WidgetRef ref, {
  required AvatarConfig initialConfig,
  String? initialBio,
  bool isLecturer = false,
  Set<String>? initialUnlockedBadges,
  AvatarSaveCallback? onSaveOverride,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<AvatarConfig>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: isDark ? NetLearnColors.darkSurface : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (ctx) => _AvatarCustomizerSheet(
      parentRef: ref,
      initialConfig: initialConfig,
      initialBio: initialBio,
      isLecturer: isLecturer,
      initialUnlockedBadges: initialUnlockedBadges,
      onSaveOverride: onSaveOverride,
    ),
  );
}

class _AvatarCustomizerSheet extends StatefulWidget {
  final WidgetRef parentRef;
  final AvatarConfig initialConfig;
  final String? initialBio;
  final bool isLecturer;
  final Set<String>? initialUnlockedBadges;
  final AvatarSaveCallback? onSaveOverride;

  const _AvatarCustomizerSheet({
    required this.parentRef,
    required this.initialConfig,
    this.initialBio,
    required this.isLecturer,
    this.initialUnlockedBadges,
    this.onSaveOverride,
  });

  @override
  State<_AvatarCustomizerSheet> createState() => _AvatarCustomizerSheetState();
}

class _AvatarCustomizerSheetState extends State<_AvatarCustomizerSheet> {
  late AvatarConfig _draft;
  late final TextEditingController _bioController;
  Set<String> _unlockedBadges = <String>{};
  int _selectedCategory = 0; // 0=Base, 1=Color, 2=Headwear, 3=Eyewear, 4=Extra, 5=Bio
  String? _lockedHintBanner;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialConfig;
    _bioController = TextEditingController(text: widget.initialBio ?? '');
    if (widget.initialUnlockedBadges != null) {
      _unlockedBadges = widget.initialUnlockedBadges!;
    } else {
      _loadBadges();
    }
  }

  Future<void> _loadBadges() async {
    final badges = await AchievementService.getUnlockedBadges();
    if (!mounted) return;
    setState(() {
      _unlockedBadges = badges;
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  void _randomize() {
    HapticFeedback.selectionClick();
    final rng = math.Random();

    final unlockedBases = AvatarCatalog.bases
        .where((b) => b.isUnlocked(
              unlockedBadges: _unlockedBadges,
              isLecturer: widget.isLecturer,
            ))
        .toList();
    final unlockedHeads = AvatarCatalog.headwear
        .where((h) => h.isUnlocked(
              unlockedBadges: _unlockedBadges,
              isLecturer: widget.isLecturer,
            ))
        .toList();
    final unlockedEyes = AvatarCatalog.eyewear
        .where((e) => e.isUnlocked(
              unlockedBadges: _unlockedBadges,
              isLecturer: widget.isLecturer,
            ))
        .toList();
    final unlockedAccs = AvatarCatalog.accessories
        .where((a) => a.isUnlocked(
              unlockedBadges: _unlockedBadges,
              isLecturer: widget.isLecturer,
            ))
        .toList();

    setState(() {
      _lockedHintBanner = null;
      _draft = AvatarConfig(
        base: unlockedBases[rng.nextInt(unlockedBases.length)].id,
        primaryColorHex: AvatarCatalog
            .primaryColorHexes[rng.nextInt(AvatarCatalog.primaryColorHexes.length)],
        bgColorHex: AvatarCatalog
            .bgColorHexes[rng.nextInt(AvatarCatalog.bgColorHexes.length)],
        headwear: unlockedHeads[rng.nextInt(unlockedHeads.length)].id,
        eyewear: unlockedEyes[rng.nextInt(unlockedEyes.length)].id,
        accessory: unlockedAccs[rng.nextInt(unlockedAccs.length)].id,
      );
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final cleanBio = _bioController.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.onSaveOverride != null) {
        await widget.onSaveOverride!(_draft, cleanBio.isEmpty ? null : cleanBio);
      } else {
        final user = supabase.auth.currentUser;
        if (user != null) {
          await supabase.from('profiles').update({
            'avatar_config': _draft.toMap(),
            'bio': cleanBio.isEmpty ? null : cleanBio,
          }).eq('id', user.id);

          // Best-effort sync onto subnet_drill_scores so Subnet Leaderboard reflects new avatar
          try {
            await supabase
                .from('subnet_drill_scores')
                .update({'avatar_config': _draft.toMap()})
                .eq('user_id', user.id);
          } catch (_) {}

          // Best-effort sync onto virtual_lab_scores so Virtual Lab Leaderboard reflects new avatar
          try {
            await supabase
                .from('virtual_lab_scores')
                .update({'avatar_config': _draft.toMap()})
                .eq('user_id', user.id);
          } catch (_) {}

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'cached_avatar_config_${user.id}',
            _draft.toJsonString(),
          );
        }

        widget.parentRef.invalidate(studentProfileProvider);
        widget.parentRef.invalidate(studentDashboardProvider);
        widget.parentRef.invalidate(lecturerProfileProvider);
        widget.parentRef.invalidate(classLeaderboardProvider);
        widget.parentRef.invalidate(assessmentLeaderboardProvider);
      }

      HapticFeedback.mediumImpact();
      SfxService.instance.playSuccess();

      if (!mounted) return;
      Navigator.of(context).pop(_draft);
      NlSnackBar.show(
        context,
        isId ? 'Avatar profil berhasil disimpan!' : 'Profile avatar saved!',
        tone: NlSnackTone.success,
      );
    } catch (e) {
      debugPrint('save avatar failed: $e');
      if (!mounted) return;
      NlSnackBar.show(
        context,
        isId
            ? 'Gagal menyimpan avatar. Silakan coba lagi.'
            : 'Could not save avatar. Please try again.',
        tone: NlSnackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final categories = [
      (icon: Icons.pets_rounded, label: isId ? 'Karakter' : 'Character'),
      (icon: Icons.palette_rounded, label: isId ? 'Warna' : 'Colors'),
      (icon: Icons.school_rounded, label: isId ? 'Topi' : 'Headwear'),
      (icon: Icons.visibility_rounded, label: isId ? 'Kacamata' : 'Eyewear'),
      (icon: Icons.headphones_rounded, label: isId ? 'Ekstra' : 'Extra'),
      (icon: Icons.edit_note_rounded, label: isId ? 'Status' : 'Status'),
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? NetLearnColors.darkLine : const Color(0xFFDDD9E9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isId ? 'Studio Avatar Kartun' : 'Cartoon Avatar Studio',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isId
                              ? 'Tampil seru di Profil, Leaderboard & Forum Kelas'
                              : 'Show off your style on Profile, Leaderboard & Forum',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? NetLearnColors.darkMuted
                                : const Color(0xFF7E7B8F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            // Live Avatar Preview Stage
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: NetLearnGradients.hero,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  NlAvatarWidget(
                    key: const Key('avatar_customizer_live_preview'),
                    config: _draft,
                    size: 88,
                    borderWidth: 3.0,
                    borderColor: Colors.white,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isLecturer
                              ? (isId
                                  ? 'Semua Aksesoris Dosen Terbuka!'
                                  : 'All Lecturer Items Unlocked!')
                              : (isId
                                  ? '${_unlockedBadges.length}/${AchievementService.allBadges.length} Lencana Pencapaian'
                                  : '${_unlockedBadges.length}/${AchievementService.allBadges.length} Badges Earned'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isLecturer
                              ? (isId
                                  ? 'Bebas pilih karakter & aksesoris favorit Anda.'
                                  : 'Mix & match any character and accessory freely.')
                              : (isId
                                  ? 'Raih lencana belajar untuk membuka aksesoris spesial!'
                                  : 'Earn study badges to unlock special accessories!'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFE5DEFF),
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            InkWell(
                              key: const Key('avatar_randomize_btn'),
                              onTap: _randomize,
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.casino_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isId ? 'Acak Gaya' : 'Randomize',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_lockedHintBanner != null)
              Container(
                margin: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_clock_rounded,
                      size: 16,
                      color: Color(0xFFF57F17),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _lockedHintBanner!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            // Category Selector Strip
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  for (var idx = 0; idx < categories.length; idx++) ...[
                    if (idx > 0) const SizedBox(width: 8),
                    Builder(
                      builder: (ctx) {
                        final cat = categories[idx];
                        final selected = _selectedCategory == idx;
                        return ChoiceChip(
                          key: Key('avatar_cat_tab_$idx'),
                          avatar: Icon(
                            cat.icon,
                            size: 15,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF6C2CE2),
                          ),
                          label: Text(cat.label),
                          selected: selected,
                          selectedColor: const Color(0xFF6C2CE2),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : (isDark
                                    ? NetLearnColors.darkText
                                    : const Color(0xFF2D2A38)),
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = idx;
                              _lockedHintBanner = null;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Scrollable Item Grid / Palette / Bio
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                child: _buildCategoryContent(isId, isDark),
              ),
            ),

            // Save Bar
            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
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
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  key: const Key('avatar_save_btn'),
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    isId ? 'Simpan Avatar & Profil' : 'Save Avatar & Profile',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6C2CE2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryContent(bool isId, bool isDark) {
    switch (_selectedCategory) {
      case 0:
        return _buildItemGrid(
          items: AvatarCatalog.bases,
          selectedId: _draft.base,
          isId: isId,
          isDark: isDark,
          previewBuilder: (id) => _draft.copyWith(base: id),
          onSelect: (id) => setState(() => _draft = _draft.copyWith(base: id)),
        );
      case 1:
        return _buildColorPalettes(isId, isDark);
      case 2:
        return _buildItemGrid(
          items: AvatarCatalog.headwear,
          selectedId: _draft.headwear,
          isId: isId,
          isDark: isDark,
          previewBuilder: (id) => _draft.copyWith(headwear: id),
          onSelect: (id) =>
              setState(() => _draft = _draft.copyWith(headwear: id)),
        );
      case 3:
        return _buildItemGrid(
          items: AvatarCatalog.eyewear,
          selectedId: _draft.eyewear,
          isId: isId,
          isDark: isDark,
          previewBuilder: (id) => _draft.copyWith(eyewear: id),
          onSelect: (id) =>
              setState(() => _draft = _draft.copyWith(eyewear: id)),
        );
      case 4:
        return _buildItemGrid(
          items: AvatarCatalog.accessories,
          selectedId: _draft.accessory,
          isId: isId,
          isDark: isDark,
          previewBuilder: (id) => _draft.copyWith(accessory: id),
          onSelect: (id) =>
              setState(() => _draft = _draft.copyWith(accessory: id)),
        );
      case 5:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isId
                  ? 'Status / Bio Singkat Profil Sosial'
                  : 'Short Social Profile Bio / Motto',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isId
                  ? 'Ditampilkan saat teman sekelas atau dosen mengunjungi profilmu.'
                  : 'Shown when classmates or your lecturer visit your profile.',
              style: TextStyle(
                fontSize: 11.5,
                color:
                    isDark ? NetLearnColors.darkMuted : const Color(0xFF7E7B8F),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('avatar_bio_input'),
              controller: _bioController,
              maxLength: 80,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: isId
                    ? 'Contoh: Semangat menaklukkan Subnetting /28! 🚀'
                    : 'e.g. Ready to master /28 Subnetting! 🚀',
                filled: true,
                fillColor:
                    isDark ? NetLearnColors.darkApp : const Color(0xFFF7F5FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildItemGrid({
    required List<AvatarCatalogItem> items,
    required String selectedId,
    required bool isId,
    required bool isDark,
    required AvatarConfig Function(String id) previewBuilder,
    required ValueChanged<String> onSelect,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 112,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.84,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, idx) {
        final item = items[idx];
        final unlocked = item.isUnlocked(
          unlockedBadges: _unlockedBadges,
          isLecturer: widget.isLecturer,
        );
        final isSelected = item.id == selectedId;

        return InkWell(
          key: Key('avatar_item_${item.id}'),
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            if (!unlocked) {
              setState(() {
                _lockedHintBanner =
                    '🔒 ${item.label(isId)}: ${item.unlockHint(isId) ?? ''}';
              });
              return;
            }
            setState(() => _lockedHintBanner = null);
            onSelect(item.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFF3EEFF)
                  : (isDark
                      ? NetLearnColors.darkApp
                      : const Color(0xFFFAF9FD)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF6C2CE2)
                    : (isDark
                        ? NetLearnColors.darkLine
                        : const Color(0xFFE8E4F3)),
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: unlocked ? 1.0 : 0.45,
                        child: NlAvatarWidget(
                          config: previewBuilder(item.id),
                          size: 48,
                          borderWidth: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.label(isId),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.15,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF5B2EE8)
                              : (isDark
                                  ? NetLearnColors.darkText
                                  : const Color(0xFF2D2A38)),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!unlocked)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFB300),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (isSelected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6C2CE2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorPalettes(bool isId, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isId ? 'Warna Karakter' : 'Character Fur / Accent Color',
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final hex in AvatarCatalog.primaryColorHexes)
              _ColorSwatchButton(
                hex: hex,
                selected:
                    _draft.primaryColorHex.toUpperCase() == hex.toUpperCase(),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(
                    () => _draft = _draft.copyWith(primaryColorHex: hex),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          isId ? 'Warna Latar Lingkaran' : 'Background Circle Pastel',
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final hex in AvatarCatalog.bgColorHexes)
              _ColorSwatchButton(
                hex: hex,
                selected: _draft.bgColorHex.toUpperCase() == hex.toUpperCase(),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _draft = _draft.copyWith(bgColorHex: hex));
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _ColorSwatchButton extends StatelessWidget {
  final String hex;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatchButton({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AvatarConfig(primaryColorHex: hex).primaryColor;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? const Color(0xFF6C2CE2) : const Color(0xFFD5D0E5),
            width: selected ? 3.0 : 1.5,
          ),
        ),
        child: selected
            ? const Icon(
                Icons.check_rounded,
                size: 18,
                color: Color(0xFF2D2A38),
              )
            : null,
      ),
    );
  }
}
