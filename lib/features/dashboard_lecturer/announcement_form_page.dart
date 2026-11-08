import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/announcement_model.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../classes/class_controller.dart';
import 'announcement_controller.dart';
import 'lecturer_bottom_navbar.dart';

class LecturerAnnouncementFormPage extends ConsumerStatefulWidget {
  final String? announcementId;

  const LecturerAnnouncementFormPage({super.key, this.announcementId});

  @override
  ConsumerState<LecturerAnnouncementFormPage> createState() =>
      _LecturerAnnouncementFormPageState();
}

class _LecturerAnnouncementFormPageState
    extends ConsumerState<LecturerAnnouncementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  AnnouncementModel? _existingAnnouncement;
  String _recipientScope = 'all_students';

  @override
  void initState() {
    super.initState();
    _isEditing = widget.announcementId != null;
    if (_isEditing) {
      _loadAnnouncement();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncement() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
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
        .eq('id', widget.announcementId!)
        .eq('lecturer_id', user.id)
        .maybeSingle();

    if (response != null && mounted) {
      setState(() {
        _existingAnnouncement = AnnouncementModel.fromMap(
          Map<String, dynamic>.from(response),
        );
        _titleController.text = _existingAnnouncement!.title;
        _contentController.text = _existingAnnouncement!.displayContent;
        _recipientScope = _existingAnnouncement!.recipientScope;
      });
    }
  }

  Future<void> _save({required bool publish}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final l10n = AppLocalizations.of(context)!;
    final activeClass = ref.read(activeLecturerClassProvider).value;
    final targetClassId = _existingAnnouncement?.classId ??
        (activeClass != null && !activeClass.isLegacyFallback ? activeClass.id : null);

    try {
      if (_isEditing) {
        await updateAnnouncement(
          ref,
          id: widget.announcementId!,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          recipientScope: _recipientScope,
          publish: publish,
          classId: targetClassId,
        );
        if (!mounted) {
          return;
        }

        NlSnackBar.show(
          context,
          publish ? l10n.announcementPublishedSuccess : l10n.announcementUpdated,
          tone: NlSnackTone.success,
        );
      } else {
        await createAnnouncement(
          ref,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          recipientScope: _recipientScope,
          publish: publish,
          classId: targetClassId,
        );
        if (!mounted) {
          return;
        }

        NlSnackBar.show(
          context,
          publish ? l10n.announcementPublishedSuccess : l10n.announcementCreated,
          tone: NlSnackTone.success,
        );
      }

      if (mounted) {
        context.go('/lecturer/announcements');
      }
    } on AnnouncementWriteException catch (error) {
      if (!mounted) {
        return;
      }

      NlSnackBar.show(
        context,
        _writeFailureMessage(error, l10n),
        tone: NlSnackTone.error,
      );
    } catch (error) {
      // Semua kegagalan tulis yang kenal harusnya sudah dibungkus
      // AnnouncementWriteException; blok ini jaring pengaman untuk sisanya
      // (mis. PostgrestException yang lolos sebelum pemetaan), supaya tidak
      // ada exception tak tertangkap yang membuat tombol terjebak loading.
      if (!mounted) {
        return;
      }

      NlSnackBar.show(
        context,
        l10n.announcementSaveFailed,
        tone: NlSnackTone.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _writeFailureMessage(AnnouncementWriteException error, AppLocalizations l10n) {
    switch (error.failure) {
      case AnnouncementWriteFailure.notPermitted:
        return l10n.notPermittedError;
      case AnnouncementWriteFailure.titleTooLong:
        return 'Title is too long';
      case AnnouncementWriteFailure.contentTooLong:
        return 'Content is too long';
      case AnnouncementWriteFailure.unknown:
        return l10n.announcementSaveFailed;
    }
  }

  Future<bool> _onWillPop() async {
    if (_titleController.text.isNotEmpty || _contentController.text.isNotEmpty) {
      final l10n = AppLocalizations.of(context)!;
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final isId = Localizations.localeOf(context).languageCode == 'id';
          return AlertDialog(
            title: Text(isId ? 'Keluar Halaman' : 'Leave Page'),
            content: Text(
              isId
                  ? 'Batalkan perubahan dan tinggalkan halaman ini?'
                  : 'Discard changes and leave this page?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(isId ? 'Keluar' : 'Leave'),
              ),
            ],
          );
        },
      );
      return shouldLeave ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: context.background,

        appBar: AppBar(
          backgroundColor: context.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                context.pop();
              }
            },
          ),
          title: Text(
            _isEditing ? l10n.editAnnouncement : l10n.createAnnouncement,
            style: theme.textTheme.titleLarge,
          ),
        ),

        body: Form(
          key: _formKey,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20 + 80),
            children: [
              Builder(
                builder: (context) {
                  final activeClass = ref.watch(activeLecturerClassProvider).value;
                  if (activeClass == null || activeClass.isLegacyFallback) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: context.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.accent.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.class_outlined, size: 20, color: context.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Target Kelas: ${activeClass.name}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Title Field
              TextFormField(
                controller: _titleController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: l10n.announcementTitle,
                  hintText: l10n.announcementTitleHint,
                  filled: true,
                  fillColor: context.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.accent, width: 1.5),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.titleRequired;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Content Field
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                minLines: 5,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: l10n.announcementContent,
                  hintText: l10n.announcementContentHint,
                  filled: true,
                  fillColor: context.surface,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.accent, width: 1.5),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.contentRequired;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Recipient Scope
              Text(
                l10n.recipientScope,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.accent,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.border),
                ),
                child: Column(
                  children: [
                    // All Students Option
                    _ScopeOption(
                      value: 'all_students',
                      groupValue: _recipientScope,
                      title: l10n.allStudents,
                      subtitle: 'Send to all students in your courses',
                      icon: Icons.people_rounded,
                      onChanged: (value) {
                        setState(() => _recipientScope = value!);
                      },
                    ),
                    // Could add more scope options here in the future
                    // (e.g., specific class, module, etc.)
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Preview Section
              if (_titleController.text.isNotEmpty || _contentController.text.isNotEmpty) ...[
                Text(
                  'Preview',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.accent,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: context.accentTint,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.campaign_rounded,
                              color: context.accent,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _titleController.text.isEmpty
                                  ? (l10n.announcementTitle)
                                  : _titleController.text,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_contentController.text.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          _contentController.text,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Action Buttons — Save Draft (outline) leads, Publish (primary) is the
              // emphasised action. Side by side only when there is room: 360dp is
              // the narrowest supported width and labels grow up to 1.3x, where
              // two full labels no longer fit on one row, so below 400dp the two
              // stack full-width instead of overflowing or truncating.
              LayoutBuilder(
                builder: (context, constraints) {
                  final saveDraftButton = NlButton(
                    label: l10n.saveDraft,
                    icon: Icons.save_outlined,
                    variant: NlButtonVariant.outline,
                    loading: _isLoading,
                    onPressed: _isLoading ? null : () => _save(publish: false),
                  );

                  final publishButton = NlButton(
                    label: l10n.publish,
                    icon: Icons.send_rounded,
                    variant: NlButtonVariant.primary,
                    loading: _isLoading,
                    onPressed: _isLoading ? null : () => _save(publish: true),
                  );

                  if (constraints.maxWidth < 400) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        saveDraftButton,
                        const SizedBox(height: 12),
                        publishButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: saveDraftButton),
                      const SizedBox(width: 12),
                      Expanded(child: publishButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        bottomNavigationBar: const LecturerBottomNavbar(
          currentIndex: 0,
        ),
      ),
    );
  }
}

class _ScopeOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _ScopeOption({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? context.accentTint : context.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? context.accent : context.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? context.accent : context.mutedText,
                    width: 2,
                  ),
                  color: selected ? context.accent : Colors.transparent,
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.onPrimary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 18, color: context.accent),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}