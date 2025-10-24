import 'package:casi/core/theme/app_pallete.dart';
import 'package:casi/core/widgets/loader.dart';
import 'package:casi/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:casi/features/auth/presentation/widgets/apple_button.dart';
import 'package:casi/features/auth/presentation/widgets/google_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});
  static Route route() => MaterialPageRoute(builder: (_) => const SignInPage());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) return const Loader();
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      const Text(
                        'Welcome',
                        style: TextStyle(
                          color: AppPallete.white,
                          fontSize: 32,
                          fontWeight: FontWeight.normal,
                        ),
                      ),

                      Image.asset('assets/images/casi_logo.png', height: 400),

                      const SizedBox(height: 100),

                      GoogleButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(AuthGoogleRequested());
                        },
                      ),

                      const SizedBox(height: 30),

                      AppleButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(AuthAppleRequested());
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
