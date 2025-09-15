import 'dart:math' as math;
import 'package:casi/core/pages/contact.dart';
import 'package:casi/core/theme/app_pallete.dart';
import 'package:casi/core/user/cubit/user_cubit.dart';
import 'package:casi/core/user/cubit/user_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final drawerW = math.min(320.0, math.max(240.0, screenW * 0.5));

    return Drawer(
      backgroundColor: AppPallete.background,
      width: drawerW,
      child: SafeArea(
        child: BlocListener<UserCubit, UserState>(
          listener: (ctx, state) {
            // Close any blocking overlay/loader on terminal states
            if (state is UserUnauthenticated || state is UserError) {
              Navigator.of(ctx, rootNavigator: true).maybePop();
            }
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Home'),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: const Icon(Icons.contact_support_outlined),
                title: const Text('Contact'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ContactPage()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Log out'),
                onTap: () async {
                  final drawerNav = Navigator.of(context);
                  if (drawerNav.canPop()) drawerNav.pop();
                  context.read<UserCubit>().signOut();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Delete account',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  final drawerNav = Navigator.of(context);
                  final rootNav = Navigator.of(context, rootNavigator: true);
                  final userCubit = context.read<UserCubit>();

                  if (drawerNav.canPop()) drawerNav.pop();

                  // Let the pop complete
                  await Future.microtask(() {});

                  //Re-acquire a fresh, valid context from the root navigator *after* the await
                  if (!rootNav.mounted) return;
                  final rootCtx = rootNav.context; // fresh BuildContext now

                  if (!rootCtx.mounted) return;

                  final confirmed = await showDialog<bool>(
                    context: rootCtx,
                    useRootNavigator: true,
                    builder: (dctx) => AlertDialog(
                      title: Text(
                        'Delete account?',
                        style: Theme.of(dctx).textTheme.headlineMedium,
                      ),
                      content: Text(
                        'This will permanently delete your account and personal information. '
                        'This action cannot be undone.\n\n'
                        'Since this is a security-sensitive operation, you might be asked to login'
                        ' before your account can be deleted.',
                        style: Theme.of(dctx).textTheme.bodyMedium,
                      ),
                      backgroundColor: AppPallete.background,
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(
                            dctx,
                            rootNavigator: true,
                          ).pop(false),
                          child: Text(
                            'Cancel',
                            style: Theme.of(dctx).textTheme.bodyMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dctx, rootNavigator: true).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;

                  userCubit.deleteAccount();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
