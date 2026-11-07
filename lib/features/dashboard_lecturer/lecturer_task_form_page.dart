// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_field.dart';
import '../../shared/widgets/nl_section_heading.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/nl_topbar.dart';
import 'assessment_models.dart';

class LecturerTaskFormPage extends StatefulWidget {
  final LecturerTask? task;
  final ValueChanged<LecturerTask>? onSave;

  const LecturerTaskFormPage({
    super.key,
    this.task,
    this.onSave,
  });

  bool get isEditing => task != null;

  @override
  State<LecturerTaskFormPage> createState() => _LecturerTaskFormPageState();
}

class _LecturerTaskFormPageState extends State<LecturerTaskFormPage> {
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
  String _status = 'draft';
  bool _isIndonesian = true;

  @override
  void initState() {
    super.initState();

    final t = widget.task;

    _titleId = TextEditingController(text: t?.titleId ?? t?.title ?? '');
    _titleEn = TextEditingController(text: t?.titleEn ?? '');
    _descriptionId = TextEditingController(text: t?.description ?? '');
    _descriptionEn = TextEditingController();
    _instructionsId = TextEditingController(text: t?.instructions ?? '');
    _instructionsEn = TextEditingController();
    _durationMinutes = TextEditingController(text: (t?.durationMinutes ?? 30).toString());
    _timeLimit = TextEditingController(text: (t?.timeLimit ?? 30).toString());
    _deadline = TextEditingController(
      text: t?.deadline != null ? _formatDateTimeForInput(t!.deadline!) : '',
    );

    _selectedModule = t?.module;
    _isModuleQuiz = t?.module != null;
    _isRequiredForModule = t?.required ?? false;
    _isLeaderboardEnabled = t?.leaderboardEnabled ?? true;
    _attemptsAllowed = t?.attemptsAllowed ?? 1;
    _status = t?.status ?? 'draft';

    _titleId.addListener(_onFieldChanged);
    _titleEn.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  String _formatDateTimeForInput(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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

  Future<void> _pickDeadline() async {
    final DateTime initialDate = _deadline.text.isNotEmpty
        ? (DateTime.tryParse(_deadline.text.replaceAll(' ', 'T')) ?? DateTime.now().add(const Duration(days: 7)))
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

  void _submit() {
    final titleIdVal = _titleId.text.trim();
    final titleEnVal = _titleEn.text.trim();

    if (titleIdVal.isEmpty && titleEnVal.isEmpty) {
      NlSnackBar.show(
        context,
        'Judul asesmen wajib diisi (minimal Bahasa Indonesia)',
        tone: NlSnackTone.warning,
      );
      if (!_isIndonesian) {
        setState(() => _isIndonesian = true);
      }
      return;
    }

    final resolvedTitle = titleIdVal.isNotEmpty ? titleIdVal : titleEnVal;
    final resolvedTitleEn = titleEnVal.isNotEmpty ? titleEnVal : titleIdVal;

    final duration = int.tryParse(_durationMinutes.text.trim()) ?? 30;
    final timeLimit = int.tryParse(_timeLimit.text.trim()) ?? 0;
    final deadlineParsed = _deadline.text.isNotEmpty
        ? DateTime.tryParse(_deadline.text.replaceAll(' ', 'T'))
        : null;

    final createdTask = LecturerTask(
      id: widget.task?.id ?? 'task-${DateTime.now().millisecondsSinceEpoch}',
      title: resolvedTitle,
      titleEn: resolvedTitleEn,
      titleId: resolvedTitle,
      assessmentType: _isModuleQuiz ? 'quiz' : 'task',
      durationMinutes: duration,
      status: _status,
      questionCount: widget.task?.questionCount ?? 10,
      answeredCount: widget.task?.answeredCount ?? 10,
      module: _isModuleQuiz ? (_selectedModule ?? 1) : null,
      required: _isModuleQuiz ? _isRequiredForModule : false,
      leaderboardEnabled: _isLeaderboardEnabled,
      attemptsAllowed: _attemptsAllowed,
      description: _descriptionId.text.trim().isNotEmpty
          ? _descriptionId.text.trim()
          : (_descriptionEn.text.trim().isNotEmpty ? _descriptionEn.text.trim() : null),
      instructions: _instructionsId.text.trim().isNotEmpty
          ? _instructionsId.text.trim()
          : (_instructionsEn.text.trim().isNotEmpty ? _instructionsEn.text.trim() : null),
      timeLimit: timeLimit,
      deadline: deadlineParsed,
      submittedCount: widget.task?.submittedCount ?? 0,
    );

    widget.onSave?.call(createdTask);

    NlSnackBar.show(
      context,
      widget.isEditing
          ? 'Asesmen "${createdTask.title}" berhasil diperbarui'
          : 'Asesmen baru "${createdTask.title}" berhasil dibuat',
      tone: NlSnackTone.success,
    );

    Navigator.pop(context, createdTask);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasIdContent = _titleId.text.trim().isNotEmpty;
    final hasEnContent = _titleEn.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: context.background,
      appBar: NlTopBar(
        title: widget.isEditing ? 'Ubah Asesmen' : 'Tambah Asesmen Baru',
        onBack: () => Navigator.pop(context),
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
            // Language Switcher Card (Persis NetLearn 2.0)
            _LanguageSwitcherCard(
              isIndonesian: _isIndonesian,
              hasIdContent: hasIdContent,
              hasEnContent: hasEnContent,
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
                          ? 'Formulir saat ini mengedit versi: Bahasa Indonesia (Wajib)'
                          : 'Formulir saat ini mengedit versi: English (Opsional)',
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

            // Section 1: Informasi Dasar
            const NlSectionHeading(
              title: 'Informasi Dasar',
              leadingIcon: Icons.info_outline,
            ),
            const SizedBox(height: NetLearnSpace.s16),

            // Task Title
            NlField(
              label: 'Judul Asesmen ${_isIndonesian ? '[Bahasa Indonesia]' : '[English]'}',
              placeholder: _isIndonesian
                  ? 'Contoh: Kuis Subnetting & Pengalamatan IP'
                  : 'e.g. Subnetting & IP Addressing Quiz',
              controller: _isIndonesian ? _titleId : _titleEn,
              validator: (value) {
                final trimmed = (value ?? '').trim();
                if (trimmed.isEmpty && (_isIndonesian ? _titleEn.text.trim().isEmpty : _titleId.text.trim().isEmpty)) {
                  return 'Judul asesmen wajib diisi';
                }
                return null;
              },
            ),

            const SizedBox(height: NetLearnSpace.s16),

            // Description
            NlField(
              label: 'Deskripsi Asesmen ${_isIndonesian ? '[Bahasa Indonesia]' : '[English]'}',
              placeholder: _isIndonesian
                  ? 'Ringkasan singkat tujuan dan materi asesmen ini...'
                  : 'Brief summary of the assessment topics...',
              controller: _isIndonesian ? _descriptionId : _descriptionEn,
              keyboardType: TextInputType.multiline,
              maxLines: 3,
            ),

            const SizedBox(height: NetLearnSpace.s20),

            // Assessment Category Selector
            const Text(
              'Kategori Asesmen',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: NetLearnColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(NetLearnRadius.card),
                border: Border.all(color: context.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioListTile<bool>(
                    title: const Text(
                      'Asesmen Kustom Bebas (LMS)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    subtitle: Text(
                      'Dapat dikerjakan mahasiswa kapan saja atau sesuai batas waktu yang ditentukan.',
                      style: TextStyle(color: context.mutedText, fontSize: 12),
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
                  Divider(height: 1, color: context.border),
                  RadioListTile<bool>(
                    title: const Text(
                      'Kuis Terikat Modul (Checkpoint)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    subtitle: Text(
                      'Diikat ke modul tertentu untuk menguji pemahaman materi perkuliahan.',
                      style: TextStyle(color: context.mutedText, fontSize: 12),
                    ),
                    value: true,
                    groupValue: _isModuleQuiz,
                    onChanged: (val) {
                      setState(() {
                        _isModuleQuiz = val ?? true;
                        _selectedModule ??= 1;
                      });
                    },
                    activeColor: context.accent,
                  ),
                ],
              ),
            ),

            if (_isModuleQuiz) ...[
              const SizedBox(height: NetLearnSpace.s16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(NetLearnRadius.field),
                  border: Border.all(color: context.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedModule ?? 1,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Modul 1: Dasar-Dasar Jaringan Komputer')),
                      DropdownMenuItem(value: 2, child: Text('Modul 2: Perangkat Jaringan Komputer')),
                      DropdownMenuItem(value: 3, child: Text('Modul 3: Topologi Jaringan Komputer')),
                      DropdownMenuItem(value: 4, child: Text('Modul 4: IP Addressing & Subnetting')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedModule = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: NetLearnSpace.s8),
              SwitchListTile(
                value: _isRequiredForModule,
                onChanged: (val) => setState(() => _isRequiredForModule = val),
                title: const Text(
                  'Wajibkan kuis untuk buka modul berikutnya',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                subtitle: Text(
                  'Jika aktif, mahasiswa wajib lulus kuis ini sebelum modul selanjutnya terbuka.',
                  style: TextStyle(color: context.mutedText, fontSize: 12),
                ),
                activeColor: context.accent,
                contentPadding: EdgeInsets.zero,
              ),
            ],

            const SizedBox(height: NetLearnSpace.s16),

            // Instructions
            NlField(
              label: 'Petunjuk Pengerjaan ${_isIndonesian ? '[Bahasa Indonesia]' : '[English]'}',
              placeholder: _isIndonesian
                  ? 'Petunjuk pengerjaan bagi mahasiswa...'
                  : 'Instructions for students...',
              controller: _isIndonesian ? _instructionsId : _instructionsEn,
              keyboardType: TextInputType.multiline,
              maxLines: 3,
            ),

            const SizedBox(height: NetLearnSpace.s24),

            // Section 2: Waktu & Tenggat
            const NlSectionHeading(
              title: 'Waktu & Tenggat',
              leadingIcon: Icons.timer_outlined,
            ),
            const SizedBox(height: NetLearnSpace.s16),

            Row(
              children: [
                Expanded(
                  child: NlField(
                    label: 'Durasi (Menit)',
                    placeholder: '30',
                    controller: _durationMinutes,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: NetLearnSpace.s12),
                Expanded(
                  child: NlField(
                    label: 'Batas Pengerjaan',
                    placeholder: '30',
                    controller: _timeLimit,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Batas waktu pengerjaan sejak mahasiswa menekan tombol mulai.',
              style: TextStyle(color: context.mutedText, fontSize: 11),
            ),

            const SizedBox(height: NetLearnSpace.s16),

            // Deadline Picker
            NlField(
              label: 'Tenggat Waktu Pengumpulan (Deadline)',
              placeholder: 'Pilih tanggal & jam...',
              controller: _deadline,
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today, size: 18),
                onPressed: _pickDeadline,
              ),
            ),

            const SizedBox(height: NetLearnSpace.s24),

            // Section 3: Pengaturan Penilaian & Leaderboard
            const NlSectionHeading(
              title: 'Pengaturan Penilaian & Leaderboard',
              leadingIcon: Icons.emoji_events_outlined,
            ),
            const SizedBox(height: NetLearnSpace.s12),

            Container(
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(NetLearnRadius.card),
                border: Border.all(color: context.border),
              ),
              padding: const EdgeInsets.all(NetLearnSpace.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    value: _isLeaderboardEnabled,
                    onChanged: (val) => setState(() => _isLeaderboardEnabled = val),
                    title: const Text(
                      'Sertakan dalam Leaderboard Kelas',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    subtitle: Text(
                      'Nilai pengerjaan mahasiswa akan diakumulasikan ke total poin peringkat kelas.',
                      style: TextStyle(color: context.mutedText, fontSize: 12),
                    ),
                    activeColor: context.accent,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: NetLearnSpace.s12),
                  DropdownButtonFormField<int>(
                    value: _attemptsAllowed,
                    decoration: InputDecoration(
                      labelText: 'Batas Percobaan Pengerjaan',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(NetLearnRadius.field),
                        borderSide: const BorderSide(color: NetLearnColors.border),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 1,
                        child: Text('1 Kali (Ujian Resmi)'),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text('2 Kali Percobaan'),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text('3 Kali Percobaan'),
                      ),
                      DropdownMenuItem(
                        value: 0,
                        child: Text('Tanpa Batas (Latihan Mandiri)'),
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

            // Section 4: Status Publikasi
            const NlSectionHeading(
              title: 'Status Publikasi',
              leadingIcon: Icons.flag_outlined,
            ),
            const SizedBox(height: NetLearnSpace.s12),

            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Draft', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    value: 'draft',
                    groupValue: _status,
                    onChanged: (value) => setState(() => _status = value!),
                    activeColor: context.accent,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Terbit (Published)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: NlButton(
                    label: 'Batal',
                    variant: NlButtonVariant.outline,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: NetLearnSpace.s12),
                Expanded(
                  child: NlButton(
                    label: widget.isEditing ? 'Simpan Perubahan' : 'Buat Asesmen',
                    variant: NlButtonVariant.primary,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
          Expanded(child: Container(color: const Color(0xFFE53935))),
          Expanded(child: Container(color: Colors.white)),
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

    final bluePaint = Paint()..color = const Color(0xFF012169);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bluePaint);

    final whitePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.22
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(w, h), whitePaint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), whitePaint);

    final redDiagonalPaint = Paint()
      ..color = const Color(0xFFC8102E)
      ..strokeWidth = w * 0.11
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(w, h), redDiagonalPaint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), redDiagonalPaint);

    final whiteCrossPaint = Paint()..color = Colors.white;
    final crossBarW = w * 0.26;
    final crossBarH = h * 0.30;
    canvas.drawRect(Rect.fromLTWH((w - crossBarW) / 2, 0, crossBarW, h), whiteCrossPaint);
    canvas.drawRect(Rect.fromLTWH(0, (h - crossBarH) / 2, w, crossBarH), whiteCrossPaint);

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
  final ValueChanged<bool> onLanguageChanged;

  const _LanguageSwitcherCard({
    required this.isIndonesian,
    required this.hasIdContent,
    required this.hasEnContent,
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
                  'Bahasa Input Konten',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: NetLearnSpace.s4),
          Text(
            'Ganti tab bahasa untuk mengisi judul, deskripsi, dan petunjuk dalam dwibahasa.',
            style: TextStyle(
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
                    tag: 'Utama (Wajib)',
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
                    tag: 'Opsional (Dwibahasa)',
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
    return Material(
      color: isSelected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      elevation: isSelected ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  flag,
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? NetLearnColors.neutral900 : NetLearnColors.neutral700,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: NetLearnColors.forest,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                tag,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? NetLearnColors.primary : NetLearnColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
