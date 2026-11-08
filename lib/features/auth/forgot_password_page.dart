import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/utils/email_mask.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_field.dart';
import '../../shared/widgets/nl_topbar.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState
    extends ConsumerState<ForgotPasswordPage> {
  final _emailFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _codeSent = false;
  String _submittedEmail = '';
  String? _successMessage;
  bool _codeFeedbackError = false;

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
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!(_emailFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    final sent = await ref
        .read(authControllerProvider.notifier)
        .requestPasswordReset(_emailController.text);

    if (!sent || !mounted) {
      return;
    }

    setState(() {
      _codeSent = true;
      _submittedEmail = _emailController.text.trim();
      _otpController.clear();
      _successMessage = l10n.resetRequestSent;
      _codeFeedbackError = false;
    });
  }

  Future<void> _resendCode() async {
    final sent = await ref
        .read(authControllerProvider.notifier)
        .requestPasswordReset(_submittedEmail);

    if (!sent || !mounted) {
      return;
    }

    setState(() {
      _successMessage = AppLocalizations.of(context)!.resendCodeSent;
      _codeFeedbackError = false;
    });
  }

  String get _normalizedOtp => _otpController.text.replaceAll(
        RegExp(r'\s+'),
        '',
      );

  Future<void> _verifyCode() async {
    if (!(_codeFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _codeFeedbackError = false;
    });

    final router = GoRouter.of(context);

    final verified = await ref
        .read(authControllerProvider.notifier)
        .verifyRecoveryOtp(
          email: _submittedEmail,
          token: _normalizedOtp,
        );

    if (!verified) {
      if (!mounted) {
        return;
      }

      setState(() {
        _successMessage = null;
        _codeFeedbackError = true;
      });

      return;
    }

    router.go('/reset-password');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: NlTopBar(
        title: l10n.forgotPasswordTitle,
        onBack: () => goBack(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            NetLearnSpace.s20,
            NetLearnSpace.s22,
            NetLearnSpace.s20,
            NetLearnSpace.s20,
          ),
          child: _codeSent
              ? _buildCodeStep(context, authState, l10n)
              : _buildEmailStep(context, authState, l10n),
        ),
      ),
    );
  }

  Widget _buildEmailStep(
    BuildContext context,
    AuthState authState,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;

    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RecoveryBrandHeader(),
          const SizedBox(height: 22),
          Text(
            l10n.resetPasswordHeading,
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.forgotPasswordSubtitle,
            style: textTheme.bodyLarge,
          ),
          if (authState.errorMessage != null) ...[
            const SizedBox(height: 18),
            AuthFeedbackBanner(
              kind: AuthFeedbackKind.error,
              message: authState.errorMessage!,
            ),
          ],
          const SizedBox(height: 22),
          NlField(
            label: l10n.email,
            placeholder: l10n.enterEmail,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onFieldSubmitted: (_) => _sendCode(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.emailRequired;
              }

              if (!value.contains('@')) {
                return l10n.invalidEmail;
              }

              return null;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: NlButton(
              label: l10n.sendOtpCode,
              loading: authState.isLoading,
              onPressed: _sendCode,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => goBack(context),
              child: Text(
                l10n.backToSecurity,
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep(
    BuildContext context,
    AuthState authState,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;

    return Form(
      key: _codeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RecoveryBrandHeader(),
          const SizedBox(height: 22),
          Text(
            l10n.otpSentTitle,
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.otpSentBody(maskEmail(_submittedEmail)),
            style: textTheme.bodyLarge,
          ),
          if (authState.errorMessage != null) ...[
            const SizedBox(height: 18),
            AuthFeedbackBanner(
              kind: AuthFeedbackKind.error,
              message: authState.errorMessage!,
            ),
          ] else if (_successMessage != null) ...[
            const SizedBox(height: 18),
            AuthFeedbackBanner(
              kind: AuthFeedbackKind.success,
              message: _successMessage!,
            ),
          ] else if (_codeFeedbackError) ...[
            const SizedBox(height: 18),
            AuthFeedbackBanner(
              kind: AuthFeedbackKind.error,
              message: l10n.invalidOtp,
            ),
          ],
          const SizedBox(height: 22),
          NlField(
            label: l10n.otpCode,
            placeholder: l10n.otpCodeHint,
            controller: _otpController,
            keyboardType: TextInputType.number,
            onFieldSubmitted: (_) => _verifyCode(),
            validator: (value) {
              final code = (value ?? '').replaceAll(RegExp(r'\s+'), '');

              if (code.isEmpty) {
                return l10n.requiredField;
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: NlButton(
              label: l10n.verifyCode,
              loading: authState.isLoading,
              onPressed: _verifyCode,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: authState.isLoading ? null : _resendCode,
              child: Text(
                l10n.resendCode,
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _codeSent = false;
                  _submittedEmail = '';
                  _successMessage = null;
                  _codeFeedbackError = false;
                });
              },
              child: Text(
                l10n.changeEmail,
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => goBack(context),
              child: Text(
                l10n.backToSecurity,
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryBrandHeader extends StatelessWidget {
  const _RecoveryBrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.school_rounded,
              color: scheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)!.appName,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Computer Networking LMS',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.mutedText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

