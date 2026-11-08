import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/progress/pretest_lock_prompt.dart';
import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_empty_state.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_material_thumbnail.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/nl_topbar.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/student_bottom_navbar.dart';
import 'student_materials_controller.dart';

class StudentMaterialsPage extends ConsumerWidget {
  const StudentMaterialsPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final modulesAsync = ref.watch(studentModulesProvider);

    return Scaffold(
      backgroundColor: context.background,

      // `.compact` di Figma selalu menampilkan tombol kembali di kiri, termasuk
      // pada daftar materi. Dulu tombol ini tidak ada (`onBack` null) sehingga
      // layar yang paling sering dibuka terasa tanpa jalan keluar. `goBack`
      // pop bila daftar memang ditumpuk, dan jatuh ke dashboard (tab materials
      // bukan halaman yang punya induk lain) ketika dibuka lewat deep link.
      appBar: NlTopBar(
        title: l10n.materials,
        onBack: () => goBack(context, fallback: '/student'),
      ),

      body: RefreshIndicator(
        color: context.accent,
        onRefresh: () async {
          ref.invalidate(studentModulesProvider);
          await ref.read(studentModulesProvider.future);
        },
        child: modulesAsync.when(
          loading: () {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(
                  height: 260,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            );
          },
          error: (error, stackTrace) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(
                  height: 90,
                ),
                NlErrorView(
                  message: l10n.failedToLoad,
                  onRetry: () {
                    ref.invalidate(studentModulesProvider);
                  },
                ),
              ],
            );
          },
          data: (modules) {
            if (modules.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(
                    height: 90,
                  ),
                  NlEmptyState(
                    icon: Icons.inbox_outlined,
                    title: l10n.noModules,
                    message: l10n.noModulesDescription,
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                NetLearnSpace.s20,
                NetLearnSpace.s20,
                NetLearnSpace.s20,
                NetLearnSpace.s32,
              ),
              children: [
                ...modules.map(
                  (module) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: NetLearnSpace.s16,
                      ),
                      child: _ModuleCard(
                        module: module,
                        onTap: () {
                          if (!module.unlocked) {
                            if (module.blockedByPretest) {
                              // Pop-up yang menjelaskan kenapa modul masih
                              // terkunci dan menawarkan langkah berikutnya —
                              // bukan loncatan langsung ke daftar assessment
                              // yang tidak menyebut Pretest sama sekali.
                              showPretestLockedDialog(context);

                              return;
                            }

                            NlSnackBar.show(
                              context,
                              l10n.completePreviousModule,
                              tone: NlSnackTone.warning,
                            );

                            return;
                          }

                          // Kartu modul membuka daftar materinya, bukan
                          // langsung `firstMaterialId`. Aturan lama hanya
                          // benar selama satu modul berisi satu materi; begitu
                          // dosen menambah materi ke modul yang sudah ada,
                          // materi kedua dan seterusnya tidak terlihat dari
                          // mana pun. Kartu modul di dashboard tetap membuka
                          // materi pertama karena di sana alur yang berjalan
                          // adalah "lanjut belajar".
                          context.push(
                            '/student/materials/${module.moduleNumber}',
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const StudentBottomNavbar(
        currentIndex: 1,
      ),
    );
  }
}

/// Ringkasan progres ("Overall progress") tidak lagi dirender di halaman
/// Materials sesuai revisi desain Figma: daftar materi kini langsung diawali
/// kartu modul (tanpa "gap" kosong yang tersisa). Ringkasan yang setara tetap
/// ada di Dashboard student dan perhitungan progresnya tidak berubah — hanya
/// penempatannya di halaman ini yang dilepas. Tombol "Continue Learning" tidak
/// pernah ada di halaman ini; di Dashboard juga tidak tersentuh perubahan ini.

class _ModuleCard extends StatelessWidget {
  final StudentModule module;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.module,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final isLocked = !module.unlocked;

    final statusLabel = module.completed
        ? l10n.completed
        : module.blockedByPretest
            ? l10n.lockedNeedsPretest
            : isLocked
                ? l10n.locked
                : l10n.unlocked;

    return Semantics(
      button: true,
      label: '${l10n.moduleEyebrow(module.moduleNumber)}, '
          '${module.title}, $statusLabel',
      child: ExcludeSemantics(
        child: Material(
          color: context.surface,
          borderRadius: BorderRadius.circular(
            NetLearnRadius.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(
              NetLearnRadius.card,
            ),
            child: Container(
              padding: const EdgeInsets.all(NetLearnSpace.s15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  NetLearnRadius.card,
                ),
                border: Border.all(
                  color: context.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NlMaterialThumbnail(
                    moduleNumber: module.moduleNumber,
                    exampleIpLabel: l10n.materialArtExampleIp,
                  ),
                  const SizedBox(
                    height: NetLearnSpace.s15,
                  ),
                  Text(
                    l10n.moduleEyebrow(
                      module.moduleNumber.toString(),
                    ).toUpperCase(),
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(
                    height: NetLearnSpace.s6,
                  ),
                  Text(
                    module.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: NetLearnSpace.s12,
                  ),
                  Wrap(
                    spacing: NetLearnSpace.s8,
                    runSpacing: NetLearnSpace.s8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_outline_rounded,
                        size: 14,
                        color: context.mutedText,
                      ),
                      Text(
                        l10n.videoLearning,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.mutedText,
                        ),
                      ),
                      Icon(
                        Icons.schedule_outlined,
                        size: 14,
                        color: context.mutedText,
                      ),
                      Text(
                        module.durationMinutes > 0
                            ? '${module.durationMinutes} ${l10n.minutes}'
                            : l10n.noVideo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.mutedText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: NetLearnSpace.s12,
                  ),
                  Wrap(
                    spacing: NetLearnSpace.s8,
                    runSpacing: NetLearnSpace.s8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusBadge(
                        status: module.completed
                            ? NetLearnStatus.linked
                            : isLocked
                                ? NetLearnStatus.down
                                : NetLearnStatus.active,
                        label: statusLabel,
                      ),
                      Icon(
                        isLocked
                            ? Icons.lock_outline_rounded
                            : Icons.chevron_right_rounded,
                        size: 18,
                        color: isLocked
                            ? context.mutedText
                            : context.accent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.material-art` lama (gradient + ikon generik + nomor) digantikan oleh
/// `NlMaterialThumbnail` — ilustrasi per topik yang di-port dari MaterialThumbnail
/// di desain Figma, sehingga empat thumbnail materi tidak lagi identik.