import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard_lecturer/lecturer_dashboard_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_field.dart';
import '../../shared/widgets/nl_skeleton.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import 'student_profile_controller.dart';

/// Change Password view (Figma `58-953`) yang dipakai dua role.
///
/// Halaman ini pindah dari `lecturer_change_password_page.dart` ketika
/// Security & Password mahasiswa mendapat baris "Change Password"-nya:
/// daripada menyalin seluruh form, satu widget menerima perbedaan antar-role
/// sebagai parameter — sumber profil ([useStudentProfile]), fallback tombol
/// back, dan navbar bawah yang hanya dosen pakai sehingga jadi opsional.
///
/// PERILAKU SIMPAN = placeholder, sama seperti halaman dosen aslinya:
/// validasi form berjalan, tetapi pengerjaannya berhenti di snackbar
/// `passwordChangeNotAvailable` (lihat komentar TODO di bawah). Forgot
/// Password di baris pertama halaman Security & Password adalah jalur
/// pengubahan kata sandi yang benar-benar berfungsi lewat Supabase Auth.
class ChangePasswordPage extends ConsumerStatefulWidget {
  /// `true` — baca identitas dari [studentProfileProvider] (mahasiswa yang
  /// sedang login); `false` — dari [lecturerProfileProvider] seperti dulu.
  final bool useStudentProfile;

  /// Tujuan tombol back ketika stack kosong (deep link / reload web).
  final String backFallback;

  /// Navbar bawah. Halaman dosen aslinya membawa [LecturerBottomNavbar]
  /// (indeks 4); halaman mahasiswa mengikuti sub-page profil lain yang tidak
  /// membawa navbar, jadi parameter ini dibiarkan kosong.
  final Widget? bottomNavbar;

  const ChangePasswordPage({
    super.key,
    required this.useStudentProfile,
    required this.backFallback,
    this.bottomNavbar,
  });

  @override
  ConsumerState<ChangePasswordPage> createState() =>
      _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    // Placeholder: no backend integration yet (behavior carried over from the
    // original lecturer page unchanged). TODO: integrate with Supabase Auth
    // updatePassword — `supabase.auth.updateUser(UserUpdateData(password: ..))`
    // — once a product decision confirms the password-change UX for BOTH roles;
    // wiring one role and not the other is the inconsistency the request
    // explicitly asked us to avoid.
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _saving = false);
      NlSnackBar.show(
        context,
        AppLocalizations.of(context)!.passwordChangeNotAvailable,
        tone: NlSnackTone.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Kedua provider punya bentuk yang sama: FutureProvider.autoDispose yang
    // mengembalikan null ketika tidak ada sesi. Generik[_profileBody] membuat
    // dua tipe nilai (raw map mahasiswa vs objek LecturerProfile) tidak perlu
    // dipaksa satu ke yang lain.
    final Widget profileBody = widget.useStudentProfile
        ? _profileBody<Map<String, dynamic>>(
            ref.watch(studentProfileProvider),
            (profile) => _AccountSnapshot(
              email: profile['email']?.toString() ?? '-',
              isActive: profile['is_active'] == true,
            ),
          )
        : _profileBody<LecturerProfile>(
            ref.watch(lecturerProfileProvider),
            (profile) => _AccountSnapshot(
              email: profile.email,
              isActive: profile.isActive,
            ),
          );

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Column(
          children: [
            // App bar — sama dengan halaman dosen aslinya.
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: NetLearnSpace.s12,
                vertical: NetLearnSpace.s12,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () =>
                        goBack(context, fallback: widget.backFallback),
                  ),
                  Expanded(
                    child: Text(
                      l10n.securityAndPassword,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(child: profileBody),
          ],
        ),
      ),
      // Navbar bawah: dosen tetap membawa navbar-nya seperti halaman aslinya;
      // halaman mahasiswa tanpa navbar.
      bottomNavigationBar: widget.bottomNavbar,
    );
  }

  /// Loading / error / data untuk profil role yang aktif, lalu formnya.
  Widget _profileBody<T>(
    AsyncValue<T?> profile,
    _AccountSnapshot Function(T) snapshot,
  ) {
    final l10n = AppLocalizations.of(context)!;

    void invalidate() {
      if (widget.useStudentProfile) {
        ref.invalidate(studentProfileProvider);
      } else {
        ref.invalidate(lecturerProfileProvider);
      }
    }

    return profile.when(
      loading: () => const NlSkeletonDetail(
        showBanner: false,
        paragraphBlocks: 2,
      ),
      error: (error, stackTrace) => NlErrorView(
        message: l10n.failedToLoad,
        onRetry: invalidate,
      ),
      data: (data) {
        if (data == null) {
          return NlErrorView(message: l10n.profileNotFound);
        }

        final account = snapshot(data);

        return _ChangePasswordForm(
          l10n: l10n,
          email: account.email,
          isActive: account.isActive,
          useStudentProfile: widget.useStudentProfile,
          saving: _saving,
          formKey: _formKey,
          currentPassword: _currentPassword,
          newPassword: _newPassword,
          confirmPassword: _confirmPassword,
          onSave: _save,
          onRetry: invalidate,
        );
      },
    );
  }
}

/// Email dan status akun yang sudah diratakan untuk kedua role.
class _AccountSnapshot {
  final String email;
  final bool isActive;

  const _AccountSnapshot({
    required this.email,
    required this.isActive,
  });
}

/// Isi halaman setelah identitas diketahui. Dipisah dari state tombol simpan
/// dengan paduan sumber data per role dibawa sebagai field.
class _ChangePasswordForm extends StatelessWidget {
  final AppLocalizations l10n;
  final String email;
  final bool isActive;
  final bool useStudentProfile;
  final bool saving;
  final GlobalKey<FormState> formKey;
  final TextEditingController currentPassword;
  final TextEditingController newPassword;
  final TextEditingController confirmPassword;
  final VoidCallback onSave;
  final VoidCallback onRetry;

  const _ChangePasswordForm({
    required this.l10n,
    required this.email,
    required this.isActive,
    required this.useStudentProfile,
    required this.saving,
    required this.formKey,
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
    required this.onSave,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        NetLearnSpace.s20,
        NetLearnSpace.s20,
        NetLearnSpace.s20,
        NetLearnSpace.s32,
      ),
      children: [
        // Card 1: Account info — memakai data asli untuk kedua role, bukan
        // lagi e-mail Figma yang di-hardcode.
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.accountEmail,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: context.mutedText,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.accountStatus,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6EF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActive ? l10n.active : l10n.inactive,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF28856A),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Card 2: Password actions — baris Change Password punya onTap sesungguhnya?
        // Dengan form ada di halaman ini juga, baris ini menggulir ke form:
        // perilaku asli dosen dipertahankan (tanpa tap = noop di kode asli).
        Container(
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border),
          ),
          child: Column(
            children: [
              _PasswordActionRow(
                icon: Icons.lock_outline_rounded,
                title: l10n.changePassword,
                subtitle: l10n.changePasswordHint,
                onTap: () {
                  // Scroll to form below (behavior carried over from the
                  // original lecturer page; the form sits on this page too).
                },
              ),
              Divider(height: 1, color: context.border),
              _PasswordActionRow(
                icon: Icons.mail_outline_rounded,
                title: l10n.forgotPassword,
                subtitle: l10n.forgotPasswordHint,
                onTap: () {
                  // Jalur pemulihan yang benar-benar berfungsi. Dua role
                  // berbagi [ForgotPasswordPage]; route bercabang per role
                  // di router supaya guard auth tidak memantulkannya.
                  if (useStudentProfile) {
                    context.push('/student/forgot-password');
                  } else {
                    context.push('/lecturer/forgot-password');
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Card 3: Change Password form
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border),
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.changePassword,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  l10n.strongPasswordHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: context.mutedText,
                  ),
                ),
                const SizedBox(height: 17),

                // Current Password
                _FormLabel(text: l10n.currentPassword),
                const SizedBox(height: 7),
                NlField(
                  label: '',
                  placeholder: l10n.currentPassword,
                  controller: currentPassword,
                  obscureText: true,
                  validator: (value) {
                    if ((value ?? '').isEmpty) {
                      return l10n.requiredField;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 17),

                // New Password
                _FormLabel(text: l10n.newPassword),
                const SizedBox(height: 7),
                NlField(
                  label: '',
                  placeholder: l10n.newPassword,
                  controller: newPassword,
                  obscureText: true,
                  validator: (value) {
                    if ((value ?? '').isEmpty) {
                      return l10n.requiredField;
                    }
                    if (value!.length < 8) {
                      return l10n.passwordMinLength;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 17),

                // Confirm New Password
                _FormLabel(text: l10n.confirmPassword),
                const SizedBox(height: 7),
                NlField(
                  label: '',
                  placeholder: l10n.confirmPassword,
                  controller: confirmPassword,
                  obscureText: true,
                  validator: (value) {
                    if ((value ?? '').isEmpty) {
                      return l10n.requiredField;
                    }
                    if (value != newPassword.text) {
                      return l10n.passwordMismatch;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 17),

                // Save Changes button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: saving ? null : onSave,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 17),
                    label: Text(l10n.saveChanges),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Cancel
                Center(
                  child: TextButton(
                    onPressed: () => goBack(context),
                    child: Text(
                      l10n.cancel,
                      style: TextStyle(
                        color: context.accent,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Footer note
        Text(
          l10n.passwordDemoNote,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 9,
            color: const Color(0xFF6C727F),
          ),
        ),
      ],
    );
  }
}

class _PasswordActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PasswordActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.accentTint,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: context.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: const Color(0xFF6C727F),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: context.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}

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
