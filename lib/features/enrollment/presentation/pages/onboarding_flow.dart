import 'package:casi/core/user/cubit/user_cubit.dart';
import 'package:casi/core/user/cubit/user_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:casi/init_dependencies.dart';
import 'package:casi/features/enrollment/presentation/bloc/enrollment_bloc.dart';

import 'package:casi/features/enrollment/presentation/pages/verify_clinic_page.dart';

class OnboardingFlow extends StatelessWidget {
  const OnboardingFlow({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = (context.read<UserCubit>().state as UserReady).user.uid;

    return BlocProvider(
      create: (_) =>
          serviceLocator<EnrollmentBloc>()..add(LoadEnrollmentEvent(uid)),
      child: Navigator(
        onGenerateRoute: (_) =>
            MaterialPageRoute(builder: (_) => const VerifyClinicPage()),
      ),
    );
  }
}
