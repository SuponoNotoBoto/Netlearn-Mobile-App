import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session/session_reset.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import 'class_action_messages.dart';
import 'class_controller.dart';

enum ClassOnboardingRole {
  student,
  lecturer,
}

typedef CreateClassOnboardingSubmitOverride = Future<({String classId, String code})>
    Function({
  required String name,
  String? description,
  String? semester,
  required bool useTemplate,
  required bool pretestEnabled,
  required bool posttestEnabled,
  required bool leaderboardEnabled,
  String? firstModuleTitle,
});

typedef JoinClassOnboardingSubmitOverride = Future<({String classId, String className})>
    Function(String code);

/// Describes one of the 4 Pretest/Posttest combinations (NETLEARN_PRD.md §3.2).
String describeAssessmentCombination({
  required bool pretestEnabled,
  required bool posttestEnabled,
  required bool isIndonesian,
}) {
  if (pretestEnabled && posttestEnabled) {
    return isIndonesian
        ? 'Pretest → Modul 1..N → Post Test'
        : 'Pretest → Modules 1..N → Post Test';
  }
  if (pretestEnabled && !posttestEnabled) {
    return isIndonesian
        ? 'Pretest → Modul 1..N (Tanpa Post Test)'
        : 'Pretest → Modules 1..N (No Post Test)';
  }
  if (!pretestEnabled && posttestEnabled) {
    return isIndonesian
        ? 'Modul 1..N langsung terbuka → Post Test'
        : 'Modules 1..N unlocked immediately → Post Test';
  }
  return isIndonesian
      ? 'Modul 1..N langsung terbuka (Tanpa Pretest & Post Test)'
      : 'Modules 1..N unlocked immediately (No Pretest & Post Test)';
}

/// Standalone route wrapper for [ClassOnboardingView].
class ClassOnboardingPage extends ConsumerWidget {
  const ClassOnboardingPage({
    super.key,
    required this.role,
    this.hasExistingClass = false,
    this.onCreateOverride,
    this.onJoinOverride,
  });

  final ClassOnboardingRole role;
  final bool hasExistingClass;
  final CreateClassOnboardingSubmitOverride? onCreateOverride;
  final JoinClassOnboardingSubmitOverride? onJoinOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: ClassOnboardingView(
          role: role,
          hasExistingClass: hasExistingClass,
          onCreateOverride: onCreateOverride,
          onJoinOverride: onJoinOverride,
          onBackToDashboard: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(
                role == ClassOnboardingRole.lecturer ? '/lecturer' : '/student',
              );
            }
          },
          onContinueToDashboard: (classId) {
            if (context.canPop()) {
              context.pop(classId);
            } else {
              context.go(
                role == ClassOnboardingRole.lecturer ? '/lecturer' : '/student',
              );
            }
          },
        ),
      ),
    );
  }
}

/// Full-screen Class Gate / Onboarding view matching `ClassOnboarding` in
/// `design_figma/src_figma_new1/ClassSystem.tsx`.
///
/// Used both as an automatic gate inside `StudentDashboardPage` /
/// `LecturerDashboardPage` when the signed-in user has 0 classes, and as a
/// standalone screen when joining another class or creating an additional class.
class ClassOnboardingView extends ConsumerStatefulWidget {
  const ClassOnboardingView({
    super.key,
    required this.role,
    this.hasExistingClass = false,
    this.onBackToDashboard,
    this.onContinueToDashboard,
    this.onCreateOverride,
    this.onJoinOverride,
  });

  final ClassOnboardingRole role;
  final bool hasExistingClass;
  final VoidCallback? onBackToDashboard;
  final ValueChanged<String>? onContinueToDashboard;
  final CreateClassOnboardingSubmitOverride? onCreateOverride;
  final JoinClassOnboardingSubmitOverride? onJoinOverride;

  @override
  ConsumerState<ClassOnboardingView> createState() =>
      _ClassOnboardingViewState();
}

class _ClassOnboardingViewState extends ConsumerState<ClassOnboardingView> {
  // Student join state
  final _codeController = TextEditingController();
  bool _submitting = false;
  String? _errorText;
  ({String classId, String className, String code})? _joinedClass;

  // Lecturer create state
  final _nameController = TextEditingController();
  final _semesterController = TextEditingController(text: 'Ganjil 2026/2027');
  final _descController = TextEditingController();
  final _firstModuleController = TextEditingController();
  bool _useTemplate = true;
  bool _pretestEnabled = true;
  bool _posttestEnabled = true;
  bool _leaderboardEnabled = true;
  bool _codeCopied = false;
  ({
    String classId,
    String className,
    String code,
    bool useTemplate,
    bool pretestEnabled,
    bool posttestEnabled,
  })? _createdClass;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _semesterController.dispose();
    _descController.dispose();
    _firstModuleController.dispose();
    super.dispose();
  }

  void _selectTemplateMode(bool useTemplate) {
    setState(() {
      _useTemplate = useTemplate;
      if (useTemplate) {
        _pretestEnabled = true;
        _posttestEnabled = true;
      } else {
        // NETLEARN_PRD.md §2.2.6: Custom classes default Pretest & Posttest to OFF.
        _pretestEnabled = false;
        _posttestEnabled = false;
      }
    });
  }

  Future<void> _handleStudentJoin() async {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final cleanCode = _codeController.text.trim().toUpperCase();

    if (cleanCode.length < 4) {
      setState(() {
        _errorText = isId
            ? 'Masukkan kode kelas yang valid (minimal 4 karakter).'
            : 'Please enter a valid class code (at least 4 characters).';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      final result = widget.onJoinOverride != null
          ? await widget.onJoinOverride!(cleanCode)
          : await joinClassByCodeAction(ref, cleanCode);

      if (!mounted) return;
      setState(() {
        _joinedClass = (
          classId: result.classId,
          className: result.className.isNotEmpty ? result.className : cleanCode,
          code: cleanCode,
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = classActionErrorMessage(context, error);
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _handleLecturerCreate() async {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final cleanName = _nameController.text.trim();

    if (cleanName.isEmpty) {
      setState(() {
        _errorText = isId
            ? 'Nama kelas wajib diisi sebelum membuat kode kelas.'
            : 'Class name is required before generating a class code.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      final ({String classId, String code}) result;
      if (widget.onCreateOverride != null) {
        result = await widget.onCreateOverride!(
          name: cleanName,
          description: _descController.text.trim(),
          semester: _semesterController.text.trim(),
          useTemplate: _useTemplate,
          pretestEnabled: _pretestEnabled,
          posttestEnabled: _posttestEnabled,
          leaderboardEnabled: _leaderboardEnabled,
          firstModuleTitle: _firstModuleController.text.trim(),
        );
      } else {
        result = await createClassAction(
          ref,
          name: cleanName,
          description: _descController.text.trim(),
          semester: _semesterController.text.trim(),
          useTemplate: _useTemplate,
          pretestEnabled: _pretestEnabled,
          posttestEnabled: _posttestEnabled,
        );

        final firstMod = _firstModuleController.text.trim();
        if (!_useTemplate && result.classId.isNotEmpty && firstMod.isNotEmpty) {
          try {
            await createClassModuleAction(
              ref,
              classId: result.classId,
              titleId: firstMod,
              titleEn: firstMod,
              position: 1,
            );
          } catch (_) {}
        }

        if (!_leaderboardEnabled && result.classId.isNotEmpty) {
          try {
            await updateClassSettingsAction(
              ref,
              classId: result.classId,
              pretestEnabled: _pretestEnabled,
              posttestEnabled: _posttestEnabled,
              leaderboardEnabled: _leaderboardEnabled,
            );
          } catch (_) {}
        }
      }

      if (!mounted) return;
      setState(() {
        _createdClass = (
          classId: result.classId,
          className: cleanName,
          code: result.code.isNotEmpty ? result.code : 'NET2026',
          useTemplate: _useTemplate,
          pretestEnabled: _pretestEnabled,
          posttestEnabled: _posttestEnabled,
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = classActionErrorMessage(context, error);
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await supabase.auth.signOut();
    } catch (_) {
      // Safe in offline tests where Supabase is not initialized.
    }
    resetUserSessionFromWidget(ref);
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLoginHeroBanner(context, isId: isId),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.role == ClassOnboardingRole.student)
                  _buildStudentOnboarding(
                    context,
                    isId: isId,
                    isDark: isDark,
                  )
                else
                  _buildLecturerOnboarding(
                    context,
                    isId: isId,
                    isDark: isDark,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// `.login-hero` — Top purple gradient header matching `ClassSystem.tsx:419-431`.
  Widget _buildLoginHeroBanner(BuildContext context, {required bool isId}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF9863FF),
            Color(0xFF7E3FF2),
            Color(0xFF6C2CE2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x387E3FF2),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.hub_rounded,
                  color: Color(0xFF7E3FF2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'NetLearn',
                style: TextStyle(
                  fontFamily: AppTheme.displayFontFamily,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isId ? 'LMS Jaringan Komputer' : 'Computer Networking LMS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Student Class Onboarding (`ClassSystem.tsx:434-538`).
  Widget _buildStudentOnboarding(
    BuildContext context, {
    required bool isId,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // `.class-gate-hero`
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF1ECFF),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F8C52FF),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.vpn_key_rounded,
                color: Color(0xFF8C52FF),
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1ECFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 14,
                      color: Color(0xFF6C2CE2),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isId
                            ? 'Wajib Sebelum Masuk Dashboard'
                            : 'Join a Class to Start Learning',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6C2CE2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          isId ? 'Masukkan Kode Kelas' : 'Enter Your Class Code',
          style: TextStyle(
            fontFamily: AppTheme.displayFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? NetLearnColors.darkText : const Color(0xFF1D1C21),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isId
              ? 'Anda belum tergabung dalam kelas aktif. Masukkan kode kelas dari dosen untuk mengakses materi, asesmen, dan progres belajar di Dashboard.'
              : 'You have not joined an active class yet. Enter the class code from your lecturer to access materials, assessments, and learning progress on the Dashboard.',
          style: TextStyle(
            fontSize: 13,
            height: 1.55,
            color: isDark ? NetLearnColors.darkMuted : const Color(0xFF7E7B8F),
          ),
        ),
        const SizedBox(height: 18),
        if (_joinedClass == null)
          Container(
            key: const Key('student_no_class_empty_card'),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? NetLearnColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? NetLearnColors.darkLine
                    : const Color(0xFFEDEAF6),
              ),
              boxShadow: isDark
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x0D1D1C21),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isId
                      ? 'Kode Kelas (6–7 Karakter)'
                      : 'Class Code (6–7 Characters)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? NetLearnColors.darkText
                        : const Color(0xFF433E52),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('student_join_code_input'),
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  maxLength: 10,
                  style: TextStyle(
                    fontFamily: AppTheme.displayFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: isDark
                        ? NetLearnColors.darkText
                        : const Color(0xFF1D1C21),
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: isId ? 'Contoh: JARKOM1' : 'e.g. JARKOM1',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                      color: Color(0xFFA7A2B8),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? NetLearnColors.darkApp
                        : const Color(0xFFFAF8FF),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFD9CEFF),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF8C52FF),
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (_) {
                    if (_errorText != null) {
                      setState(() => _errorText = null);
                    }
                  },
                  onSubmitted: (_) => _handleStudentJoin(),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 10),
                  _buildErrorBanner(_errorText!),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    key: const Key('student_empty_join_class_btn'),
                    onPressed: _submitting ? null : _handleStudentJoin,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8C52FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  isId
                                      ? 'Gabung Kelas Sekarang'
                                      : 'Join Class Now',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          )
        else
          _buildStudentJoinedSuccessCard(
            context,
            isId: isId,
            isDark: isDark,
          ),
        const SizedBox(height: 16),
        _buildFooterActions(context, isId: isId),
      ],
    );
  }

  Widget _buildStudentJoinedSuccessCard(
    BuildContext context, {
    required bool isId,
    required bool isDark,
  }) {
    final joined = _joinedClass!;
    return Container(
      key: const Key('student_joined_class_success_card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? NetLearnColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? NetLearnColors.darkLine : const Color(0xFFEDEAF6),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F8F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF35C779),
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isId
                ? 'Berhasil Bergabung ke Kelas!'
                : 'Successfully Joined Class!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.displayFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? NetLearnColors.darkText : const Color(0xFF1D1C21),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isId
                ? 'Anda kini terdaftar di ${joined.className} (${joined.code}).'
                : 'You are now enrolled in ${joined.className} (${joined.code}).',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? NetLearnColors.darkMuted : const Color(0xFF7E7B8F),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const Key('student_continue_to_dashboard_btn'),
              onPressed: () {
                if (widget.onContinueToDashboard != null) {
                  widget.onContinueToDashboard!(joined.classId);
                } else {
                  ref.invalidate(studentClassesProvider);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8C52FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      isId ? 'Masuk ke Dashboard' : 'Continue to Dashboard',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lecturer Class Onboarding (`ClassSystem.tsx:540-746`).
  Widget _buildLecturerOnboarding(
    BuildContext context, {
    required bool isId,
    required bool isDark,
  }) {
    final title = widget.hasExistingClass
        ? (isId ? 'Buat Kelas Baru' : 'Create New Class')
        : (isId ? 'Buat Kelas Pertama Anda' : 'Create Your First Class');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // `.class-gate-hero`
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF1ECFF),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F8C52FF),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Color(0xFF8C52FF),
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1ECFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 14,
                      color: Color(0xFF6C2CE2),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isId
                            ? 'Wajib Sebelum Masuk Dashboard'
                            : 'Create a Class to Start Teaching',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6C2CE2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.displayFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? NetLearnColors.darkText : const Color(0xFF1D1C21),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isId
              ? 'Sebagai dosen, Anda wajib membuat minimal satu kelas dan menghasilkan kode kelas sebelum dapat masuk ke Teaching Workspace di Dashboard.'
              : 'As a lecturer, you must create at least one class and generate a class invite code before entering your Teaching Workspace on the Dashboard.',
          style: TextStyle(
            fontSize: 13,
            height: 1.55,
            color: isDark ? NetLearnColors.darkMuted : const Color(0xFF7E7B8F),
          ),
        ),
        const SizedBox(height: 18),
        if (_createdClass == null)
          Container(
            key: const Key('lecturer_no_class_onboarding_card'),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? NetLearnColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? NetLearnColors.darkLine
                    : const Color(0xFFEDEAF6),
              ),
              boxShadow: isDark
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x0D1D1C21),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFieldLabel(
                  isId ? 'Nama Kelas *' : 'Class Name *',
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('create_class_name_field'),
                  controller: _nameController,
                  decoration: _inputDecoration(
                    hintText: isId
                        ? 'Contoh: Jaringan Komputer - TI 2A'
                        : 'e.g. Computer Networks - CS 2A',
                    isDark: isDark,
                  ),
                  onChanged: (_) {
                    if (_errorText != null) {
                      setState(() => _errorText = null);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel(
                            isId ? 'Semester / Tahun' : 'Semester / Year',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            key: const Key('create_class_semester_field'),
                            controller: _semesterController,
                            decoration: _inputDecoration(
                              hintText: 'Ganjil 2026/2027',
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel(
                            isId ? 'Deskripsi Singkat' : 'Short Description',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            key: const Key('create_class_desc_field'),
                            controller: _descController,
                            decoration: _inputDecoration(
                              hintText: isId ? 'Opsional' : 'Optional',
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildFieldLabel(
                  isId
                      ? 'Sumber Konten Pembelajaran'
                      : 'Learning Content Source',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TemplateChoiceCard(
                        key: const Key('create_class_mode_template'),
                        icon: Icons.auto_awesome_rounded,
                        title: 'Use NetLearn Template',
                        subtitle: isId
                            ? 'Salin 4 Modul, Materi, Video & Pre/Post Test bawaan'
                            : 'Copy the 4 default Modules, Materials, Videos & Pre/Post Test',
                        selected: _useTemplate,
                        onTap: () => _selectTemplateMode(true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TemplateChoiceCard(
                        key: const Key('create_class_mode_custom'),
                        icon: Icons.layers_outlined,
                        title: 'Create Custom Class',
                        subtitle: isId
                            ? 'Susun modul, materi, dan asesmen sendiri dari awal'
                            : 'Build your own modules, materials, and assessments from scratch',
                        selected: !_useTemplate,
                        onTap: () => _selectTemplateMode(false),
                      ),
                    ),
                  ],
                ),
                if (!_useTemplate) ...[
                  const SizedBox(height: 12),
                  _buildFieldLabel(
                    isId
                        ? 'Judul Modul 1 Awal (Opsional)'
                        : 'Initial Module 1 Title (Optional)',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    key: const Key('create_class_first_module_field'),
                    controller: _firstModuleController,
                    decoration: _inputDecoration(
                      hintText: isId
                          ? 'Contoh: Pengenalan Jaringan & OSI Layer'
                          : 'e.g. Network Fundamentals & OSI Layer',
                      isDark: isDark,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                // `.policy-switches-box` wrapped in Material so SwitchListTile has a direct Material ancestor
                Material(
                  color: isDark
                      ? NetLearnColors.darkApp
                      : const Color(0xFFFAF9FD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isDark
                          ? NetLearnColors.darkLine
                          : const Color(0xFFEDEAF6),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          isId
                              ? 'Pengaturan Alur & Evaluasi Kelas'
                              : 'Class Flow & Evaluation Settings',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? NetLearnColors.darkText
                                : const Color(0xFF433E52),
                          ),
                        ),
                        SwitchListTile(
                          key: const Key('create_class_pretest_switch'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          activeThumbColor: const Color(0xFF8C52FF),
                          value: _pretestEnabled,
                          onChanged: (val) =>
                              setState(() => _pretestEnabled = val),
                          title: Text(
                            isId ? 'Aktifkan Pretest' : 'Enable Pretest',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            isId
                                ? 'Syarat wajib membuka Modul 1'
                                : 'Required gate before Module 1',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        SwitchListTile(
                          key: const Key('create_class_posttest_switch'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          activeThumbColor: const Color(0xFF8C52FF),
                          value: _posttestEnabled,
                          onChanged: (val) =>
                              setState(() => _posttestEnabled = val),
                          title: Text(
                            isId ? 'Aktifkan Post Test' : 'Enable Post Test',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            isId
                                ? 'Terbuka setelah seluruh modul selesai'
                                : 'Unlocks after all required modules are completed',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        SwitchListTile(
                          key: const Key('create_class_leaderboard_switch'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          activeThumbColor: const Color(0xFF8C52FF),
                          value: _leaderboardEnabled,
                          onChanged: (val) =>
                              setState(() => _leaderboardEnabled = val),
                          title: Text(
                            isId
                                ? 'Aktifkan Leaderboard Kelas'
                                : 'Enable Class Leaderboard',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            isId
                                ? 'Tampilkan peringkat skor mahasiswa'
                                : 'Display student score rankings',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1ECFF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${isId ? 'Alur Belajar Kelas: ' : 'Class Learning Flow: '}'
                            '${describeAssessmentCombination(pretestEnabled: _pretestEnabled, posttestEnabled: _posttestEnabled, isIndonesian: isId)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6C2CE2),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 10),
                  _buildErrorBanner(_errorText!),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    key: const Key('create_class_submit_button'),
                    onPressed: _submitting ? null : _handleLecturerCreate,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8C52FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  isId
                                      ? 'Buat Kelas & Buat Kode'
                                      : 'Create Class & Generate Code',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          )
        else
          _buildLecturerCreatedSuccessCard(
            context,
            isId: isId,
            isDark: isDark,
          ),
        const SizedBox(height: 16),
        _buildFooterActions(context, isId: isId),
      ],
    );
  }

  Widget _buildLecturerCreatedSuccessCard(
    BuildContext context, {
    required bool isId,
    required bool isDark,
  }) {
    final created = _createdClass!;
    return Container(
      key: const Key('lecturer_created_class_success_card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? NetLearnColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? NetLearnColors.darkLine : const Color(0xFFEDEAF6),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F8F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF35C779),
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isId ? 'Kelas Berhasil Dibuat!' : 'Class Created Successfully!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.displayFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? NetLearnColors.darkText : const Color(0xFF1D1C21),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${created.className} (${created.useTemplate ? 'Template NetLearn' : 'Custom Class'})',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? NetLearnColors.darkMuted : const Color(0xFF7E7B8F),
            ),
          ),
          const SizedBox(height: 14),
          // `.created-code-banner`
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F1FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF8C52FF),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  isId ? 'KODE KELAS MAHASISWA' : 'STUDENT CLASS CODE',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Color(0xFF7E7B8F),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  created.code,
                  key: const Key('created_class_code_text'),
                  style: const TextStyle(
                    fontFamily: AppTheme.displayFontFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3.0,
                    color: Color(0xFF6C2CE2),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('copy_created_class_code_btn'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: created.code));
                    setState(() => _codeCopied = true);
                  },
                  icon: Icon(
                    _codeCopied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 15,
                  ),
                  label: Text(
                    _codeCopied
                        ? (isId ? 'Kode Tersalin!' : 'Code Copied!')
                        : (isId ? 'Salin Kode Kelas' : 'Copy Class Code'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6C2CE2),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFD9CEFF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const Key('lecturer_continue_to_dashboard_btn'),
              onPressed: () {
                if (!created.useTemplate &&
                    created.classId.isNotEmpty &&
                    widget.onCreateOverride == null) {
                  ref.invalidate(lecturerClassesProvider);
                  context.go(
                    '/lecturer/classes/${created.classId}?walkthrough=1',
                  );
                } else if (widget.onContinueToDashboard != null) {
                  widget.onContinueToDashboard!(created.classId);
                } else {
                  ref.invalidate(lecturerClassesProvider);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8C52FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      !created.useTemplate
                          ? (isId
                              ? 'Kelola Kelas & Mulai Panduan'
                              : 'Manage Class & Start Guide')
                          : (isId
                              ? 'Masuk ke Dashboard Dosen'
                              : 'Enter Lecturer Dashboard'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(BuildContext context, {required bool isId}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.hasExistingClass && widget.onBackToDashboard != null) ...[
          OutlinedButton(
            key: const Key('class_onboarding_back_btn'),
            onPressed: widget.onBackToDashboard,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6C2CE2),
              side: const BorderSide(color: Color(0xFFD9CEFF)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              isId ? 'Kembali ke Dashboard' : 'Back to Dashboard',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Center(
          child: TextButton.icon(
            key: const Key('class_onboarding_logout_btn'),
            onPressed: _handleLogout,
            icon: const Icon(
              Icons.logout_rounded,
              size: 15,
              color: Color(0xFF7E7B8F),
            ),
            label: Text(
              isId ? 'Ganti Akun / Keluar' : 'Switch Account / Logout',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7E7B8F),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text, {required bool isDark}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isDark ? NetLearnColors.darkText : const Color(0xFF433E52),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 12,
        color: Color(0xFFA7A2B8),
      ),
      filled: true,
      fillColor: isDark ? NetLearnColors.darkApp : const Color(0xFFFAF9FD),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? NetLearnColors.darkLine : const Color(0xFFE7E2F3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF8C52FF),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFF4D4D),
        ),
      ),
    );
  }
}

class _TemplateChoiceCard extends StatelessWidget {
  const _TemplateChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFF5F1FF)
              : (isDark ? NetLearnColors.darkApp : const Color(0xFFFAF9FD)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF8C52FF)
                : (isDark ? NetLearnColors.darkLine : const Color(0xFFE6E1F4)),
            width: 1.5,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x1F8C52FF),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: const Color(0xFF8C52FF),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected
                    ? const Color(0xFF1D1C21)
                    : (isDark
                        ? NetLearnColors.darkText
                        : const Color(0xFF1D1C21)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                height: 1.4,
                color: Color(0xFF7E7B8F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
