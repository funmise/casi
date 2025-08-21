import 'package:casi/auth_gate.dart';
import 'package:casi/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/user/cubit/user_cubit.dart';
import 'core/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  //await ensureFreshAuth();
  runApp(
    MultiBlocProvider(
      providers: [
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
      debugShowCheckedModeBanner: false,
      title: 'CASI',
      theme: AppTheme.theme,
      home: const AuthGate(),
    );
  }
}
