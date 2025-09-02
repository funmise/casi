import 'package:fpdart/fpdart.dart';
import 'package:casi/core/error/failures.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/features/survey/domain/repositories/survey_repository.dart';

class SaveSurveyDraft implements UseCase<void, ParamsSaveSurvey> {
  final SurveyRepository repo;
  SaveSurveyDraft(this.repo);

  @override
  Future<Either<Failure, void>> call(ParamsSaveSurvey p) {
    return repo.saveDraft(
      uid: p.uid,
      quarterId: p.quarterId,
      templateVersion: p.templateVersion,
      answers: p.answers,
      currentIndex: p.currentIndex,
    );
  }
}

class ParamsSaveSurvey {
  final String uid;
  final String quarterId;
  final String templateVersion;
  final Map<String, dynamic> answers;
  int currentIndex;
  ParamsSaveSurvey({
    required this.uid,
    required this.quarterId,
    required this.templateVersion,
    required this.answers,
    required this.currentIndex,
  });
}
