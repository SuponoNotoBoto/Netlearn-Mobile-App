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
    const errorShape = OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(NetLearnRadius.field),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: NetLearnColors.neutral900,
            ),
          ),
          const SizedBox(height: 7),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          onFieldSubmitted: onFieldSubmitted,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 13,
            color: NetLearnColors.neutral900,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: NetLearnColors.neutral400,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NetLearnRadius.field),
              borderSide: const BorderSide(color: NetLearnColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NetLearnRadius.field),
              borderSide: const BorderSide(color: NetLearnColors.primary, width: 1.5),
            ),
            errorStyle: const TextStyle(
              color: NetLearnColors.danger,
              fontSize: 11,
            ),
            errorBorder: errorShape.copyWith(
              borderSide: const BorderSide(color: NetLearnColors.danger),
            ),
            focusedErrorBorder: errorShape.copyWith(
              borderSide: const BorderSide(color: NetLearnColors.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

