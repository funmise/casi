import 'package:casi/core/enums.dart';
import 'package:casi/core/widgets/loader.dart';
import 'package:casi/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:casi/features/enrollment/presentation/pages/onboarding_flow.dart';
import 'package:casi/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/user/cubit/user_cubit.dart';
import 'core/theme/theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/sign_in_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  //await ensureFreshAuth();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => serviceLocator<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider(create: (_) => serviceLocator<UserCubit>()..resubscribe()),
      ],
      child: const CASIApp(),
    ),
  );
}

class CASIApp extends StatelessWidget {
  const CASIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: BlocSelector<AuthBloc, AuthState, AuthStatus>(
        selector: (s) => s is AuthAuthenticated
            ? AuthStatus.authed
            : s is AuthLoading
            ? AuthStatus.loading
            : AuthStatus.unauthed,
        builder: (context, status) {
          switch (status) {
            case AuthStatus.authed:
              return const OnboardingFlow();
            case AuthStatus.loading:
              return const Scaffold(body: Loader());
            case AuthStatus.unauthed:
              return const SignInPage();
          }
        },
      ),
    );
  }
}
