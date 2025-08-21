import 'package:flutter/material.dart';
import 'package:casi/core/theme/app_pallete.dart';

class PrimaryTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final bool readOnly;
  final void Function(String)? onChanged;

  // so RawAutocomplete can manage focus & submit
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const PrimaryTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.suffix,
    this.readOnly = false,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: const TextStyle(color: AppPallete.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppPallete.white),
        filled: true,
        fillColor: AppPallete.black.withValues(alpha: .15),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppPallete.white.withValues(alpha: .3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppPallete.white.withValues(alpha: .3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPallete.white),
        ),
      ),
    );
  }
}
