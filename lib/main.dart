import 'package:casi/core/widgets/loader.dart';
import 'package:casi/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:casi/features/enrollment/presentation/pages/onboarding_flow.dart';
import 'package:casi/init_dependencies.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/cubits/app_user/app_user_cubit.dart';
import 'core/theme/theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/sign_in_page.dart';

// Top-level helper: force-refresh the cached Firebase user.
// If the user was deleted/disabled server-side, this will fail and we sign out.
Future<void> ensureFreshAuth() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      await user.getIdToken(true); // force refresh token
    } on FirebaseAuthException {
      await FirebaseAuth.instance.signOut(); // drop stale session
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  await ensureFreshAuth();
  runApp(const CASIApp());
}

class CASIApp extends StatelessWidget {
  const CASIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => serviceLocator<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider(create: (_) => serviceLocator<AppUserCubit>()),
      ],
      child: MaterialApp(
        builder: (context, child) {
          final auth = context.watch<AuthBloc>().state;
          if (auth is AuthAuthenticated) {
            return BlocProvider<EnrollmentBloc>(
              key: ValueKey(auth.user.id),
              create: (_) => serviceLocator<EnrollmentBloc>(),
              child: child!,
            );
          }
          return child!;
        },
        debugShowCheckedModeBanner: false,
        title: 'CASI',
        theme: AppTheme.theme,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return const OnboardingFlow();
            }
            if (state is AuthLoading) {
              return const Scaffold(body: Loader());
            }
            return const SignInPage();
          },
        ),
      ),
    );
  }
}
