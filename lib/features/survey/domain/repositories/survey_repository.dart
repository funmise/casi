import 'package:casi/features/survey/domain/entities/survey_instance.dart';
import 'package:casi/features/survey/domain/entities/survey_template.dart';
import 'package:casi/features/survey/domain/entities/user_survey.dart';
import 'package:fpdart/fpdart.dart';
import 'package:casi/core/error/failures.dart';

abstract interface class SurveyRepository {
  Future<Either<Failure, SurveyInstance>> getActiveInstance();
  Future<Either<Failure, SurveyTemplate>> getTemplate(String versionId);
  Future<Either<Failure, UserSurvey?>> getUserSubmission({
    required String uid,
    required String quarterId,
  });

  Future<Either<Failure, void>> saveDraft({
    required String uid,
    required String quarterId,
    required String templateVersion,
    required Map<String, dynamic> answers,
  });

  Future<Either<Failure, void>> submit({
    required String uid,
    required String quarterId,
    required String templateVersion,
    required Map<String, dynamic> answers,
  });
}
