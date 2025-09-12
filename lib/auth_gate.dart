import 'package:casi/core/enums.dart';
import 'package:casi/core/push/push_token_uploader.dart';
import 'package:casi/core/push/push_topics.dart';
import 'package:casi/core/user/cubit/user_cubit.dart';
import 'package:casi/core/user/cubit/user_state.dart';
import 'package:casi/core/widgets/loader.dart';
import 'package:casi/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:casi/features/auth/presentation/pages/sign_in_page.dart';
import 'package:casi/features/enrollment/presentation/pages/onboarding_flow.dart';
import 'package:casi/core/pages/dashboard.dart';
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
  final _innerNavKey = GlobalKey<NavigatorState>();
  _Phase? _lastPhase;
  bool _decided = false; // we’ve chosen onboarding/dashboard

  void _go(_Phase phase, Widget page) {
    if (_lastPhase == phase) return;
    _lastPhase = phase;
    _decided = phase == _Phase.onboarding || phase == _Phase.dashboard;

    _innerNavKey.currentState!.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listenWhen: (prev, curr) {
        if (prev.runtimeType != curr.runtimeType) return true;

        if (prev is UserReady && curr is UserReady) {
          final statusChanged =
              prev.user.enrollmentStatus != curr.user.enrollmentStatus;
          final cacheFlipBeforeDecision =
              !_decided && (prev.fromCache != curr.fromCache);
          // After we’ve decided, ignore cache flips completely.
          return statusChanged || cacheFlipBeforeDecision;
        }
        return false;
      },
      listener: (context, state) async {
        if (state is UserInitial || state is UserLoading) {
          if (!_decided) _go(_Phase.loading, const Scaffold(body: Loader()));
          return;
        }

        if (state is UserUnauthenticated) {
          _decided = false; // reset decision
          _lastPhase = null;
          _go(
            _Phase.unauth,
            BlocProvider(
              create: (_) =>
                  serviceLocator<AuthBloc>()..add(AuthCheckRequested()),
              child: const SignInPage(),
            ),
          );
          return;
        }

        if (state is UserReady) {
          // While we haven't decided yet, show loader on cached snapshots.
          if (state.fromCache && !_decided) {
            _go(_Phase.loading, const Scaffold(body: Loader()));
            return;
          }

          final status = state.user.enrollmentStatus;
          final phase = status == EnrollmentStatus.active
              ? _Phase.dashboard
              : _Phase.onboarding;

          // Only navigate on real (non-cached) data.
          if (!state.fromCache) {
            _go(
              phase,
              phase == _Phase.dashboard
                  ? const TempDashboard()
                  : const OnboardingFlow(),
            );

            // subscribe this device to the active quarter topic
            // This is idempotent and cheap; it will no-op if already subscribed.
            final user = state.user;
            final qid = user.activeSurveyQuarter;
            final qStatus = user.activeSurveyStatus;

            if (qid == null || qid.isEmpty || qStatus == 'submitted') {
              // fire-and-forget is fine; no need to block navigation
              PushTopics.unsubscribeAll();
            } else {
              // Client-side subscription
              await PushTopics.ensureSubscribed(qid);

              // Also upload token so server can manage subscriptions
              await PushTokenUploader.ensureUploaded();
            }
          }
        }
      },
      child: Navigator(
        key: _innerNavKey,
        onGenerateRoute: (_) => PageRouteBuilder(
          pageBuilder: (_, __, ___) => const Scaffold(body: Loader()),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      ),
    );
  }
}
