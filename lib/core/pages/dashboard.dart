import 'dart:math' as math;
import 'package:casi/core/utils/days_to_quarter.dart';
import 'package:casi/core/widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:casi/core/user/cubit/user_cubit.dart';
import 'package:casi/core/user/cubit/user_state.dart';
import 'package:casi/features/survey/presentation/pages/survey_flow.dart';

class TempDashboard extends StatelessWidget {
  const TempDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, userState) {
        if (userState is! UserReady) {
          // Fallback shell (AuthGate shows loader during transitions)
          return const Scaffold(body: SizedBox.shrink());
        }

        final user = userState.user;
        final String displayName = user.name ?? 'Clinician';
        final String clinicName = user.clinicName ?? '';

        return _DashboardScaffold(
          displayName: displayName,
          clinicName: clinicName,
        );
      },
    );
  }
}

class _DashboardScaffold extends StatelessWidget {
  final String displayName;
  final String clinicName;

  const _DashboardScaffold({
    required this.displayName,
    required this.clinicName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text(
          'CASI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = math.min(constraints.maxWidth, 500.0);
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints.tightFor(width: maxW),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Greeting
                      Text(
                        'Hello, $displayName',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 12),

                      if (clinicName.isNotEmpty)
                        Text(
                          clinicName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      Padding(
                        padding: const EdgeInsets.all(50.0),
                        child: Image.asset(
                          'assets/images/therapy-dog.png',
                          height: 180,
                        ),
                      ),

                      const _TakeSurveyButton(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Therapy dog icon designed by Freepik',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.black.withValues(alpha: 0.35),
                ),
          ),
        ),
      ),
    );
  }
}

class _TakeSurveyButton extends StatelessWidget {
  const _TakeSurveyButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      buildWhen: (p, c) => c is UserReady,
      builder: (context, state) {
        if (state is! UserReady) return const SizedBox.shrink();

        final profile = state.user;
        final String? activeQ = profile.activeSurveyQuarter;
        final String status = (profile.activeSurveyStatus ?? '').toLowerCase();

        final bool hasActive = activeQ != null;
        final bool isSubmitted = status == 'submitted';
        final bool enabled = hasActive && !isSubmitted;

        final String label = (status == 'draft')
            ? 'Resume Survey'
            : 'Take Survey';

        final days = daysUntilNextQuarter(DateTime.now());
        String msg;

        if (activeQ == null) {
          msg = days > 0
              ? 'No survey available right now. \n Next survey opens in $days day${days == 1 ? '' : 's'}.'
              : 'No survey available right now. Please check back soon.';
        } else if (isSubmitted) {
          msg =
              "You've already submitted the $activeQ survey. \n"
              'Next survey opens in $days day${days == 1 ? '' : 's'}.';
        } else {
          msg =
              'Fill in survey about specific diseases\n'
              'diagnosed in dogs';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              msg,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 190,
              height: 48,
              child: ElevatedButton(
                onPressed: enabled
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SurveyFlow()),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
                child: Text(label),
              ),
            ),
          ],
        );
      },
    );
  }
}
