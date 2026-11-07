import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_field.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import 'lecturer_bottom_navbar.dart';
import 'lecturer_dashboard_controller.dart';

class LecturerChangePasswordPage extends ConsumerStatefulWidget {
  const LecturerChangePasswordPage({super.key});

  @override
  ConsumerState<LecturerChangePasswordPage> createState() =>
      _LecturerChangePasswordPageState();
}

class _LecturerChangePasswordPageState
    extends ConsumerState<LecturerChangePasswordPage> {
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
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _saving = false);
      NlSnackBar.show(
        context,
        AppLocalizations.of(context)?.passwordChangeNotAvailable ??
            'Penggantian kata sandi belum tersedia.',
        tone: NlSnackTone.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profileAsync = ref.watch(lecturerProfileProvider);

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Column(
          children: [
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
                    onPressed: () => goBack(context, fallback: '/lecturer/security'),
                  ),
                  Expanded(
                    child: Text(
                      l10n?.securityAndPassword ?? 'Keamanan & Kata Sandi',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: profileAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => _buildForm(
                  context,
                  email: 'supono@kampus.ac.id',
                  isActive: true,
                ),
                data: (profile) => _buildForm(
                  context,
                  email: profile?.email ?? 'supono@kampus.ac.id',
                  isActive: profile?.isActive ?? true,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const LecturerBottomNavbar(currentIndex: 4),
    );
  }

  Widget _buildForm(
    BuildContext context, {
    required String email,
    required bool isActive,
  }) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        NetLearnSpace.s20,
        NetLearnSpace.s20,
        NetLearnSpace.s20,
        NetLearnSpace.s32,
      ),
      children: [
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
                l10n?.accountEmail ?? 'Email Akun',
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
                l10n?.accountStatus ?? 'Status Akun',
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
                  isActive ? (l10n?.active ?? 'Aktif') : (l10n?.inactive ?? 'Nonaktif'),
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
                title: l10n?.changePassword ?? 'Ubah Kata Sandi',
                subtitle: l10n?.changePasswordHint ?? 'Ganti kata sandi akun Anda secara berkala',
                onTap: () {},
              ),
              Divider(height: 1, color: context.border),
              _PasswordActionRow(
                icon: Icons.mail_outline_rounded,
                title: l10n?.forgotPassword ?? 'Lupa Kata Sandi',
                subtitle: l10n?.forgotPasswordHint ?? 'Kirim tautan pemulihan ke email terdaftar',
                onTap: () {
                  NlSnackBar.show(
                    context,
                    l10n?.forgotPasswordHint ?? 'Tautan pemulihan dikirim ke email',
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.changePassword ?? 'Ubah Kata Sandi',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  l10n?.strongPasswordHint ?? 'Gunakan minimal 8 karakter dengan kombinasi huruf dan angka.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: context.mutedText,
                  ),
                ),
                const SizedBox(height: 17),
                _FormLabel(text: l10n?.currentPassword ?? 'Kata Sandi Saat Ini'),
                const SizedBox(height: 7),
                NlField(
                  label: '',
                  placeholder: l10n?.currentPassword ?? 'Kata Sandi Saat Ini',
                  controller: _currentPassword,
                  obscureText: true,
                  validator: (value) {
                    if ((value ?? '').isEmpty) {
                      return l10n?.requiredField ?? 'Wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 17),
                _FormLabel(text: l10n?.newPassword ?? 'Kata Sandi Baru'),
                const SizedBox(height: 7),
                NlField(
                  label: '',
                  placeholder: l10n?.newPassword ?? 'Kata Sandi Baru',
                  controller: _newPassword,
                  obscureText: true,
                  validator: (value) {
                    if ((value ?? '').isEmpty) {
                      return l10n?.requiredField ?? 'Wajib diisi';
                    }
                    if (value!.length < 8) {
                      return l10n?.passwordMinLength ?? 'Minimal 8 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 17),
                _FormLabel(text: l10n?.confirmPassword ?? 'Konfirmasi Kata Sandi Baru'),
                const SizedBox(height: 7),
                NlField(
                  label: '',
                  placeholder: l10n?.confirmPassword ?? 'Konfirmasi Kata Sandi Baru',
                  controller: _confirmPassword,
                  obscureText: true,
                  validator: (value) {
                    if ((value ?? '').isEmpty) {
                      return l10n?.requiredField ?? 'Wajib diisi';
                    }
                    if (value != _newPassword.text) {
                      return l10n?.passwordMismatch ?? 'Kata sandi tidak cocok';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 17),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 17),
                    label: Text(l10n?.saveChanges ?? 'Simpan Perubahan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF543CD1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => goBack(context),
                    child: Text(
                      l10n?.cancel ?? 'Batal',
                      style: const TextStyle(
                        color: Color(0xFF543CD1),
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
        Text(
          l10n?.passwordDemoNote ?? 'Perubahan kata sandi akan disinkronkan ke email universitas Anda.',
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
