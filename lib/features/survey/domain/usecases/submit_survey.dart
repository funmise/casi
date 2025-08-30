import 'package:fpdart/fpdart.dart';
import 'package:casi/core/error/failures.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/features/survey/domain/repositories/survey_repository.dart';

class SubmitSurvey implements UseCase<void, ParamsSubmitSurvey> {
  final SurveyRepository repo;
  SubmitSurvey(this.repo);

  @override
  Future<Either<Failure, void>> call(ParamsSubmitSurvey p) {
    return repo.submit(
      uid: p.uid,
      quarterId: p.quarterId,
      templateVersion: p.templateVersion,
      answers: p.answers,
    );
  }
}

class ParamsSubmitSurvey {
  final String uid;
  final String quarterId;
  final String templateVersion;
  final Map<String, dynamic> answers;
  ParamsSubmitSurvey({
    required this.uid,
    required this.quarterId,
    required this.templateVersion,
    required this.answers,
  });
}
