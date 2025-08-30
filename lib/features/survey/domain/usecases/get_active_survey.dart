import 'package:casi/features/survey/domain/entities/survey_instance.dart';
import 'package:casi/features/survey/domain/entities/survey_template.dart';
import 'package:fpdart/fpdart.dart';
import 'package:casi/core/error/failures.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/features/survey/domain/repositories/survey_repository.dart';

class GetActiveSurvey
    implements UseCase<(SurveyInstance, SurveyTemplate), NoParams> {
  final SurveyRepository repo;
  GetActiveSurvey(this.repo);

  @override
  Future<Either<Failure, (SurveyInstance, SurveyTemplate)>> call(
    NoParams _,
  ) async {
    final inst = await repo.getActiveInstance();
    return inst.fold(left, (i) async {
      final tmpl = await repo.getTemplate(i.templateVersion);
      return tmpl.fold(left, (t) => right((i, t)));
    });
  }
}
