import 'package:flutter/material.dart';
import 'package:casi/core/theme/app_pallete.dart';

class GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  const GoogleButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPallete.white,
          foregroundColor: AppPallete.black,
          textStyle: const TextStyle(fontSize: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/google_logo.png', height: 30),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(color: AppPallete.grey),
            ),
          ],
        ),
      ),
    );
  }
}
