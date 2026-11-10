import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/material_model.dart';
import '../../shared/widgets/nl_field.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../classes/class_controller.dart';
import '../materials/material_lab_binding.dart';
import '../virtual_lab/virtual_lab_saved_topology.dart';
import '../virtual_lab/virtual_lab_storage_service.dart';
import 'lecturer_ai_service.dart';
import 'lecturer_materials_controller.dart';

/// Create or edit a material.
///
/// Pass [materialId] to edit; omit it to create. Create and edit share one form
/// because the fields and the constraints are identical, and the only
/// behavioural difference -- which columns may be written -- is decided from
/// `isCore` when the save runs.
class LecturerMaterialFormPage extends ConsumerStatefulWidget {
  final String? materialId;
  final String? classId;
  final String? moduleId;
  final int? initialModuleNumber;

  const LecturerMaterialFormPage({
    super.key,
    this.materialId,
    this.classId,
    this.moduleId,
    this.initialModuleNumber,
  });

  @override
  ConsumerState<LecturerMaterialFormPage> createState() =>
      _LecturerMaterialFormPageState();
}

class _LecturerMaterialFormPageState
    extends ConsumerState<LecturerMaterialFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleEn = TextEditingController();
  final _titleId = TextEditingController();

  final _descriptionEn = TextEditingController();
  final _descriptionId = TextEditingController();

  final _summaryEn = TextEditingController();
  final _summaryId = TextEditingController();

  final _contentEn = TextEditingController();
  final _contentId = TextEditingController();

  final _videoUrl = TextEditingController();
  final _duration = TextEditingController();

  /// Held in a controller rather than only in `_orderIndex` so the field shows
  /// what is actually stored. Building a controller inline to seed the text
  /// would recreate it on every rebuild and throw away whatever was typed.
  final _orderIndex = TextEditingController(text: '1');

  // Konfigurasi Praktikum Virtual Lab
  bool _labEnabled = false;
  String _labPreset = 'star';
  final _labTitle = TextEditingController();
  final _labInstructions = TextEditingController();
  List<VirtualLabSavedTopology> _lecturerSavedTopologies = [];
  String? _selectedSavedTopologyId;

  /// The row being edited. Null in create mode, and stays null until the list
  /// has loaded in edit mode.
  MaterialModel? _editing;

  /// Object path of the PDF currently associated with this material, inside the
  /// `material-files` bucket. Null means no PDF. Uploaded immediately on pick,
  /// so a value here is a real object (or an orphan if the form is abandoned).
  String? _pdfPath;

  /// Display name of the chosen file, kept only for the UI.
  String? _pdfName;

  bool _uploadingPdf = false;

  /// Hanya di mode tambah: urutan awal dihitung sekali dari data yang
  /// dimuat. Tanpa flag ini, penyegaran provider setelah simpan menjalankan
  /// penugasan lagi dan menimpa isian yang baru saja disimpan.
  bool _orderIndexSeeded = false;

  int? _moduleNumber = 1;
  bool _published = false;
  bool _saving = false;
  bool _translatingAi = false;
  bool _hydrated = false;

  /// Akses materi yang dipilih dosen: `default` (ikut progres mahasiswa),
  /// `unlocked` (selalu terbuka) atau `locked` (selalu terkunci). Nilai ini
  /// disimpan apa adanya ke `materials.lock_status` — kolom enum yang sudah
  /// ada — dan dibaca server untuk gerbang baca (`is_material_unlocked`),
  /// syarat modul (`get_learning_flow_status`) dan posttest
  /// (`has_completed_all_modules`), jadi di sisi client cukup dikirim.
  String _lockStatus = 'default';

  /// Whether this is the edit form.
  ///
  /// Driven by the route argument, NOT by `_editing != null`. `_editing` is only
  /// filled in by `_hydrate`, and `_hydrate` only runs inside the branch that is
  /// itself gated on this getter, so reading `_editing` here makes the condition
  /// permanently false: the edit route rendered a blank "Add Material" form and
  /// `_save` then ran `createMaterial`, which is both the wrong screen and the
  /// wrong write (an INSERT of a duplicate row instead of an UPDATE).
  bool get _isEditing => widget.materialId != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialModuleNumber != null) {
      _moduleNumber = widget.initialModuleNumber;
    }
    if (!_isEditing && widget.classId != null) {
      _published = true;
    }
    _loadLecturerSavedTopologies();
  }

  Future<void> _loadLecturerSavedTopologies() async {
    try {
      final storage = ref.read(virtualLabStorageServiceProvider);
      final list = await storage.getSavedTopologies();
      if (mounted) {
        setState(() {
          _lecturerSavedTopologies = list;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleEn.dispose();
    _titleId.dispose();
    _descriptionEn.dispose();
    _descriptionId.dispose();
    _summaryEn.dispose();
    _summaryId.dispose();
    _contentEn.dispose();
    _contentId.dispose();
    _videoUrl.dispose();
    _duration.dispose();
    _orderIndex.dispose();
    _labTitle.dispose();
    _labInstructions.dispose();
    super.dispose();
  }

  /// Copies the loaded row into the fields, once.
  ///
  /// Guarded by [_hydrated] because the provider is auto-disposed and refetches
  /// after every write: without the flag, saving the form would overwrite
  /// whatever the lecturer had typed with the row that was just written.
  void _hydrate(MaterialModel material) {
    if (_hydrated) {
      return;
    }

    _editing = material;
    _hydrated = true;

    _titleEn.text = material.titleEn ?? '';
    _titleId.text = material.titleId ?? material.title;

    _descriptionEn.text = material.descriptionEn ?? '';
    _descriptionId.text = material.descriptionId ?? '';

    _summaryEn.text = material.summaryEn ?? '';
    _summaryId.text = material.summaryId ?? '';

    _contentEn.text = MaterialLabBinding.stripLabTag(material.contentEn ?? '');
    _contentId.text = MaterialLabBinding.stripLabTag(material.contentId ?? '');

    final labBinding = MaterialLabBinding.fromMaterial(material);
    if (labBinding != null) {
      _labEnabled = true;
      _labPreset = labBinding.preset;
      _labTitle.text = labBinding.title;
      _labInstructions.text = labBinding.instructions.join('\n');
    }

    _videoUrl.text = material.videoUrl ?? '';
    _duration.text = material.durationMinutes?.toString() ?? '';

    _moduleNumber = material.moduleNumber ?? 1;
    _orderIndex.text = material.orderIndex.toString();
    _published = material.published;
    _lockStatus = material.lockStatus;

    _pdfPath = material.pdfUrl;
    _pdfName = material.pdfUrl?.split('/').last;
  }

  Future<void> _translateMaterialWithAi(String targetLangCode) async {
    final isTargetEn = targetLangCode == 'en';
    final srcTitle = isTargetEn ? _titleId.text.trim() : _titleEn.text.trim();
    final srcSummary =
        isTargetEn ? _summaryId.text.trim() : _summaryEn.text.trim();
    final srcDesc =
        isTargetEn ? _descriptionId.text.trim() : _descriptionEn.text.trim();

    final isIdUi = Localizations.localeOf(context).languageCode == 'id';

    if (srcTitle.isEmpty && srcSummary.isEmpty && srcDesc.isEmpty) {
      NlSnackBar.show(
        context,
        isIdUi
            ? 'Isi terlebih dahulu judul atau ringkasan sumber sebelum menerjemahkan.'
            : 'Please fill in the source title or summary before translating.',
        tone: NlSnackTone.warning,
      );
      return;
    }

    setState(() => _translatingAi = true);

    try {
      final result = await LecturerAiService.translateMaterial(
        title: srcTitle,
        summary: srcSummary,
        description: srcDesc,
        targetLanguageCode: targetLangCode,
      );

      if (!mounted) return;
      setState(() {
        if (isTargetEn) {
          if (result.title.isNotEmpty) _titleEn.text = result.title;
          if (result.summary.isNotEmpty) _summaryEn.text = result.summary;
          if (result.description.isNotEmpty) {
            _descriptionEn.text = result.description;
          }
        } else {
          if (result.title.isNotEmpty) _titleId.text = result.title;
          if (result.summary.isNotEmpty) _summaryId.text = result.summary;
          if (result.description.isNotEmpty) {
            _descriptionId.text = result.description;
          }
        }
        _translatingAi = false;
      });

      NlSnackBar.show(
        context,
        isIdUi
            ? 'Berhasil diterjemahkan otomatis oleh ${result.providerName} ✨'
            : 'Successfully translated by ${result.providerName} ✨',
        tone: NlSnackTone.success,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _translatingAi = false);
      NlSnackBar.show(
        context,
        isIdUi
            ? 'Gagal menerjemahkan materi dengan AI. Silakan coba lagi.'
            : 'Failed to translate material with AI. Please try again.',
        tone: NlSnackTone.error,
      );
    }
  }

  String? _writeFailureMessage(Object error) {
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

  /// Builds the row to write.
  ///
  /// The base `title` column is NOT NULL and holds the Indonesian copy, so it is
  /// filled from `title_id` and only falls back to `title_en`. Every reader uses
  /// the base column as its fallback in both languages
  /// (`MaterialModel.localizedTitle`), so leaving it empty is what makes a
  /// material render with a blank title once the other language is selected.
  MaterialModel _buildDraft() {
    final titleId = _titleId.text.trim();
    final titleEn = _titleEn.text.trim();

    String? emptyToNull(String value) {
      final trimmed = value.trim();

      return trimmed.isEmpty ? null : trimmed;
    }

    final existing = _editing;

    var contentId = _contentId.text.trim();
    var contentEn = _contentEn.text.trim();

    if (_labEnabled) {
      final instructions = _labInstructions.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      Map<String, dynamic>? customTopologyJson;
      if (_labPreset == 'custom' && _selectedSavedTopologyId != null) {
        final found = _lecturerSavedTopologies
            .where((t) => t.id == _selectedSavedTopologyId)
            .firstOrNull;
        if (found != null) {
          customTopologyJson = found.sessionData;
        }
      }

      final binding = MaterialLabBinding(
        enabled: true,
        preset: _labPreset,
        title: _labTitle.text.trim().isNotEmpty
            ? _labTitle.text.trim()
            : 'Praktikum Virtual Lab',
        instructions: instructions,
        customTopology: customTopologyJson,
      );

      contentId = MaterialLabBinding.embedLabTag(contentId, binding);
      if (contentEn.isNotEmpty) {
        contentEn = MaterialLabBinding.embedLabTag(contentEn, binding);
      }
    } else if (_isEditing) {
      contentId = MaterialLabBinding.stripLabTag(contentId);
      if (contentEn.isNotEmpty) {
        contentEn = MaterialLabBinding.stripLabTag(contentEn);
      }
    }

    return MaterialModel(
      id: existing?.id ?? '',
      isCore: existing?.isCore ?? false,
      orderIndex: int.tryParse(_orderIndex.text.trim()) ?? 1,
      moduleNumber: _moduleNumber,

      title: titleId.isNotEmpty ? titleId : titleEn,

      description: emptyToNull(
            titleId.isEmpty ? _descriptionEn.text : _descriptionId.text,
          ),
      content: emptyToNull(
            titleId.isEmpty ? contentEn : contentId,
          ),
      summary: emptyToNull(
            titleId.isEmpty ? _summaryEn.text : _summaryId.text,
          ),

      titleEn: emptyToNull(titleEn),
      titleId: emptyToNull(titleId),

      descriptionEn: emptyToNull(_descriptionEn.text),
      descriptionId: emptyToNull(_descriptionId.text),

      contentEn: emptyToNull(contentEn),
      contentId: emptyToNull(contentId),

      summaryEn: emptyToNull(_summaryEn.text),
      summaryId: emptyToNull(_summaryId.text),

      videoUrl: emptyToNull(_videoUrl.text),
      durationMinutes: int.tryParse(_duration.text.trim()),

      published: _published,

      // Kini disimpan, bukan sekadar dibawa-bawa: dosen memilihnya di bagian
      // "Akses materi" form ini dan server menegakkannya.
      lockStatus: _lockStatus,
      pdfUrl: _pdfPath,
      createdBy: existing?.createdBy,
      createdAt: existing?.createdAt,
      updatedAt: existing?.updatedAt,
    );
  }

  /// Picks a PDF, validates it, and uploads it to Storage immediately.
  ///
  /// Uploading on pick means the row only ever stores a path that points at an
  /// object that already exists; if the user abandons the form the object is
  /// left behind, which is the accepted trade-off for not blocking the save on
  /// a second network round-trip.
  Future<void> _pickPdf() async {
    final l10n = AppLocalizations.of(context)!;

    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );

    if (file == null) {
      return;
    }

    final name = file.name;

    if (!name.toLowerCase().endsWith('.pdf')) {
      if (!mounted) return;

      NlSnackBar.show(
        context,
        l10n.pdfInvalidType,
        tone: NlSnackTone.error,
      );
      return;
    }

    final length = await file.length();

    if (length != null && length > materialPdfMaxBytes) {
      if (!mounted) return;

      NlSnackBar.show(
        context,
        l10n.pdfTooLarge,
        tone: NlSnackTone.error,
      );
      return;
    }

    final Uint8List bytes;

    try {
      bytes = await file.readAsBytes();
    } catch (error) {
      if (mounted) {
        NlSnackBar.show(
          context,
          l10n.pdfUploadFailed,
          tone: NlSnackTone.error,
        );
      }
      return;
    }

    final previousPath = _pdfPath;

    setState(() => _uploadingPdf = true);

    try {
      final path = await uploadMaterialPdf(
        ref,
        bytes: bytes,
        fileName: name,
      );

      if (!mounted) return;

      setState(() {
        _pdfPath = path;
        _pdfName = name;
      });

      // The old object is only removed once the new one is safely stored, so a
      // failed upload never destroys the PDF the material still points at.
      if (previousPath != null && previousPath != path) {
        await deleteMaterialPdf(ref, previousPath);
      }

      if (!mounted) return;

      NlSnackBar.show(
        context,
        l10n.pdfUploaded,
        tone: NlSnackTone.success,
      );
    } catch (error) {
      if (!mounted) return;

      NlSnackBar.show(
        context,
        _writeFailureMessage(error) ?? l10n.pdfUploadFailed,
        tone: NlSnackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingPdf = false);
      }
    }
  }

  Future<void> _viewPdf() async {
    final path = _pdfPath;

    if (path == null) return;

    final l10n = AppLocalizations.of(context)!;

    try {
      final url = await signedMaterialPdfUrl(ref, path);
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        NlSnackBar.show(
          context,
          l10n.openPdfFailed,
          tone: NlSnackTone.error,
        );
      }
    } catch (error) {
      if (mounted) {
        NlSnackBar.show(
          context,
          l10n.openPdfFailed,
          tone: NlSnackTone.error,
        );
      }
    }
  }

  Future<void> _removePdf() async {
    final path = _pdfPath;

    if (path == null) return;

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _pdfPath = null;
      _pdfName = null;
    });

    await deleteMaterialPdf(ref, path);

    if (!mounted) return;

    NlSnackBar.show(
      context,
      l10n.pdfRemoved,
      tone: NlSnackTone.success,
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _saving = true;
    });

    try {
      final draft = _buildDraft();

      if (_isEditing) {
        await updateMaterial(ref, draft);
        ref.invalidate(classModulesProvider);
        ref.invalidate(classModuleMaterialsProvider);
      } else {
        if (widget.classId != null && widget.moduleId != null) {
          await createClassMaterialAction(
            ref,
            classId: widget.classId!,
            moduleId: widget.moduleId!,
            modulePosition: draft.moduleNumber ?? widget.initialModuleNumber ?? 1,
            draft: draft,
          );
        } else {
          await createMaterial(ref, draft);
        }
      }

      if (!mounted) {
        return;
      }

      NlSnackBar.show(
        context,
        _isEditing ? l10n.materialUpdated : l10n.materialCreated,
        tone: NlSnackTone.success,
      );

      context.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      NlSnackBar.show(
        context,
        _writeFailureMessage(error) ??
            AppLocalizations.of(context)!.materialSaveFailed,
        tone: NlSnackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final materialsAsync = ref.watch(lecturerMaterialsProvider);

    return Scaffold(
      backgroundColor: context.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFECEEF2),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditing ? l10n.editMaterial : l10n.addMaterial,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
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
                const Icon(Icons.error_outline, size: 46),
                const SizedBox(height: NetLearnSpace.s12),
                Text(
                  l10n.failedToLoad,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        data: (materials) {
          if (_isEditing) {
            final found = materials
                .where((m) => m.id == widget.materialId)
                .toList();

            if (found.isEmpty) {
              return Center(
                child: Padding(
                  padding:
                      const EdgeInsets.all(NetLearnSpace.s24),
                  child: Text(
                    l10n.materialNotFound,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            _hydrate(found.first);
          }

          // Mode tambah: urutan awal = max(order_index) + 1 dari materi yang
          // sudah ada. Urutan menentukan materi pertama modul, dan materi
          // pertamalah yang memberi judul serta deskripsi kartu modul di
          // sisi mahasiswa (`studentModulesProvider`), jadi materi baru tidak
          // boleh seri dengan baris inti (order_index 1..4): `order by
          // order_index` tanpa tie-break bisa memindahkan judul modul ke
          // materi baru. Dosen tetap boleh menimpanya.
          else if (!_orderIndexSeeded) {
            _orderIndexSeeded = true;

            var maxOrder = 0;
            for (final material in materials) {
              if (material.orderIndex > maxOrder) {
                maxOrder = material.orderIndex;
              }
            }

            _orderIndex.text = '${maxOrder + 1}';
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                NetLearnSpace.s20,
                NetLearnSpace.s16,
                NetLearnSpace.s20,
                NetLearnSpace.s32,
              ),
              children: [
                // Module dropdown
                _FormLabel(text: l10n.module),
                const SizedBox(height: 7),
                DropdownButtonFormField<int>(
                  initialValue: _moduleNumber,
                  isExpanded: true,
                  decoration: InputDecoration(
                    helperText: (_editing?.isCore ?? false)
                        ? l10n.coreModuleLocked
                        : null,
                  ),
                  items: [
                    if (_moduleNumber != null &&
                        (_moduleNumber! < 1 || _moduleNumber! > 4))
                      DropdownMenuItem(
                        value: _moduleNumber,
                        child: Text(
                          '${l10n.module} $_moduleNumber',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    for (var module = 1; module <= 4; module++)
                      DropdownMenuItem(
                        value: module,
                        child: Text(
                          '${l10n.module} $module: ${_moduleName(module)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (_editing?.isCore ?? false)
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _moduleNumber = value);
                        },
                ),

                const SizedBox(height: NetLearnSpace.s17),

                // AI Bilingual Translator Banner
                _buildAiTranslateBar(context),

                const SizedBox(height: NetLearnSpace.s17),

                // Title (Indonesian)
                _FormLabel(text: l10n.titleIndonesian),
                const SizedBox(height: 7),
                NlField(
                  label: '',
                  placeholder: l10n.titleIndonesianHint,
                  controller: _titleId,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return l10n.requiredField;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: NetLearnSpace.s17),

                // Title (English)
                _FormLabel(text: l10n.titleEnglish),
                const SizedBox(height: 7),
                NlField(
                  label: '',
                  placeholder: l10n.titleEnglishHint,
                  controller: _titleEn,
                ),

                const SizedBox(height: NetLearnSpace.s17),

                // Summary (Indonesian)
                _FormLabel(text: '${l10n.summary} (ID)'),
                const SizedBox(height: 7),
                NlField(
                  label: '',
                  placeholder: l10n.summaryHint,
                  controller: _summaryId,
                ),

                const SizedBox(height: NetLearnSpace.s17),

                // Summary (English)
                _FormLabel(text: '${l10n.summary} (EN)'),
                const SizedBox(height: 7),
                NlField(
                  label: '',
                  placeholder: l10n.summaryHint,
                  controller: _summaryEn,
                ),

                const SizedBox(height: NetLearnSpace.s17),

                // Description / Content (ID)
                _FormLabel(text: '${l10n.description} (ID)'),
                const SizedBox(height: 7),
                NlField(
                  label: '',
                  placeholder: l10n.descriptionHint,
                  controller: _descriptionId,
                  maxLines: 6,
                ),

                const SizedBox(height: NetLearnSpace.s17),

                // Description / Content (EN)
                _FormLabel(text: '${l10n.description} (EN)'),
                const SizedBox(height: 7),
                NlField(
                  label: '',
                  placeholder: l10n.descriptionHint,
                  controller: _descriptionEn,
                  maxLines: 6,
                ),

                const SizedBox(height: NetLearnSpace.s17),

                // Upload Material PDF
                _PdfUploadCard(
                  fileName: _pdfName,
                  hasPdf: _pdfPath != null,
                  uploading: _uploadingPdf,
                  onPick: _uploadingPdf ? null : _pickPdf,
                  onView: _pdfPath == null ? null : _viewPdf,
                  onRemove: _pdfPath == null ? null : _removePdf,
                ),

                const SizedBox(height: NetLearnSpace.s17),

                // URL Video YouTube
                _FormLabel(text: l10n.videoUrl),
                const SizedBox(height: 7),
                NlField(
                  label: '',
                  placeholder: 'https://youtube.com/watch?v=...',
                  controller: _videoUrl,
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null;
                    final uri = Uri.tryParse(text);
                    if (uri == null ||
                        !uri.hasScheme ||
                        !uri.host.contains('youtu')) {
                      return l10n.invalidVideoUrlError;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: NetLearnSpace.s17),

                // Duration + Order side by side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FormLabel(text: l10n.studyTimeLabel),
                          const SizedBox(height: 7),
                          NlField(
                            label: '',
                            placeholder: '15',
                            controller: _duration,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final text = (value ?? '').trim();
                              if (text.isEmpty) return null;
                              final parsed = int.tryParse(text);
                              if (parsed == null || parsed < 1) {
                                return l10n.durationInvalid;
                              }
                              return null;
                            },
                          ),
                          // Bukan durasi video YouTube — tanpa hint ini
                          // dosen mengisinya dengan panjang video karena
                          // label lamanya "Durasi (menit)".
                          const SizedBox(height: 6),
                          Text(
                            l10n.studyTimeHint,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: context.mutedText),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FormLabel(text: l10n.orderIndex),
                          const SizedBox(height: 7),
                          NlField(
                            label: '',
                            placeholder: '1',
                            controller: _orderIndex,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final parsed =
                                  int.tryParse((value ?? '').trim());
                              if (parsed == null || parsed < 1) {
                                return l10n.orderIndexInvalid;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: NetLearnSpace.s17),

                // Publish material checkbox
                Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: _published,
                        onChanged: _saving
                            ? null
                            : (value) {
                                setState(() => _published = value ?? false);
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.publish,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: NetLearnSpace.s17),

                // Akses materi: 3 pilihan per materi. `default` ikut progres
                // mahasiswa; `unlocked`/`locked` mengabaikannya sama sekali.
                // Penegakan ada di server (migrasi
                // 20261101130000_material_lock_status_override.sql), jadi
                // kontrol ini hanya memilih nilai `lock_status`.
                _FormLabel(text: l10n.materialAccessLabel),
                const SizedBox(height: 7),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'default',
                      label: Text(l10n.materialAccessOptionProgress),
                    ),
                    ButtonSegment(
                      value: 'unlocked',
                      label: Text(l10n.materialAccessOptionOpen),
                    ),
                    ButtonSegment(
                      value: 'locked',
                      label: Text(l10n.materialAccessOptionLocked),
                    ),
                  ],
                  selected: {_lockStatus},
                  onSelectionChanged: _saving
                      ? null
                      : (selection) {
                          setState(() => _lockStatus = selection.first);
                        },
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.materialAccessHelp,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.mutedText,
                      ),
                ),

                const SizedBox(height: NetLearnSpace.s17),

                _buildLabConfigSection(context),

                const SizedBox(height: NetLearnSpace.s17),

                _SaveButton(
                  label: l10n.save,
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _moduleName(int module) {
    switch (module) {
      case 1:
        return 'Computer Networking Fundamentals';
      case 2:
        return 'Network Devices';
      case 3:
        return 'Network Topologies';
      case 4:
        return 'IP Address';
      default:
        return '';
    }
  }

  Widget _buildAiTranslateBar(BuildContext context) {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.accentTint.withAlpha(110),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.accent.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.translate_rounded, size: 18, color: context.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isId
                      ? 'Asisten AI Penerjemah Materi Otomatis ✨'
                      : 'AI Bilingual Material Translator ✨',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.onSurface,
                  ),
                ),
              ),
              if (_translatingAi)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isId
                ? 'Cukup ketik materi dalam 1 bahasa, lalu klik tombol di bawah untuk mengisi bahasa lainnya secara instan.'
                : 'Write your material in one language, then tap below to auto-fill the other language instantly.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.mutedText,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _translatingAi || _saving
                      ? null
                      : () => _translateMaterialWithAi('en'),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                  label: const Text(
                    'ID → English',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _translatingAi || _saving
                      ? null
                      : () => _translateMaterialWithAi('id'),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                  label: const Text(
                    'English → ID',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabConfigSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(NetLearnSpace.s16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(
          color: _labEnabled
              ? context.accent.withAlpha(isDark ? 90 : 60)
              : context.border,
          width: _labEnabled ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science_rounded,
                color: _labEnabled ? context.accent : context.mutedText,
                size: 20,
              ),
              const SizedBox(width: NetLearnSpace.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Praktikum Virtual Lab (Opsional)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Sertakan simulasi jaringan interaktif untuk materi ini',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.mutedText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _labEnabled,
                activeThumbColor: context.accent,
                onChanged: _saving
                    ? null
                    : (val) {
                        setState(() {
                          _labEnabled = val;
                          if (val && _labTitle.text.isEmpty) {
                            final baseTitle = _titleId.text.isNotEmpty
                                ? _titleId.text
                                : _titleEn.text;
                            _labTitle.text = baseTitle.isNotEmpty
                                ? 'Praktikum $baseTitle'
                                : 'Praktikum Simulasi Jaringan';
                          }
                        });
                      },
              ),
            ],
          ),
          if (_labEnabled) ...[
            const SizedBox(height: NetLearnSpace.s14),
            const Divider(height: 1),
            const SizedBox(height: NetLearnSpace.s14),

            // Pilihan Topologi Skenario Awal
            const _FormLabel(text: 'Topologi Skenario Awal'),
            const SizedBox(height: 7),
            DropdownButtonFormField<String>(
              initialValue: _labPreset,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: NetLearnSpace.s12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: context.border),
                ),
                filled: true,
                fillColor: context.raisedSurface,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'star',
                  child: Text('Topologi Star (1 Switch + 3 PC LAN)'),
                ),
                DropdownMenuItem(
                  value: 'dual_subnet',
                  child: Text('Dual-Subnet Routing (Router L3 + 2 Switch)'),
                ),
                DropdownMenuItem(
                  value: 'p2p',
                  child: Text('Peer-to-Peer (2 PC Terhubung Langsung)'),
                ),
                DropdownMenuItem(
                  value: 'dhcp_server',
                  child: Text('Client-Server LAN (DHCP & Web HTTP)'),
                ),
                DropdownMenuItem(
                  value: 'blank',
                  child: Text('Kanvas Kosong (Mulai dari Nol)'),
                ),
                DropdownMenuItem(
                  value: 'custom',
                  child: Text('Topologi Tersimpan Dosen (Cloud)...'),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (val) {
                      if (val != null) {
                        setState(() => _labPreset = val);
                      }
                    },
            ),

            if (_labPreset == 'custom') ...[
              const SizedBox(height: 10),
              const _FormLabel(text: 'Pilih Topologi Tersimpan Milik Anda'),
              const SizedBox(height: 7),
              if (_lecturerSavedTopologies.isEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.raisedSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Belum ada topologi tersimpan di akun Anda. Silakan simpan topologi di Virtual Lab terlebih dahulu.',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedSavedTopologyId ??
                      (_lecturerSavedTopologies.isNotEmpty
                          ? _lecturerSavedTopologies.first.id
                          : null),
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: NetLearnSpace.s12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: context.raisedSurface,
                  ),
                  items: _lecturerSavedTopologies.map((t) {
                    return DropdownMenuItem(
                      value: t.id,
                      child: Text(
                        '${t.name} (${t.deviceCount} perangkat)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedSavedTopologyId = val);
                  },
                ),
            ],

            const SizedBox(height: 12),
            const _FormLabel(text: 'Judul Praktikum'),
            const SizedBox(height: 7),
            TextFormField(
              controller: _labTitle,
              decoration: InputDecoration(
                hintText: 'Misal: Praktikum Subnetting & Routing Statis',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: context.raisedSurface,
              ),
            ),

            const SizedBox(height: 12),
            const _FormLabel(text: 'Panduan / Instruksi Tugas (1 baris per langkah)'),
            const SizedBox(height: 7),
            TextFormField(
              controller: _labInstructions,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '1. Hubungkan PC ke Switch\n2. Atur IP address\n3. Lakukan ping dan periksa status',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: context.raisedSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Label field form — 11px SemiBold #1a1d26 sesuai Figma.
class _FormLabel extends StatelessWidget {
  final String text;

  const _FormLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'DMSans',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1D26),
      ),
    );
  }
}

/// Card upload PDF dengan border, label di dalam, sesuai Figma 47:1478.
class _PdfUploadCard extends StatelessWidget {
  final String? fileName;
  final bool hasPdf;
  final bool uploading;
  final VoidCallback? onPick;
  final VoidCallback? onView;
  final VoidCallback? onRemove;

  const _PdfUploadCard({
    required this.fileName,
    required this.hasPdf,
    required this.uploading,
    required this.onPick,
    required this.onView,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FormLabel(text: l10n.uploadPdf),
          const SizedBox(height: 7),
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE3E4EC)),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Text(
              hasPdf ? (fileName ?? l10n.viewPdf) : l10n.uploadPdf,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: hasPdf ? null : context.mutedText,
              ),
            ),
          ),
          const SizedBox(height: 17),
          Text(
            l10n.pdfUploadHint,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 9,
              color: const Color(0xFF6C727F),
            ),
          ),
          const SizedBox(height: 12),
          // Use a Column of full-width buttons instead of Wrap.
          // Wrap cannot size itself in a Column with crossAxisAlignment.start,
          // causing the buttons to overflow horizontally.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: onPick,
                icon: Icon(
                  hasPdf ? Icons.swap_horiz_rounded : Icons.upload_file_rounded,
                  size: 18,
                ),
                label: Text(
                  uploading
                      ? l10n.pdfUploading
                      : (hasPdf ? l10n.replacePdf : l10n.uploadPdf),
                ),
              ),
              if (hasPdf) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: Text(l10n.viewPdf),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(l10n.removePdf),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NetLearnColors.danger,
                    side: BorderSide(color: NetLearnColors.danger),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// PDF picker/preview row: shows the chosen file and the upload/view/remove
/// actions. Kept local to the form because it is the only screen that manages a
/// material's PDF.
// ignore: unused_element
class _PdfField extends StatelessWidget {
  final String? fileName;
  final bool hasPdf;
  final bool uploading;
  final VoidCallback? onPick;
  final VoidCallback? onView;
  final VoidCallback? onRemove;

  const _PdfField({
    required this.fileName,
    required this.hasPdf,
    required this.uploading,
    required this.onPick,
    required this.onView,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(NetLearnSpace.s16),
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
              Icon(
                Icons.picture_as_pdf_outlined,
                color: hasPdf ? context.accent : context.mutedText,
                size: 22,
              ),
              const SizedBox(width: NetLearnSpace.s12),
              Expanded(
                child: Text(
                  hasPdf ? (fileName ?? l10n.viewPdf) : l10n.noPdf,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: hasPdf ? null : context.mutedText,
                  ),
                ),
              ),
              if (uploading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: NetLearnSpace.s12),
          Wrap(
            spacing: NetLearnSpace.s12,
            runSpacing: NetLearnSpace.s8,
            children: [
              OutlinedButton.icon(
                onPressed: onPick,
                icon: Icon(
                  hasPdf ? Icons.swap_horiz_rounded : Icons.upload_file_rounded,
                  size: 18,
                ),
                label: Text(
                  uploading
                      ? l10n.pdfUploading
                      : (hasPdf ? l10n.replacePdf : l10n.uploadPdf),
                ),
              ),
              if (hasPdf)
                FilledButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: Text(l10n.viewPdf),
                ),
              if (hasPdf)
                OutlinedButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(l10n.removePdf),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NetLearnColors.danger,
                    side: BorderSide(color: NetLearnColors.danger),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF543CD1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        icon: loading
            ? const SizedBox.shrink()
            : const Icon(Icons.check_rounded, size: 17),
        label: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : Text(label),
      ),
    );
  }
}