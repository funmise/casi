import 'package:flutter/material.dart';
import 'package:casi/core/theme/app_pallete.dart';

class SegmentedOption<T> {
  final String label;
  final T value;
  SegmentedOption({required this.label, required this.value});
}

class SegmentedToggle<T> extends StatelessWidget {
  final T? value;
  final List<SegmentedOption<T>> options;
  final ValueChanged<T?>? onChanged;

  const SegmentedToggle({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Row(
        children: [
          for (int i = 0; i < options.length; i++) ...[
            Expanded(
              child: _pill(options[i], value, disabled ? null : onChanged!),
            ),
            if (i < options.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  Widget _pill(
    SegmentedOption<T> opt,
    T? current,
    ValueChanged<T?>? onChanged,
  ) {
    final bool selected = current == opt.value;

    final Color fill = selected
        ? AppPallete.secondary.withValues(alpha: 0.6)
        : AppPallete.white.withValues(alpha: 0.10);

    final Color borderColor = selected
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0);

    return GestureDetector(
      onTap: (onChanged == null)
          ? null
          : () => onChanged(selected ? null : opt.value),
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
          opt.label,
          style: const TextStyle(
            color: AppPallete.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
