import 'package:casi/core/user/cubit/user_cubit.dart';
import 'package:casi/core/user/cubit/user_state.dart';
import 'package:casi/core/widgets/loader.dart';
import 'package:casi/features/survey/presentation/pages/survey_page_renderer.dart';
import 'package:casi/features/survey/presentation/pages/survey_thank_you_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:casi/init_dependencies.dart';
import 'package:casi/features/survey/presentation/bloc/survey_bloc.dart';
import 'survey_instructions_page.dart';

class SurveyFlow extends StatelessWidget {
  const SurveyFlow({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = (context.read<UserCubit>().state as UserReady).user.uid;

    return BlocProvider(
      create: (_) =>
          serviceLocator<SurveyBloc>()..add(LoadActiveSurveyEvent(uid)),
      child: Builder(
        builder: (parentCtx) {
          return BlocConsumer<SurveyBloc, SurveyState>(
            listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
            listener: (context, state) {
              if (state is SurveySubmitted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SurveyThankYouPage()),
                );
              }
              if (state is SurveyError) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            builder: (ctx, state) {
              if (state is! SurveyLoaded) {
                return const Scaffold(body: Loader());
              }

              final startOnRenderer = (state.currentIndex) > 0;
              return PopScope(
                canPop: false,
                child: Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute(
                    builder: (_) => startOnRenderer
                        ? SurveyPageRenderer(
                            exitFlow: () => Navigator.of(parentCtx).pop(),
                          )
                        : SurveyInstructionsPage(
                            exitFlow: () => Navigator.of(parentCtx).pop(),
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
