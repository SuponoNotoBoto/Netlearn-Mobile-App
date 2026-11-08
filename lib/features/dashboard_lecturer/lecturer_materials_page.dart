import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/language_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/material_model.dart';
import '../../shared/widgets/nl_empty_state.dart';
import '../../shared/widgets/nl_material_thumbnail.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/nl_topbar.dart';
import '../../shared/widgets/status_badge.dart';
import 'lecturer_bottom_navbar.dart';
import 'lecturer_materials_controller.dart';
import '../classes/class_controller.dart';
import '../classes/class_models.dart';
import '../classes/lecturer_manage_class_section.dart';

class LecturerMaterialsPage extends ConsumerStatefulWidget {
  const LecturerMaterialsPage({super.key});

  @override
  ConsumerState<LecturerMaterialsPage> createState() =>
      _LecturerMaterialsPageState();
}

class _LecturerMaterialsPageState
    extends ConsumerState<LecturerMaterialsPage> {
  final _searchController = TextEditingController();

  /// null means "every module". A material with no module number still shows
  /// under the unfiltered list, which is why this is not just module 0.
  int? _moduleFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MaterialModel> _filter(
    List<MaterialModel> materials,
  ) {
    final search = _searchController.text.trim().toLowerCase();

    return materials.where((material) {
      final matchesModule = _moduleFilter == null ||
          material.moduleNumber == _moduleFilter;

      if (!matchesModule) {
        return false;
      }

      if (search.isEmpty) {
        return true;
      }

      // Both languages are searched. A lecturer looking for a material often
      // knows it by the Indonesian title while the app is set to English.
      return material.title.toLowerCase().contains(search) ||
          (material.titleEn?.toLowerCase().contains(search) ??
              false) ||
          (material.titleId?.toLowerCase().contains(search) ??
              false);
    }).toList();
  }

  Future<void> _refresh() async {
    ref.invalidate(lecturerMaterialsProvider);
    await ref.read(lecturerMaterialsProvider.future);
  }

  String _writeFailureMessage(Object error) {
    final l10n = AppLocalizations.of(context)!;

    if (error is! LecturerWriteException) {
      return l10n.materialSaveFailed;
    }

    switch (error.failure) {
      case LecturerWriteFailure.coreProtected:
        return l10n.coreProtectedError;

      case LecturerWriteFailure.invalidVideoUrl:
        return l10n.invalidVideoUrlError;

      case LecturerWriteFailure.notPermitted:
        return l10n.notPermittedError;

      case LecturerWriteFailure.unknown:
        return l10n.materialSaveFailed;
    }
  }

  Future<void> _togglePublished(
    MaterialModel material,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final next = !material.published;

    try {
      await setMaterialPublished(ref, material.id, next);

      if (!mounted) return;

      NlSnackBar.show(
        context,
        next ? l10n.materialPublished : l10n.materialUnpublished,
        tone: NlSnackTone.success,
      );
    } catch (error) {
      if (!mounted) return;

      NlSnackBar.show(
        context,
        _writeFailureMessage(error),
        tone: NlSnackTone.error,
      );
    }
  }

  Future<void> _confirmDelete(
    MaterialModel material,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteMaterial),
          content: Text(l10n.deleteMaterialConfirmBody),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(l10n.deleteMaterial),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await deleteMaterial(ref, material);

      if (!mounted) return;

      NlSnackBar.show(
        context,
        l10n.materialDeleted,
        tone: NlSnackTone.success,
      );
    } catch (error) {
      if (!mounted) return;

      NlSnackBar.show(
        context,
        _writeFailureMessage(error),
        tone: NlSnackTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final languageCode =
        ref.watch(languageProvider).languageCode;

    final materialsAsync = ref.watch(lecturerMaterialsProvider);
    final activeClass = ref.watch(activeLecturerClassProvider).value;
    final classes = ref.watch(lecturerClassesProvider).value;

    return Scaffold(
      backgroundColor: context.background,

      // Header `.compact` yang sama dengan halaman Materials student
      // (`NlTopBar`): bar putih 53px dengan garis rambut, tombol kembali ke
      // dashboard dosen, dan bel notifikasi di kanan — struktur visual halaman
      // mengikuti halaman student di Figma.
      appBar: NlTopBar(
        title: l10n.materials,
        onBack: () => context.go('/lecturer'),
        actions: IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () {
            // TODO: buka panel notifikasi dosen
          },
        ),
      ),

      body: materialsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(NetLearnSpace.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 46,
                  color: NetLearnColors.danger,
                ),
                const SizedBox(height: NetLearnSpace.s12),
                Text(
                  l10n.failedToLoad,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: NetLearnSpace.s12),
                OutlinedButton(
                  onPressed: _refresh,
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),

        data: (materials) {
          final visible = _filter(materials);

          final moduleNumbers =
              materials.map((m) => m.moduleNumber).whereType<int>().toSet().toList()
                ..sort();
          // moduleNumber null (materi pendukung) tidak masuk daftar chip:
          // tanpa chip "tanpa modul", dan `.sort()` pada List<int?> yang
          // berisi null melempar "Null is not a subtype of Comparable".
          // Materi itu sendiri tetap muncul di daftar tanpa filter.

          return RefreshIndicator(
            color: context.accent,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                NetLearnSpace.s20,
                NetLearnSpace.s20,
                NetLearnSpace.s20,
                NetLearnSpace.s20 + 80, // Space for bottom nav
              ),
              children: [
                if (classes != null &&
                    activeClass != null &&
                    activeClass.id != kLegacyFallbackClassId) ...[
                  LecturerActiveClassBar(
                    classes: classes,
                    activeClass: activeClass,
                  ),
                  const SizedBox(height: NetLearnSpace.s16),
                ],
                // Add Material Button - Full width, matches Figma design
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/lecturer/materials/create');
                    },
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(l10n.addMaterial),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.accent,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(NetLearnRadius.button),
                      ),
                      textStyle: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: NetLearnSpace.s16),

                // Search Field - Matches Figma design
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l10n.searchMaterials,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear, size: 20),
                          ),
                    filled: true,
                    fillColor: context.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: NetLearnSpace.s16,
                      vertical: NetLearnSpace.s12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(NetLearnRadius.field),
                      borderSide: BorderSide(color: context.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(NetLearnRadius.field),
                      borderSide: BorderSide(color: context.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(NetLearnRadius.field),
                      borderSide: BorderSide(color: context.accent, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: NetLearnSpace.s12),

                // Module Filter Chips - Matches Figma design
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ModuleChip(
                        label: l10n.allModules,
                        selected: _moduleFilter == null,
                        onTap: () {
                          setState(() {
                            _moduleFilter = null;
                          });
                        },
                      ),

                    for (final moduleNumber in moduleNumbers)
                      _ModuleChip(
                        label: '${l10n.module} $moduleNumber',
                        selected:
                            _moduleFilter == moduleNumber,
                        onTap: () {
                          setState(() {
                            _moduleFilter = moduleNumber;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: NetLearnSpace.s16),

                // Material List
                if (visible.isEmpty)
                  NlEmptyState(
                    icon: Icons.menu_book_outlined,
                    title: l10n.noMaterials,
                    message: l10n.noMaterialsDescription,
                    actionLabel: l10n.addMaterial,
                    onAction: () {
                      context.push('/lecturer/materials/create');
                    },
                  )
                else
                  for (final material in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: NetLearnSpace.s16),
                      child: _MaterialCard(
                        material: material,
                        languageCode: languageCode,
                        onEdit: () {
                          context.push(
                            '/lecturer/materials/${material.id}/edit',
                          );
                        },
                        onTogglePublished: () {
                          _togglePublished(material);
                        },
                        onDelete: () {
                          _confirmDelete(material);
                        },
                      ),
                    ),
              ],
            ),
          );
        },
      ),

      bottomNavigationBar: const LecturerBottomNavbar(
        currentIndex: 1,
      ),
    );
  }
}

class _ModuleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModuleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: NetLearnSpace.s8),
      child: Material(
        color: selected ? context.accent : context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NetLearnRadius.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: NetLearnSpace.s16,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(NetLearnRadius.pill),
              border: Border.all(
                color: selected ? context.accent : context.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : context.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final MaterialModel material;
  final String languageCode;
  final VoidCallback onEdit;
  final VoidCallback onTogglePublished;
  final VoidCallback onDelete;

  const _MaterialCard({
    required this.material,
    required this.languageCode,
    required this.onEdit,
    required this.onTogglePublished,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final title = material.localizedTitle(languageCode);

    final description = material.localizedDescription(languageCode);

    final durationText = material.durationMinutes != null
        ? '${material.durationMinutes} ${l10n.minutes}'
        : null;

    // Kartu dosen memakai struktur sama dengan kartu student (banner
    // ilustrasi, eyebrow modul, judul, deskripsi, meta, badge + chevron), lalu
    // menambahkan baris aksi dosen di bawahnya (varian `management` dari
    // MaterialCard di Figma). Nomor "modul" tidak lagi menyatu di meta — ia
    // jadi eyebrow seperti pada kartu student.
    return Container(
      padding: const EdgeInsets.all(NetLearnSpace.s15),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NlMaterialThumbnail(
            moduleNumber: material.moduleNumber,
            exampleIpLabel: l10n.materialArtExampleIp,
          ),

          const SizedBox(height: NetLearnSpace.s15),

          if (material.moduleNumber != null) ...[
            Text(
              l10n.moduleEyebrow(material.moduleNumber.toString())
                  .toUpperCase(),
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: NetLearnSpace.s6),
          ],

          Text(
            title.isEmpty ? '-' : title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),

          if (description != null && description.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.mutedText,
              ),
            ),
          ],

          const SizedBox(height: NetLearnSpace.s12),

          // Meta kartu management hanya menampilkan durasi; nama modul sudah
          // berdiri sebagai eyebrow di atas judul.
          if (durationText != null) ...[
            Wrap(
              spacing: NetLearnSpace.s6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 14,
                  color: context.mutedText,
                ),
                Text(
                  durationText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.mutedText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: NetLearnSpace.s12),
          ],

          // `.section-heading`: badge di kiri, chevron di kanan. Badge "Inti"
          // hanya milik dosen (student membaca status kuncinya sendiri).
          Wrap(
            spacing: NetLearnSpace.s8,
            runSpacing: NetLearnSpace.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(
                status: material.published
                    ? NetLearnStatus.linked
                    : NetLearnStatus.active,
                label: material.published ? l10n.published : l10n.draft,
              ),
              if (material.isCore)
                StatusBadge(
                  status: NetLearnStatus.down,
                  label: l10n.coreMaterial,
                ),
              // Katup dosen yang menimpa progres mahasiswa (20261101130000):
              // tanpa badge ini dosen tidak bisa melihat mana saja yang sudah
              // dia atur terbuka/terkunci setelah pilihan itu tersimpan.
              if (material.lockStatus == 'unlocked')
                StatusBadge(
                  status: NetLearnStatus.linked,
                  label: l10n.materialAccessForcedOpenBadge,
                ),
              if (material.lockStatus == 'locked')
                StatusBadge(
                  status: NetLearnStatus.down,
                  label: l10n.materialAccessForcedLockedBadge,
                ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: context.accent,
              ),
            ],
          ),

          const SizedBox(height: NetLearnSpace.s12),

          // View Material button — light purple, full width (Figma `min-h-11`
          // = 44px, ditinggikan dari 40 untuk menyamai daftar student).
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                // Route lecturer material detail — NOT student route.
                // Previously '/student/material/${material.id}' which sent
                // lecturers to the student dashboard after popping.
                context.push('/lecturer/materials/${material.id}/view');
              },
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: Text(l10n.viewMaterial),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.accent,
                backgroundColor: context.accentTint,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(NetLearnRadius.button),
                ),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: NetLearnSpace.s8),

          // Edit / Delete: baris penuh berdua di ujung (Figma `justify-between`
          // `.link min-h-11`), ikon pensil/tempah disertai teks. Target sentuh
          // tetap selebar tombol; hapus untuk materi inti terkunci karena
          // trigger DB menolaknya (`CORE_MODULE_PROTECTED`), sama seperti
          // implementasi lama.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(l10n.editMaterial),
                style: TextButton.styleFrom(
                  foregroundColor: context.accent,
                  minimumSize: const Size(44, 44),
                  textStyle: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: material.isCore ? null : onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: Text(l10n.deleteMaterial),
                style: TextButton.styleFrom(
                  foregroundColor: material.isCore
                      ? context.mutedText
                      : NetLearnColors.danger,
                  // Keep the muted colour at full strength even when the
                  // button reports disabled instead of the default faded
                  // overlay, matching the old link treatment.
                  disabledForegroundColor: context.mutedText,
                  minimumSize: const Size(44, 44),
                  textStyle: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}