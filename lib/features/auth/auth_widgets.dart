import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_netlearn_logo.dart';
import '../../shared/widgets/nl_segmented_tabs.dart';
import 'auth_controller.dart';

/// `.login-hero` — purple gradient header holding the brand mark, the wordmark
/// and the "Computer Networking LMS" tagline.
class AuthHero extends StatelessWidget {
  const AuthHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: NetLearnGradients.hero,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 34, 20, 34),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const NlNetLearnLogo(inverse: true, size: 44),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'NetLearn',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontWeight: FontWeight.w800,
                    fontSize: 34,
                    height: 40.8 / 34,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Computer Networking LMS',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: 19.8 / 12,
              color: Color(0xFFCEC8ED),
              letterSpacing: 0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// `.tabs` — the Student/Lecturer selector shared by both auth screens.
class AuthRoleSegmented extends StatelessWidget {
  final AppUserRole role;
  final ValueChanged<AppUserRole> onChanged;

  const AuthRoleSegmented({
    super.key,
    required this.role,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return NlSegmentedTabs(
      labels: [l10n.student, l10n.lecturer],
      selectedIndex: role == AppUserRole.student ? 0 : 1,
      semanticLabel: l10n.role,
      onChanged: (index) {
        onChanged(index == 0 ? AppUserRole.student : AppUserRole.lecturer);
      },
    );
  }
}

enum AuthFeedbackKind { error, success }

class AuthFeedbackBanner extends StatelessWidget {
  final AuthFeedbackKind kind;
  final String message;

  const AuthFeedbackBanner({
    super.key,
    required this.kind,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final status = Theme.of(context).statusColors;

    final (bg, fg, icon) = kind == AuthFeedbackKind.error
        ? (status.dangerBg, status.dangerText, Icons.error_outline_rounded)
        : (status.positiveBg, status.positiveText,
            Icons.check_circle_outline_rounded);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w500,
                fontSize: 12,
                height: 18 / 12,
                color: fg,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final AutovalidateMode? autovalidateMode;

  const AuthField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.onFieldSubmitted,
    this.autovalidateMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = theme.statusColors;

    const errorShape = OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(NetLearnRadius.field),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          autovalidateMode: autovalidateMode,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            suffixIcon: suffixIcon,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            errorStyle: TextStyle(
              color: status.dangerText,
              fontSize: 11,
              height: 14.5 / 11,
            ),
            errorBorder: errorShape.copyWith(
              borderSide: const BorderSide(color: NetLearnColors.danger),
            ),
            focusedErrorBorder: errorShape.copyWith(
              borderSide:
                  const BorderSide(color: NetLearnColors.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

