import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/language_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_button.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  AppUserRole _role = AppUserRole.student;
  bool _obscurePassword = true;
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
    _identifierController.dispose();
    _passwordController.dispose();
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

    final success = await ref.read(authControllerProvider.notifier).login(
      identityNumber: _identifierController.text,
      password: _passwordController.text,
      role: _role,
    );

    if (!success || !mounted) {
      return;
    }

    final language = ref.read(languageProvider.notifier);
    final themeMode = ref.read(themeModeProvider.notifier);

    await language.syncFromProfile();
    await themeMode.syncFromProfile();

    if (!mounted) {
      return;
    }

    switch (_role) {
      case AppUserRole.student:
        context.go('/student');
        break;
      case AppUserRole.lecturer:
        context.go('/lecturer');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const AuthHero(),
              _LoginForm(
                formKey: _formKey,
                identifierController: _identifierController,
                passwordController: _passwordController,
                role: _role,
                onRoleChanged: (role) {
                  setState(() {
                    _role = role;
                    _identifierController.clear();
                  });
                },
                obscurePassword: _obscurePassword,
                onObscureToggle: () {
                  setState(() => _obscurePassword = !_obscurePassword);
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
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final AppUserRole role;
  final ValueChanged<AppUserRole> onRoleChanged;
  final bool obscurePassword;
  final VoidCallback onObscureToggle;
  final VoidCallback onSubmit;
  final bool isLoading;
  final String? errorMessage;
  final bool showFieldErrors;

  const _LoginForm({
    required this.formKey,
    required this.identifierController,
    required this.passwordController,
    required this.role,
    required this.onRoleChanged,
    required this.obscurePassword,
    required this.onObscureToggle,
    required this.onSubmit,
    required this.isLoading,
    required this.errorMessage,
    required this.showFieldErrors,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.welcomeBack,
              style: TextStyle(
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
              l10n.loginSubtitle,
              style: TextStyle(
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
            if (errorMessage != null) ...[
              const SizedBox(height: 18),
              AuthFeedbackBanner(
                kind: AuthFeedbackKind.error,
                message: errorMessage!,
              ),
            ],
            const SizedBox(height: 18),
            AuthField(
              label: role == AppUserRole.lecturer
                  ? l10n.emailOrLecturerId
                  : l10n.emailOrStudentId,
              placeholder: role == AppUserRole.lecturer
                  ? l10n.enterEmailOrLecturerId
                  : l10n.enterEmailOrStudentId,
              controller: identifierController,
              autovalidateMode: showFieldErrors
                  ? AutovalidateMode.onUserInteraction
                  : null,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.authIdentifierRequired;
                }

                if (value.contains('@') && !value.contains('.')) {
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
                return null;
              },
              onFieldSubmitted: (_) => onSubmit(),
            ),
            const SizedBox(height: 17),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.forgotPassword,
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
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: NlButton(
                label: l10n.signIn,
                loading: isLoading,
                onPressed: onSubmit,
                trailingIcon: Icons.arrow_forward_rounded,
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: () => context.go('/register'),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                  padding: const EdgeInsets.all(8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.noAccountYet,
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

