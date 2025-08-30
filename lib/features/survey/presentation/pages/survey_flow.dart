import 'package:casi/core/user/cubit/user_cubit.dart';
import 'package:casi/core/user/cubit/user_state.dart';
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
          return PopScope(
            canPop: false,
            child: Navigator(
              onGenerateRoute: (_) {
                return MaterialPageRoute(
                  builder: (_) => SurveyInstructionsPage(
                    exitFlow: () => Navigator.of(parentCtx).pop(),
                    // pops parent of SurveyFlow
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
