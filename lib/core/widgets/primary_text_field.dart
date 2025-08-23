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

  // form support
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;

  final bool enabled;

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
    this.validator,
    this.autovalidateMode,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = !enabled || readOnly;

    final fillColor = isDisabled
        ? AppPallete.white.withValues(alpha: .08)
        : AppPallete.black.withValues(alpha: .15);

    final borderColor = isDisabled
        ? AppPallete.white.withValues(alpha: .15)
        : AppPallete.white.withValues(alpha: .3);

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      enabled: enabled,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      autovalidateMode: autovalidateMode,
      style: TextStyle(
        color: isDisabled
            ? AppPallete.white.withValues(alpha: .65)
            : AppPallete.white,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppPallete.white.withValues(alpha: isDisabled ? .4 : .6),
        ),
        filled: true,
        fillColor: fillColor,
        suffixIcon: suffix == null
            ? (isDisabled
                  ? const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: AppPallete.white,
                    )
                  : null)
            : Opacity(opacity: isDisabled ? .55 : 1, child: suffix),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppPallete.white.withValues(alpha: .15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          // keep a subtle focus even when disabled/readonly so UI stays consistent
          borderSide: BorderSide(
            color: isDisabled
                ? AppPallete.white.withValues(alpha: .25)
                : AppPallete.white,
          ),
        ),
      ),
    );
  }
}
