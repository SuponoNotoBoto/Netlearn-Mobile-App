import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_field.dart';
import 'user_management_controller.dart';

/// Menampilkan modal bottom sheet untuk menambah akun pengguna baru oleh Admin.
Future<bool> showAddUserSheet(
  BuildContext context, {
  String initialRole = 'student',
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _AddUserSheet(initialRole: initialRole),
  );
  return result == true;
}

class _AddUserSheet extends StatefulWidget {
  final String initialRole;

  const _AddUserSheet({required this.initialRole});

  @override
  State<_AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends State<_AddUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _identityCtrl = TextEditingController();
  final _programCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late String _selectedRole;
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _selectedRole = (widget.initialRole == 'lecturer' ||
            widget.initialRole == 'admin')
        ? widget.initialRole
        : 'student';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _identityCtrl.dispose();
    _programCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMsg = null;
    });

    try {
      await UserManagementService.createUser(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        role: _selectedRole,
        identityNumber: _identityCtrl.text,
        program: _programCtrl.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final identityLabel = _selectedRole == 'student'
        ? 'NIM'
        : (_selectedRole == 'lecturer' ? 'NIDN / NIP' : 'ID Admin / NIP');
    final identityHint = _selectedRole == 'student'
        ? (isId ? 'Contoh: 23050974001' : 'e.g. 23050974001')
        : (isId ? 'Contoh: 198801012015041001' : 'e.g. 198801012015041001');

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: context.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isId ? 'Tambah Akun Pengguna' : 'Add User Account',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          isId
                              ? 'Buat akun baru untuk mahasiswa, dosen, atau admin'
                              : 'Create a new student, lecturer, or admin account',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: context.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Role selector
              Text(
                isId ? 'Peran Akun (Role)' : 'Account Role',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _RoleChoiceChip(
                    label: isId ? 'Mahasiswa' : 'Student',
                    icon: Icons.school_outlined,
                    selected: _selectedRole == 'student',
                    color: const Color(0xFF2563EB),
                    onTap: () => setState(() => _selectedRole = 'student'),
                  ),
                  const SizedBox(width: 8),
                  _RoleChoiceChip(
                    label: isId ? 'Dosen' : 'Lecturer',
                    icon: Icons.co_present_outlined,
                    selected: _selectedRole == 'lecturer',
                    color: const Color(0xFF7C3AED),
                    onTap: () => setState(() => _selectedRole = 'lecturer'),
                  ),
                  const SizedBox(width: 8),
                  _RoleChoiceChip(
                    label: 'Admin',
                    icon: Icons.admin_panel_settings_outlined,
                    selected: _selectedRole == 'admin',
                    color: const Color(0xFFD97706),
                    onTap: () => setState(() => _selectedRole = 'admin'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_errorMsg != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.feedback.errorBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.feedback.errorBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: context.feedback.errorFg,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.feedback.errorFg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              NlField(
                label: isId ? 'Nama Lengkap' : 'Full Name',
                placeholder: isId
                    ? 'Masukkan nama lengkap'
                    : 'Enter full name',
                controller: _nameCtrl,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return isId
                        ? 'Nama lengkap wajib diisi'
                        : 'Full name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              NlField(
                label: 'Email',
                placeholder: 'nama@unesa.ac.id',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  final v = val?.trim() ?? '';
                  if (v.isEmpty) {
                    return isId ? 'Email wajib diisi' : 'Email is required';
                  }
                  if (!v.contains('@') || !v.contains('.')) {
                    return isId
                        ? 'Format email tidak valid'
                        : 'Invalid email format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: NlField(
                      label: identityLabel,
                      placeholder: identityHint,
                      controller: _identityCtrl,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NlField(
                      label: isId ? 'Program Studi' : 'Study Program',
                      placeholder: 'Pendidikan TI',
                      controller: _programCtrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              NlField(
                label: isId ? 'Kata Sandi Awal' : 'Initial Password',
                placeholder: isId
                    ? 'Minimal 6 karakter'
                    : 'Minimum 6 characters',
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: context.mutedText,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                validator: (val) {
                  if (val == null || val.length < 6) {
                    return isId
                        ? 'Kata sandi minimal 6 karakter'
                        : 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                child: NlButton(
                  label: isId ? 'Simpan & Buat Akun' : 'Create Account',
                  loading: _submitting,
                  onPressed: _submit,
                  trailingIcon: Icons.check_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _RoleChoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : context.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : context.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? color : context.mutedText,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? color : context.onSurface,
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

