import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_button.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _identityController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AppUserRole _role = AppUserRole.student;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _successMessage;
  bool _showFieldErrors = false;

  late final AuthController _authController;

  @override
  void initState() {
    super.initState();

    _authController = ref.read(authControllerProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authController.clearError();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _identityController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _showFieldErrors = true;
      });
      return;
    }

    setState(() {
      _showFieldErrors = false;
    });

    final outcome =
        await ref.read(authControllerProvider.notifier).register(
      name: _nameController.text,
      identityNumber: _identityController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    if (outcome == RegisterOutcome.emailConfirmationRequired) {
      setState(() {
        _successMessage = l10n.registerSuccessMessage;
      });
    } else if (outcome == RegisterOutcome.success) {
      setState(() {
        _successMessage = l10n.registerSuccessLoginPrompt;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    if (_successMessage != null) {
      return _buildSuccess(context, _successMessage!);
    }

    return Scaffold(
      backgroundColor: NetLearnColors.appBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const AuthHero(),
              _RegisterForm(
                formKey: _formKey,
                nameController: _nameController,
                identityController: _identityController,
                emailController: _emailController,
                passwordController: _passwordController,
                confirmPasswordController: _confirmPasswordController,
                role: _role,
                onRoleChanged: (role) {
                  setState(() {
                    _role = role;
                  });
                },
                obscurePassword: _obscurePassword,
                onObscureToggle: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                obscureConfirmPassword: _obscureConfirmPassword,
                onConfirmObscureToggle: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
                onSubmit: _submit,
                isLoading: authState.isLoading,
                errorMessage: authState.errorMessage,
                showFieldErrors: _showFieldErrors,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context, String message) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: NetLearnColors.appBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            NetLearnSpace.s20,
            NetLearnSpace.s32,
            NetLearnSpace.s20,
            NetLearnSpace.s20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: NetLearnColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: NetLearnColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: NetLearnSpace.s24),
              Text(
                l10n.registerSuccessTitle,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NetLearnSpace.s12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 310),
                child: Text(
                  message,
                  style: textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: NetLearnSpace.s32),
              SizedBox(
                width: double.infinity,
                child: NlButton(
                  label: l10n.signIn,
                  onPressed: () {
                    context.go('/login');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController identityController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final AppUserRole role;
  final ValueChanged<AppUserRole> onRoleChanged;
  final bool obscurePassword;
  final VoidCallback onObscureToggle;
  final bool obscureConfirmPassword;
  final VoidCallback onConfirmObscureToggle;
  final VoidCallback onSubmit;
  final bool isLoading;
  final String? errorMessage;
  final bool showFieldErrors;

  const _RegisterForm({
    required this.formKey,
    required this.nameController,
    required this.identityController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.role,
    required this.onRoleChanged,
    required this.obscurePassword,
    required this.onObscureToggle,
    required this.obscureConfirmPassword,
    required this.onConfirmObscureToggle,
    required this.onSubmit,
    required this.isLoading,
    required this.errorMessage,
    required this.showFieldErrors,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isLecturer = role == AppUserRole.lecturer;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.registerHeading,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                height: 30 / 20,
                color: NetLearnColors.ink,
                letterSpacing: -0.45,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.registerSubtitle,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                height: 21 / 12,
                color: NetLearnColors.muted,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 18),
            AuthRoleSegmented(role: role, onChanged: onRoleChanged),
            if (isLecturer) ...[
              const SizedBox(height: 12),
              _LecturerNotice(text: l10n.registerLecturerNotice),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 18),
              AuthFeedbackBanner(
                kind: AuthFeedbackKind.error,
                message: errorMessage!,
              ),
            ],
            const SizedBox(height: 18),
            AuthField(
              label: l10n.fullName,
              placeholder: l10n.enterFullName,
              controller: nameController,
              autovalidateMode: showFieldErrors
                  ? AutovalidateMode.onUserInteraction
                  : null,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.fullNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 17),
            AuthField(
              label: l10n.studentIdOrEmployeeId,
              placeholder: l10n.enterStudentOrEmployeeId,
              controller: identityController,
              keyboardType: TextInputType.number,
              autovalidateMode: showFieldErrors
                  ? AutovalidateMode.onUserInteraction
                  : null,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.studentIdRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 17),
            AuthField(
              label: l10n.userEmail,
              placeholder: l10n.enterEmail,
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autovalidateMode: showFieldErrors
                  ? AutovalidateMode.onUserInteraction
                  : null,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.emailRequired;
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return l10n.invalidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 17),
            AuthField(
              label: l10n.password,
              placeholder: l10n.enterPassword,
              controller: passwordController,
              obscureText: obscurePassword,
              autovalidateMode: showFieldErrors
                  ? AutovalidateMode.onUserInteraction
                  : null,
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: NetLearnColors.muted,
                ),
                onPressed: onObscureToggle,
                padding: const EdgeInsets.all(13),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.authPasswordRequired;
                }
                if (value.length < 8) {
                  return l10n.passwordMinLength;
                }
                return null;
              },
            ),
            const SizedBox(height: 17),
            AuthField(
              label: l10n.confirmPassword,
              placeholder: l10n.confirmPasswordPlaceholder,
              controller: confirmPasswordController,
              obscureText: obscureConfirmPassword,
              autovalidateMode: showFieldErrors
                  ? AutovalidateMode.onUserInteraction
                  : null,
              suffixIcon: IconButton(
                icon: Icon(
                  obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: NetLearnColors.muted,
                ),
                onPressed: onConfirmObscureToggle,
                padding: const EdgeInsets.all(13),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.confirmPasswordRequired;
                }
                if (value != passwordController.text) {
                  return l10n.passwordMismatch;
                }
                return null;
              },
              onFieldSubmitted: isLecturer ? null : (_) => onSubmit(),
            ),
            const SizedBox(height: 17),
            SizedBox(
              width: double.infinity,
              child: NlButton(
                label: l10n.registerButton,
                loading: isLoading,
                onPressed: isLecturer ? null : onSubmit,
                trailingIcon: Icons.arrow_forward_rounded,
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: () => context.go('/login'),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                  padding: const EdgeInsets.all(8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.alreadyHaveAccount,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                    height: 16.5 / 11,
                    color: scheme.primary,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LecturerNotice extends StatelessWidget {
  final String text;

  const _LecturerNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: NetLearnColors.primaryTint,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: NetLearnColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w400,
                fontSize: 11,
                height: 16.5 / 11,
                color: NetLearnColors.ink,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

