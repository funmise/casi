import 'package:flutter/material.dart';
import 'package:casi/core/theme/app_pallete.dart';

class AppleButton extends StatelessWidget {
  final VoidCallback onPressed;
  const AppleButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    // HIG-ish: solid black, white text, rounded 8, centered Apple icon
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPallete.black,
          foregroundColor: AppPallete.white,
          textStyle: const TextStyle(fontSize: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apple, size: 28),
            SizedBox(width: 12),
            Text('Continue with Apple'),
          ],
        ),
      ),
    );
  }
}
