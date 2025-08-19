import 'package:casi/core/enums.dart';
import 'package:casi/features/enrollment/presentation/pages/temp_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:casi/core/widgets/loader.dart';
import 'package:casi/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:casi/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'verify_clinic_page.dart';
import 'terms_of_service_page.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      context.read<EnrollmentBloc>().add(LoadEnrollmentEvent(auth.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EnrollmentBloc, EnrollmentState>(
      // Rebuild the parent:
      //  • on initial -> loading (first spinner)
      //  • when we actually render something new (Loaded / not-found)
      buildWhen: (prev, cur) {
        if (cur is EnrollmentInitial) return true;
        if (prev is EnrollmentInitial && cur is EnrollmentLoading) {
          return true; // first load only
        }
        if (cur is EnrollmentLoaded) return true;
        if (cur is EnrollmentError && cur.message == 'enrollment-not-found') {
          return true;
        }
        return false; // ignore later EnrollmentLoading (from ToS page)
      },

      // Side-effects (routing/snackbars) that shouldn't rebuild this widget.
      listenWhen: (prev, cur) =>
          cur is ClinicSetSuccess ||
          cur is EthicsAccepted ||
          (cur is EnrollmentError && cur.message != 'enrollment-not-found'),

      listener: (context, state) {
        if (state is EnrollmentError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }

        if (state is ClinicSetSuccess) {
          // After verifying/choosing a clinic, go accept terms.
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
          );
        }

        if (state is EthicsAccepted) {
          // After accepting terms, go to your real home/dashboard.
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) =>
                  const Scaffold(body: Center(child: Text('dashboard'))),
            ),
          );
        }
      },

      builder: (context, state) {
        // Spinner only shows for the FIRST load (thanks to buildWhen above).
        if (state is EnrollmentInitial || state is EnrollmentLoading) {
          return const Scaffold(body: Loader());
        }

        // If the enrollment doc doesn't exist, ask to verify clinic.
        if (state is EnrollmentError &&
            state.message == 'enrollment-not-found') {
          return const VerifyClinicPage();
        }

        if (state is EnrollmentLoaded) {
          // Already picked a clinic but haven't accepted ethics yet.
          if (state.enrollment.status == EnrollmentStatus.awaitingEthics) {
            return const TermsOfServicePage();
          }

          // Already active → (temporary) dashboard/home.
          return const TempDashboard();
        }

        // Safety: shouldn't hit because of buildWhen, but keep a neutral fallback.
        return const Scaffold(body: Loader());
      },
    );
  }
}
