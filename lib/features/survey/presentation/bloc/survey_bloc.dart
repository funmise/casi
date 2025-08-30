import 'package:casi/features/survey/domain/entities/survey_instance.dart';
import 'package:casi/features/survey/domain/entities/survey_template.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/features/survey/domain/usecases/get_active_survey.dart';
import 'package:casi/features/survey/domain/usecases/get_user_submission.dart';
import 'package:casi/features/survey/domain/usecases/save_survey_draft.dart';
import 'package:casi/features/survey/domain/usecases/submit_survey.dart';

part 'survey_event.dart';
part 'survey_state.dart';

class SurveyBloc extends Bloc<SurveyEvent, SurveyState> {
  final GetActiveSurvey _getActive;
  final GetUserSubmission _getUserSub;
  final SaveSurveyDraft _saveDraft;
  final SubmitSurvey _submitSurvey;

  SurveyBloc({
    required GetActiveSurvey getActive,
    required GetUserSubmission getUserSubmission,
    required SaveSurveyDraft saveDraft,
    required SubmitSurvey submitSurvey,
  }) : _getActive = getActive,
       _getUserSub = getUserSubmission,
       _saveDraft = saveDraft,
       _submitSurvey = submitSurvey,
       super(SurveyInitial()) {
    on<LoadActiveSurveyEvent>(_onLoad);
    on<UpdateAnswerEvent>(_onUpdate);
    on<SaveDraftEvent>(_onSave);
    on<SubmitSurveyEvent>(_onSubmit);
    on<GoToPageEvent>((e, emit) {
      final st = state;
      if (st is SurveyLoaded) {
        emit(st.copyWith(currentIndex: e.index));
      }
    });
  }

  Future<void> _onLoad(
    LoadActiveSurveyEvent e,
    Emitter<SurveyState> emit,
  ) async {
    emit(SurveyLoading());
    final res = await _getActive(NoParams());
    await res.fold((l) async => emit(SurveyError(l.message)), (tuple) async {
      final (inst, tmpl) = tuple;
      final existing = await _getUserSub(
        ParamsGetUserSubmission(uid: e.uid, quarterId: inst.quarterId),
      );
      existing.fold(
        (l) => emit(SurveyError(l.message)),
        (u) => emit(
          SurveyLoaded(
            instance: inst,
            template: tmpl,
            answers: (u?.answers ?? {}),
            currentIndex: 0,
            status: u?.status ?? 'draft',
          ),
        ),
      );
    });
  }

  void _onUpdate(UpdateAnswerEvent e, Emitter<SurveyState> emit) {
    final st = state;
    if (st is! SurveyLoaded) return;
    final answers = Map<String, dynamic>.from(st.answers);
    final page = Map<String, dynamic>.from(answers[e.pageId] ?? {});
    page[e.fieldId] = e.value;
    answers[e.pageId] = page;
    emit(st.copyWith(answers: answers));
  }

  Future<void> _onSave(SaveDraftEvent e, Emitter<SurveyState> emit) async {
    final st = state;
    if (st is! SurveyLoaded) return;
    final res = await _saveDraft(
      ParamsSaveSurvey(
        uid: e.uid,
        quarterId: st.instance.quarterId,
        templateVersion: st.instance.templateVersion,
        answers: st.answers,
      ),
    );
    res.fold((l) => emit(SurveyError(l.message)), (_) {
      // re-read the *latest* state after the await
      final latest = state;
      if (latest is SurveyLoaded) {
        // Only flip the saved flag; keep whatever currentIndex (or other fields)
        // the user might have changed meanwhile.
        emit(latest.copyWith(savedFlag: true));
      }
    });
  }

  Future<void> _onSubmit(SubmitSurveyEvent e, Emitter<SurveyState> emit) async {
    final st = state;
    if (st is! SurveyLoaded) return;
    emit(SurveyLoading());
    final res = await _submitSurvey(
      ParamsSubmitSurvey(
        uid: e.uid,
        quarterId: st.instance.quarterId,
        templateVersion: st.instance.templateVersion,
        answers: st.answers,
      ),
    );
    res.fold(
      (l) => emit(SurveyError(l.message)),
      (_) => emit(SurveySubmitted()),
    );
  }
}
