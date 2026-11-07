import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/language_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_field.dart';
import '../../shared/widgets/nl_section_heading.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/nl_topbar.dart';
import 'lecturer_assessments_controller.dart';
import 'lecturer_bottom_navbar.dart';
import 'lecturer_materials_controller.dart';

class LecturerTaskFormPage extends ConsumerStatefulWidget {
  final String? taskId;

  const LecturerTaskFormPage({
    super.key,
    this.taskId,
  });

  bool get isEditing => taskId != null;

  @override
  ConsumerState<LecturerTaskFormPage> createState() => _LecturerTaskFormPageState();
}

class _LecturerTaskFormPageState extends ConsumerState<LecturerTaskFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleId;
  late final TextEditingController _titleEn;
  late final TextEditingController _descriptionId;
  late final TextEditingController _descriptionEn;
  late final TextEditingController _instructionsId;
  late final TextEditingController _instructionsEn;
  late final TextEditingController _durationMinutes;
  late final TextEditingController _timeLimit;
  late final TextEditingController _deadline;

  int? _selectedModule;
  bool _isModuleQuiz = false;
  bool _isRequiredForModule = false;
  bool _isLeaderboardEnabled = true;
  int _attemptsAllowed = 1;
  double _weight = 1.0;
  String _status = 'draft';
  bool _isIndonesian = true;

  @override
  void initState() {
    super.initState();

    _titleId = TextEditingController();
    _titleEn = TextEditingController();
    _descriptionId = TextEditingController();
    _descriptionEn = TextEditingController();
    _instructionsId = TextEditingController();
    _instructionsEn = TextEditingController();
    _durationMinutes = TextEditingController(text: '0');
    _timeLimit = TextEditingController(text: '0');
    _deadline = TextEditingController();

    _titleId.addListener(_onFieldChanged);
    _titleEn.addListener(_onFieldChanged);

    if (widget.isEditing) {
      _loadTask();
    }
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTask() async {
    final task = await ref.read(lecturerTaskProvider(widget.taskId!).future);
    if (task == null || !mounted) return;

    setState(() {
      _titleId.text = task.titleId;
      _titleEn.text = task.titleEn;
      _descriptionId.text = task.descriptionId ?? '';
      _descriptionEn.text = task.descriptionEn ?? '';
      _instructionsId.text = task.instructionsId ?? '';
      _instructionsEn.text = task.instructionsEn ?? '';
      _durationMinutes.text = task.durationMinutes.toString();
      _timeLimit.text = task.timeLimit.toString();
      _selectedModule = task.module;
      _isModuleQuiz = task.module != null;
      _isRequiredForModule = task.required;
      _isLeaderboardEnabled = task.leaderboardEnabled;
      _attemptsAllowed = task.attemptsAllowed;
      _weight = task.weight;
      _status = task.status;
      if (task.deadline != null) {
        _deadline.text = _formatDateTimeForInput(task.deadline!);
      }
    });
  }

  String _formatDateTimeForInput(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}T${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _titleId.removeListener(_onFieldChanged);
    _titleEn.removeListener(_onFieldChanged);
    _titleId.dispose();
    _titleEn.dispose();
    _descriptionId.dispose();
    _descriptionEn.dispose();
    _instructionsId.dispose();
    _instructionsEn.dispose();
    _durationMinutes.dispose();
    _timeLimit.dispose();
    _deadline.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final isAppId = ref.read(languageProvider).languageCode == 'id';

    final titleIdVal = _titleId.text.trim();
    final titleEnVal = _titleEn.text.trim();

    if (titleIdVal.isEmpty && titleEnVal.isEmpty) {
      NlSnackBar.show(
        context,
        isAppId
            ? 'Judul asesmen wajib diisi (minimal Bahasa Indonesia)'
            : 'Assessment title is required (at least in Indonesian)',
        tone: NlSnackTone.warning,
      );
      if (!_isIndonesian) {
        setState(() => _isIndonesian = true);
      }
      return;
    }

    final resolvedTitle = titleIdVal.isNotEmpty ? titleIdVal : titleEnVal;
    final resolvedTitleEn = titleEnVal.isNotEmpty ? titleEnVal : titleIdVal;

    final task = LecturerTask(
      id: widget.taskId ?? '',
      title: resolvedTitle,
      titleEn: resolvedTitleEn,
      titleId: resolvedTitle,
      assessmentType: 'task',
      durationMinutes: int.tryParse(_durationMinutes.text.trim()) ?? 0,
      status: _status,
      questionCount: 0,
      answeredCount: 0,
      module: _isModuleQuiz ? _selectedModule : null,
      required: _isModuleQuiz ? _isRequiredForModule : false,
      leaderboardEnabled: _isLeaderboardEnabled,
      attemptsAllowed: _attemptsAllowed,
      weight: _weight,
      description: _descriptionId.text.trim().isEmpty
          ? (_descriptionEn.text.trim().isEmpty ? null : _descriptionEn.text.trim())
          : _descriptionId.text.trim(),
      descriptionEn: _descriptionEn.text.trim().isEmpty ? null : _descriptionEn.text.trim(),
      descriptionId: _descriptionId.text.trim().isEmpty ? null : _descriptionId.text.trim(),
      instructions: _instructionsId.text.trim().isEmpty
          ? (_instructionsEn.text.trim().isEmpty ? null : _instructionsEn.text.trim())
          : _instructionsId.text.trim(),
      instructionsEn: _instructionsEn.text.trim().isEmpty ? null : _instructionsEn.text.trim(),
      instructionsId: _instructionsId.text.trim().isEmpty ? null : _instructionsId.text.trim(),
      timeLimit: int.tryParse(_timeLimit.text.trim()) ?? 0,
      deadline: _deadline.text.trim().isEmpty ? null : DateTime.tryParse(_deadline.text.trim()),
      submittedCount: 0,
    );

    try {
      if (widget.isEditing) {
        await updateTask(ref, task);

        if (!mounted) return;

        NlSnackBar.show(
          context,
          l10n.taskUpdated,
          tone: NlSnackTone.success,
        );

        context.go('/lecturer/assessments');
      } else {
        final taskId = await createTask(ref, task);

        if (!mounted) return;

        NlSnackBar.show(
          context,
          l10n.taskCreated,
          tone: NlSnackTone.success,
        );

        // Multiple-choice questions need a persisted quiz id, so the new task
        // is created first and the lecturer lands straight on its question
        // editor -- the same editor the task detail page opens. This keeps one
        // question editor instead of a second copy embedded in this form.
        context.go('/lecturer/assessments/$taskId/questions');
      }
    } on AssessmentWriteException catch (error) {
      if (!mounted) return;

      NlSnackBar.show(
        context,
        switch (error.failure) {
          AssessmentWriteFailure.missingAnswerKey =>
            l10n.answerKeyMissing(0),
          AssessmentWriteFailure.quizIncomplete =>
            l10n.assessmentQuizIncomplete,
          AssessmentWriteFailure.notPermitted =>
            l10n.notPermittedError,
          AssessmentWriteFailure.unknown =>
            error.detail != null && error.detail!.isNotEmpty
                ? '${l10n.taskSaveFailed} (${error.detail})'
                : l10n.taskSaveFailed,
        },
        tone: NlSnackTone.error,
      );
    }
  }

  Future<void> _pickDeadline() async {
    final DateTime initialDate = _deadline.text.isNotEmpty
        ? (DateTime.tryParse(_deadline.text) ?? DateTime.now().add(const Duration(days: 7)))
        : DateTime.now().add(const Duration(days: 7));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (pickedTime == null || !mounted) return;

    final DateTime combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _deadline.text = _formatDateTimeForInput(combined);
    });
  }

  Future<void> _pickModule() async {
    final int? selected = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => _ModulePicker(
        initialValue: _selectedModule,
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedModule = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isAppId = ref.watch(languageProvider).languageCode == 'id';
    final hasIdContent = _titleId.text.trim().isNotEmpty;
    final hasEnContent = _titleEn.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: context.background,
      appBar: NlTopBar(
        title: widget.isEditing ? l10n.editTask : l10n.addTask,
        onBack: () => context.pop(),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            NetLearnSpace.s20,
            NetLearnSpace.s16,
            NetLearnSpace.s20,
            NetLearnSpace.s32,
          ),
          children: [
            // Modern Language Switcher Card
            _LanguageSwitcherCard(
              isIndonesian: _isIndonesian,
              hasIdContent: hasIdContent,
              hasEnContent: hasEnContent,
              isAppId: isAppId,
              onLanguageChanged: (val) {
                setState(() => _isIndonesian = val);
              },
            ),

            const SizedBox(height: NetLearnSpace.s12),

            // Active language feedback banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isIndonesian
                    ? const Color(0xFFE53935).withValues(alpha: 0.08)
                    : const Color(0xFF012169).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isIndonesian
                      ? const Color(0xFFE53935).withValues(alpha: 0.25)
                      : const Color(0xFF012169).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  _isIndonesian
                      ? const IndonesiaFlag(width: 20, height: 14)
                      : const UkFlag(width: 20, height: 14),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isIndonesian
                          ? (isAppId
                              ? 'Formulir saat ini mengedit versi: Bahasa Indonesia (Wajib)'
                              : 'Currently editing: Indonesian Version (Required)')
                          : (isAppId
                              ? 'Formulir saat ini mengedit versi: English (Opsional)'
                              : 'Currently editing: English Version (Optional)'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: _isIndonesian
                            ? const Color(0xFFC62828)
                            : const Color(0xFF0D47A1),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: NetLearnSpace.s20),

            // Basic Information Section
            NlSectionHeading(
              title: l10n.basicInformation,
              leadingIcon: Icons.info_outline,
            ),

            const SizedBox(height: NetLearnSpace.s16),

            // Task Title
            NlField(
              label: '${l10n.taskTitle} ${_isIndonesian ? '[Bahasa Indonesia]' : '[English]'}',
              placeholder: _isIndonesian ? 'Contoh: Kuis Subnetting & Pengalamatan IP' : 'e.g. Subnetting & IP Addressing Quiz',
              controller: _isIndonesian ? _titleId : _titleEn,
              validator: (value) {
                final trimmed = (value ?? '').trim();
                if (trimmed.isEmpty && (_isIndonesian ? _titleEn.text.trim().isEmpty : _titleId.text.trim().isEmpty)) {
                  return l10n.requiredField;
                }
                return null;
              },
            ),

            const SizedBox(height: NetLearnSpace.s16),

            // Description
            NlField(
              label: '${l10n.description} ${_isIndonesian ? '[Bahasa Indonesia]' : '[English]'}',
              placeholder: _isIndonesian ? 'Ringkasan singkat tujuan dan materi asesmen ini...' : 'Brief summary of the assessment topics...',
              controller: _isIndonesian ? _descriptionId : _descriptionEn,
              keyboardType: TextInputType.multiline,
              maxLines: 3,
            ),

            const SizedBox(height: NetLearnSpace.s16),

            // Assessment Category Selector
            const SizedBox(height: NetLearnSpace.s16),
            Container(
              decoration: BoxDecoration(
                color: context.raisedSurface,
                borderRadius: BorderRadius.circular(NetLearnRadius.card),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioListTile<bool>(
                    title: Text(
                      isAppId ? 'Asesmen Kustom Bebas (LMS)' : 'Custom Standalone Assessment',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      isAppId
                          ? 'Dapat dikerjakan mahasiswa kapan saja atau sesuai batas waktu yang ditentukan.'
                          : 'Available for students anytime or within the specified deadline.',
                      style: theme.textTheme.bodySmall?.copyWith(color: context.mutedText),
                    ),
                    value: false,
                    groupValue: _isModuleQuiz,
                    onChanged: (val) {
                      setState(() {
                        _isModuleQuiz = val ?? false;
                        if (!_isModuleQuiz) {
                          _selectedModule = null;
                          _isRequiredForModule = false;
                        }
                      });
                    },
                    activeColor: context.accent,
                  ),
                  const Divider(height: 1),
                  RadioListTile<bool>(
                    title: Text(
                      isAppId ? 'Kuis Terikat Modul (Checkpoint)' : 'Module-Bound Quiz',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      isAppId
                          ? 'Diikat ke modul tertentu untuk menguji pemahaman materi.'
                          : 'Linked to a specific module to test comprehension.',
                      style: theme.textTheme.bodySmall?.copyWith(color: context.mutedText),
                    ),
                    value: true,
                    groupValue: _isModuleQuiz,
                    onChanged: (val) {
                      setState(() {
                        _isModuleQuiz = val ?? true;
                      });
                    },
                    activeColor: context.accent,
                  ),
                ],
              ),
            ),

            if (_isModuleQuiz) ...[
              const SizedBox(height: NetLearnSpace.s16),
              // Module selector
              NlField(
                label: l10n.module,
                placeholder: _selectedModule == null
                    ? l10n.moduleHint
                    : 'Modul $_selectedModule',
                controller: TextEditingController(
                  text: _selectedModule?.toString() ?? '',
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_drop_down),
                  onPressed: _pickModule,
                ),
                validator: (value) {
                  if (_isModuleQuiz && _selectedModule == null) {
                    return l10n.requiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: NetLearnSpace.s8),
              SwitchListTile(
                value: _isRequiredForModule,
                onChanged: (val) => setState(() => _isRequiredForModule = val),
                title: Text(
                  isAppId
                      ? 'Wajibkan kuis untuk buka modul berikutnya'
                      : 'Require quiz to unlock next module',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  isAppId
                      ? 'Default nonaktif. Jika aktif, mahasiswa wajib lulus kuis ini sebelum modul selanjutnya terbuka.'
                      : 'Default disabled. If active, students must pass this quiz before advancing.',
                  style: theme.textTheme.bodySmall?.copyWith(color: context.mutedText),
                ),
                activeColor: context.accent,
                contentPadding: EdgeInsets.zero,
              ),
            ],

            const SizedBox(height: NetLearnSpace.s16),

            // Instructions
            NlField(
              label: '${l10n.instructions} ${_isIndonesian ? '[Bahasa Indonesia]' : '[English]'}',
              placeholder: _isIndonesian
                  ? 'Petunjuk pengerjaan bagi mahasiswa...'
                  : 'Instructions for students...',
              controller: _isIndonesian ? _instructionsId : _instructionsEn,
              keyboardType: TextInputType.multiline,
              maxLines: 3,
            ),

            const SizedBox(height: NetLearnSpace.s24),

            // Timing & Deadline Section
            NlSectionHeading(
              title: l10n.timingDeadline,
              leadingIcon: Icons.timer_outlined,
            ),

            const SizedBox(height: NetLearnSpace.s16),

            // Duration
            NlField(
              label: l10n.durationMinutesLabel,
              placeholder: '0',
              controller: _durationMinutes,
              keyboardType: TextInputType.number,
              validator: (value) {
                final parsed = int.tryParse((value ?? '').trim());
                if (parsed == null || parsed < 0) {
                  return l10n.durationInvalid;
                }
                return null;
              },
            ),

            const SizedBox(height: NetLearnSpace.s16),

            // Time Limit
            NlField(
              label: l10n.timeLimitMinutes,
              placeholder: '0',
              controller: _timeLimit,
              keyboardType: TextInputType.number,
              validator: (value) {
                final parsed = int.tryParse((value ?? '').trim());
                if (parsed == null || parsed < 0 || parsed > 180) {
                  return l10n.timeLimitInvalid;
                }
                return null;
              },
            ),

            const SizedBox(height: NetLearnSpace.s16),

            // Time Limit Helper Text
            Text(
              l10n.timeLimitHelper,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.mutedText,
              ),
            ),

            const SizedBox(height: NetLearnSpace.s16),

            // Deadline
            NlField(
              label: l10n.deadline,
              placeholder: l10n.deadlineHint,
              controller: _deadline,
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _pickDeadline,
              ),
              validator: (value) {
                if ((value ?? '').trim().isNotEmpty) {
                  final parsed = DateTime.tryParse((value ?? '').trim());
                  if (parsed == null) {
                    return l10n.deadlineInvalid;
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: NetLearnSpace.s24),

            // Leaderboard & Grading Settings
            NlSectionHeading(
              title: isAppId ? 'Pengaturan Penilaian & Leaderboard' : 'Grading & Leaderboard Settings',
              leadingIcon: Icons.emoji_events_outlined,
            ),

            const SizedBox(height: NetLearnSpace.s12),

            Container(
              decoration: BoxDecoration(
                color: context.raisedSurface,
                borderRadius: BorderRadius.circular(NetLearnRadius.card),
                border: Border.all(color: theme.dividerColor),
              ),
              padding: const EdgeInsets.all(NetLearnSpace.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    value: _isLeaderboardEnabled,
                    onChanged: (val) => setState(() => _isLeaderboardEnabled = val),
                    title: Text(
                      isAppId ? 'Sertakan dalam Leaderboard Kelas' : 'Include in Class Leaderboard',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      isAppId
                          ? 'Nilai pengerjaan mahasiswa akan diakumulasikan ke total poin peringkat kelas.'
                          : 'Student scores will be accumulated into their class total leaderboard points.',
                      style: theme.textTheme.bodySmall?.copyWith(color: context.mutedText),
                    ),
                    activeColor: context.accent,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: NetLearnSpace.s16),
                  DropdownButtonFormField<int>(
                    value: _attemptsAllowed,
                    decoration: InputDecoration(
                      labelText: isAppId ? 'Batas Percobaan Pengerjaan' : 'Allowed Attempts',
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 1,
                        child: Text(isAppId ? '1 Kali (Ujian Resmi)' : '1 Attempt (Official Test)'),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text(isAppId ? '2 Kali Percobaan' : '2 Attempts'),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text(isAppId ? '3 Kali Percobaan' : '3 Attempts'),
                      ),
                      DropdownMenuItem(
                        value: 0,
                        child: Text(isAppId ? 'Tanpa Batas (Latihan Mandiri)' : 'Unlimited (Practice)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _attemptsAllowed = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: NetLearnSpace.s24),

            // Status Section
            NlSectionHeading(
              title: l10n.status,
              leadingIcon: Icons.flag_outlined,
            ),

            const SizedBox(height: NetLearnSpace.s16),

            // Radio buttons for status
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text(l10n.draft),
                    value: 'draft',
                    groupValue: _status,
                    onChanged: (value) => setState(() => _status = value!),
                    activeColor: context.accent,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text(l10n.published),
                    value: 'published',
                    groupValue: _status,
                    onChanged: (value) => setState(() => _status = value!),
                    activeColor: context.accent,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),

            const SizedBox(height: NetLearnSpace.s32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: NlButton(
                    label: l10n.cancel,
                    variant: NlButtonVariant.outline,
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(width: NetLearnSpace.s12),
                Expanded(
                  child: NlButton(
                    label: widget.isEditing ? l10n.save : l10n.createTask,
                    variant: NlButtonVariant.primary,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const LecturerBottomNavbar(currentIndex: 3),
    );
  }
}

class IndonesiaFlag extends StatelessWidget {
  final double width;
  final double height;

  const IndonesiaFlag({
    super.key,
    this.width = 22,
    this.height = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.20),
          width: 0.7,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Container(color: const Color(0xFFE53935)),
          ),
          Expanded(
            child: Container(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class UkFlag extends StatelessWidget {
  final double width;
  final double height;

  const UkFlag({
    super.key,
    this.width = 22,
    this.height = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.20),
          width: 0.7,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        size: Size(width, height),
        painter: _UkFlagPainter(),
      ),
    );
  }
}

class _UkFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Navy blue field
    final bluePaint = Paint()..color = const Color(0xFF012169);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bluePaint);

    // 2. White saltire (diagonal cross)
    final whitePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.22
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(w, h), whitePaint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), whitePaint);

    // 3. Red saltire (thinner diagonal cross)
    final redDiagonalPaint = Paint()
      ..color = const Color(0xFFC8102E)
      ..strokeWidth = w * 0.11
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(w, h), redDiagonalPaint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), redDiagonalPaint);

    // 4. White cross (St George's broad cross)
    final whiteCrossPaint = Paint()..color = Colors.white;
    final crossBarW = w * 0.26;
    final crossBarH = h * 0.30;
    canvas.drawRect(Rect.fromLTWH((w - crossBarW) / 2, 0, crossBarW, h), whiteCrossPaint);
    canvas.drawRect(Rect.fromLTWH(0, (h - crossBarH) / 2, w, crossBarH), whiteCrossPaint);

    // 5. Red cross (St George's central cross)
    final redCrossPaint = Paint()..color = const Color(0xFFC8102E);
    final innerCrossW = w * 0.16;
    final innerCrossH = h * 0.18;
    canvas.drawRect(Rect.fromLTWH((w - innerCrossW) / 2, 0, innerCrossW, h), redCrossPaint);
    canvas.drawRect(Rect.fromLTWH(0, (h - innerCrossH) / 2, w, innerCrossH), redCrossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LanguageSwitcherCard extends StatelessWidget {
  final bool isIndonesian;
  final bool hasIdContent;
  final bool hasEnContent;
  final bool isAppId;
  final ValueChanged<bool> onLanguageChanged;

  const _LanguageSwitcherCard({
    required this.isIndonesian,
    required this.hasIdContent,
    required this.hasEnContent,
    required this.isAppId,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(NetLearnSpace.s14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: context.accentTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.translate_rounded,
                  size: 16,
                  color: context.accent,
                ),
              ),
              const SizedBox(width: NetLearnSpace.s8),
              Expanded(
                child: Text(
                  isAppId ? 'Bahasa Input Konten' : 'Content Input Language',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: NetLearnSpace.s4),
          Text(
            isAppId
                ? 'Ganti tab bahasa untuk mengisi judul, deskripsi, dan petunjuk dalam dwibahasa.'
                : 'Switch language tab to edit title, description, and instructions in dual language.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.mutedText,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: NetLearnSpace.s12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.raisedSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.border.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _LangOption(
                    flag: const IndonesiaFlag(),
                    title: 'Bahasa Indonesia',
                    isSelected: isIndonesian,
                    isCompleted: hasIdContent,
                    tag: isAppId ? 'Utama (Wajib)' : 'Primary (Required)',
                    onTap: () => onLanguageChanged(true),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _LangOption(
                    flag: const UkFlag(),
                    title: 'English',
                    isSelected: !isIndonesian,
                    isCompleted: hasEnContent,
                    tag: isAppId ? 'Opsional (Dwibahasa)' : 'Optional (Dual Lang)',
                    onTap: () => onLanguageChanged(false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final Widget flag;
  final String title;
  final bool isSelected;
  final bool isCompleted;
  final String tag;
  final VoidCallback onTap;

  const _LangOption({
    required this.flag,
    required this.title,
    required this.isSelected,
    required this.isCompleted,
    required this.tag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? context.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
            border: isSelected
                ? Border.all(color: context.accent.withValues(alpha: 0.4), width: 1.2)
                : Border.all(color: Colors.transparent, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  flag,
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? context.accent : context.mutedText,
                        fontSize: 12.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCompleted) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: Color(0xFF2E7D32),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                      : (isSelected
                          ? context.accent.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCompleted
                      ? (isSelected ? '• Aktif Diedit' : '✓ Terisi')
                      : tag,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? const Color(0xFF2E7D32)
                        : (isSelected ? context.accent : context.mutedText),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModulePicker extends ConsumerWidget {
  final int? initialValue;

  const _ModulePicker({required this.initialValue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // Module names come from the core materials actually stored for each
    // module (module_number 1-4), not a hardcoded list, so renaming a module in
    // the content manager is reflected here. A module with no readable core
    // material falls back to a bare "Modul N" label.
    final materials = ref.watch(lecturerMaterialsProvider).value ??
        const [];

    String moduleName(int module) {
      for (final material in materials) {
        if (material.isCore && material.moduleNumber == module) {
          return material.title;
        }
      }

      return '';
    }

    return Container(
      padding: const EdgeInsets.all(NetLearnSpace.s16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(NetLearnRadius.card),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.module,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: NetLearnSpace.s16),
          for (int module = 1; module <= 4; module++)
            ListTile(
              title: Text(
                moduleName(module).isEmpty
                    ? '${l10n.module} $module'
                    : '${l10n.module} $module — ${moduleName(module)}',
              ),
              leading: Radio<int>(
                value: module,
                groupValue: initialValue,
                onChanged: (value) => Navigator.of(context).pop(value),
                activeColor: context.accent,
              ),
              onTap: () => Navigator.of(context).pop(module),
            ),
          const SizedBox(height: NetLearnSpace.s16),
        ],
      ),
    );
  }
}