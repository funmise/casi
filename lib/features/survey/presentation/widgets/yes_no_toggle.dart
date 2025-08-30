import 'package:flutter/material.dart';
import 'package:casi/core/theme/app_pallete.dart';

class YesNoToggle extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final String? errorText;

  const YesNoToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final bool yesSelected = value == true;
    final bool noSelected = value == false;

    Widget pill({
      required String label,
      required bool selected,
      required VoidCallback? onTap,
    }) {
      final Color fill = selected
          ? AppPallete.secondary.withValues(alpha: 0.6)
          : AppPallete.white.withValues(alpha: 0.10);

      final Color borderColor = selected
          ? Colors.white.withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0);

      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              border: Border.all(color: borderColor, width: 2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: AppPallete.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      );
    }

    final disabled = onChanged == null;
    final opacity = disabled ? 0.5 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              pill(
                label: 'YES',
                selected: yesSelected,
                onTap: disabled
                    ? null
                    : () => onChanged!(yesSelected ? null : true),
              ),
              const SizedBox(width: 12),
              pill(
                label: 'NO',
                selected: noSelected,
                onTap: disabled
                    ? null
                    : () => onChanged!(noSelected ? null : false),
              ),
            ],
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                errorText!,
                style: const TextStyle(
                  color: AppPallete.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
