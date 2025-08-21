import 'package:casi/core/enums.dart';
import 'package:casi/core/user/cubit/user_cubit.dart';
import 'package:casi/core/user/cubit/user_state.dart';
import 'package:casi/core/widgets/loader.dart';
import 'package:casi/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:casi/features/auth/presentation/pages/sign_in_page.dart';
import 'package:casi/features/enrollment/presentation/pages/onboarding_flow.dart';
import 'package:casi/core/pages/temp_dashboard.dart';
import 'package:casi/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _Phase { loading, unauth, onboarding, dashboard }

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final GlobalKey<NavigatorState> _innerNavKey = GlobalKey<NavigatorState>();
  _Phase? _lastPhase;

  void _resetInnerTo(Widget target, _Phase phase) {
    if (_lastPhase == phase) {
      return; // Prevent loops when the state re-emits same phase
    }
    _lastPhase = phase;

    final nav = _innerNavKey.currentState!;
    nav.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => target,
        transitionDuration: Duration.zero,
      ),
      (r) => false, // wipe ONLY the inner navigator
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listenWhen: (p, c) {
        if (p.runtimeType != c.runtimeType) return true;
        // also fire when enrollmentStatus changes while still UserReady
        if (p is UserReady && c is UserReady) {
          return p.user.enrollmentStatus != c.user.enrollmentStatus;
        }
        return false;
      },
      listener: (context, state) {
        if (state is UserInitial || state is UserLoading) {
          _resetInnerTo(const Scaffold(body: Loader()), _Phase.loading);
          return;
        }

        if (state is UserUnauthenticated) {
          _resetInnerTo(
            BlocProvider(
              create: (_) =>
                  serviceLocator<AuthBloc>()..add(AuthCheckRequested()),
              child: const SignInPage(),
            ),
            _Phase.unauth,
          );
        }

        if (state is UserReady &&
            state.user.enrollmentStatus != EnrollmentStatus.active) {
          _resetInnerTo(const OnboardingFlow(), _Phase.onboarding);
          return;
        }

        if (state is UserReady) {
          _resetInnerTo(const TempDashboard(), _Phase.dashboard);
        }
      },

      // The outer scaffold hosts an INNER Navigator. Users never see this route.
      // Initial inner route is just a loader until the first state arrives.
      child: Navigator(
        key: _innerNavKey,
        onGenerateRoute: (_) =>
            MaterialPageRoute(builder: (_) => const Scaffold(body: Loader())),
      ),
    );
  }
}
