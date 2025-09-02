import 'package:casi/features/survey/domain/entities/survey_instance.dart';
import 'package:casi/features/survey/domain/entities/survey_template.dart';
import 'package:casi/features/survey/domain/entities/user_survey.dart';
import 'package:fpdart/fpdart.dart';
import 'package:casi/core/error/failures.dart';
import 'package:casi/core/error/exceptions.dart';
import 'package:casi/features/survey/domain/repositories/survey_repository.dart';
import 'package:casi/features/survey/data/data_sources/survey_remote_data_source.dart';

class SurveyRepositoryImpl implements SurveyRepository {
  final SurveyRemoteDataSource remote;
  SurveyRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, SurveyInstance>> getActiveInstance() async {
    try {
      final res = await remote.getActiveInstance();
      return right(res);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, SurveyTemplate>> getTemplate(String versionId) async {
    try {
      final res = await remote.getTemplate(versionId);
      return right(res);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserSurvey?>> getUserSubmission({
    required String uid,
    required String quarterId,
  }) async {
    try {
      final res = await remote.getUserSubmission(
        uid: uid,
        quarterId: quarterId,
      );
      return right(res);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> saveDraft({
    required String uid,
    required String quarterId,
    required String templateVersion,
    required Map<String, dynamic> answers,
    required int currentIndex,
  }) async {
    try {
      await remote.saveDraft(
        uid: uid,
        quarterId: quarterId,
        templateVersion: templateVersion,
        answers: answers,
        currentIndex: currentIndex,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> submit({
    required String uid,
    required String quarterId,
    required String templateVersion,
    required Map<String, dynamic> answers,
  }) async {
    try {
      await remote.submit(
        uid: uid,
        quarterId: quarterId,
        templateVersion: templateVersion,
        answers: answers,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
