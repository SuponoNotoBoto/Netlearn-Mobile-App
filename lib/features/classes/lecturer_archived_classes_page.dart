import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_skeleton.dart';
import '../../shared/widgets/nl_surface_card.dart';
import '../dashboard_lecturer/lecturer_bottom_navbar.dart';
import 'class_action_messages.dart';
import 'class_controller.dart';

class LecturerArchivedClassesPage extends ConsumerWidget {
  const LecturerArchivedClassesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final archivedAsync = ref.watch(lecturerArchivedClassesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.archivedClassesTitle),
      ),
      body: SafeArea(
        child: archivedAsync.when(
          loading: () => const NlSkeletonList(
            itemCount: 3,
            padding: EdgeInsets.all(AppSpacing.s20),
          ),
          error: (_, _) => Center(child: Text(l10n.couldNotLoadData)),
          data: (classes) {
            if (classes.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s24),
                  child: Text(
                    l10n.noClassesLecturerTitle,
                    style: AppTypography.body(context),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.s20),
              itemCount: classes.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.s12),
              itemBuilder: (context, index) {
                final cls = classes[index];
                return NlSurfaceCard(
                  key: Key('archived_class_card_${cls.id}'),
                  onTap: () => context.push('/lecturer/classes/${cls.id}'),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cls.name,
                              style: AppTypography.cardTitle(context),
                            ),
                            if (cls.semester != null &&
                                cls.semester!.isNotEmpty)
                              Text(
                                cls.semester!,
                                style: AppTypography.caption(context),
                              ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        key: Key('restore_archived_class_${cls.id}'),
                        onPressed: () => runClassAction(
                          context,
                          () => setClassStatusAction(
                            ref,
                            classId: cls.id,
                            status: 'draft',
                          ),
                          successMessage: l10n.classUpdatedSuccess,
                        ),
                        icon: const Icon(Icons.restore_rounded, size: 16),
                        label: Text(l10n.classRestoreAction),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const LecturerBottomNavbar(currentIndex: 0),
    );
  }
}

