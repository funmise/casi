import 'package:casi/features/survey/domain/entities/user_survey.dart';
import 'package:fpdart/fpdart.dart';
import 'package:casi/core/error/failures.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/features/survey/domain/repositories/survey_repository.dart';

class GetUserSubmission
    implements UseCase<UserSurvey?, ParamsGetUserSubmission> {
  final SurveyRepository repo;
  GetUserSubmission(this.repo);

  @override
  Future<Either<Failure, UserSurvey?>> call(ParamsGetUserSubmission p) {
    return repo.getUserSubmission(uid: p.uid, quarterId: p.quarterId);
  }
}

class ParamsGetUserSubmission {
  final String uid;
  final String quarterId;
  ParamsGetUserSubmission({required this.uid, required this.quarterId});
}
