import 'package:flutter/material.dart';
import 'package:casi/core/theme/app_pallete.dart';

/// A compact, accessible control that combines:
///     [-]    VALUE     [+]
///     <----- slider ----->
///
/// - Honors min/max and an optional step (defaults to 1).
/// - Uses app colors; neutral when disabled.
/// - Emits the *clamped* integer value on every change.
///
class NumericStepperSlider extends StatelessWidget {
  final int min;
  final int max;
  final int value;
  final bool enabled;
  final int step;
  final ValueChanged<int> onChanged;
  final String? errorText;
  final ValueChanged<int>? onChangeEnd;

  const NumericStepperSlider({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.step = 1,
    this.errorText,
    this.onChangeEnd,
  }) : assert(step > 0, 'step must be > 0');

  int _clamp(int v) => v.clamp(min, max);

  void _bump(int delta) {
    if (!enabled) return;
    final next = _clamp(value + delta);
    if (next != value) {
      onChanged(next); // immediate UI update upstream
      onChangeEnd?.call(next); // treat ± tap as a committed change
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = enabled;
    final opacity = active ? 1.0 : 0.5;

    final Color trackColor = AppPallete.secondary.withValues(alpha: 0.6);
    final Color inactiveTrack = AppPallete.white.withValues(alpha: 0.25);
    final Color thumbColor = AppPallete.secondary.withValues(alpha: 0.9);

    final divisions = (max - min) > 0 ? ((max - min) ~/ step) : null;
    final sliderValue = value.toDouble().clamp(min.toDouble(), max.toDouble());

    return Opacity(
      opacity: opacity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: [-]   000   [+]
          Row(
            children: [
              _RoundIconButton(
                icon: Icons.remove,
                onPressed: active ? () => _bump(-step) : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$value',
                    style: const TextStyle(
                      color: AppPallete.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              _RoundIconButton(
                icon: Icons.add,
                onPressed: active ? () => _bump(step) : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: trackColor,
              inactiveTrackColor: inactiveTrack,
              thumbColor: thumbColor,
              overlayColor: AppPallete.black.withValues(alpha: .08),
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: Slider(
              value: sliderValue,
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: divisions,
              onChanged: active
                  ? (double v) {
                      // snap to step on drag
                      final snapped = (v.round() ~/ step) * step;
                      onChanged(_clamp(snapped));
                    }
                  : null,
              onChangeEnd: active
                  ? (v) {
                      // Fire validation once user releases the thumb
                      final snapped = (v.round() ~/ step) * step;
                      if (onChangeEnd != null) {
                        onChangeEnd!(_clamp(snapped));
                      }
                    }
                  : null,
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                errorText!,
                style: const TextStyle(
                  color: Colors.red,
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

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _RoundIconButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final bg = enabled
        ? AppPallete.white.withValues(alpha: 0.10)
        : AppPallete.white.withValues(alpha: 0.04);
    final border = enabled
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.18);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border, width: 2),
          ),
          child: Icon(icon, color: AppPallete.white, size: 22),
        ),
      ),
    );
  }
}
