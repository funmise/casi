import 'package:casi/core/widgets/loader.dart';
import 'package:casi/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/cubits/app_user/app_user_cubit.dart';
import 'core/theme/theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/sign_in_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
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
        debugShowCheckedModeBanner: false,
        title: 'CASI',
        theme: AppTheme.theme,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              // For now, just show a simple “logged in” screen
              return Scaffold(
                appBar: AppBar(title: const Text('CASI')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hello, ${state.user.name ?? 'clinician'}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(state.user.email),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<AuthBloc>().add(AuthSignedOut()),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
              );
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
