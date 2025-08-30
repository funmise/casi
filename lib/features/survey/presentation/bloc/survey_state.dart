part of 'survey_bloc.dart';

sealed class SurveyState extends Equatable {
  const SurveyState();
  @override
  List<Object?> get props => [];
}

class SurveyInitial extends SurveyState {}

class SurveyLoading extends SurveyState {}

class SurveyError extends SurveyState {
  final String message;
  const SurveyError(this.message);
  @override
  List<Object?> get props => [message];
}

class SurveyLoaded extends SurveyState {
  final SurveyInstance instance;
  final SurveyTemplate template;
  final Map<String, dynamic> answers;
  final int currentIndex;
  final String status;
  final bool savedFlag;
  const SurveyLoaded({
    required this.instance,
    required this.template,
    required this.answers,
    required this.currentIndex,
    required this.status,
    this.savedFlag = false,
  });

  SurveyLoaded copyWith({
    SurveyInstance? instance,
    SurveyTemplate? template,
    Map<String, dynamic>? answers,
    int? currentIndex,
    String? status,
    bool? savedFlag,
  }) => SurveyLoaded(
    instance: instance ?? this.instance,
    template: template ?? this.template,
    answers: answers ?? this.answers,
    currentIndex: currentIndex ?? this.currentIndex,
    status: status ?? this.status,
    savedFlag: savedFlag ?? this.savedFlag,
  );

  @override
  List<Object?> get props => [
    instance,
    template,
    answers,
    currentIndex,
    status,
    savedFlag,
  ];
}

class SurveySubmitted extends SurveyState {}
