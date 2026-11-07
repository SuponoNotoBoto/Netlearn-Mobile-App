import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class NlField extends StatelessWidget {
  final String label;
  final String placeholder;
  final bool obscureText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final void Function(String)? onFieldSubmitted;

  /// 1 by default. Pass a higher value for material content, descriptions and
  /// question text so the lecturer can actually read what they are typing
  /// while editing instead of opening a dialog.
  final int maxLines;

  const NlField({
    super.key,
    required this.label,
    required this.placeholder,
    this.obscureText = false,
    this.controller,
    this.validator,
    this.suffixIcon,
    this.keyboardType,
    this.onFieldSubmitted,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final status = Theme.of(context).statusColors;

    // Same error presentation as the auth screens' AuthField: a clearly red
    // border and an error-text colour with >= 4.5:1 contrast on the fill.
    // Styled per widget rather than in the global inputDecorationTheme so
    // only failing fields pay, and both themes read from the shared
    // NetLearnStatusColors extension.
    const errorShape = OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(NetLearnRadius.field),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 7),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          onFieldSubmitted: onFieldSubmitted,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: placeholder,
            suffixIcon: suffixIcon,
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