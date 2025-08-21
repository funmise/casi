import 'package:casi/core/widgets/loader.dart';
import 'package:casi/features/auth/presentation/pages/sign_in_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:casi/core/user/cubit/user_cubit.dart';
import 'package:casi/core/user/cubit/user_state.dart';

class Nextboard extends StatelessWidget {
  const Nextboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        if (state is UserReady) {
          final u = state.user;
          return Scaffold(
            appBar: AppBar(title: const Text('CASI')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hello, ${u.name ?? 'clinician'}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(u.email),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: () => context.read<UserCubit>().signOut(),
                    child: const Text('Sign out'),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Go to Dashboard"),
                  ),
                ],
              ),
            ),
          );
        }

        // if (state is UserLoading || state is UserInitial) {
        //   return const Scaffold(body: Loader());
        // }

        if (state is UserError) {
          return Scaffold(
            appBar: AppBar(title: const Text('CASI')),
            body: Center(child: Text(state.message)),
          );
        }

        // AppUserUnauthenticated
        // print("secer");
        // return const Scaffold(
        //   body: Center(child: Text('it stays')),
        //   backgroundColor: Colors.green,
        // );

        return const SizedBox.shrink();
      },
    );
  }
}
