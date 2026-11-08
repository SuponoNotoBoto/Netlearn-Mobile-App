import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_field.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/nl_topbar.dart';
import 'auth_controller.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() =>
      _ResetPasswordPageState();
}

class _ResetPasswordPageState
    extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _saved = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final saved = await ref
        .read(authControllerProvider.notifier)
        .completePasswordReset(_passwordController.text);

    if (!mounted) {
      return;
    }

    if (!saved) {
      NlSnackBar.show(
        context,
        AppLocalizations.of(context)!.passwordUpdateFailed,
        tone: NlSnackTone.error,
      );

      return;
    }

    setState(() {
      _saved = true;
    });
  }

  Future<void> _backToLogin() async {
    await ref.read(authControllerProvider.notifier).logout();

    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: context.background,
      appBar: NlTopBar(
        title: l10n.setNewPasswordHeading,
        onBack: _saved ? null : () => goBack(context, fallback: '/login'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            NetLearnSpace.s20,
            NetLearnSpace.s22,
            NetLearnSpace.s20,
            NetLearnSpace.s20,
          ),
          child: _saved
              ? _buildSaved(context, l10n)
              : _buildForm(context, l10n, authState.isLoading),
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n,
    bool saving,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.setNewPasswordHeading,
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.setNewPasswordSubtitle,
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          NlField(
            label: l10n.newPassword,
            placeholder: l10n.newPasswordHint,
            controller: _passwordController,
            obscureText: true,
            validator: (value) {
              if ((value ?? '').isEmpty) {
                return l10n.requiredField;
              }

              if (value!.length < 8) {
                return l10n.passwordTooShort;
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          NlField(
            label: l10n.confirmNewPassword,
            placeholder: l10n.confirmNewPasswordHint,
            controller: _confirmController,
            obscureText: true,
            validator: (value) {
              if ((value ?? '').isEmpty) {
                return l10n.requiredField;
              }

              if (value != _passwordController.text) {
                return l10n.passwordMismatch;
              }

              return null;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: NlButton(
              label: l10n.savePassword,
              loading: saving,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaved(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(NetLearnSpace.s20),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(NetLearnRadius.card),
            border: Border.all(color: context.border),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: context.accentTint,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.check_rounded,
                  size: 26,
                  color: context.accent,
                ),
              ),
              const SizedBox(height: NetLearnSpace.s16),
              Text(
                l10n.passwordUpdated,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: NetLearnSpace.s8),
              Text(
                l10n.passwordUpdatedBody,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: context.mutedText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NetLearnSpace.s20),
        NlButton(
          label: l10n.backToLogin,
          onPressed: _backToLogin,
        ),
      ],
    );
  }
}

