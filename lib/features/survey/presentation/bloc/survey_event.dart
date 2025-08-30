part of 'survey_bloc.dart';

sealed class SurveyEvent extends Equatable {
  const SurveyEvent();
  @override
  List<Object?> get props => [];
}

class LoadActiveSurveyEvent extends SurveyEvent {
  final String uid;
  const LoadActiveSurveyEvent(this.uid);
  @override
  List<Object?> get props => [uid];
}

class UpdateAnswerEvent extends SurveyEvent {
  final String pageId;
  final String fieldId;
  final dynamic value;
  const UpdateAnswerEvent(this.pageId, this.fieldId, this.value);
  @override
  List<Object?> get props => [pageId, fieldId, value];
}

class SaveDraftEvent extends SurveyEvent {
  final String uid;
  const SaveDraftEvent(this.uid);
  @override
  List<Object?> get props => [uid];
}

class SubmitSurveyEvent extends SurveyEvent {
  final String uid;
  const SubmitSurveyEvent(this.uid);
  @override
  List<Object?> get props => [uid];
}

class GoToPageEvent extends SurveyEvent {
  final int index;
  const GoToPageEvent(this.index);
  @override
  List<Object?> get props => [index];
}
