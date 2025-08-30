import 'package:flutter/material.dart';
import 'package:casi/core/theme/app_pallete.dart';
import 'package:casi/core/widgets/primary_button.dart';

class SurveyThankYouPage extends StatelessWidget {
  final VoidCallback exitFlow;

  const SurveyThankYouPage({super.key, required this.exitFlow});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thank you'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // badge
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFF64F0AE),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 96,
                        color: AppPallete.black,
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Text(
                      'Thank you!',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppPallete.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your responses have been submitted successfully.',
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.35,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'We appreciate your time and effort — your participation helps protect both animal and public health.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'The next survey will be available in 3 months.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    PrimaryButton(label: 'Continue', onPressed: exitFlow),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
